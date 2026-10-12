// Provider ด้านนัดหมายที่ห้องกิจการนิสิต
// นักศึกษาขอนัด -> เจ้าหน้าที่ยืนยัน หรือเสนอเวลาใหม่ -> นักศึกษาตกลง/ยกเลิก
// กติกาเวลานัด (วันทำการ, ช่วงละ 30 นาที) อยู่ใน AppData.isOfficeDay / slotsOf / isBookable
// รับ AuthProvider ผ่าน ChangeNotifierProxyProvider (บทที่ 11) เพื่อรู้ว่าใครล็อกอิน
import 'package:flutter/foundation.dart';

import '../data/app_data.dart';
import '../data/models.dart';
import 'auth_provider.dart';

class AppointmentProvider extends ChangeNotifier {
  AppointmentProvider(this.data, this._auth);

  final AppData data;
  AuthProvider _auth;

  AppUser? get _me => _auth.currentUser;

  /// ProxyProvider เรียกเมื่อ AuthProvider เปลี่ยน (รายการนัดขึ้นกับว่าใครล็อกอิน)
  void update(AuthProvider auth) {
    _auth = auth;
    notifyListeners();
  }

  /// นัดอื่นที่ยืนยันแล้วในเวลาเดียวกัน (ใช้เตือนเจ้าหน้าที่ตอนตรวจเวลาว่าง)
  List<Appointment> conflictsOf(Appointment a) => data.appointments
      .where(
        (o) =>
            o != a &&
            o.status == AppointmentStatus.confirmed &&
            o.start == a.start,
      )
      .toList();

  /// นักศึกษาส่งคำขอนัดหมาย -> สถานะ “รอยืนยัน” และไปแจ้งเตือนเจ้าหน้าที่ทุกคน
  /// [staffId] = เจ้าหน้าที่ที่เลือกเอง (null = คนไหนก็ได้ ส่งถึงทุกคน)
  Appointment requestAppointment(
    DateTime start,
    String note, {
    String? staffId,
  }) {
    final a = Appointment(
      id: data.newId('a'),
      studentId: _me!.id,
      start: start,
      note: note.trim(),
      requestedStaffId: staffId,
    );
    data.appointments.add(a);
    data.db.saveAppointment(a);
    notifyListeners();
    return a;
  }

  /// นัดหมายของนักศึกษาที่ล็อกอินอยู่ (ใหม่สุด/ใกล้สุดอยู่บน)
  List<Appointment> myAppointments() {
    final me = _me;
    if (me == null) return [];
    return data.appointments.where((a) => a.studentId == me.id).toList()
      ..sort((a, b) => b.start.compareTo(a.start));
  }

  /// จำนวนนัดที่สถานะเปลี่ยนแต่นักศึกษายังไม่ได้ดู (badge แท็บ “นัดหมาย”)
  int get studentAppointmentUpdates =>
      myAppointments().where((a) => !a.seenByStudent).length;

  /// เรียกตอนนักศึกษาเปิดหน้านัดหมาย: ถือว่าเห็นการเปลี่ยนแปลงทั้งหมดแล้ว
  void markAppointmentsSeen() {
    final unseen = myAppointments().where((a) => !a.seenByStudent);
    if (unseen.isEmpty) return;
    for (final a in unseen) {
      a.seenByStudent = true;
      data.db.saveAppointment(a);
    }
    notifyListeners();
  }

  /// นักศึกษายกเลิกนัด (เฉพาะที่ยังไม่ถึงเวลา)
  void cancelAppointment(Appointment a) {
    a.status = AppointmentStatus.cancelled;
    data.db.saveAppointment(a);
    notifyListeners();
  }

  /// นัดที่เจ้าหน้าที่คนนี้มองเห็น: นัดแบบคนไหนก็ได้ทุกนัด + นัดที่ขอตัวเองโดยตรง
  /// (นัดที่นักศึกษาเลือกเจ้าหน้าที่คนอื่น จะไม่เห็นและไม่ได้แจ้งเตือน)
  bool _visibleToStaff(Appointment a, AppUser me) =>
      a.requestedStaffId == null || a.requestedStaffId == me.id;

  /// รายการนัดสำหรับเจ้าหน้าที่ที่ล็อกอินอยู่ กรองตามสถานะได้
  /// เรียงตามเวลานัด ใกล้สุดขึ้นก่อน
  List<Appointment> staffAppointments({AppointmentStatus? status}) {
    final me = _me;
    if (me == null) return [];
    return data.appointments
        .where(
          (a) =>
              _visibleToStaff(a, me) && (status == null || a.status == status),
        )
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
  }

  /// จำนวนคำขอที่รอเจ้าหน้าที่ยืนยัน (badge แท็บ “นัดหมาย” ฝั่งเจ้าหน้าที่)
  int get pendingAppointmentCount =>
      staffAppointments(status: AppointmentStatus.pending)
          .where((a) => a.start.isAfter(DateTime.now()))
          .length;

  /// เจ้าหน้าที่ตรวจแล้วว่าว่าง กดยืนยันนัด
  void confirmAppointment(Appointment a) {
    a.status = AppointmentStatus.confirmed;
    a.staffId = _me!.id;
    a.seenByStudent = false;
    data.db.saveAppointment(a);
    notifyListeners();
  }

  /// เจ้าหน้าที่ไม่ว่างเวลานั้น: เสนอเวลาที่ตัวเองว่างแทน แล้วรอนักศึกษาตอบรับ
  void proposeAppointmentTime(
    Appointment a,
    DateTime newStart,
    String message,
  ) {
    a.status = AppointmentStatus.proposed;
    a.proposedStart = newStart;
    a.staffMessage = message.trim();
    a.staffId = _me!.id;
    a.seenByStudent = false;
    data.db.saveAppointment(a);
    notifyListeners();
  }

  /// นักศึกษาตกลงเวลาที่พี่เสนอ -> นัดยืนยันทันทีตามเวลาใหม่
  void acceptProposedTime(Appointment a) {
    a.start = a.proposedStart!;
    a.proposedStart = null;
    a.status = AppointmentStatus.confirmed;
    data.db.saveAppointment(a);
    notifyListeners();
  }
}
