import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart' show DatabaseFactory;

import 'app_database.dart';
import 'attachments.dart';
import 'models.dart';
import 'passwords.dart';
import 'registration_rules.dart';

/// ที่เก็บข้อมูลของแอป (store) + logic ทั้งหมด
///
/// - ข้อมูลเก็บถาวรใน SQLite ในเครื่อง ([AppDatabase]) ไม่หายตอนปิดแอป
///   ตอนเปิดแอปโหลดขึ้นหน่วยความจำทั้งหมด แล้วทุกครั้งที่ข้อมูลเปลี่ยนจะบันทึกลงฐานข้อมูลทันที
///   (เมธอดต่างๆ จึงยังทำงานแบบ sync ได้ หน้าจอไม่ต้องรอ)
/// - ฝั่งนักศึกษาและเจ้าหน้าที่ใช้ store เดียวกัน: ส่งข้อความในฐานะนักศึกษา
///   แล้ว logout ไปเข้าเป็นเจ้าหน้าที่ จะเห็นกระดิ่งแจ้งเตือนของข้อความนั้น
/// - เป็น [ChangeNotifier]: ทุกครั้งที่ข้อมูลเปลี่ยนจะเรียก notifyListeners()
///   หน้าจอที่ห่อด้วย ListenableBuilder จะวาดใหม่เอง
///
/// ตอนต่อ backend จริง ให้แทนที่เมธอดในไฟล์นี้ด้วยการเรียก API
/// โดยคงชื่อเมธอดเดิมไว้ หน้าจอจะได้ไม่ต้องแก้มาก
class MockStore extends ChangeNotifier {
  MockStore._(this._db);

  final AppDatabase _db;

  /// เปิด store: เปิดฐานข้อมูล -> ครั้งแรกใส่ข้อมูลตั้งต้น, ครั้งต่อไปโหลดของเดิม
  /// และคืนสถานะล็อกอินค้างไว้ (ถ้ายังไม่ได้ออกจากระบบ)
  /// [factory]/[path] ใช้ตอนทดสอบ ปกติไม่ต้องส่ง
  static Future<MockStore> open({
    DatabaseFactory? factory,
    String? path,
  }) async {
    final db = await AppDatabase.open(factory: factory, path: path);
    final s = MockStore._(db);
    if (await db.isEmpty()) {
      s._seed();
      s._saveAll();
      s.conversations.forEach(s._syncChatReport);
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
      final uid = data.settings[_kCurrentUser];
      s.currentUser = s.users.where((u) => u.id == uid).firstOrNull;
    }
    return s;
  }

  /// รอให้การบันทึกลงฐานข้อมูลที่ค้างอยู่เสร็จ (ใช้ตอนทดสอบ)
  Future<void> flush() => _db.flush();

  static const _kCurrentUser = 'current_user_id'; // ผู้ที่ล็อกอินค้างไว้

  int _idSeq = 100;

  /// สร้าง id ใหม่ที่ไม่ซ้ำแม้ปิด-เปิดแอปใหม่ (p = prefix เช่น c, a, u)
  String _nextId(String p) =>
      '$p${DateTime.now().microsecondsSinceEpoch}_${_idSeq++}';

  /// รหัสผ่านของบัญชีตั้งต้น ใช้เฉพาะปุ่ม “บัญชีทดลอง” กรอกอัตโนมัติ
  /// (ในฐานข้อมูลเก็บแค่ hash จึงต้องจำตัวจริงไว้ที่นี่สำหรับเดโม)
  static const demoPasswords = {
    'somjaij67@nu.ac.th': '1234',
    'kittik66@nu.ac.th': '1234',
    'maneerats68@nu.ac.th': '1234',
    'piyaromk@nu.ac.th': 'kaiwanpiyaromk',
    'khuwnruanep@nu.ac.th': 'kaiwankhuwnruanep',
    'chonnikank@nu.ac.th': 'kaiwanchonnikank',
  };

