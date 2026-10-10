import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:kaiwan_chuaiduai/data/mock_store.dart';

/// เปิด store สำหรับทดสอบ: ใช้ SQLite ผ่าน FFI (รันบนเครื่องคอมได้)
/// ไม่ส่ง [path] = ฐานข้อมูลในหน่วยความจำ (ใหม่ทุกครั้ง)
Future<MockStore> openTestStore({String? path}) {
  sqfliteFfiInit();
  return MockStore.open(
    factory: databaseFactoryFfi,
    path: path ?? inMemoryDatabasePath,
  );
}
