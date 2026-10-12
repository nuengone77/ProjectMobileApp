// หน้า “ตารางสรุปเคส” ของเจ้าหน้าที่ (เข้าจากการ์ดในหน้าภาพรวม)
//
// - ตารางเดียว เรียงตามวันที่ กรองช่องทาง ทั้งหมด / online / onsite
// - กรองช่วงวันที่: รายเดือน (เลื่อนเดือนได้) หรือกำหนดช่วงวันเอง
// - แถว online มาจากแชทที่จบแล้วอัตโนมัติ, แถว onsite เจ้าหน้าที่กดเพิ่มเอง
// - แตะแถวเพื่อแก้ (เฉพาะ ประเภท / เรื่องที่ปรึกษา / คำปรึกษา / ระดับ) แก้แล้วไม่กระทบแชท
// - export เฉพาะแถวที่กรองอยู่: CSV, PDF (แชร์ไฟล์ผ่านหน้าแชร์ของเครื่อง)
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/app_data.dart';
import '../data/models.dart';
import '../data/registration_rules.dart';
import '../data/report_export.dart';
import '../providers/auth_provider.dart';
import '../providers/report_provider.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// รูปแบบไฟล์ที่ export ได้
enum _ExportKind { csv, pdf }

class StaffReportScreen extends StatefulWidget {
  const StaffReportScreen({super.key});

  @override
  State<StaffReportScreen> createState() => _StaffReportScreenState();
}

class _StaffReportScreenState extends State<StaffReportScreen> {
  /// เดือนที่เลือก (ใช้เมื่อ [_custom] = null)
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  /// ช่วงวันที่กำหนดเอง (null = ใช้แบบรายเดือน)
  DateTimeRange? _custom;

  /// ช่องทางที่กรอง (null = ทั้งหมด)
  ConsultChannel? _channel;

  bool _exporting = false;

  DateTime get _from => _custom?.start ?? _month;
  DateTime get _to =>
      _custom?.end ??
      DateTime(_month.year, _month.month + 1, 0); // วันสุดท้ายของเดือน

  String get _rangeLabel => _custom == null
      ? thaiMonthYear(_month)
      : '${thaiDateShort(_custom!.start)} – ${thaiDateShort(_custom!.end)}';

  /// แถวตามตัวกรองปัจจุบัน ([listen] = true ใน build ให้ตารางวาดใหม่เมื่อข้อมูลเปลี่ยน)
  List<CaseReport> _rows({bool listen = false}) =>
      (listen
              ? context.watch<ReportProvider>()
              : context.read<ReportProvider>())
          .myReports(from: _from, to: _to, channel: _channel);