  /// บันทึกทุกอย่างในหน่วยความจำลงฐานข้อมูล (ใช้หลังใส่ข้อมูลตั้งต้น)
  void _saveAll() {
    users.forEach(_db.saveUser);
    conversations.forEach(_db.saveConversation);
    appointments.forEach(_db.saveAppointment);
    reports.forEach(_db.saveReport);
  }

  /// รีเซ็ตข้อมูลทดลอง: ลบทุกอย่างแล้วใส่ข้อมูลตั้งต้นใหม่ (ออกจากระบบด้วย)
  void resetDemoData() {
    _db.clearAll();
    try {
      Attachments.clear();
    } on StateError {
      // ยังไม่ได้ตั้งโฟลเดอร์ไฟล์แนบ (เช่น ตอนทดสอบ) ไม่มีอะไรต้องลบ
    }
    users.clear();
    conversations.clear();
    appointments.clear();
    reports.clear();
    currentUser = null;
    _seed();
    _saveAll();
    conversations.forEach(_syncChatReport);
    notifyListeners();
  }

  AppUser? currentUser; // ผู้ที่ล็อกอินอยู่ (null = ยังไม่ล็อกอิน)
  final List<AppUser> users = []; // ผู้ใช้ทั้งหมด (นักศึกษา + เจ้าหน้าที่)
  final List<Conversation> conversations = []; // ห้องแชททั้งหมด
  final List<Appointment> appointments = []; // นัดหมายที่ห้องกิจการนิสิตทั้งหมด
  final List<CaseReport> reports = []; // ตารางสรุปเคสของเจ้าหน้าที่ทุกคน

  /// หัวข้อที่ให้เลือกปรึกษา แก้ได้ที่นี่ที่เดียว ทั้งฝั่งนักศึกษาและเจ้าหน้าที่จะเปลี่ยนตาม
  static const categories = <ConsultCategory>[
    ConsultCategory(
      id: 'general',
      title: 'ถาม/ตอบเรื่องทั่วไป',
      subtitle: 'สอบถามได้ทุกเรื่อง เลือกคุยกับพี่คนไหนก็ได้',
      icon: Icons.forum_rounded,
    ),
    ConsultCategory(
      id: 'urgent',
      title: 'ขอความช่วยเหลือแบบเร่งด่วน',
      subtitle: 'ส่งถึงพี่ไข่หวานทุกคนทันที',
      icon: Icons.sos_rounded,
      urgent: true,
    ),
  ];

  /// หาหัวข้อจาก id เช่น 'urgent' -> ขอความช่วยเหลือแบบเร่งด่วน
  static ConsultCategory category(String id) =>
      categories.firstWhere((c) => c.id == id);

  /// ข้อมูลห้องกิจการนิสิต (ข้อมูลตัวอย่าง แก้เป็นข้อมูลจริงได้ที่นี่)
  static const officeName = 'ห้องกิจการนิสิต';
  static const officeLocation = 'อาคารกิจการนิสิต ชั้น 1 (ข้อมูลตัวอย่าง)';
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

  // ---------------------------------------------------------------- auth
  // ล็อกอิน / สมัครสมาชิก / ออกจากระบบ

