import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart' show DatabaseFactory;

import '../config/staff_accounts.dart';
import 'app_database.dart';
import 'attachments.dart';
import 'models.dart';
import 'passwords.dart';

/// ข้อมูลกลางของแอป (ไม่ใช่ Provider) ที่ Provider ทุกตัวใช้ร่วมกัน
///
/// - เก็บข้อมูลทั้งหมดในหน่วยความจำ (users / conversations / appointments / reports)
///   และบันทึกถาวรลง SQLite ผ่าน [db] ([AppDatabase]) ปิดแอปแล้วข้อมูลไม่หาย
/// - ค่าคงที่ของแอป (หัวข้อ, ห้องกิจการนิสิต, เบอร์ฉุกเฉิน, ภาควิชา/สาขา, เวลานัด)
/// - ข้อมูลตั้งต้นตอนเปิดแอปครั้งแรก (บัญชีเจ้าหน้าที่ + นักศึกษาทดสอบ)
///
/// ตรรกะแต่ละเรื่องแยกไปอยู่ใน Provider ตามฟีเจอร์ (lib/providers/):
///   AuthProvider (ล็อกอิน/สมัคร/โปรไฟล์), ChatProvider (แชท),
///   AppointmentProvider (นัดหมาย), ReportProvider (ตารางสรุปเคส)
/// หน้าจอเรียกใช้ผ่าน context.watch / context.read (บทที่ 10–11)
class AppData {
  AppData._(this.db, this._demoData);

  /// ฐานข้อมูล SQLite (Provider ใช้บันทึกข้อมูลที่เปลี่ยน)
  final AppDatabase db;

  /// ใส่ข้อมูลทดลอง (นักศึกษา/แชท/นัด/เคสตัวอย่าง) ตอนสร้างฐานข้อมูลใหม่หรือไม่
  final bool _demoData;

  /// id ของผู้ที่ล็อกอินค้างไว้จากครั้งก่อน (AuthProvider ใช้คืนสถานะล็อกอิน)
  String? savedUserId;

  /// เปิดข้อมูล: เปิดฐานข้อมูล -> ครั้งแรกใส่ข้อมูลตั้งต้น, ครั้งต่อไปโหลดของเดิม
  /// [factory]/[path]/[demoData] ใช้ตอนทดสอบ ปกติไม่ต้องส่ง
  /// แอปจริงเริ่มจากฐานข้อมูลว่าง มีแค่บัญชีเจ้าหน้าที่ + นักศึกษาทดสอบ
  static Future<AppData> open({
    DatabaseFactory? factory,
    String? path,
    bool demoData = false,
  }) async {
    final db = await AppDatabase.open(factory: factory, path: path);
    final s = AppData._(db, demoData);
    db.onWriteError = (e) => s.onSaveFailed?.call(e);
    if (await db.isEmpty()) {
      s._seedAll();
    } else {
      final data = await db.loadAll();
      s.users.addAll(data.users);
      s.conversations.addAll(data.conversations);
      s.appointments.addAll(data.appointments);
      s.reports.addAll(data.reports);
      // ลบค่าตั้งค่าโหมดตอบกลับอัตโนมัติที่เลิกใช้แล้ว (ฐานข้อมูลจากเวอร์ชันก่อน)
      if (data.settings.containsKey('auto_reply')) {
        db.setSetting('auto_reply', null);
      }
      s.savedUserId = data.settings[currentUserKey];
    }
    return s;
  }

  /// ถูกเรียกเมื่อบันทึกข้อมูลลงฐานข้อมูลไม่สำเร็จ
  /// main.dart ตั้งให้ขึ้นแถบแจ้งเตือนล่างจอ ผู้ใช้จะได้รู้ว่าข้อมูลล่าสุดอาจไม่ถูกเก็บ
  void Function(Object error)? onSaveFailed;

  /// รอให้การบันทึกลงฐานข้อมูลที่ค้างอยู่เสร็จ (ใช้ตอนทดสอบ)
  Future<void> flush() => db.flush();

