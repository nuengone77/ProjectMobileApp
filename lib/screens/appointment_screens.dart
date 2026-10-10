// หน้าจอนัดหมาย “ถามตอบกับพี่ไข่หวานที่ห้องกิจการนิสิต”
//
// ลำดับการใช้งาน:
//   นักศึกษา: เลือกคนไหนก็ได้ / เลือกพี่เอง (ConsultModeScreen ใน student_screens.dart)
//             -> AppointmentBookingScreen (เลือกวันในปฏิทิน + เลือกเวลาจาก dropdown) -> ส่งคำขอ
//             คนไหนก็ได้ = แจ้งเตือนเจ้าหน้าที่ทุกคน, เลือกพี่เอง = แจ้งเตือนเฉพาะคนนั้น
//             -> แท็บ “นัดหมาย” (MyAppointmentsScreen) ดูสถานะ
//   เจ้าหน้าที่: แท็บ “นัดหมาย” (StaffAppointmentsScreen) ตรวจเวลาว่างเอง แล้ว
//             - ว่าง    -> กด “ยืนยัน สะดวกเวลานี้”
//             - ไม่ว่าง -> กด “เสนอเวลาอื่น” เลือกวัน/เวลาที่ตัวเองว่าง (+ ข้อความ)
//                         -> นักศึกษากด “ตกลงเวลานี้” หรือ “เลือกเวลาอื่น”
import 'package:flutter/material.dart';

import '../data/mock_store.dart';
import '../data/models.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// วันแรกที่ยังนัดได้: วันนี้ถ้ายังมีช่องเวลาที่ยังไม่ผ่านไป ไม่งั้นเลื่อนไปวันทำการถัดไป
DateTime firstBookableDay() {
  final now = DateTime.now();
  var d = DateTime(now.year, now.month, now.day);
  while (!MockStore.isOfficeDay(d) ||
      !MockStore.slotsOf(d).any(MockStore.isBookable)) {
    d = d.add(const Duration(days: 1));
  }
  return d;
}

/// ช่องเลือกเวลาแบบ dropdown (ครั้งละ 30 นาที) ของวัน [day]
/// แสดงทุกช่องเวลาของวันนั้น ยกเว้นเวลาที่ผ่านไปแล้ว
/// ใช้ทั้งหน้าจองของนักศึกษา และหน้าเสนอเวลาใหม่ของเจ้าหน้าที่
class SlotDropdown extends StatelessWidget {
  const SlotDropdown({
    super.key,
    required this.day,
    required this.value,
    required this.onChanged,
  });
  final DateTime day;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    final slots = MockStore.slotsOf(day).where(MockStore.isBookable).toList();
    return DropdownButtonFormField<DateTime>(
      // key ตามวัน: เปลี่ยนวันแล้วล้างเวลาที่เลือกไว้
      key: ValueKey(day),
      initialValue: slots.contains(value) ? value : null,
      isExpanded: true,
      menuMaxHeight: 320,
      borderRadius: BorderRadius.circular(16),
      icon: const Icon(Icons.keyboard_arrow_down_rounded),
      hint: const Text('เลือกเวลา'),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.schedule, color: AppColors.caramel),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.line),
        ),
      ),
      items: [
        for (final s in slots)
          DropdownMenuItem(value: s, child: Text('${timeRange(s)} น.')),
      ],
      onChanged: onChanged,
    );
  }
}

/// หน้าจองนัด: ข้อมูลห้อง, นัดกับใคร, ปฏิทินเลือกวัน, dropdown เลือกเวลา,
/// ช่องเรื่องที่อยากปรึกษา และปุ่มส่งคำขอ
/// [staffId] = เจ้าหน้าที่ที่เลือกเอง (null = คนไหนก็ได้ แจ้งเตือนทุกคน)
class AppointmentBookingScreen extends StatefulWidget {
  const AppointmentBookingScreen({super.key, this.staffId});
  final String? staffId;

  @override
  State<AppointmentBookingScreen> createState() =>
      _AppointmentBookingScreenState();
}

class _AppointmentBookingScreenState extends State<AppointmentBookingScreen> {
  DateTime _day = firstBookableDay();
  DateTime? _slot; // เวลาที่เลือก (null = ยังไม่เลือก)
  final _note = TextEditingController();

