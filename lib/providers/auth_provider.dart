// Provider ด้านบัญชีผู้ใช้: ล็อกอิน / สมัครสมาชิก / ออกจากระบบ / แก้โปรไฟล์
//
// เป็น ChangeNotifier (บทที่ 10): เมื่อสถานะล็อกอินเปลี่ยนจะเรียก notifyListeners()
// - หน้าจอที่ใช้ context.watch<AuthProvider>() จะวาดใหม่เอง เช่น _RoleGate ใน main.dart
// - Provider ตัวอื่น (แชท/นัดหมาย/รายงาน) ต้องรู้ว่าใครล็อกอินอยู่
//   จึงรับ AuthProvider ผ่าน ChangeNotifierProxyProvider (บทที่ 11) ดู main.dart
import 'package:flutter/foundation.dart';

import '../data/app_data.dart';
import '../data/models.dart';
import '../data/passwords.dart';
import '../data/registration_rules.dart';

class AuthProvider extends ChangeNotifier {
  /// [data] = ข้อมูลกลาง ถ้าเคยล็อกอินค้างไว้จะคืนสถานะให้ทันที
  AuthProvider(this.data)
    : currentUser = data.users
          .where((u) => u.id == data.savedUserId)
          .firstOrNull;

  final AppData data;

  /// ผู้ที่ล็อกอินอยู่ (null = ยังไม่ล็อกอิน)
  AppUser? currentUser;

  /// ล็อกอิน: สำเร็จคืน null, ไม่สำเร็จคืนข้อความ error ไปแสดงบนหน้าจอ
  String? login(String email, String password) {
    final u = data.users.where(
      (u) => u.email.toLowerCase() == email.trim().toLowerCase(),
    );
    if (u.isEmpty) return 'ไม่พบบัญชีผู้ใช้นี้';
    if (u.first.passwordHash != hashPassword(email, password)) {
      return 'รหัสผ่านไม่ถูกต้อง';
    }
    currentUser = u.first;
    data.savedUserId = u.first.id;
    data.db.setSetting(AppData.currentUserKey, u.first.id); // จำการล็อกอินไว้
    notifyListeners();
    return null;
  }

  /// สมัครสมาชิก (นักศึกษาเท่านั้น) แล้วล็อกอินให้ทันที
  /// สำเร็จคืน null, ไม่ผ่านคืนข้อความ error
  /// ตรวจเงื่อนไขซ้ำอีกรอบ (เหมือนฝั่ง server) แม้หน้าจอจะตรวจไปแล้ว
  String? register({
    required String email,
    required String password,
    required String name,
    required String major,
    String studentId = '',
    String nameEn = '',
    String phone = '',
  }) {
    final rule =
        RegistrationRules.studentIdError(studentId) ??
        RegistrationRules.nameEnError(nameEn) ??
        RegistrationRules.emailError(
          email,
          nameEn: nameEn,
          studentId: studentId,
        );
    if (rule != null) return rule;
    if (AppData.departmentOf(major) == null) return 'กรุณาเลือกสาขา';
    final users = data.users;
    if (users.any((u) => u.email.toLowerCase() == email.trim().toLowerCase())) {
      return 'อีเมลนี้ถูกใช้แล้ว';
    }
    if (users.any((u) => u.studentId == studentId.trim())) {
      return 'รหัสนิสิตนี้ลงทะเบียนแล้ว';
    }
    final u = AppUser(
      id: data.newId('u'),
      email: email.trim().toLowerCase(),
      passwordHash: hashPassword(email, password),
      name: name.trim(),
      major: major,
      studentId: studentId.trim(),
      nameEn: nameEn.trim(),
      phone: phone.trim(),
      role: Role.student,
    );
    users.add(u);
    data.db.saveUser(u);
    currentUser = u;
    data.savedUserId = u.id;
    data.db.setSetting(AppData.currentUserKey, u.id);
    notifyListeners();
    return null;
  }

  void logout() {
    currentUser = null;
    data.savedUserId = null;
    data.db.setSetting(AppData.currentUserKey, null);
    notifyListeners();
  }

  /// นักศึกษาแก้ข้อมูลตัวเองในหน้าโปรไฟล์ (เบอร์โทร / สาขา ซึ่งบอกภาควิชาด้วย)
  /// คืน null ถ้าสำเร็จ หรือข้อความ error
  String? updateMyProfile({String? phone, String? major}) {
    final me = currentUser!;
    if (phone != null && !AppData.isValidPhone(phone)) {
      return 'เบอร์โทร 10 หลัก ขึ้นต้นด้วย 0';
    }
    if (major != null && AppData.departmentOf(major) == null) {
      return 'กรุณาเลือกสาขา';
    }
    if (phone != null) me.phone = phone.trim();
    if (major != null) me.major = major;
    data.db.saveUser(me);
    notifyListeners();
    return null;
  }

  // ตัวช่วยค้นหาผู้ใช้ (หน้าจอใช้แสดงชื่อ/รูป)
  List<AppUser> get staff => data.staff;
  AppUser user(String id) => data.user(id);

  /// รีเซ็ตข้อมูลทั้งหมดแล้วออกจากระบบ (ใช้กับ --dart-define=RESET_DB=true และในเทสต์)
  void resetData() {
    data.resetData();
    currentUser = null;
    notifyListeners();
  }
}
