// แท็บ “นัดหมาย” ฝั่งนักศึกษา: ดูสถานะนัด ยกเลิกนัดที่ยังไม่ยืนยัน และตอบเวลาที่พี่เสนอ
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models.dart';
import '../../providers/appointment_provider.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'booking_screen.dart';
import 'appointment_card.dart';

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
    final appts = context.read<AppointmentProvider>(); // ดึงก่อน await
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
    if (ok == true) appts.cancelAppointment(a);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('นัดหมายของฉัน')),
      body: Builder(
        builder: (context) {
          final list = context.watch<AppointmentProvider>().myAppointments();
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
                          context.read<AppointmentProvider>().cancelAppointment(
                            a,
                          );
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
                        onPressed: () => context
                            .read<AppointmentProvider>()
                            .acceptProposedTime(a),
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
