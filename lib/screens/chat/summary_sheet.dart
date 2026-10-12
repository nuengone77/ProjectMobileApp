// สรุปการสนทนา: ฟอร์มที่เจ้าหน้าที่กรอกตอนจบแชท + กล่องแสดงสรุปหลังจบ
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models.dart';
import '../../providers/auth_provider.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// ฟอร์มสรุปการปรึกษา (เลื่อนขึ้นจากด้านล่าง) ให้เจ้าหน้าที่กรอกตอนจบการปรึกษา
/// ต้องกรอกครบ: เรื่องที่ปรึกษา / คำปรึกษาที่เจ้าหน้าที่ให้ / ระดับเคส (เล็ก/กลาง/ใหญ่)
/// [closing] = true ตอนกดจบ, false ตอนแก้ไขสรุปทีหลัง (เติมค่าเดิมไว้ให้)
class SummarySheet extends StatefulWidget {
  const SummarySheet({super.key, required this.conv, required this.closing});
  final Conversation conv;
  final bool closing;

  @override
  State<SummarySheet> createState() => _SummarySheetState();
}

class _SummarySheetState extends State<SummarySheet> {
  final _form = GlobalKey<FormState>();
  late final _topic = TextEditingController(text: widget.conv.summaryTopic);
  late final _help = TextEditingController(text: widget.conv.summaryHelp);
  late CaseLevel? _level = widget.conv.caseLevel; // ระดับเคส (ต้องเลือก)

  InputDecoration _box(String label, String hint) => InputDecoration(
    labelText: label,
    hintText: hint,
    alignLabelWithHint: true,
    floatingLabelBehavior: FloatingLabelBehavior.always,
    contentPadding: const EdgeInsets.all(16),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.line),
    ),
  );

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'กรุณากรอกช่องนี้' : null;

  @override
  Widget build(BuildContext context) {
    final student = context.watch<AuthProvider>().user(widget.conv.studentId);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
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
                  widget.closing ? 'จบการสนทนา' : 'สรุปการสนทนา',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'บันทึกสรุปเก็บเป็นประวัติ · ${student.name}',
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _topic,
                  maxLines: 3,
                  validator: _required,
                  decoration: _box(
                    'เรื่องที่ถาม/ตอบ',
                    'เช่น สอบถามเอกสาร กยศ. ที่ต้องใช้',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _help,
                  maxLines: 3,
                  validator: _required,
                  decoration: _box(
                    'คำตอบที่เจ้าหน้าที่ให้',
                    'เช่น แจ้งรายการเอกสารและกำหนดส่ง',
                  ),
                ),
                const SizedBox(height: 16),
                // ระดับเคส: เล็ก 🟢 / กลาง 🟡 / ใหญ่ 🔴
                DropdownButtonFormField<CaseLevel>(
                  initialValue: _level,
                  borderRadius: BorderRadius.circular(16),
                  decoration: _box('ระดับเคส', ''),
                  hint: const Text('เลือกระดับเคส'),
                  items: [
                    for (final l in CaseLevel.values)
                      DropdownMenuItem(value: l, child: Text(l.display)),
                  ],
                  onChanged: (v) => setState(() => _level = v),
                  validator: (v) => v == null ? 'กรุณาเลือกระดับเคส' : null,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () {
                    if (!_form.currentState!.validate()) return;
                    Navigator.pop(context, (_topic.text, _help.text, _level!));
                  },
                  child: Text(
                    widget.closing ? 'บันทึกและจบการสนทนา' : 'บันทึกสรุป',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// แถบล่างของแชทที่จบแล้ว (ฝั่งเจ้าหน้าที่): แสดงสรุปการปรึกษา + ปุ่มแก้ไข
/// ถ้านักศึกษากดจบเองจะยังไม่มีสรุป -> แสดงปุ่ม “บันทึกสรุป”
class SummaryPanel extends StatelessWidget {
  const SummaryPanel({super.key, required this.conv, required this.onEdit});
  final Conversation conv;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final closer = conv.closedById == null
        ? null
        : context.watch<AuthProvider>().user(conv.closedById!);
    Widget field(String label, String value) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          Text(value),
        ],
      ),
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.cream,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.assignment_turned_in_outlined,
                  size: 18,
                  color: AppColors.black,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'จบการสนทนาแล้ว'
                    '${conv.closedAt != null ? ' · ${timeLabel(conv.closedAt!)}' : ''}'
                    '${closer != null ? ' · โดย ${closer.isStaff ? closer.displayName : 'นักศึกษา'}' : ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onEdit,
                  child: Text(conv.hasSummary ? 'แก้ไขสรุป' : 'บันทึกสรุป'),
                ),
              ],
            ),
            if (conv.hasSummary) ...[
              if (conv.caseLevel != null)
                field('ระดับเคส', conv.caseLevel!.display),
              field('เรื่องที่ถามตอบ', conv.summaryTopic),
              field('คำตอบที่เจ้าหน้าที่ให้', conv.summaryHelp),
            ] else
              const Text(
                'ยังไม่ได้บันทึกสรุป (นักศึกษากดจบการสนทนาเอง)',
                style: TextStyle(color: AppColors.alert),
              ),
          ],
        ),
      ),
    );
  }
}