  /// key ใน settings ที่จำผู้ที่ล็อกอินค้างไว้
  static const currentUserKey = 'current_user_id';

  int _idSeq = 100;

  /// สร้าง id ใหม่ที่ไม่ซ้ำแม้ปิด-เปิดแอปใหม่ (p = prefix เช่น c, a, u, r)
  String newId(String p) =>
      '$p${DateTime.now().microsecondsSinceEpoch}_${_idSeq++}';

  /// บันทึกทุกอย่างในหน่วยความจำลงฐานข้อมูล (ใช้หลังใส่ข้อมูลตั้งต้น)
  void _saveAll() {
    users.forEach(db.saveUser);
    conversations.forEach(db.saveConversation);
    appointments.forEach(db.saveAppointment);
    reports.forEach(db.saveReport);
  }

  /// ใส่ข้อมูลตั้งต้นลงฐานข้อมูลใหม่: บัญชีเจ้าหน้าที่ (+ ข้อมูลทดลองถ้าเปิดไว้)
  void _seedAll() {
    _seed();
    if (_demoData) _seedDemo();
    _saveAll();
    conversations.forEach(syncChatReport);
  }

  /// รีเซ็ตข้อมูล: ลบทุกอย่างแล้วกลับเป็นข้อมูลตั้งต้น (ไม่มีใครล็อกอินค้าง)
  void resetData() {
    db.clearAll();
    try {
      Attachments.clear();
    } on StateError {
      // ยังไม่ได้ตั้งโฟลเดอร์ไฟล์แนบ (เช่น ตอนทดสอบ) ไม่มีอะไรต้องลบ
    }
    users.clear();
    conversations.clear();
    appointments.clear();
    reports.clear();
    savedUserId = null;
    _seedAll();
  }

  final List<AppUser> users = []; // ผู้ใช้ทั้งหมด (นักศึกษา + เจ้าหน้าที่)
  final List<Conversation> conversations = []; // ห้องแชททั้งหมด
  final List<Appointment> appointments = []; // นัดหมายที่ห้องกิจการนิสิตทั้งหมด
  final List<CaseReport> reports = []; // ตารางสรุปเคสของเจ้าหน้าที่ทุกคน

  /// หัวข้อที่ให้เลือกปรึกษา แก้ได้ที่นี่ที่เดียว ทั้งฝั่งนักศึกษาและเจ้าหน้าที่จะเปลี่ยนตาม
  static const categories = <ConsultCategory>[
    ConsultCategory(
      id: 'general',
      title: 'ถาม/ตอบเรื่องทั่วไป',
      subtitle: 'กยศ./ทุน/การเรียน/ปัญหาทั่วไป/อื่นๆ',
      icon: Icons.forum_rounded,
    ),
    ConsultCategory(
      id: 'urgent',
      title: 'ขอความช่วยเหลือแบบเร่งด่วน',
      subtitle: 'อุบัติเหตุ/โดนทำร้ายร่างกาย/สต็อคเกอร์/เรื่องเร่งด่วนอื่นๆ',
      icon: Icons.sos_rounded,
      urgent: true,
    ),
  ];

  /// หาหัวข้อจาก id เช่น 'urgent' -> ขอความช่วยเหลือแบบเร่งด่วน
  static ConsultCategory category(String id) =>
      categories.firstWhere((c) => c.id == id);

  /// ข้อมูลห้องกิจการนิสิต (ข้อมูลตัวอย่าง แก้เป็นข้อมูลจริงได้ที่นี่)
  static const officeName = 'ห้องกิจการนิสิต';
  static const officeLocation = 'ห้องกิจการนิสิต คณะวิทยาศาสตร์';
  static const officeHoursText = 'จันทร์–ศุกร์ 08:30–16:30 น.';

