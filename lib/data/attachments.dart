// ไฟล์แนบในแชท (รูปภาพ / ไฟล์) เก็บเป็นสำเนาในโฟลเดอร์ของแอป
//
// ฐานข้อมูลเก็บแค่ “ชื่อไฟล์” ไม่เก็บ path เต็ม
// เพราะบน iOS path ของโฟลเดอร์แอปเปลี่ยนได้ทุกครั้งที่ติดตั้ง/อัปเดตแอป
// ตอนแสดงผลจึงต่อ path ใหม่จาก [dir] ทุกครั้ง
//
// หมายเหตุ: ไฟล์อยู่ในเครื่องนี้เท่านั้น (เหมือน SQLite) ส่งข้ามเครื่องต้องมี server ภายหลัง
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class Attachments {
  /// ขนาดไฟล์สูงสุดที่แนบได้ต่อไฟล์
  static const maxBytes = 20 * 1024 * 1024;

  static String? _dir;

  /// โฟลเดอร์เก็บไฟล์แนบ (ต้องเรียก [init] ก่อน)
  static String get dir => _dir ?? (throw StateError('Attachments.init()'));

  /// เตรียมโฟลเดอร์ (เรียกครั้งเดียวตอนเปิดแอป) [path] ใช้ตอนทดสอบ
  static Future<void> init([String? path]) async {
    _dir =
        path ??
        p.join((await getApplicationDocumentsDirectory()).path, 'attachments');
    await Directory(_dir!).create(recursive: true);
  }

  /// path เต็มของไฟล์แนบจากชื่อไฟล์ที่เก็บในฐานข้อมูล
  static String pathOf(String fileName) => p.join(dir, fileName);

  /// คัดลอกไฟล์ที่ผู้ใช้เลือกเข้ามาเก็บในแอป คืนชื่อไฟล์ใหม่ (ไม่ซ้ำ)
  static Future<String> import(String sourcePath) async {
    final ext = p.extension(sourcePath).toLowerCase();
    final name = '${DateTime.now().microsecondsSinceEpoch}$ext';
    await File(sourcePath).copy(pathOf(name));
    return name;
  }

  /// ลบไฟล์แนบทั้งหมด (ใช้ตอนรีเซ็ตข้อมูล)
  static void clear() {
    final d = Directory(dir);
    if (!d.existsSync()) return;
    for (final f in d.listSync()) {
      f.deleteSync(recursive: true);
    }
  }

  /// ขนาดไฟล์แบบอ่านง่าย เช่น 1.2 MB
  static String sizeText(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }
}