  void _submit() {
    final a = store.requestAppointment(
      _slot!,
      _note.text,
      staffId: widget.staffId,
    );
    Navigator.of(context).popUntil((r) => r.isFirst);
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const MyAppointmentsScreen()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'ส่งคำขอนัด ${thaiDate(a.start)} ${timeRange(a.start)} แล้ว รอพี่ไข่หวานยืนยันนะ',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return Scaffold(
      appBar: AppBar(title: const Text('นัดหมายที่ห้องกิจการนิสิต')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          const OfficeInfoCard(),
          const SizedBox(height: 12),
          _WithWhom(staffId: widget.staffId),
          const SizedBox(height: 16),
          const _SectionTitle('เลือกวัน'),
          // ปฏิทิน: เลือกได้เฉพาะวันจันทร์–ศุกร์ ภายใน 60 วัน
          Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            child: CalendarDatePicker(
              initialDate: _day,
              firstDate: today,
              lastDate: today.add(const Duration(days: 60)),
              selectableDayPredicate: MockStore.isOfficeDay,
              onDateChanged: (d) => setState(() {
                _day = d;
                _slot = null;
              }),
            ),
          ),
          const SizedBox(height: 16),
          _SectionTitle(
            'เลือกเวลา · ${thaiDate(_day)}',
            caption:
                'ให้คำปรึกษาครั้งละ 30 นาที พี่จะตรวจเวลาว่างแล้วยืนยันให้',
          ),
          SlotDropdown(
            day: _day,
            value: _slot,
            onChanged: (s) => setState(() => _slot = s),
          ),
          const SizedBox(height: 16),
          const _SectionTitle('อยากปรึกษาเรื่องอะไร (ไม่บังคับ)'),
          TextField(
            controller: _note,
            maxLines: 3,
            decoration: _boxDecoration('เล่าสั้นๆ ให้พี่เตรียมตัวก่อนได้'),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _slot == null ? null : _submit,
            child: Text(
              _slot == null
                  ? 'เลือกเวลาก่อนนะ'
                  : 'ส่งคำขอนัด ${timeRange(_slot!)}',
            ),
          ),
        ],
      ),
    );
  }
}

/// กรอบช่องพิมพ์ข้อความหลายบรรทัด (มุมโค้ง ขอบอ่อน)
InputDecoration _boxDecoration(String hint) => InputDecoration(
  hintText: hint,
  contentPadding: const EdgeInsets.all(16),
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: const BorderSide(color: AppColors.line),
  ),
);

/// แถบบอกว่านัดนี้ส่งถึงใคร: พี่ที่เลือก หรือพี่ไข่หวานทุกคน
class _WithWhom extends StatelessWidget {
  const _WithWhom({required this.staffId});
  final String? staffId;

  @override
  Widget build(BuildContext context) {
    final staff = staffId == null ? null : store.user(staffId!);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          if (staff != null)
            StaffAvatar(user: staff, size: 40)
          else
            const CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.honey,
              child: Icon(Icons.groups_rounded, color: AppColors.ink),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  staff != null
                      ? 'นัดกับ ${staff.displayName}'
                      : 'นัดกับพี่ไข่หวานคนไหนก็ได้',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  staff != null
                      ? 'แจ้งเตือนเวลานัดถึงพี่คนนี้เท่านั้น'
                      : 'แจ้งเตือนเวลานัดถึงพี่ไข่หวานทุกคน',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// การ์ดข้อมูลห้องกิจการนิสิต (ที่ตั้ง, เวลาเปิด, เบอร์โทร)
class OfficeInfoCard extends StatelessWidget {
  const OfficeInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    Widget row(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.caramel),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.honey.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            MockStore.officeName,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          row(Icons.place_outlined, MockStore.officeLocation),
          row(Icons.schedule, MockStore.officeHoursText),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {this.caption});
  final String title;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          if (caption != null)
            Text(
              caption!,
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
        ],
      ),
    );
  }
}

/// แท็บ/หน้า “นัดหมาย” ฝั่งนักศึกษา: รายการนัดทั้งหมดพร้อมสถานะ
/// - รอยืนยัน: ยกเลิกนัดได้
/// - พี่เสนอเวลาใหม่: “ยกเลิกนัด” / “เลือกเวลาอื่น” / “ตกลงเวลานี้”
/// (ยืนยันแล้วยกเลิกเองไม่ได้)
/// (การล้าง badge ทำใน StudentShell ตอนเลือกแท็บนี้)
/// นัดใหม่ทำที่หน้าแรก: ถาม/ตอบเรื่องทั่วไป -> ที่ห้องกิจการนิสิต
class MyAppointmentsScreen extends StatelessWidget {
  const MyAppointmentsScreen({super.key});

