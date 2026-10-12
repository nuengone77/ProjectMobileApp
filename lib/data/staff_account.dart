// ข้อมูลบัญชีเจ้าหน้าที่ 1 คน ที่สร้างไว้ให้ตอนเปิดแอปครั้งแรก (เจ้าหน้าที่สมัครเองไม่ได้)
//
// รายการบัญชีจริงอยู่ในไฟล์ lib/config/staff_accounts.dart ซึ่ง "ไม่ได้ commit" (อยู่ใน .gitignore)
// เพราะมีรหัสผ่าน ให้คัดลอกจาก lib/config/staff_accounts.sample.dart แล้วใส่ข้อมูลจริง
class StaffAccount {
  const StaffAccount({
    required this.email,
    required this.password,
    required this.name,
    required this.nickname,
  });

  final String email;

  /// รหัสผ่านตั้งต้น (ตอนบันทึกลงฐานข้อมูลจะเก็บเป็น hash เท่านั้น)
  final String password;

  /// ชื่อ-สกุลเจ้าหน้าที่
  final String name;

  /// ชื่อที่แสดงในแอป จะขึ้นเป็น "พี่ไข่หวาน" ตามด้วย nickname เช่น พี่ไข่หวาน 1
  final String nickname;
}
