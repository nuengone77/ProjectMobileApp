// ตัวอย่างไฟล์บัญชีเจ้าหน้าที่ (ไฟล์นี้ commit ได้ ไม่มีรหัสผ่านจริง)
//
// วิธีใช้: คัดลอกไฟล์นี้เป็น lib/config/staff_accounts.dart
// แล้วแก้อีเมล/รหัสผ่าน/ชื่อเป็นข้อมูลจริง (ไฟล์ staff_accounts.dart อยู่ใน .gitignore จะไม่ขึ้น git)
// รหัสผ่านจริงส่งให้ผู้สอน/สมาชิกทางช่องทางส่วนตัว
//
// บัญชีถูกสร้างตอนเปิดแอปครั้งแรก (หรือรีเซ็ตข้อมูล) ถ้าแก้ไฟล์ทีหลัง ต้องรีเซ็ตข้อมูลก่อนจึงจะมีผล:
//   flutter run --dart-define=RESET_DB=true
import '../data/staff_account.dart';

const staffAccounts = <StaffAccount>[
  StaffAccount(
    email: 'staff1@nu.ac.th',
    password: 'changeme1',
    name: 'เจ้าหน้าที่คนที่ 1',
    nickname: '1',
  ),
  StaffAccount(
    email: 'staff2@nu.ac.th',
    password: 'changeme2',
    name: 'เจ้าหน้าที่คนที่ 2',
    nickname: '2',
  ),
  StaffAccount(
    email: 'staff3@nu.ac.th',
    password: 'changeme3',
    name: 'เจ้าหน้าที่คนที่ 3',
    nickname: '3',
  ),
];