  /// เบอร์ฉุกเฉินที่แจ้งอัตโนมัติในแชทเร่งด่วน (แก้เป็นเบอร์จริงได้ที่นี่)
  static const emergencyPhone = '0869369977';
  static const emergencyMessage =
      'หากฉุกเฉินโปรดโทรเบอร์นี้ทันที $emergencyPhone';

  /// เวลาเปิดให้นัด: 08:30 ถึง 16:30 (นัดสุดท้ายเริ่ม 16:00) เป็นนาทีนับจากเที่ยงคืน
  static const officeOpenMinute = 8 * 60 + 30;
  static const officeCloseMinute = 16 * 60 + 30;

  /// ภาควิชาและสาขาวิชาของคณะวิทยาศาสตร์ (หน้าสมัครสมาชิก: เลือกภาควิชาก่อน แล้วเลือกสาขา)
  /// ในฐานข้อมูลเก็บแค่ชื่อสาขา ภาควิชาหาได้จาก [departmentOf]
  static const departments = <String, List<String>>{
    'ภาควิชาคณิตศาสตร์': [
      'สาขาวิชาคณิตศาสตร์',
      'สาขาวิชาสถิติประยุกต์และการวิเคราะห์ข้อมูล',
      'สาขาวิชาวิทยาการข้อมูล',
    ],
    'ภาควิชาเคมี': ['สาขาวิชาเคมี'],
    'ภาควิชาชีววิทยา': ['สาขาวิชาชีววิทยา'],
    'ภาควิชาฟิสิกส์': [
      'สาขาวิชาฟิสิกส์',
      'สาขาวิชาฟิสิกส์ประยุกต์',
      'สาขาวิชาเทคโนโลยีการวัดและระบบอัจฉริยะ',
      'สาขาวิชาเทคโนโลยีและนวัตกรรมพลังงานและสิ่งแวดล้อม',
    ],
    'ภาควิชาวิทยาการคอมพิวเตอร์และเทคโนโลยีสารสนเทศ': [
      'สาขาวิชาวิทยาการคอมพิวเตอร์',
      'สาขาวิชาเทคโนโลยีสารสนเทศ',
    ],
  };

  /// สาขาทั้งหมด (ทุกภาควิชา)
  static List<String> get majors => [
    for (final list in departments.values) ...list,
  ];

  /// หาภาควิชาของสาขา (null = ไม่อยู่ในรายการ เช่น ข้อมูลเก่า)
  static String? departmentOf(String major) => departments.entries
      .where((e) => e.value.contains(major))
      .map((e) => e.key)
      .firstOrNull;

  // ตัวช่วยค้นหาข้อมูล
  List<AppUser> get staff => users.where((u) => u.isStaff).toList();
  AppUser user(String id) => users.firstWhere((u) => u.id == id);
  Conversation conversation(String id) =>
      conversations.firstWhere((c) => c.id == id);

  /// รูปแบบเบอร์โทร: 10 หลัก ขึ้นต้นด้วย 0 (ใช้ทั้งตอนสมัครและแก้โปรไฟล์)
  static bool isValidPhone(String phone) =>
      RegExp(r'^0\d{9}$').hasMatch(phone.trim());

  // ---------------------------------------------------------------- appointments (กติกาเวลานัด)

  /// วันที่นัดได้: จันทร์–ศุกร์ ตั้งแต่วันนี้เป็นต้นไป
  static bool isOfficeDay(DateTime d) =>
      d.weekday != DateTime.saturday && d.weekday != DateTime.sunday;

  /// ช่องเวลาทั้งหมดของวันนั้น (ทุก 30 นาที ตามเวลาเปิดห้อง)
  static List<DateTime> slotsOf(DateTime day) => [
    for (
      var m = officeOpenMinute;
      m + Appointment.duration.inMinutes <= officeCloseMinute;
      m += Appointment.duration.inMinutes
    )
      DateTime(day.year, day.month, day.day, m ~/ 60, m % 60),
  ];

