// แท็บ “นัดหมาย” ฝั่งเจ้าหน้าที่: ตรวจเวลาว่างเอง แล้ว
//   - ว่าง    -> กด “ยืนยัน สะดวกเวลานี้”
//   - ไม่ว่าง -> กด “เสนอเวลาอื่น” เลือกวัน/เวลาที่ตัวเองว่าง (+ ข้อความ)
//               -> นักศึกษากด “ตกลงเวลานี้” หรือ “เลือกเวลาอื่น”
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_data.dart';
import '../../data/models.dart';
import '../../providers/appointment_provider.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'booking_screen.dart';
import 'appointment_card.dart';

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
      builder: (_) => ProposeTimeSheet(appointment: a),
    );
    if (result == null || !mounted) return;
    context.read<AppointmentProvider>().proposeAppointmentTime(
      a,
      result.$1,
      result.$2,
    );
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
      body: Builder(
        builder: (context) {
          final list = context.watch<AppointmentProvider>().staffAppointments(
            status: _filter,
          );
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: SegmentedButton<AppointmentStatus?>(
                  segments: [
                    ButtonSegment(
                      value: AppointmentStatus.pending,
                      label: Text(
                        'รอยืนยัน (${context.watch<AppointmentProvider>().pendingAppointmentCount})',
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
                                    onPressed: () => context
                                        .read<AppointmentProvider>()
                                        .confirmAppointment(a),
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
class ProposeTimeSheet extends StatefulWidget {
  const ProposeTimeSheet({super.key, required this.appointment});
  final Appointment appointment;

  @override
  State<ProposeTimeSheet> createState() => _ProposeTimeSheetState();
}

class _ProposeTimeSheetState extends State<ProposeTimeSheet> {
  late DateTime _day = _initialDay();
  DateTime? _slot;
  final _message = TextEditingController();

  /// เริ่มที่วันเดียวกับที่นักศึกษาขอ (ถ้ายังมีเวลาเหลือ) ให้พี่เสนอเวลาอื่นในวันเดิมได้ง่าย
  DateTime _initialDay() {
    final s = widget.appointment.start;
    final day = DateTime(s.year, s.month, s.day);
    return AppData.slotsOf(day).any(AppData.isBookable)
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
      selectableDayPredicate: AppData.isOfficeDay,
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
                decoration: noteBoxDecoration(
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