  /// ถามยืนยันก่อนยกเลิกนัด (กันกดพลาด)
  Future<void> _confirmCancel(BuildContext context, Appointment a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ยกเลิกนัดนี้?'),
        content: Text(
          '${thaiDate(a.proposedStart ?? a.start)} · ${timeRange(a.proposedStart ?? a.start)}\n'
          'ถ้าเปลี่ยนใจภายหลัง นัดใหม่ได้ที่หน้าแรก',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ไม่ยกเลิก'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.alert),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ยกเลิกนัด'),
          ),
        ],
      ),
    );
    if (ok == true) store.cancelAppointment(a);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('นัดหมายของฉัน')),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final list = store.myAppointments();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (list.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Text(
                    'ยังไม่มีนัดหมาย\nนัดได้ที่หน้าแรก > ถาม/ตอบเรื่องทั่วไป > ที่ห้องกิจการนิสิต',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted),
                  ),
                ),
              for (final a in list)
                AppointmentCard(
                  appointment: a,
                  forStaff: false,
                  actions: [
                    // ยกเลิกได้ตราบใดที่เจ้าหน้าที่ยังไม่ได้กดยืนยัน (รอยืนยัน / พี่เสนอเวลาใหม่)
                    if ((a.status == AppointmentStatus.pending &&
                            a.start.isAfter(DateTime.now())) ||
                        a.status == AppointmentStatus.proposed)
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.alert,
                        ),
                        onPressed: () => _confirmCancel(context, a),
                        child: const Text('ยกเลิกนัด'),
                      ),
                    if (a.status == AppointmentStatus.proposed) ...[
                      // ไม่สะดวกเวลาที่พี่เสนอ: ยกเลิกนัดนี้แล้วเลือกเวลาใหม่ (กับพี่คนเดิม/คนไหนก็ได้ตามเดิม)
                      TextButton(
                        onPressed: () {
                          store.cancelAppointment(a);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AppointmentBookingScreen(
                                staffId: a.requestedStaffId,
                              ),
                            ),
                          );
                        },
                        child: const Text('เลือกเวลาอื่น'),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 40),
                        ),
                        onPressed: () => store.acceptProposedTime(a),
                        child: const Text('ตกลงเวลานี้'),
                      ),
                    ],
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

/// แท็บ “นัดหมาย” ฝั่งเจ้าหน้าที่: คำขอนัดจากนักศึกษา กรองตามสถานะได้
/// คำขอที่รอยืนยันมีปุ่ม “เสนอเวลาอื่น” / “ยืนยัน สะดวกเวลานี้”
class StaffAppointmentsScreen extends StatefulWidget {
  const StaffAppointmentsScreen({super.key});

  @override
  State<StaffAppointmentsScreen> createState() =>
      _StaffAppointmentsScreenState();
}

class _StaffAppointmentsScreenState extends State<StaffAppointmentsScreen> {
  AppointmentStatus? _filter = AppointmentStatus.pending; // null = ทั้งหมด

