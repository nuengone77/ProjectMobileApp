// การ์ดนัดหมาย 1 รายการ + ป้ายสถานะ (ใช้ร่วมกันทั้งฝั่งนักศึกษาและเจ้าหน้าที่)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_data.dart';
import '../../data/models.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

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
    final student = context.watch<AuthProvider>().user(a.studentId);
    final staff = a.staffId == null
        ? null
        : context.watch<AuthProvider>().user(a.staffId!);
    final conflicts = forStaff && a.status == AppointmentStatus.pending
        ? context.watch<AppointmentProvider>().conflictsOf(a)
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
        border: highlight
            ? Border.all(color: AppColors.yellow, width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event_available, color: AppColors.black),
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
            const Text('${AppData.officeName} · ${AppData.officeLocation}'),
          // นัดกับใคร: ฝั่งเจ้าหน้าที่บอกว่าขอตัวเองโดยตรงไหม, ฝั่งนักศึกษาบอกว่าส่งถึงใคร
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              forStaff
                  ? (a.requestedStaffId != null
                        ? '🔒 ขอนัดกับคุณโดยตรง'
                        : 'ส่งถึงพี่ไข่หวานทุกคน')
                  : (a.requestedStaffId != null
                        ? 'นัดกับ ${context.watch<AuthProvider>().user(a.requestedStaffId!).displayName}'
                        : 'นัดกับพี่ไข่หวานคนไหนก็ได้'),
              style: TextStyle(
                fontSize: 13,
                color: forStaff && a.requestedStaffId != null
                    ? AppColors.black
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
    final staff = context.watch<AuthProvider>().user(a.staffId!);
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
              color: AppColors.black,
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

/// ป้ายสถานะนัด: รอยืนยัน (ดำ) / ยืนยันแล้ว (เขียว) / พี่เสนอเวลาใหม่ (ฟ้า) / ยกเลิกแล้ว (เทา)
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});
  final AppointmentStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      AppointmentStatus.pending => AppColors.black,
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
