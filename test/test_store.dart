import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:kaiwan_chuaiduai/config/staff_accounts.dart';
import 'package:kaiwan_chuaiduai/data/app_store.dart';
import 'package:kaiwan_chuaiduai/data/staff_account.dart';

/// เปิด store สำหรับทดสอบ: ใช้ SQLite ผ่าน FFI (รันบนเครื่องคอมได้)
/// ไม่ส่ง [path] = ฐานข้อมูลในหน่วยความจำ (ใหม่ทุกครั้ง)
/// [demoData] = ใส่นักศึกษา/แชท/นัด/เคสตัวอย่าง (เทสต์ส่วนใหญ่ใช้)
Future<AppStore> openTestStore({String? path, bool demoData = true}) {
  sqfliteFfiInit();
  return AppStore.open(
    factory: databaseFactoryFfi,
    path: path ?? inMemoryDatabasePath,
    demoData: demoData,
  );
}

/// บัญชีเจ้าหน้าที่ อ่านจาก lib/config/staff_accounts.dart (ไม่ได้ commit)
/// เทสต์จึงไม่เขียนอีเมล/รหัสผ่านเจ้าหน้าที่ไว้ตรงๆ
final staff1 = staffAccounts[0];
final staff2 = staffAccounts[1];
final staff3 = staffAccounts[2];

/// ชื่อเจ้าหน้าที่ที่แสดงในแอป เช่น "พี่ไข่หวาน มะนาว" (ตามไฟล์ config)
String shown(StaffAccount a) => 'พี่ไข่หวาน ${a.nickname}';

/// รหัสผ่านของบัญชีตั้งต้นและนักศึกษาทดลอง ใช้ล็อกอินในเทสต์
/// ฐานข้อมูลเก็บแค่ hash จึงต้องจำตัวจริงไว้ที่นี่
final testPasswords = {
  'somjaij67@nu.ac.th': '1234',
  'kittik66@nu.ac.th': '1234',
  'maneerats68@nu.ac.th': '1234',
  AppStore.testStudentEmail: AppStore.testStudentPassword,
  for (final a in staffAccounts) a.email: a.password,
};