  /// เปิดหน้าต่างเสนอเวลาใหม่ แล้วบันทึกเมื่อกดส่ง
  Future<void> _propose(Appointment a) async {
    final result = await showModalBottomSheet<(DateTime, String)>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ProposeTimeSheet(appointment: a),
    );
    if (result == null || !mounted) return;
    store.proposeAppointmentTime(a, result.$1, result.$2);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'เสนอเวลา ${thaiDate(result.$1)} ${timeRange(result.$1)} ให้นักศึกษาแล้ว',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('นัดหมายที่ห้องกิจการนิสิต')),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final list = store.staffAppointments(status: _filter);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: SegmentedButton<AppointmentStatus?>(
                  segments: [
                    ButtonSegment(
                      value: AppointmentStatus.pending,
                      label: Text(
                        'รอยืนยัน (${store.pendingAppointmentCount})',
                      ),
                    ),
                    const ButtonSegment(
                      value: AppointmentStatus.confirmed,
                      label: Text('ยืนยันแล้ว'),
                    ),
                    const ButtonSegment(value: null, label: Text('ทั้งหมด')),
                  ],
                  selected: {_filter},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => setState(() => _filter = s.first),
                ),
              ),
              Expanded(
                child: list.isEmpty
                    ? const Center(
                        child: Text(
                          'ไม่มีนัดหมายในรายการนี้',
                          style: TextStyle(color: AppColors.muted),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        children: [
                          for (final a in list)
                            AppointmentCard(
                              appointment: a,
                              forStaff: true,
                              actions: [
                                if (a.status == AppointmentStatus.pending &&
                                    a.start.isAfter(DateTime.now())) ...[
                                  TextButton(
                                    onPressed: () => _propose(a),
                                    child: const Text('เสนอเวลาอื่น'),
                                  ),
                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                      minimumSize: const Size(0, 40),
                                    ),
                                    onPressed: () =>
                                        store.confirmAppointment(a),
                                    child: const Text('ยืนยัน สะดวกเวลานี้'),
                                  ),
                                ],
                              ],
                            ),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// หน้าต่างเสนอเวลาใหม่ (เลื่อนขึ้นจากด้านล่าง) สำหรับเจ้าหน้าที่ที่ไม่ว่างเวลานั้น
/// เลือกวัน (ปฏิทิน) + เวลา (dropdown) + ข้อความถึงนักศึกษา
/// กดส่งแล้วคืนค่า (เวลาใหม่, ข้อความ)
class _ProposeTimeSheet extends StatefulWidget {
  const _ProposeTimeSheet({required this.appointment});
  final Appointment appointment;

  @override
  State<_ProposeTimeSheet> createState() => _ProposeTimeSheetState();
}

class _ProposeTimeSheetState extends State<_ProposeTimeSheet> {
  late DateTime _day = _initialDay();
  DateTime? _slot;
  final _message = TextEditingController();

  /// เริ่มที่วันเดียวกับที่นักศึกษาขอ (ถ้ายังมีเวลาเหลือ) ให้พี่เสนอเวลาอื่นในวันเดิมได้ง่าย
  DateTime _initialDay() {
    final s = widget.appointment.start;
    final day = DateTime(s.year, s.month, s.day);
    return MockStore.slotsOf(day).any(MockStore.isBookable)
        ? day
        : firstBookableDay();
  }

  Future<void> _pickDay() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: today,
      lastDate: today.add(const Duration(days: 60)),
      selectableDayPredicate: MockStore.isOfficeDay,
    );
    if (d != null) {
      setState(() {
        _day = d;
        _slot = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.appointment;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'เสนอเวลาที่พี่ว่าง',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'นักศึกษาขอ ${thaiDate(a.start)} ${timeRange(a.start)}',
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  alignment: Alignment.centerLeft,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _pickDay,
                icon: const Icon(Icons.calendar_month),
                label: Text('วันที่: ${thaiDate(_day)}'),
              ),
              const SizedBox(height: 12),
              SlotDropdown(
                day: _day,
                value: _slot,
                onChanged: (s) => setState(() => _slot = s),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _message,
                maxLines: 2,
                decoration: _boxDecoration(
                  'ข้อความถึงนักศึกษา (ไม่บังคับ) เช่น ช่วงเช้าพี่ติดประชุมนะ',
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _slot == null
                    ? null
                    : () => Navigator.pop(context, (_slot!, _message.text)),
                child: Text(
                  _slot == null
                      ? 'เลือกเวลาก่อน'
                      : 'เสนอเวลา ${timeRange(_slot!)}',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// การ์ดนัดหมาย 1 รายการ ใช้ทั้งสองฝั่ง
/// - ฝั่งนักศึกษา: แสดงสถานะ, ชื่อพี่ที่ยืนยัน และเวลาที่พี่เสนอ (ถ้ามี)
/// - ฝั่งเจ้าหน้าที่ ([forStaff]): แสดงชื่อ/สาขานักศึกษา, เรื่องที่อยากปรึกษา
///   และคำเตือนถ้าเวลานั้นมีนัดอื่นที่ยืนยันแล้ว (ช่วยตรวจเวลาว่าง)
class AppointmentCard extends StatelessWidget {
  const AppointmentCard({
    super.key,
    required this.appointment,
    required this.forStaff,
    this.actions = const [],
  });
  final Appointment appointment;
  final bool forStaff;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    final student = store.user(a.studentId);
    final staff = a.staffId == null ? null : store.user(a.staffId!);
    final conflicts = forStaff && a.status == AppointmentStatus.pending
        ? store.conflictsOf(a)
        : const <Appointment>[];
    final highlight =
        (forStaff && a.status == AppointmentStatus.pending) ||
        (!forStaff && a.status == AppointmentStatus.proposed);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: highlight ? Border.all(color: AppColors.honey, width: 2) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event_available, color: AppColors.caramel),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${thaiDate(a.start)} · ${timeRange(a.start)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    // เวลาเดิมที่พี่เสนอให้เปลี่ยน ขีดฆ่าไว้
                    decoration: a.status == AppointmentStatus.proposed
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
              ),
              StatusChip(status: a.status),
            ],
          ),
          const SizedBox(height: 8),
          if (forStaff)
            Text('${student.name} · ${student.major}')
          else
            const Text('${MockStore.officeName} · ${MockStore.officeLocation}'),
          // นัดกับใคร: ฝั่งเจ้าหน้าที่บอกว่าขอตัวเองโดยตรงไหม, ฝั่งนักศึกษาบอกว่าส่งถึงใคร
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              forStaff
                  ? (a.requestedStaffId != null
                        ? '🔒 ขอนัดกับคุณโดยตรง'
                        : 'ส่งถึงพี่ไข่หวานทุกคน')
                  : (a.requestedStaffId != null
                        ? 'นัดกับ ${store.user(a.requestedStaffId!).displayName}'
                        : 'นัดกับพี่ไข่หวานคนไหนก็ได้'),
              style: TextStyle(
                fontSize: 13,
                color: forStaff && a.requestedStaffId != null
                    ? AppColors.caramel
                    : AppColors.muted,
                fontWeight: forStaff && a.requestedStaffId != null
                    ? FontWeight.w700
                    : FontWeight.normal,
              ),
            ),
          ),
          if (a.note.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'เรื่อง: ${a.note}',
                style: const TextStyle(color: AppColors.muted),
              ),
            ),
          if (conflicts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '⚠ เวลานี้มีนัดที่ยืนยันแล้ว ${conflicts.length} นัด',
                style: const TextStyle(fontSize: 13, color: AppColors.alert),
              ),
            ),
          if (a.status == AppointmentStatus.proposed && a.proposedStart != null)
            _ProposalBox(appointment: a, forStaff: forStaff),
          if (a.status == AppointmentStatus.confirmed && staff != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'ยืนยันโดย ${staff.displayName}',
                style: const TextStyle(fontSize: 13, color: AppColors.muted),
              ),
            ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 8),
            // Wrap: ปุ่มหลายปุ่มบนจอแคบจะขึ้นบรรทัดใหม่แทนการล้นจอ
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 4,
              children: actions,
            ),
          ],
        ],
      ),
    );
  }
}

