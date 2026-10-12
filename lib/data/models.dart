// โครงสร้างข้อมูล (models) ทั้งหมดของแอป
// ตอนนี้เก็บในหน่วยความจำผ่าน AppData ถ้าต่อ backend จริงก็ใช้ class ชุดนี้ต่อได้
import 'package:flutter/material.dart';

/// บทบาทผู้ใช้: นักศึกษา หรือ เจ้าหน้าที่ (Admin ยังไม่ได้ทำ)
enum Role { student, staff }

/// ผู้ใช้ 1 คน ใช้ class เดียวกันทั้งนักศึกษาและเจ้าหน้าที่ แยกด้วย [role]
class AppUser {
  AppUser({
    required this.id,
    required this.email,
    required this.passwordHash,
    required this.name,
    required this.role,
    this.major = '',
    this.studentId = '',
    this.nameEn = '',
    this.phone = '',
    this.nickname = '',
    this.specialty = '',
    this.avatarColor = const Color(0xFFB9D7E8),
  });

  final String id;
  final String email;
  final String
  passwordHash; // รหัสผ่านแบบ hash (ดู passwords.dart) ไม่เก็บตัวจริง
  final String name;
  final Role role;
  String major; // สาขา (เฉพาะนักศึกษา แก้ได้ในหน้าโปรไฟล์)
  final String studentId; // รหัสนิสิต (เฉพาะนักศึกษา)
  final String nameEn; // ชื่อ-สกุลภาษาอังกฤษ (เฉพาะนักศึกษา)
  String phone; // เบอร์โทรศัพท์ (เฉพาะนักศึกษา แก้ได้ในหน้าโปรไฟล์)
  final String nickname; // ชื่อเล่น เช่น แอน (เฉพาะเจ้าหน้าที่)
  final String specialty; // ความเชี่ยวชาญ แสดงในหน้าเลือกพี่ไข่หวาน
  final Color avatarColor; // สีพื้นหลังรูปโปรไฟล์

  bool get isStaff => role == Role.staff;

  /// ชื่อที่แสดงในแอป: เจ้าหน้าที่แสดงเป็น “พี่ไข่หวาน <ชื่อเล่น>”
  String get displayName => isStaff ? 'พี่ไข่หวาน $nickname' : name;
}

