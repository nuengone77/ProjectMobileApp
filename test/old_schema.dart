// โครงสร้างฐานข้อมูลเวอร์ชัน 1 (ก่อนมีตาราง case_reports และคอลัมน์ไฟล์แนบ)
// เก็บไว้ในเทสต์เพื่อจำลอง “เครื่องที่ยังมีฐานข้อมูลเก่า” แล้วทดสอบว่าแอปอัปเกรดได้โดยข้อมูลไม่หาย
// (คัดลอกแยกจากแอป: ถ้าแอปเปลี่ยนโครงสร้างในอนาคต ไฟล์นี้ยังเป็นเวอร์ชัน 1 เหมือนเดิม)
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> createV1Tables(Database db) async {
  await db.execute('''
    CREATE TABLE users (
      id TEXT PRIMARY KEY,
      email TEXT NOT NULL UNIQUE,
      password_hash TEXT NOT NULL,
      name TEXT NOT NULL,
      role TEXT NOT NULL,
      major TEXT NOT NULL DEFAULT '',
      student_id TEXT NOT NULL DEFAULT '',
      name_en TEXT NOT NULL DEFAULT '',
      phone TEXT NOT NULL DEFAULT '',
      nickname TEXT NOT NULL DEFAULT '',
      specialty TEXT NOT NULL DEFAULT '',
      avatar_color INTEGER NOT NULL
    )''');
  await db.execute('''
    CREATE TABLE conversations (
      id TEXT PRIMARY KEY,
      student_id TEXT NOT NULL,
      category_id TEXT NOT NULL,
      is_specific INTEGER NOT NULL,
      staff_id TEXT,
      student_read INTEGER NOT NULL DEFAULT 0,
      staff_read INTEGER NOT NULL DEFAULT 0,
      closed INTEGER NOT NULL DEFAULT 0,
      closed_at INTEGER,
      closed_by TEXT,
      summary_topic TEXT NOT NULL DEFAULT '',
      summary_help TEXT NOT NULL DEFAULT '',
      case_level TEXT
    )''');
  await db.execute('''
    CREATE TABLE messages (
      conversation_id TEXT NOT NULL,
      seq INTEGER NOT NULL,
      sender_id TEXT NOT NULL,
      text TEXT NOT NULL,
      time INTEGER NOT NULL,
      is_system INTEGER NOT NULL DEFAULT 0,
      is_alert INTEGER NOT NULL DEFAULT 0,
      PRIMARY KEY (conversation_id, seq)
    )''');
  await db.execute('''
    CREATE TABLE appointments (
      id TEXT PRIMARY KEY,
      student_id TEXT NOT NULL,
      start INTEGER NOT NULL,
      note TEXT NOT NULL DEFAULT '',
      status TEXT NOT NULL,
      staff_id TEXT,
      requested_staff_id TEXT,
      proposed_start INTEGER,
      staff_message TEXT NOT NULL DEFAULT '',
      seen_by_student INTEGER NOT NULL DEFAULT 1
    )''');
  await db.execute('''
    CREATE TABLE settings (
      key TEXT PRIMARY KEY,
      value TEXT
    )''');
}