  void _shiftMonth(int delta) => setState(() {
    _custom = null;
    _month = DateTime(_month.year, _month.month + delta);
  });

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: DateTimeRange(start: _from, end: _to),
      helpText: 'เลือกช่วงวันที่',
    );
    if (r != null) setState(() => _custom = r);
  }

  // ---------------------------------------------------------------- export

  Future<void> _export(_ExportKind kind) async {
    final rows = _rows();
    final me = context.read<AuthProvider>().currentUser!;
    final stamp = _custom == null
        ? '${_month.year + 543}-${_month.month.toString().padLeft(2, '0')}'
        : 'custom';
    final base = 'kaiwan_case_report_$stamp';
    setState(() => _exporting = true);
    try {
      final dir = await getTemporaryDirectory();
      final File file;
      final String mime;
      if (kind == _ExportKind.pdf) {
        final bytes = await ReportExport.buildPdf(
          rows,
          title: 'ตารางสรุปเคส · $_rangeLabel',
          subtitle:
              '${me.displayName} (${me.name})'
              '${_channel == null ? '' : ' · ช่องทาง ${_channel!.name}'}',
        );
        file = File('${dir.path}/$base.pdf')..writeAsBytesSync(bytes);
        mime = 'application/pdf';
      } else {
        file = File('${dir.path}/$base.csv')
          ..writeAsStringSync(ReportExport.buildCsv(rows));
        mime = 'text/csv';
      }
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: mime)],
          subject: 'ตารางสรุปเคส $_rangeLabel',
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('export ไม่สำเร็จ: $e')));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  // ---------------------------------------------------------------- add / edit

  Future<void> _openEditor({CaseReport? row}) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _ReportEditor(row: row),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ตารางสรุปเคส'),
        actions: [
          if (_exporting)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            PopupMenuButton<_ExportKind>(
              tooltip: 'Export',
              icon: const Icon(Icons.ios_share),
              onSelected: (k) => _export(k),
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: _ExportKind.csv,
                  child: ListTile(
                    leading: Icon(Icons.table_view_outlined),
                    title: Text('Export CSV'),
                  ),
                ),
                PopupMenuItem(
                  value: _ExportKind.pdf,
                  child: ListTile(
                    leading: Icon(Icons.picture_as_pdf_outlined),
                    title: Text('Export PDF'),
                  ),
                ),
              ],
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.black,
        foregroundColor: Colors.white,
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มเคส onsite'),
      ),
      body: Builder(
        builder: (context) {
          final rows = _rows(listen: true);
          return Column(
            children: [
              // ---- ตัวกรองช่วงวันที่
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'เดือนก่อน',
                      onPressed: () => _shiftMonth(-1),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: Text(
                        _rangeLabel,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'เดือนถัดไป',
                      onPressed: () => _shiftMonth(1),
                      icon: const Icon(Icons.chevron_right),
                    ),
                    TextButton.icon(
                      onPressed: _pickRange,
                      icon: const Icon(Icons.date_range, size: 18),
                      label: const Text('กำหนดเอง'),
                    ),
                  ],
                ),
              ),
              // ---- ตัวกรองช่องทาง
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: SegmentedButton<ConsultChannel?>(
                  segments: const [
                    ButtonSegment(value: null, label: Text('ทั้งหมด')),
                    ButtonSegment(
                      value: ConsultChannel.online,
                      label: Text('online'),
                    ),
                    ButtonSegment(
                      value: ConsultChannel.onsite,
                      label: Text('onsite'),
                    ),
                  ],
                  selected: {_channel},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => setState(() => _channel = s.first),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                child: Row(
                  children: [
                    Text(
                      '${rows.length} เคส',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    const Text(
                      'แตะแถวเพื่อแก้ไข',
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: rows.isEmpty
                    ? const Center(
                        child: Text(
                          'ไม่มีเคสในช่วงเวลานี้',
                          style: TextStyle(color: AppColors.muted),
                        ),
                      )
                    : _ReportTable(
                        rows: rows,
                        onTap: (r) => _openEditor(row: r),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// ตารางเลื่อนได้ทั้งแนวตั้งและแนวนอน (คอลัมน์ตามแบบ 8 คอลัมน์)
class _ReportTable extends StatelessWidget {
  const _ReportTable({required this.rows, required this.onTap});
  final List<CaseReport> rows;
  final ValueChanged<CaseReport> onTap;

  @override
  Widget build(BuildContext context) {
    // ข้อความยาวตัดที่ 2 บรรทัด (ดูเต็มได้ตอนแตะแก้ไข)
    DataCell text(String v, {double width = 160}) => DataCell(
      SizedBox(
        width: width,
        child: Text(v, maxLines: 2, overflow: TextOverflow.ellipsis),
      ),
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 96), // เว้นที่ให้ปุ่มเพิ่มเคส
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          showCheckboxColumn: false,
          headingRowColor: const WidgetStatePropertyAll(AppColors.yellowDeep),
          dataRowMinHeight: 52,
          dataRowMaxHeight: 68,
          border: TableBorder.symmetric(
            inside: const BorderSide(color: AppColors.line),
          ),
          columns: [
            for (final h in ReportExport.headers)
              DataColumn(
                label: Text(
                  h,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
          ],
          rows: [
            for (final r in rows)
              DataRow(
                color: WidgetStatePropertyAll(
                  AppData.category(r.categoryId).urgent
                      ? AppColors.orange
                      : AppColors.yellowLight,
                ),
                onSelectChanged: (_) => onTap(r),
                cells: [
                  text(ReportExport.dateText(r.date), width: 110),
                  text(r.studentIdNo, width: 80),
                  text(r.studentName, width: 130),
                  text(ReportExport.categoryLabel(r.categoryId), width: 70),
                  text(r.channel.name, width: 60),
                  text(r.topic.isEmpty ? '—' : r.topic, width: 200),
                  text(r.advice.isEmpty ? '—' : r.advice, width: 220),
                  text(r.level?.display ?? '—', width: 70),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// แผ่นแก้ไขแถว / เพิ่มแถว onsite
/// - แก้แถวเดิม ([row] มีค่า): แก้ได้เฉพาะ ประเภท / เรื่องที่ปรึกษา / คำปรึกษา / ระดับ
///   แถว onsite ที่เพิ่มเองลบได้ด้วย
/// - เพิ่มแถว onsite ([row] = null): กรอกวันที่ รหัสนิสิต ชื่อ-สกุล + ข้อมูลเคส
class _ReportEditor extends StatefulWidget {
  const _ReportEditor({this.row});
  final CaseReport? row;

  @override
  State<_ReportEditor> createState() => _ReportEditorState();
}

class _ReportEditorState extends State<_ReportEditor> {
  final _form = GlobalKey<FormState>();
  late final _topic = TextEditingController(text: widget.row?.topic ?? '');
  late final _advice = TextEditingController(text: widget.row?.advice ?? '');
  late final _idNo = TextEditingController();
  late final _name = TextEditingController();
  late String _category = widget.row?.categoryId ?? 'general';
  late CaseLevel? _level = widget.row?.level;
  DateTime _date = DateTime.now();

  bool get _isNew => widget.row == null;

  InputDecoration _box(String label) => InputDecoration(
    labelText: label,
    alignLabelWithHint: true,
    floatingLabelBehavior: FloatingLabelBehavior.always,
    contentPadding: const EdgeInsets.all(14),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.line),
    ),
  );

  Future<void> _pickDateTime() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(DateTime.now().year - 3),
      lastDate: DateTime.now(),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
    );
    setState(
      () => _date = DateTime(
        d.year,
        d.month,
        d.day,
        t?.hour ?? _date.hour,
        t?.minute ?? _date.minute,
      ),
    );
  }

  /// พิมพ์รหัสนิสิตครบแล้วเจอในระบบ -> กรอกชื่อให้อัตโนมัติ
  void _onIdChanged(String v) {
    final s = context.read<ReportProvider>().studentByIdNo(v);
    if (s != null && _name.text.trim().isEmpty) _name.text = s.name;
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    if (_isNew) {
      context.read<ReportProvider>().addOnsiteReport(
        date: _date,
        studentIdNo: _idNo.text,
        studentName: _name.text,
        categoryId: _category,
        topic: _topic.text,
        advice: _advice.text,
        level: _level,
      );
    } else {
      context.read<ReportProvider>().updateReport(
        widget.row!,
        categoryId: _category,
        topic: _topic.text,
        advice: _advice.text,
        level: _level,
      );
    }
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ลบแถวนี้?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.alert),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      context.read<ReportProvider>().deleteReport(widget.row!);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.row;
    Widget locked(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
          ),
          Expanded(child: Text(value)),
          const Icon(Icons.lock_outline, size: 14, color: AppColors.muted),
        ],
      ),
    );
    return UnsavedChangesGuard(
      // บทที่ 9 (PopScope): แก้/กรอกแล้วปัดปิดหรือกดย้อนกลับ -> ถามก่อนทิ้ง
      isDirty: () {
        final r = widget.row;
        if (r == null) {
          return [_idNo, _name, _topic, _advice].any((c) => c.text.isNotEmpty);
        }
        return _topic.text != r.topic ||
            _advice.text != r.advice ||
            _category != r.categoryId ||
            _level != r.level;
      },
      listenable: Listenable.merge([_idNo, _name, _topic, _advice]),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Form(
              key: _form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _isNew ? 'เพิ่มเคส onsite' : 'แก้ไขแถวในตาราง',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isNew
                        ? 'กรอกหลังคุยกับนิสิตที่ห้องกิจการนิสิตเสร็จ'
                        : 'แก้เฉพาะในตารางรายงาน ไม่กระทบข้อมูลในแชท',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 16),
                  if (r != null) ...[
                    // คอลัมน์ที่ล็อก (แก้ไม่ได้)
                    locked('วันที่', ReportExport.dateText(r.date)),
                    locked('รหัสนิสิต', r.studentIdNo),
                    locked('ชื่อ-สกุล', r.studentName),
                    locked('ช่องทาง', r.channel.name),
                    const SizedBox(height: 10),
                  ] else ...[
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        alignment: Alignment.centerLeft,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _pickDateTime,
                      icon: const Icon(Icons.event),
                      label: Text('วันที่: ${ReportExport.dateText(_date)}'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _idNo,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(8),
                      ],
                      onChanged: _onIdChanged,
                      validator: RegistrationRules.studentIdError,
                      decoration: _box('รหัสนิสิต'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _name,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'กรุณากรอกชื่อ-สกุล'
                          : null,
                      decoration: _box('ชื่อ-สกุล'),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // ---- คอลัมน์ที่แก้ได้
                  DropdownButtonFormField<String>(
                    initialValue: _category,
                    decoration: _box('ประเภทการถาม/ตอบ'),
                    borderRadius: BorderRadius.circular(14),
                    items: [
                      for (final c in AppData.categories)
                        DropdownMenuItem(
                          value: c.id,
                          child: Text(ReportExport.categoryLabel(c.id)),
                        ),
                    ],
                    onChanged: (v) => setState(() => _category = v!),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _topic,
                    maxLines: 3,
                    decoration: _box('เรื่องที่ถาม/ตอบ'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _advice,
                    maxLines: 3,
                    decoration: _box('คำตอบที่เจ้าหน้าที่ให้'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<CaseLevel>(
                    initialValue: _level,
                    decoration: _box('ระดับ'),
                    hint: const Text('เลือกระดับ'),
                    borderRadius: BorderRadius.circular(14),
                    items: [
                      for (final l in CaseLevel.values)
                        DropdownMenuItem(value: l, child: Text(l.display)),
                    ],
                    onChanged: (v) => setState(() => _level = v),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _save,
                    child: Text(_isNew ? 'เพิ่มลงตาราง' : 'บันทึก'),
                  ),
                  if (r != null && r.isManual) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.alert,
                      ),
                      onPressed: _delete,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('ลบแถวนี้'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
