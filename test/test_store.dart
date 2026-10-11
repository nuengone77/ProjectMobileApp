import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:kaiwan_chuaiduai/data/mock_store.dart';

/// เปิด store สำหรับทดสอบ: ใช้ SQLite ผ่าน FFI (รันบนเครื่องคอมได้)
/// ไม่ส่ง [path] = ฐานข้อมูลในหน่วยความจำ (ใหม่ทุกครั้ง)
/// [demoData] = ใส่นักศึกษา/แชท/นัด/เคสตัวอย่าง (เทสต์ส่วนใหญ่ใช้)
Future<MockStore> openTestStore({String? path, bool demoData = true}) {
  sqfliteFfiInit();
  return MockStore.open(
    factory: databaseFactoryFfi,
    path: path ?? inMemoryDatabasePath,
    demoData: demoData,
  );
}

/// รหัสผ่านของบัญชีตั้งต้น (ข้อมูลทดลองใน MockStore._seed) ใช้ล็อกอินในเทสต์
/// ฐานข้อมูลเก็บแค่ hash จึงต้องจำตัวจริงไว้ที่นี่
const testPasswords = {
  'somjaij67@nu.ac.th': '1234',
  'kittik66@nu.ac.th': '1234',
  'maneerats68@nu.ac.th': '1234',
  'piyaromk@nu.ac.th': 'kaiwanpiyaromk',
  'khuwnruanep@nu.ac.th': 'kaiwankhuwnruanep',
  'chonnikank@nu.ac.th': 'kaiwanchonnikank',
};