/// กล่องแสดงเวลาที่เจ้าหน้าที่เสนอใหม่ + ข้อความจากพี่
class _ProposalBox extends StatelessWidget {
  const _ProposalBox({required this.appointment, required this.forStaff});
  final Appointment appointment;
  final bool forStaff;

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    final staff = store.user(a.staffId!);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            forStaff
                ? '${staff.displayName} เสนอเวลาใหม่ · รอนักศึกษาตอบรับ'
                : '${staff.displayName} ไม่ว่างเวลานี้ เสนอเวลาใหม่:',
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          const SizedBox(height: 2),
          Text(
            '${thaiDate(a.proposedStart!)} · ${timeRange(a.proposedStart!)}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.caramel,
            ),
          ),
          if (a.staffMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('“${a.staffMessage}”'),
            ),
        ],
      ),
    );
  }
}

/// ป้ายสถานะนัด: รอยืนยัน (น้ำตาล) / ยืนยันแล้ว (เขียว) / พี่เสนอเวลาใหม่ (ฟ้า) / ยกเลิกแล้ว (เทา)
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});
  final AppointmentStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      AppointmentStatus.pending => AppColors.caramel,
      AppointmentStatus.confirmed => const Color(0xFF2E9E5B),
      AppointmentStatus.proposed => const Color(0xFF2F7FD1),
      AppointmentStatus.cancelled => AppColors.muted,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