  /// เลือกช่องเวลานี้ได้ไหม: ทุกช่องเลือกได้ ยกเว้นเวลาที่ผ่านไปแล้ว
  /// (ไม่เช็กว่าเจ้าหน้าที่ว่างไหม ให้เจ้าหน้าที่ตรวจเองแล้วยืนยัน/เสนอเวลาใหม่)
  static bool isBookable(DateTime start) => start.isAfter(DateTime.now());

  // ---------------------------------------------------------------- case reports
  // ใช้ร่วมกันตอนใส่ข้อมูลตั้งต้นและตอนแชทจบ (ChatProvider -> ReportProvider)

  /// สร้าง/อัปเดตแถว online ของแชทที่จบแล้ว
  /// - ยังไม่มีแถว -> สร้างใหม่ (วันที่ = เวลาที่เปิดแชท)
  /// - มีแล้วและยังไม่เคยแก้ในตาราง -> อัปเดตตามสรุปในแชท
  /// - เคยแก้ในตารางแล้ว -> ไม่ทับ (ค่าในตารางเป็นตัวจริง)
  void syncChatReport(Conversation c) {
    if (!c.closed || c.staffId == null) return;
    final student = user(c.studentId);
    final existing = reports.where((r) => r.conversationId == c.id).firstOrNull;
    if (existing != null && existing.edited) return;
    final r =
        existing ??
        CaseReport(
          id: newId('r'),
          staffId: c.staffId!,
          conversationId: c.id,
          date: c.messages.isEmpty ? DateTime.now() : c.messages.first.time,
          studentIdNo: student.studentId,
          studentName: student.name,
          categoryId: c.categoryId,
          channel: ConsultChannel.online,
        );
    r
      ..categoryId = c.categoryId
      ..topic = c.summaryTopic
      ..advice = c.summaryHelp
      ..level = c.caseLevel;
    if (existing == null) reports.add(r);
    db.saveReport(r);
  }

  /// รูปเจ้าหน้าที่ (ตาม id) ใช้แทน emoji ในวงกลมรูปโปรไฟล์
  /// รูปต้นฉบับเก็บไว้ที่ design/staff_photos/ ส่วนในแอปใช้รูปที่ครอปเป็นสี่เหลี่ยมจัตุรัส 400x400
  /// เจ้าหน้าที่ที่ไม่มีในรายการนี้จะแสดง emoji 👩🏻‍💼 เหมือนเดิม
  static const staffPhotos = {
    'st1': 'assets/images/staff_manao.jpg', // มะนาว
    'st2': 'assets/images/staff_naen.jpg', // แนน
    'st3': 'assets/images/staff_kwan.jpg', // ขวัญ
  };

  // ---------------------------------------------------------------- seed data
  // ข้อมูลตั้งต้นตอนเปิดแอปครั้งแรก (และตอนรีเซ็ต)

  /// สีพื้นหลังรูปโปรไฟล์ของเจ้าหน้าที่ (วนใช้ตามลำดับ)
  static const _staffColors = [
    Color(0xFFB9D7E8),
    Color(0xFFF6C9D0),
    Color(0xFFCDE8C5),
  ];

  /// บัญชีนักศึกษาทดสอบ 1 บัญชี ให้ผู้สอน/ผู้ทดลองล็อกอินได้ทันทีโดยไม่ต้องสมัคร
  /// ข้อมูลสมมติที่ผ่านเงื่อนไขการลงทะเบียน · รหัสผ่านทดสอบ ไม่ใช่รหัสจริงของใคร
  static const testStudentEmail = 'testerk67@nu.ac.th';
  static const testStudentPassword = 'test1234';

