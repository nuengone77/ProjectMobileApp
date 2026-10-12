// Provider ด้านตารางสรุปเคสของเจ้าหน้าที่ (หน้า “ตารางสรุปเคส”)
//
// - แถว online สร้าง/อัปเดตอัตโนมัติเมื่อแชทจบ (ChatProvider เรียก [syncChatReport])
// - แถว onsite เจ้าหน้าที่เพิ่มเอง แก้ได้เฉพาะ ประเภท/เรื่อง/คำตอบ/ระดับ
// รับ AuthProvider ผ่าน ChangeNotifierProxyProvider (บทที่ 11) เพื่อรู้ว่าเป็นตารางของใคร
import 'package:flutter/foundation.dart';

import '../data/app_data.dart';
import '../data/models.dart';
import 'auth_provider.dart';

class ReportProvider extends ChangeNotifier {
  ReportProvider(this.data, this._auth);

  final AppData data;
  AuthProvider _auth;

  AppUser? get _me => _auth.currentUser;

  /// ProxyProvider เรียกเมื่อ AuthProvider เปลี่ยน (ล็อกอินคนใหม่ = ตารางของคนใหม่)
  void update(AuthProvider auth) {
    _auth = auth;
    notifyListeners();
  }

  /// สร้าง/อัปเดตแถว online ของแชทที่จบแล้ว (ตรรกะอยู่ใน AppData ใช้ร่วมกับข้อมูลตั้งต้น)
  void syncChatReport(Conversation c) {
    data.syncChatReport(c);
    notifyListeners();
  }

  /// แถวในตารางของเจ้าหน้าที่ที่ล็อกอินอยู่ ตามตัวกรอง (เรียงตามวันที่ เก่า -> ใหม่)
  /// [from]/[to] = ช่วงวันที่ (รวมทั้งวัน), [channel] = online/onsite (null = ทั้งหมด)
  List<CaseReport> myReports({
    DateTime? from,
    DateTime? to,
    ConsultChannel? channel,
  }) {
    final me = _me;
    if (me == null) return [];
    final start = from == null
        ? null
        : DateTime(from.year, from.month, from.day);
    final end = to == null ? null : DateTime(to.year, to.month, to.day + 1);
    return data.reports
        .where(
          (r) =>
              r.staffId == me.id &&
              (channel == null || r.channel == channel) &&
              (start == null || !r.date.isBefore(start)) &&
              (end == null || r.date.isBefore(end)),
        )
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// หานักศึกษาจากรหัสนิสิต (ใช้กรอกชื่อให้อัตโนมัติตอนเพิ่มแถว onsite)
  AppUser? studentByIdNo(String idNo) => data.users
      .where((u) => !u.isStaff && u.studentId == idNo.trim())
      .firstOrNull;

  /// เจ้าหน้าที่เพิ่มแถว onsite เอง (หลังคุยกับนิสิตที่ห้องกิจการนิสิตเสร็จ)
  CaseReport addOnsiteReport({
    required DateTime date,
    required String studentIdNo,
    required String studentName,
    required String categoryId,
    String topic = '',
    String advice = '',
    CaseLevel? level,
  }) {
    final r = CaseReport(
      id: data.newId('r'),
      staffId: _me!.id,
      date: date,
      studentIdNo: studentIdNo.trim(),
      studentName: studentName.trim(),
      categoryId: categoryId,
      channel: ConsultChannel.onsite,
      topic: topic.trim(),
      advice: advice.trim(),
      level: level,
      edited: true,
    );
    data.reports.add(r);
    data.db.saveReport(r);
    notifyListeners();
    return r;
  }

  /// แก้แถวในตาราง (เฉพาะ ประเภท / เรื่องที่ปรึกษา / คำปรึกษา / ระดับ) ไม่กระทบแชท
  void updateReport(
    CaseReport r, {
    required String categoryId,
    required String topic,
    required String advice,
    CaseLevel? level,
  }) {
    r
      ..categoryId = categoryId
      ..topic = topic.trim()
      ..advice = advice.trim()
      ..level = level
      ..edited = true;
    data.db.saveReport(r);
    notifyListeners();
  }

  /// ลบแถว (เฉพาะแถว onsite ที่เพิ่มเอง แถวจากแชทลบไม่ได้)
  void deleteReport(CaseReport r) {
    if (!r.isManual) return;
    data.reports.remove(r);
    data.db.deleteReport(r.id);
    notifyListeners();
  }
}