  /// ล็อกอิน: สำเร็จคืน null, ไม่สำเร็จคืนข้อความ error ไปแสดงบนหน้าจอ
  String? login(String email, String password) {
    final u = users.where(
      (u) => u.email.toLowerCase() == email.trim().toLowerCase(),
    );
    if (u.isEmpty) return 'ไม่พบบัญชีผู้ใช้นี้';
    if (u.first.passwordHash != hashPassword(email, password)) {
      return 'รหัสผ่านไม่ถูกต้อง';
    }
    currentUser = u.first;
    _db.setSetting(_kCurrentUser, u.first.id); // จำการล็อกอินไว้
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
    if (departmentOf(major) == null) return 'กรุณาเลือกสาขา';
    if (users.any((u) => u.email.toLowerCase() == email.trim().toLowerCase())) {
      return 'อีเมลนี้ถูกใช้แล้ว';
    }
    if (users.any((u) => u.studentId == studentId.trim())) {
      return 'รหัสนิสิตนี้ลงทะเบียนแล้ว';
    }
    final u = AppUser(
      id: _nextId('u'),
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
    _db.saveUser(u);
    currentUser = u;
    _db.setSetting(_kCurrentUser, u.id);
    notifyListeners();
    return null;
  }

  void logout() {
    currentUser = null;
    _db.setSetting(_kCurrentUser, null);
    notifyListeners();
  }

  // ---------------------------------------------------------------- student
  // ฟังก์ชันที่ใช้ฝั่งนักศึกษา

  /// แชททั้งหมดของนักศึกษาที่ล็อกอินอยู่ เรียงจากข้อความล่าสุด (หน้า “แชทของฉัน”)
  List<Conversation> myConversations() {
    // ไม่มีผู้ใช้ (เช่น ระหว่างแอนิเมชันตอน logout) คืนรายการว่างแทนการ crash
    final me = currentUser;
    if (me == null) return [];
    // ห้องที่กดเข้าไปแต่ยังไม่ได้พิมพ์/ส่งอะไรเลย ไม่ต้องขึ้นในรายการ (กันรายการรก)
    // กดเลือกหัวข้อ/พี่คนเดิมอีกครั้งจะเปิดห้องเดิมให้
    final list = conversations
        .where((c) => c.studentId == me.id && hasStudentMessage(c))
        .toList();
    list.sort(
      (a, b) =>
          (b.last?.time ?? DateTime(0)).compareTo(a.last?.time ?? DateTime(0)),
    );
    return list;
  }

  /// เปิดห้องแชทเมื่อนักศึกษาเลือกหัวข้อ (+ รูปแบบการปรึกษา) เสร็จ
  /// - staffId = null  -> ปรึกษาเจ้าหน้าที่คนไหนก็ได้ (ส่วนรวม)
  /// - staffId มีค่า   -> ปรึกษาเจ้าหน้าที่คนนั้นโดยตรง (ส่วนตัว)
  /// ถ้ามีห้องหัวข้อเดิม/แบบเดิมที่ยังไม่จบอยู่แล้ว จะเปิดห้องเดิมแทนการสร้างใหม่
  Conversation openConversation({required String categoryId, String? staffId}) {
    final me = currentUser!;
    final existing = conversations.where(
      (c) =>
          !c.closed &&
          c.studentId == me.id &&
          c.categoryId == categoryId &&
          c.isSpecific == (staffId != null) &&
          (staffId == null || c.staffId == staffId),
    );
    if (existing.isNotEmpty) return existing.first;

    final title = category(categoryId).title;
    final conv = Conversation(
      id: _nextId('c'),
      studentId: me.id,
      categoryId: categoryId,
      isSpecific: staffId != null,
      staffId: staffId,
      messages: [
        Message(
          senderId: 'system',
          isSystem: true,
          text: staffId != null
              ? 'เริ่มการปรึกษา "$title" กับ ${user(staffId).displayName}'
              : category(categoryId).urgent
              ? 'ส่งคำขอความช่วยเหลือเร่งด่วนถึงพี่ไข่หวานทุกคนแล้ว พี่จะรีบตอบนะ'
              : 'เริ่มการปรึกษา "$title" ระบบกำลังหาพี่ไข่หวานที่ว่างให้นะ',
        ),
        // แชทเร่งด่วน: แจ้งเบอร์ฉุกเฉินอัตโนมัติทันทีที่เปิดห้อง
        if (category(categoryId).urgent)
          Message(
            senderId: 'system',
            isSystem: true,
            isAlert: true,
            text: emergencyMessage,
          ),
      ],
    );
    conv.studentReadCount = conv.messages.length;
    conversations.add(conv);
    _db.saveConversation(conv);
    notifyListeners();
    return conv;
  }

  // ---------------------------------------------------------------- shared
  // ฟังก์ชันแชทที่ใช้ทั้งสองฝั่ง

  /// ส่งข้อความในนามผู้ที่ล็อกอินอยู่
  void send(Conversation conv, String text) {
    final t = text.trim();
    if (t.isEmpty) return;
    _post(conv, Message(senderId: currentUser!.id, text: t));
  }

  /// ส่งไฟล์แนบ (รูป/ไฟล์) [file] = ชื่อไฟล์ที่คัดลอกเก็บในแอปแล้ว (Attachments.import)
  void sendAttachment(
    Conversation conv, {
    required String file,
    required String name,
    required bool isImage,
  }) => _post(
    conv,
    Message(
      senderId: currentUser!.id,
      text: '',
      attachment: file,
      attachmentName: name,
      isImage: isImage,
    ),
  );

  /// เพิ่มข้อความของผู้ที่ล็อกอินอยู่ลงห้อง แล้วบันทึก
  void _post(Conversation conv, Message m) {
    final me = currentUser!;
    conv.messages.add(m);
    if (me.isStaff) {
      conv.staffId ??=
          me.id; // เจ้าหน้าที่คนแรกที่ตอบห้องส่วนรวม = ผู้รับเรื่อง
      conv.staffReadCount = conv.messages.length;
    } else {
      conv.studentReadCount = conv.messages.length;
    }
    _db.saveConversation(conv);
    notifyListeners();
  }

  /// ทำเครื่องหมายว่าผู้ที่ล็อกอินอยู่อ่านทุกข้อความในห้องนี้แล้ว (เรียกตอนเปิดห้องแชท)
  void markRead(Conversation conv) {
    final me = currentUser;
    if (me == null) return;
    if (me.isStaff) {
      if (conv.staffReadCount == conv.messages.length) return;
      conv.staffReadCount = conv.messages.length;
    } else {
      if (conv.studentReadCount == conv.messages.length) return;
      conv.studentReadCount = conv.messages.length;
    }
    _db.saveConversation(conv);
    notifyListeners();
  }

  /// จบการปรึกษา: ปิดช่องพิมพ์และเพิ่มข้อความระบบแจ้งว่าจบแล้ว
  /// เจ้าหน้าที่กดจบต้องส่ง [topic] (เรื่องที่ปรึกษา), [help] (ช่วยอะไรได้บ้าง)
  /// และ [level] (ระดับเคส เล็ก/กลาง/ใหญ่)
  /// นักศึกษากดจบเองไม่ต้องกรอก (เจ้าหน้าที่มาบันทึกสรุปทีหลังได้ด้วย [saveSummary])
  void closeConversation(
    Conversation conv, {
    String topic = '',
    String help = '',
    CaseLevel? level,
  }) {
    conv.closed = true;
    conv.caseLevel = level;
    conv.closedAt = DateTime.now();
    conv.closedById = currentUser?.id;
    // เจ้าหน้าที่กดจบห้องส่วนรวมที่ยังไม่มีผู้รับเรื่อง = นับเป็นคนให้คำปรึกษาห้องนี้
    if (currentUser?.isStaff ?? false) conv.staffId ??= currentUser!.id;
    conv.summaryTopic = topic.trim();
    conv.summaryHelp = help.trim();
    _syncChatReport(conv);
    conv.messages.add(
      Message(
        senderId: 'system',
        isSystem: true,
        text: 'การปรึกษานี้สิ้นสุดแล้ว ขอบคุณที่ใช้บริการ',
      ),
    );
    _db.saveConversation(conv);
    notifyListeners();
  }

  /// จำนวนข้อความจากเจ้าหน้าที่ที่นักศึกษายังไม่อ่าน
  int unreadForStudent(Conversation c) => c.messages
      .skip(c.studentReadCount)
      .where((m) => m.senderId != c.studentId && !m.isSystem)
      .length;

  /// จำนวนข้อความจากนักศึกษาที่เจ้าหน้าที่ยังไม่อ่าน (ตัวเลขบนกระดิ่ง)
  int unreadForStaff(Conversation c) => c.messages
      .skip(c.staffReadCount)
      .where((m) => m.senderId == c.studentId)
      .length;

  /// รวมข้อความที่ยังไม่อ่านทุกห้องของนักศึกษา (badge ที่แท็บ “แชทของฉัน”)
  int get studentUnreadTotal =>
      myConversations().fold(0, (s, c) => s + unreadForStudent(c));

  // ---------------------------------------------------------------- staff

  /// ห้องแชทที่เจ้าหน้าที่ที่ล็อกอินอยู่มองเห็น:
  /// ห้องส่วนรวมทุกห้อง + ห้องส่วนตัวที่ส่งถึงตัวเองเท่านั้น
  /// (ห้องส่วนตัวของเจ้าหน้าที่คนอื่นจะไม่เห็น)
  /// กรองเพิ่มได้ตามหัวข้อ / ส่วนรวม-ส่วนตัว
  /// เรียงลำดับ: เร่งด่วนที่ยังไม่อ่าน -> ห้องอื่นที่ยังไม่อ่าน -> ห้องล่าสุด
  /// [closed]: null = ทั้งหมด, false = ยังคุยอยู่ (หน้าข้อความ), true = จบแล้ว (ประวัติ)
  /// ประวัติ (closed = true) เรียงตามเวลาที่จบ ล่าสุดขึ้นก่อน
  /// ห้องที่นักศึกษายังไม่ได้พิมพ์อะไรเลยจะยังไม่แสดง (กันกดผิด) รวมถึงห้องเร่งด่วน
  List<Conversation> staffConversations({
    String? categoryId,
    bool? specific,
    bool? closed,
  }) {
    final me = currentUser;
    if (me == null) return [];
    final list = conversations.where((c) {
      if (c.isSpecific && c.staffId != me.id) return false;
      if (!hasStudentMessage(c)) return false;
      if (categoryId != null && c.categoryId != categoryId) return false;
      if (specific != null && c.isSpecific != specific) return false;
      if (closed != null && c.closed != closed) return false;
      return true;
    }).toList();
    if (closed == true) {
      return list..sort(
        (a, b) =>
            (b.closedAt ?? DateTime(0)).compareTo(a.closedAt ?? DateTime(0)),
      );
    }
    list.sort((a, b) {
      int rank(Conversation c) {
        if (unreadForStaff(c) == 0) return 2;
        return category(c.categoryId).urgent ? 0 : 1;
      }

      final r = rank(a).compareTo(rank(b));
      if (r != 0) return r;
      return (b.last?.time ?? DateTime(0)).compareTo(
        a.last?.time ?? DateTime(0),
      );
    });
    return list;
  }

  /// รวมข้อความที่ยังไม่อ่าน (เฉพาะแชทที่ยังไม่จบ) ใช้แสดงตัวเลขแจ้งเตือน
  /// นักศึกษาพิมพ์ข้อความในห้องนี้แล้วหรือยัง (ไม่นับข้อความระบบ)
  bool hasStudentMessage(Conversation c) =>
      c.messages.any((m) => m.senderId == c.studentId);

  int staffUnread({String? categoryId, bool? specific}) => staffConversations(
    categoryId: categoryId,
    specific: specific,
    closed: false,
  ).fold(0, (s, c) => s + unreadForStaff(c));

  /// จำนวนครั้งที่เจ้าหน้าที่ที่ล็อกอินอยู่ “ให้คำปรึกษาไปแล้ว” ในหัวข้อนั้น
  /// นับแชทที่จบแล้ว และเจ้าหน้าที่คนนี้เป็นผู้ดูแล (เลือกตรง หรือรับเรื่องห้องส่วนรวม)
  int staffConsultedCount(String categoryId) {
    final me = currentUser;
    if (me == null) return 0;
    return conversations
        .where(
          (c) => c.closed && c.categoryId == categoryId && c.staffId == me.id,
        )
        .length;
  }

  /// เจ้าหน้าที่บันทึก/แก้ไขสรุปของแชทที่จบแล้ว
  void saveSummary(
    Conversation conv,
    String topic,
    String help,
    CaseLevel level,
  ) {
    conv.caseLevel = level;
    conv.summaryTopic = topic.trim();
    conv.summaryHelp = help.trim();
    _db.saveConversation(conv);
    _syncChatReport(conv);
    notifyListeners();
  }

  // ---------------------------------------------------------------- case reports
  // ตารางสรุปเคสของเจ้าหน้าที่ (สำเนาแยกจากแชท แก้ในตารางแล้วไม่กระทบแชท)

  /// สร้าง/อัปเดตแถว online ของแชทที่จบแล้ว
  /// - ยังไม่มีแถว -> สร้างใหม่ (วันที่ = เวลาที่เปิดแชท)
  /// - มีแล้วและยังไม่เคยแก้ในตาราง -> อัปเดตตามสรุปในแชท
  /// - เคยแก้ในตารางแล้ว -> ไม่ทับ (ค่าในตารางเป็นตัวจริง)
  void _syncChatReport(Conversation c) {
    if (!c.closed || c.staffId == null) return;
    final student = user(c.studentId);
    final existing = reports.where((r) => r.conversationId == c.id).firstOrNull;
    if (existing != null && existing.edited) return;
    final r =
        existing ??
        CaseReport(
          id: _nextId('r'),
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
    _db.saveReport(r);
  }

  /// แถวในตารางของเจ้าหน้าที่ที่ล็อกอินอยู่ ตามตัวกรอง (เรียงตามวันที่ เก่า -> ใหม่)
  /// [from]/[to] = ช่วงวันที่ (รวมทั้งวัน), [channel] = online/onsite (null = ทั้งหมด)
  List<CaseReport> myReports({
    DateTime? from,
    DateTime? to,
    ConsultChannel? channel,
  }) {
    final me = currentUser;
    if (me == null) return [];
    final start = from == null
        ? null
        : DateTime(from.year, from.month, from.day);
    final end = to == null ? null : DateTime(to.year, to.month, to.day + 1);
    return reports
        .where(
          (r) =>
              r.staffId == me.id &&
              (channel == null || r.channel == channel) &&
              (start == null || !r.date.isBefore(start)) &&
              (end == null || r.date.isBefore(end)),
        )
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// หานักศึกษาจากรหัสนิสิต (ใช้กรอกชื่อให้อัตโนมัติตอนเพิ่มแถว onsite)
  AppUser? studentByIdNo(String idNo) =>
      users.where((u) => !u.isStaff && u.studentId == idNo.trim()).firstOrNull;

  /// เจ้าหน้าที่เพิ่มแถว onsite เอง (หลังคุยกับนิสิตที่ห้องกิจการนิสิตเสร็จ)
  CaseReport addOnsiteReport({
    required DateTime date,
    required String studentIdNo,
    required String studentName,
    required String categoryId,
    String topic = '',
    String advice = '',
    CaseLevel? level,
  }) {
    final r = CaseReport(
      id: _nextId('r'),
      staffId: currentUser!.id,
      date: date,
      studentIdNo: studentIdNo.trim(),
      studentName: studentName.trim(),
      categoryId: categoryId,
      channel: ConsultChannel.onsite,
      topic: topic.trim(),
      advice: advice.trim(),
      level: level,
      edited: true,
    );
    reports.add(r);
    _db.saveReport(r);
    notifyListeners();
    return r;
  }

  /// แก้แถวในตาราง (เฉพาะ ประเภท / เรื่องที่ปรึกษา / คำปรึกษา / ระดับ) ไม่กระทบแชท
  void updateReport(
    CaseReport r, {
    required String categoryId,
    required String topic,
    required String advice,
    CaseLevel? level,
  }) {
    r
      ..categoryId = categoryId
      ..topic = topic.trim()
      ..advice = advice.trim()
      ..level = level
      ..edited = true;
    _db.saveReport(r);
    notifyListeners();
  }

  /// ลบแถว (เฉพาะแถว onsite ที่เพิ่มเอง แถวจากแชทลบไม่ได้)
  void deleteReport(CaseReport r) {
    if (!r.isManual) return;
    reports.remove(r);
    _db.deleteReport(r.id);
    notifyListeners();
  }

  // ---------------------------------------------------------------- appointments
  // นัดหมายถามตอบที่ห้องกิจการนิสิต: นักศึกษาขอเวลา -> เจ้าหน้าที่ยืนยัน/เสนอเวลาใหม่

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

  /// นัดอื่นที่ยืนยันแล้วในเวลาเดียวกัน (ใช้เตือนเจ้าหน้าที่ตอนตรวจเวลาว่าง)
  List<Appointment> conflictsOf(Appointment a) => appointments
      .where(
        (o) =>
            o != a &&
            o.status == AppointmentStatus.confirmed &&
            o.start == a.start,
      )
      .toList();

  /// นักศึกษาส่งคำขอนัดหมาย -> สถานะ “รอยืนยัน” และไปแจ้งเตือนเจ้าหน้าที่ทุกคน
  /// [staffId] = เจ้าหน้าที่ที่เลือกเอง (null = คนไหนก็ได้ ส่งถึงทุกคน)
  Appointment requestAppointment(
    DateTime start,
    String note, {
    String? staffId,
  }) {
    final a = Appointment(
      id: _nextId('a'),
      studentId: currentUser!.id,
      start: start,
      note: note.trim(),
      requestedStaffId: staffId,
    );
    appointments.add(a);
    _db.saveAppointment(a);
    notifyListeners();
    return a;
  }

  /// นัดหมายของนักศึกษาที่ล็อกอินอยู่ (ใหม่สุด/ใกล้สุดอยู่บน)
  List<Appointment> myAppointments() {
    final me = currentUser;
    if (me == null) return [];
    return appointments.where((a) => a.studentId == me.id).toList()
      ..sort((a, b) => b.start.compareTo(a.start));
  }

  /// จำนวนนัดที่สถานะเปลี่ยนแต่นักศึกษายังไม่ได้ดู (badge แท็บ “นัดหมาย”)
  int get studentAppointmentUpdates =>
      myAppointments().where((a) => !a.seenByStudent).length;

  /// เรียกตอนนักศึกษาเปิดหน้านัดหมาย: ถือว่าเห็นการเปลี่ยนแปลงทั้งหมดแล้ว
  void markAppointmentsSeen() {
    final unseen = myAppointments().where((a) => !a.seenByStudent);
    if (unseen.isEmpty) return;
    for (final a in unseen) {
      a.seenByStudent = true;
      _db.saveAppointment(a);
    }
    notifyListeners();
  }

  /// นักศึกษายกเลิกนัด (เฉพาะที่ยังไม่ถึงเวลา)
  void cancelAppointment(Appointment a) {
    a.status = AppointmentStatus.cancelled;
    _db.saveAppointment(a);
    notifyListeners();
  }

  /// นัดที่เจ้าหน้าที่คนนี้มองเห็น: นัดแบบคนไหนก็ได้ทุกนัด + นัดที่ขอตัวเองโดยตรง
  /// (นัดที่นักศึกษาเลือกเจ้าหน้าที่คนอื่น จะไม่เห็นและไม่ได้แจ้งเตือน)
  bool _visibleToStaff(Appointment a, AppUser me) =>
      a.requestedStaffId == null || a.requestedStaffId == me.id;

  /// รายการนัดสำหรับเจ้าหน้าที่ที่ล็อกอินอยู่ กรองตามสถานะได้
  /// เรียงตามเวลานัด ใกล้สุดขึ้นก่อน
  List<Appointment> staffAppointments({AppointmentStatus? status}) {
    final me = currentUser;
    if (me == null) return [];
    return appointments
        .where(
          (a) =>
              _visibleToStaff(a, me) && (status == null || a.status == status),
        )
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
  }

  /// จำนวนคำขอที่รอเจ้าหน้าที่ยืนยัน (badge แท็บ “นัดหมาย” ฝั่งเจ้าหน้าที่)
  int get pendingAppointmentCount =>
      staffAppointments(status: AppointmentStatus.pending)
          .where((a) => a.start.isAfter(DateTime.now()))
          .length;

  /// เจ้าหน้าที่ตรวจแล้วว่าว่าง กดยืนยันนัด
  void confirmAppointment(Appointment a) {
    a.status = AppointmentStatus.confirmed;
    a.staffId = currentUser!.id;
    a.seenByStudent = false;
    _db.saveAppointment(a);
    notifyListeners();
  }

  /// เจ้าหน้าที่ไม่ว่างเวลานั้น: เสนอเวลาที่ตัวเองว่างแทน แล้วรอนักศึกษาตอบรับ
  void proposeAppointmentTime(
    Appointment a,
    DateTime newStart,
    String message,
  ) {
    a.status = AppointmentStatus.proposed;
    a.proposedStart = newStart;
    a.staffMessage = message.trim();
    a.staffId = currentUser!.id;
    a.seenByStudent = false;
    _db.saveAppointment(a);
    notifyListeners();
  }

  /// นักศึกษาตกลงเวลาที่พี่เสนอ -> นัดยืนยันทันทีตามเวลาใหม่
  void acceptProposedTime(Appointment a) {
    a.start = a.proposedStart!;
    a.proposedStart = null;
    a.status = AppointmentStatus.confirmed;
    _db.saveAppointment(a);
    notifyListeners();
  }

  // ---------------------------------------------------------------- seed data
  // ข้อมูลตั้งต้นตอนเปิดแอปครั้งแรก (และตอนรีเซ็ต): บัญชีเจ้าหน้าที่, นักศึกษาทดลอง (รหัส 1234), แชท/นัดตัวอย่าง

  void _seed() {
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
      // บัญชีเจ้าหน้าที่ (สร้างไว้ให้แล้ว มี 3 คน ไม่ต้องสมัคร)
      // ชื่อเล่นเป็นชื่อชั่วคราว แก้เป็นชื่อจริงได้ที่นี่
      AppUser(
        id: 'st1',
        email: 'piyaromk@nu.ac.th',
        passwordHash: hashPassword('piyaromk@nu.ac.th', 'kaiwanpiyaromk'),
        name: 'เจ้าหน้าที่คนที่ 1',
        nickname: '1',
        avatarColor: const Color(0xFFB9D7E8),
        role: Role.staff,
      ),
      AppUser(
        id: 'st2',
        email: 'khuwnruanep@nu.ac.th',
        passwordHash: hashPassword('khuwnruanep@nu.ac.th', 'kaiwankhuwnruanep'),
        name: 'เจ้าหน้าที่คนที่ 2',
        nickname: '2',
        avatarColor: const Color(0xFFF6C9D0),
        role: Role.staff,
      ),
      AppUser(
        id: 'st3',
        email: 'chonnikank@nu.ac.th',
        passwordHash: hashPassword('chonnikank@nu.ac.th', 'kaiwanchonnikank'),
        name: 'เจ้าหน้าที่คนที่ 3',
        nickname: '3',
        avatarColor: const Color(0xFFCDE8C5),
        role: Role.staff,
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
        id: _nextId('c'),
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
        id: _nextId('a'),
        studentId: 'stu2',
        start: at(nextOfficeDay(0), 10, 0),
        note: 'อยากปรึกษาเรื่องเอกสาร กยศ. แบบเจอตัว',
      ),
      Appointment(
        id: _nextId('a'),
        studentId: 'stu3',
        start: at(nextOfficeDay(1), 13, 30),
        note: 'ปรึกษาเรื่องการปรับตัว',
        requestedStaffId: 'st1', // ขอนัดกับเจ้าหน้าที่คนที่ 1 โดยตรง
      ),
      Appointment(
        id: _nextId('a'),
        studentId: 'stu3',
        start: at(nextOfficeDay(0), 14, 0),
        status: AppointmentStatus.confirmed,
        staffId: 'st3',
      ),
      // นัดของนักศึกษาทดลองที่พี่ไม่ว่าง เลยเสนอเวลาใหม่ (ไว้เดโมฝั่งนักศึกษา)
      Appointment(
          id: _nextId('a'),
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
        id: _nextId('r'),
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

/// store ตัวเดียวที่ทั้งแอปใช้ร่วมกัน (import ไฟล์นี้แล้วเรียก `store` ได้เลย)
/// ต้องเปิดก่อนใช้: `store = await MockStore.open();` (ทำใน main.dart)
late MockStore store;