  /// ข้อมูลตั้งต้นที่มีทุกครั้ง:
  /// - บัญชีเจ้าหน้าที่จาก lib/config/staff_accounts.dart (ไม่ได้ commit เพราะมีรหัสผ่าน)
  ///   id = st1, st2, ... ตามลำดับในไฟล์ (รูปเจ้าหน้าที่ใน [staffPhotos] จับคู่ด้วย id นี้)
  /// - บัญชีนักศึกษาทดสอบ 1 บัญชี
  void _seed() {
    users.addAll([
      for (final (i, a) in staffAccounts.indexed)
        AppUser(
          id: 'st${i + 1}',
          email: a.email.trim().toLowerCase(),
          passwordHash: hashPassword(a.email, a.password),
          name: a.name,
          nickname: a.nickname,
          avatarColor: _staffColors[i % _staffColors.length],
          role: Role.staff,
        ),
      AppUser(
        id: 'tester',
        email: testStudentEmail,
        passwordHash: hashPassword(testStudentEmail, testStudentPassword),
        name: 'ทดสอบ ระบบ',
        nameEn: 'Tester Kaiwan',
        studentId: '67310001',
        phone: '0800000000',
        major: 'สาขาวิชาวิทยาการคอมพิวเตอร์',
        role: Role.student,
      ),
    ]);
  }

