// หน้าจองนัด “ถามตอบกับพี่ไข่หวานที่ห้องกิจการนิสิต” (ฝั่งนักศึกษา)
// เลือกวันในปฏิทิน + เลือกเวลาจาก dropdown (ช่วงละ 30 นาที) + โน้ต -> ส่งคำขอ
// คนไหนก็ได้ = แจ้งเตือนเจ้าหน้าที่ทุกคน, เลือกพี่เอง = แจ้งเตือนเฉพาะคนนั้น
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_data.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'my_appointments.dart';

DateTime firstBookableDay() {
  final now = DateTime.now();
  var d = DateTime(now.year, now.month, now.day);
  while (!AppData.isOfficeDay(d) ||
      !AppData.slotsOf(d).any(AppData.isBookable)) {
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
    final slots = AppData.slotsOf(day).where(AppData.isBookable).toList();
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
        prefixIcon: const Icon(Icons.schedule, color: AppColors.black),
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
    final a = context.read<AppointmentProvider>().requestAppointment(
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
    return UnsavedChangesGuard(
      // บทที่ 9 (PopScope): เลือกเวลา/พิมพ์โน้ตแล้วกดย้อนกลับ -> ถามก่อนทิ้ง
      isDirty: () => _slot != null || _note.text.isNotEmpty,
      listenable: _note,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('นัดหมายที่ห้องกิจการนิสิต'),
          actions: const [HomeButton()],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            const OfficeInfoCard(),
            const SizedBox(height: 12),
            _WithWhom(staffId: widget.staffId),
            const SizedBox(height: 16),
            const SectionTitle('เลือกวัน'),
            // ปฏิทิน: เลือกได้เฉพาะวันจันทร์–ศุกร์ ภายใน 60 วัน
            Material(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              child: CalendarDatePicker(
                initialDate: _day,
                firstDate: today,
                lastDate: today.add(const Duration(days: 60)),
                selectableDayPredicate: AppData.isOfficeDay,
                onDateChanged: (d) => setState(() {
                  _day = d;
                  _slot = null;
                }),
              ),
            ),
            const SizedBox(height: 16),
            SectionTitle(
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
            const SectionTitle('อยากถาม/ตอบเรื่องอะไร (ไม่บังคับ)'),
            TextField(
              controller: _note,
              maxLines: 3,
              decoration: noteBoxDecoration('เล่าสั้นๆ ให้พี่เตรียมตัวก่อนได้'),
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
      ),
    );
  }
}

/// กรอบช่องพิมพ์ข้อความหลายบรรทัด (มุมโค้ง ขอบอ่อน)
InputDecoration noteBoxDecoration(String hint) => InputDecoration(
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
    final staff = staffId == null
        ? null
        : context.watch<AuthProvider>().user(staffId!);
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
              backgroundColor: AppColors.yellow,
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
          Icon(icon, size: 18, color: AppColors.black),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.yellow.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            AppData.officeName,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          row(Icons.place_outlined, AppData.officeLocation),
          row(Icons.schedule, AppData.officeHoursText),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.caption});
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