/// หัวข้อการปรึกษา (ตอนนี้มี 2 แบบ: ถาม/ตอบเรื่องทั่วไป, ขอความช่วยเหลือแบบเร่งด่วน)
class ConsultCategory {
  const ConsultCategory({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.urgent = false,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;

  /// true = เร่งด่วน: ไม่ให้เลือกเจ้าหน้าที่ ส่งถึงทุกคน และแสดงเป็นสีแดงให้เห็นชัด
  final bool urgent;
}

/// ข้อความ 1 ข้อความในแชท
/// [isSystem] = ข้อความจากระบบ (แสดงเป็นแถบกลางจอ เช่น “เริ่มการปรึกษา...”)
class Message {
  Message({
    required this.senderId,
    required this.text,
    DateTime? time,
    this.isSystem = false,
    this.isAlert = false,
    this.attachment,
    this.attachmentName,
    this.isImage = false,
  }) : time = time ?? DateTime.now();

  final String senderId;
  final String text;
  final DateTime time;
  final bool isSystem;

  /// ข้อความแจ้งเตือนสำคัญจากระบบ (เช่น เบอร์ฉุกเฉินในแชทเร่งด่วน) แสดงเป็นการ์ดสีแดง
  final bool isAlert;

  /// ไฟล์แนบ: ชื่อไฟล์ที่เก็บในแอป (ดู Attachments) null = ข้อความธรรมดา
  final String? attachment;

  /// ชื่อไฟล์เดิมที่ผู้ใช้เห็น (เช่น ใบรับรองแพทย์.pdf)
  final String? attachmentName;

  /// ไฟล์แนบเป็นรูปภาพ (แสดงรูปในแชท) หรือไฟล์ทั่วไป
  final bool isImage;

  /// ข้อความสั้นสำหรับแสดงในรายการแชท
  String get preview => attachment == null
      ? text
      : isImage
      ? '📷 รูปภาพ'
      : '📎 ${attachmentName ?? 'ไฟล์'}';
}

/// ระดับเคสที่เจ้าหน้าที่เลือกตอนจบการปรึกษา
enum CaseLevel {
  small('เล็ก', '🟢'),
  medium('กลาง', '🟡'),
  large('ใหญ่', '🔴');

  const CaseLevel(this.label, this.emoji);
  final String label;
  final String emoji;

  /// ข้อความแสดงผล เช่น “เล็ก 🟢”
  String get display => '$label $emoji';
}

/// ห้องแชท 1 ห้อง = นักศึกษา 1 คน + หัวข้อการปรึกษา 1 หัวข้อ
class Conversation {
  Conversation({
    required this.id,
    required this.studentId,
    required this.categoryId,
    required this.isSpecific,
    this.staffId,
    List<Message>? messages,
  }) : messages = messages ?? [];

  final String id;
  final String studentId;
  final String categoryId;

  /// true = ปรึกษาแบบเลือกเจ้าหน้าที่เฉพาะเจาะจง (ส่วนตัว)
  /// false = เจ้าหน้าที่คนไหนก็ได้ (ส่วนรวม)
  final bool isSpecific;

  /// แบบเจาะจง: เจ้าหน้าที่ที่นักศึกษาเลือก
  /// แบบคนไหนก็ได้: เจ้าหน้าที่คนแรกที่ตอบ (เป็น null จนกว่าจะมีคนรับเรื่อง)
  String? staffId;
  final List<Message> messages;

  /// จำนวนข้อความที่แต่ละฝั่งอ่านแล้ว ใช้คำนวณเลขแจ้งเตือนที่ยังไม่อ่าน
  /// (ข้อความลำดับที่ >= ค่านี้ = ยังไม่อ่าน)
  int studentReadCount = 0;
  int staffReadCount = 0;
  bool closed = false; // จบการปรึกษาแล้ว (พิมพ์ต่อไม่ได้)
  DateTime? closedAt; // เวลาที่จบการปรึกษา
  String? closedById; // ใครกดจบ (เจ้าหน้าที่หรือนักศึกษา)

  /// สรุปที่เจ้าหน้าที่กรอกตอนจบการปรึกษา (เก็บเป็นประวัติ)
  String summaryTopic = ''; // เรื่องที่ปรึกษา
  String summaryHelp = ''; // คำปรึกษาที่เจ้าหน้าที่ให้
  CaseLevel? caseLevel; // ระดับเคส เล็ก/กลาง/ใหญ่ (null = ยังไม่ได้สรุป)

  /// มีสรุปจากเจ้าหน้าที่แล้วหรือยัง (นักศึกษากดจบเองจะยังไม่มี)
  bool get hasSummary => summaryTopic.isNotEmpty || summaryHelp.isNotEmpty;

  Message? get last => messages.isEmpty ? null : messages.last;
}

/// สถานะคำขอนัดหมายที่ห้องกิจการนิสิต
enum AppointmentStatus {
  pending('รอยืนยัน'), // นักศึกษาส่งคำขอแล้ว รอเจ้าหน้าที่ดู
  confirmed('ยืนยันแล้ว'), // เจ้าหน้าที่สะดวกและกดยืนยัน
  proposed(
    'พี่เสนอเวลาใหม่',
  ), // เจ้าหน้าที่ไม่ว่าง เสนอเวลาที่ตัวเองว่างแทน รอนักศึกษาตอบรับ
  cancelled('ยกเลิกแล้ว'); // นักศึกษายกเลิกเอง

  const AppointmentStatus(this.label);
  final String label;
}

/// นัดหมายถามตอบกับพี่ไข่หวานที่ห้องกิจการนิสิต (ครั้งละ 30 นาที)
class Appointment {
  Appointment({
    required this.id,
    required this.studentId,
    required this.start,
    this.note = '',
    this.status = AppointmentStatus.pending,
    this.staffId,
    this.requestedStaffId,
  });

  /// ระยะเวลาให้คำปรึกษาต่อ 1 นัด
  static const duration = Duration(minutes: 30);

  final String id;
  final String studentId;

  /// วันและเวลาเริ่มนัด (เปลี่ยนได้ถ้านักศึกษาตกลงเวลาที่พี่เสนอ)
  DateTime start;
  final String note; // เรื่องที่อยากปรึกษา (ไม่บังคับ)
  AppointmentStatus status;
  String? staffId; // เจ้าหน้าที่ที่กดยืนยัน/เสนอเวลาใหม่

  /// เจ้าหน้าที่ที่นักศึกษาเลือกนัดด้วย
  /// null = คนไหนก็ได้ (แจ้งเตือนทุกคน), มีค่า = แจ้งเตือนเฉพาะคนนั้น
  final String? requestedStaffId;

  /// เวลาที่เจ้าหน้าที่เสนอแทน (มีค่าเฉพาะสถานะ proposed)
  DateTime? proposedStart;

  /// ข้อความจากเจ้าหน้าที่ตอนเสนอเวลาใหม่ เช่น “ช่วงเช้าพี่ติดประชุมนะ”
  String staffMessage = '';

  /// นักศึกษาเห็นการเปลี่ยนสถานะล่าสุดแล้วหรือยัง (ใช้ทำ badge แจ้งเตือนฝั่งนักศึกษา)
  bool seenByStudent = true;

  DateTime get end => start.add(duration);
}

/// ช่องทางที่ปรึกษา (ใช้ในตารางสรุปเคส)
enum ConsultChannel { online, onsite }

/// 1 แถวในตารางสรุปเคสของเจ้าหน้าที่ (รายงานส่งส่วนกลาง)
///
/// เป็น “สำเนา” แยกจากแชท: แก้ในตารางแล้วไม่กระทบแชท
/// - แถว online สร้างอัตโนมัติจากแชทที่จบแล้ว ([conversationId] มีค่า)
///   ถ้ายังไม่เคยแก้ในตาราง ([edited] = false) จะอัปเดตตามสรุปในแชทอัตโนมัติ
/// - แถว onsite เจ้าหน้าที่เพิ่มเองหลังคุยกับนิสิตเสร็จ ([conversationId] = null)
class CaseReport {
  CaseReport({
    required this.id,
    required this.staffId,
    required this.date,
    required this.studentIdNo,
    required this.studentName,
    required this.categoryId,
    required this.channel,
    this.conversationId,
    this.topic = '',
    this.advice = '',
    this.level,
    this.edited = false,
  });

  final String id;
  final String staffId; // เจ้าของแถว (เห็นเฉพาะเจ้าหน้าที่คนนี้)
  final String? conversationId; // แชทต้นทาง (null = แถว onsite ที่เพิ่มเอง)

  // คอลัมน์ที่ล็อก (มาจากระบบ / ตอนเพิ่มแถว)
  final DateTime date; // วันที่มาขอรับคำปรึกษา
  final String studentIdNo; // รหัสนิสิต
  final String studentName; // ชื่อ-สกุล
  final ConsultChannel channel; // ช่องทางที่ปรึกษา

  // คอลัมน์ที่แก้ได้ในตาราง
  String categoryId; // ประเภทปรึกษา: general / urgent
  String topic; // เรื่องที่ปรึกษา
  String advice; // คำปรึกษาที่เจ้าหน้าที่ให้
  CaseLevel? level; // ระดับ

  /// เคยแก้ในตารางแล้ว -> ไม่ดึงสรุปจากแชทมาทับอีก
  bool edited;

  bool get isManual => conversationId == null;
}