  /// ข้อมูลทดลอง (นักศึกษา 3 คน + แชท นัดหมาย เคส onsite ตัวอย่าง)
  /// ใช้เฉพาะตอนทดสอบ (open(demoData: true)) แอปจริงเริ่มจากข้อมูลว่าง
  void _seedDemo() {
    users.addAll([
      // นักศึกษาทดลอง (อีเมล/รหัสนิสิต/ชื่ออังกฤษ ตามเงื่อนไขการลงทะเบียน · รหัสผ่าน 1234)
      AppUser(
        id: 'stu1',
        email: 'somjaij67@nu.ac.th',
        passwordHash: hashPassword('somjaij67@nu.ac.th', '1234'),
        name: 'สมใจ ใจดี',
        nameEn: 'Somjai Jaidee',
        studentId: '67313301',
        phone: '0812345678',
        major: 'สาขาวิชาวิทยาการคอมพิวเตอร์',
        role: Role.student,
      ),
      AppUser(
        id: 'stu2',
        email: 'kittik66@nu.ac.th',
        passwordHash: hashPassword('kittik66@nu.ac.th', '1234'),
        name: 'กิตติ ขยันเรียน',
        nameEn: 'Kitti Khayanrian',
        studentId: '66313302',
        phone: '0823456789',
        major: 'สาขาวิชาเคมี',
        role: Role.student,
      ),
      AppUser(
        id: 'stu3',
        email: 'maneerats68@nu.ac.th',
        passwordHash: hashPassword('maneerats68@nu.ac.th', '1234'),
        name: 'มณีรัตน์ แสงทอง',
        nameEn: 'Maneerat Saengthong',
        studentId: '68313303',
        phone: '0834567890',
        major: 'สาขาวิชาชีววิทยา',
        role: Role.student,
      ),
    ]);

    final now = DateTime.now();
    // ตัวช่วยสร้างห้องแชทตัวอย่าง (staffRead = จำนวนข้อความที่เจ้าหน้าที่อ่านแล้ว)
    Conversation seed(
      String student,
      String cat,
      String? staffId,
      List<(String, String, int)> msgs, {
      int staffRead = 0,
    }) {
      final c = Conversation(
        id: newId('c'),
        studentId: student,
        categoryId: cat,
        isSpecific: staffId != null,
        staffId: staffId,
        messages: [
          for (final m in msgs)
            Message(
              senderId: m.$1,
              text: m.$2,
              time: now.subtract(Duration(minutes: m.$3)),
            ),
        ],
      );
      c.staffReadCount = staffRead;
      c.studentReadCount = c.messages.length;
      conversations.add(c);
      return c;
    }

    // แชทที่ยังไม่ได้อ่าน เพื่อให้กระดิ่งฝั่งเจ้าหน้าที่มีตัวเลขให้เห็น
    // รูปแบบข้อความ: (ผู้ส่ง, ข้อความ, กี่นาทีที่แล้ว)
    seed('stu2', 'general', null, [
      ('stu2', 'สวัสดีครับ ส่งเอกสาร กยศ. รอบนี้ต้องใช้อะไรบ้างครับ', 42),
      ('stu2', 'ผมต้องส่งภายในวันไหนครับ', 41),
    ]);
    seed('stu3', 'general', 'st1', [
      (
        'stu3',
        'พี่คะ ผู้ปกครองอยู่ต่างจังหวัด เซ็นเอกสาร กยศ. แทนได้ไหมคะ',
        30,
      ),
    ]);
    seed('stu3', 'general', 'st2', [
      ('stu3', 'พี่คะ ดรอปวิชาตอนนี้ยังทันไหมคะ', 12),
      ('st2', 'ทันค่ะ ภายในสัปดาห์ที่ 12 นะคะ', 10),
      ('stu3', 'ต้องให้อาจารย์ที่ปรึกษาเซ็นด้วยไหมคะ', 6),
    ], staffRead: 2);
    seed('stu2', 'urgent', null, [
      ('stu2', 'พี่ครับ ตอนนี้ผมรู้สึกแย่มาก ไม่รู้จะทำยังไงดีครับ', 4),
    ]);

    // นัดหมายตัวอย่าง: รอยืนยัน 2 นัด, ยืนยันแล้ว 1 นัด, พี่เสนอเวลาใหม่ 1 นัด (ในวันทำการถัดๆ ไป)
    DateTime nextOfficeDay(int skip) {
      var d = DateTime(now.year, now.month, now.day);
      var left = skip;
      while (true) {
        d = d.add(const Duration(days: 1));
        if (isOfficeDay(d) && left-- == 0) return d;
      }
    }

    DateTime at(DateTime day, int h, int m) =>
        DateTime(day.year, day.month, day.day, h, m);
    appointments.addAll([
      Appointment(
        id: newId('a'),
        studentId: 'stu2',
        start: at(nextOfficeDay(0), 10, 0),
        note: 'อยากปรึกษาเรื่องเอกสาร กยศ. แบบเจอตัว',
      ),
      Appointment(
        id: newId('a'),
        studentId: 'stu3',
        start: at(nextOfficeDay(1), 13, 30),
        note: 'ปรึกษาเรื่องการปรับตัว',
        requestedStaffId: 'st1', // ขอนัดกับเจ้าหน้าที่คนที่ 1 โดยตรง
      ),
      Appointment(
        id: newId('a'),
        studentId: 'stu3',
        start: at(nextOfficeDay(0), 14, 0),
        status: AppointmentStatus.confirmed,
        staffId: 'st3',
      ),
      // นัดของนักศึกษาทดลองที่พี่ไม่ว่าง เลยเสนอเวลาใหม่ (ไว้เดโมฝั่งนักศึกษา)
      Appointment(
          id: newId('a'),
          studentId: 'stu1',
          start: at(nextOfficeDay(1), 9, 0),
          note: 'อยากปรึกษาเรื่องทุนการศึกษา',
          status: AppointmentStatus.proposed,
          staffId: 'st1',
        )
        ..proposedStart = at(nextOfficeDay(1), 11, 0)
        ..staffMessage = 'ช่วงเช้าพี่ติดประชุม สะดวก 11 โมงไหมคะ'
        ..seenByStudent = false,
    ]);

    // ห้องที่จบแล้ว = ประวัติการปรึกษา (มีสรุปจากเจ้าหน้าที่ / ยังไม่สรุป)
    void close(
      Conversation c,
      String by,
      int minutesAgo, [
      String t = '',
      String h = '',
      CaseLevel? level,
    ]) {
      c
        ..caseLevel = level
        ..closed = true
        ..closedAt = now.subtract(Duration(minutes: minutesAgo))
        ..closedById = by
        ..summaryTopic = t
        ..summaryHelp = h;
      // ห้องส่วนรวม: เจ้าหน้าที่คนแรกที่ตอบ = ผู้รับเรื่อง
      c.staffId ??= c.messages
          .map((m) => user(m.senderId))
          .firstWhere((u) => u.isStaff)
          .id;
      c.messages.add(
        Message(
          senderId: 'system',
          isSystem: true,
          text: 'การปรึกษานี้สิ้นสุดแล้ว ขอบคุณที่ใช้บริการ',
          time: c.closedAt,
        ),
      );
      c.staffReadCount = c.studentReadCount = c.messages.length;
    }

    // แชทเก่าของนักศึกษาทดลอง เพื่อให้หน้า “แชทของฉัน” ไม่ว่าง
    close(
      seed('stu1', 'general', 'st2', [
        ('stu1', 'ยื่นขอจบต้องทำยังไงบ้างคะ', 1440),
        (
          'st2',
          'ตรวจหน่วยกิตให้ครบ แล้วยื่นคำร้องที่งานทะเบียนได้เลยค่ะ',
          1430,
        ),
      ]),
      'st2',
      1420,
      'สอบถามขั้นตอนการยื่นขอจบการศึกษา',
      'อธิบายให้ตรวจหน่วยกิตให้ครบ แล้วยื่นคำร้องที่งานทะเบียน',
      CaseLevel.small,
    );
    close(
      seed('stu3', 'general', null, [
        ('stu3', 'ทุนเรียนดีปีนี้เปิดรับเมื่อไหร่คะ', 2900),
        ('st1', 'เปิดรับถึงปลายเดือนนี้ค่ะ ยื่นออนไลน์ได้เลยนะคะ', 2890),
      ]),
      'st1',
      2880,
      'สอบถามช่วงเวลาเปิดรับทุนเรียนดี',
      'แจ้งกำหนดปิดรับและช่องทางยื่นออนไลน์',
      CaseLevel.small,
    );
    close(
      seed('stu2', 'urgent', null, [
        ('stu2', 'พี่ครับ ผมเครียดเรื่องสอบมาก นอนไม่หลับหลายวันแล้ว', 4400),
        ('st3', 'พี่อยู่ตรงนี้นะ ตอนนี้ปลอดภัยไหมคะ เล่าให้พี่ฟังได้เลย', 4398),
      ]),
      'st3',
      4300,
      'ความเครียดเรื่องสอบ นอนไม่หลับ',
      'รับฟัง แนะนำเทคนิคผ่อนคลาย และนัดพบนักจิตวิทยาที่ห้องกิจการนิสิต',
      CaseLevel.large,
    );
    // นักศึกษากดจบเอง -> ยังไม่มีสรุป ให้เจ้าหน้าที่มาบันทึกทีหลัง
    close(
      seed('stu3', 'general', null, [
        ('stu3', 'ขอเอกสารรับรองการเป็นนักศึกษาได้ที่ไหนคะ', 300),
        ('st1', 'ขอได้ที่งานทะเบียน ชั้น 1 ค่ะ', 295),
      ]),
      'stu3',
      290,
    );

    // แถว onsite ตัวอย่างในตารางสรุปเคส (เจ้าหน้าที่คนที่ 1 เพิ่มเองหลังคุยที่ห้อง)
    final twoDaysAgo = now.subtract(const Duration(days: 2));
    reports.add(
      CaseReport(
        id: newId('r'),
        staffId: 'st1',
        date: DateTime(twoDaysAgo.year, twoDaysAgo.month, twoDaysAgo.day, 10),
        studentIdNo: '66313302',
        studentName: 'กิตติ ขยันเรียน',
        categoryId: 'general',
        channel: ConsultChannel.onsite,
        topic: 'ปรึกษาเรื่องเอกสาร กยศ. แบบเจอตัว',
        advice: 'ตรวจเอกสารให้ครบและนัดส่งที่กองพัฒนานักศึกษา',
        level: CaseLevel.small,
        edited: true,
      ),
    );
  }
}
