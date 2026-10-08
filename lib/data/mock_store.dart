import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'models.dart';

/// In-memory mock backend. Everything lives for the app session only, but
/// the student and staff sides share it, so a message sent as a student shows
/// up (with a notification bell) when you log in as staff.
class MockStore extends ChangeNotifier {
  MockStore() {
    _seed();
  }

  final _rand = Random(7);
  int _idSeq = 100;
  String _nextId(String p) => '$p${_idSeq++}';

  /// When true, staff auto-reply to students so the prototype feels alive.
  bool autoReply = true;

  void setAutoReply(bool v) {
    autoReply = v;
    notifyListeners();
  }

  AppUser? currentUser;
  final List<AppUser> users = [];
  final List<Conversation> conversations = [];
  final List<Report> reports = [];
  final Set<String> typing = {};

  static const categories = <ConsultCategory>[
    ConsultCategory(
      id: 'loan',
      title: 'กยศ',
      subtitle: 'กองทุนเงินให้กู้ยืมเพื่อการศึกษา',
      icon: Icons.account_balance_rounded,
      subtopics: ['ปรึกษาเกี่ยวการส่งเอกสาร', 'สอบถามการเซ็นเอกสาร', 'อื่นๆ'],
    ),
    ConsultCategory(
      id: 'scholarship',
      title: 'ทุนการศึกษา',
      subtitle: 'ทุนภายใน / ทุนภายนอก',
      icon: Icons.workspace_premium_rounded,
      subtopics: [
        'สอบถามเรื่องทุนการศึกษา',
        'สอบถามส่งเอกสารทุนการศึกษา',
        'อื่นๆ',
      ],
    ),
    ConsultCategory(
      id: 'study',
      title: 'การเรียน',
      subtitle: 'ดรอปเรียน / ยื่นจบการศึกษา',
      icon: Icons.menu_book_rounded,
      subtopics: ['การดรอปเรียน', 'การยื่นเอกสารจบปีการศึกษา', 'อื่นๆ'],
    ),
    ConsultCategory(
      id: 'mental',
      title: 'สุขภาพจิต',
      subtitle: 'พูดคุยได้ทุกเรื่อง เป็นความลับ',
      icon: Icons.favorite_rounded,
      subtopics: [
        'ปัญหาเกี่ยวกับการอยู่ในสังคมมหาลัย',
        'ปัญหาการปรับตัวเข้ากับสังคมมหาลัย',
        'อื่นๆ',
      ],
    ),
  ];

  static ConsultCategory category(String id) =>
      categories.firstWhere((c) => c.id == id);

  static const majors = [
    'วิศวกรรมคอมพิวเตอร์',
    'วิทยาการคอมพิวเตอร์',
    'บริหารธุรกิจ',
    'นิเทศศาสตร์',
    'พยาบาลศาสตร์',
    'ศึกษาศาสตร์',
    'นิติศาสตร์',
  ];

  static const reportReasons = [
    'ใช้ถ้อยคำไม่สุภาพ / คุกคาม',
    'ผู้ใช้อยู่ในภาวะเสี่ยง ต้องการความช่วยเหลือด่วน',
    'สแปม / ก่อกวน',
    'ข้อมูลเท็จ / แอบอ้าง',
    'อื่นๆ',
  ];

  List<AppUser> get staff => users.where((u) => u.isStaff).toList();
  AppUser user(String id) => users.firstWhere((u) => u.id == id);
  Conversation conversation(String id) =>
      conversations.firstWhere((c) => c.id == id);

  // ---------------------------------------------------------------- auth

  String? login(String email, String password) {
    final u = users.where(
      (u) => u.email.toLowerCase() == email.trim().toLowerCase(),
    );
    if (u.isEmpty) return 'ไม่พบบัญชีผู้ใช้นี้';
    if (u.first.password != password) return 'รหัสผ่านไม่ถูกต้อง';
    currentUser = u.first;
    notifyListeners();
    return null;
  }

  String? register({
    required String email,
    required String password,
    required String name,
    required String major,
  }) {
    if (users.any((u) => u.email.toLowerCase() == email.trim().toLowerCase())) {
      return 'อีเมลนี้ถูกใช้แล้ว';
    }
    final u = AppUser(
      id: _nextId('u'),
      email: email.trim(),
      password: password,
      name: name.trim(),
      major: major,
      role: Role.student,
    );
    users.add(u);
    currentUser = u;
    notifyListeners();
    return null;
  }

  void logout() {
    currentUser = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------- student

  List<Conversation> myConversations() {
    final me = currentUser!;
    final list = conversations.where((c) => c.studentId == me.id).toList();
    list.sort(
      (a, b) =>
          (b.last?.time ?? DateTime(0)).compareTo(a.last?.time ?? DateTime(0)),
    );
    return list;
  }

  /// Opens (or reuses) the chat for this topic, as described in the UX doc:
  /// choosing a topic + consult mode lands the user straight in a chat.
  Conversation openConversation({
    required String categoryId,
    required String subtopic,
    String? staffId,
  }) {
    final me = currentUser!;
    final existing = conversations.where(
      (c) =>
          !c.closed &&
          c.studentId == me.id &&
          c.categoryId == categoryId &&
          c.subtopic == subtopic &&
          c.isSpecific == (staffId != null) &&
          (staffId == null || c.staffId == staffId),
    );
    if (existing.isNotEmpty) return existing.first;

    final conv = Conversation(
      id: _nextId('c'),
      studentId: me.id,
      categoryId: categoryId,
      subtopic: subtopic,
      isSpecific: staffId != null,
      staffId: staffId,
      messages: [
        Message(
          senderId: 'system',
          isSystem: true,
          text: staffId != null
              ? 'เริ่มการปรึกษาเรื่อง "$subtopic" กับ ${user(staffId).displayName}'
              : 'เริ่มการปรึกษาเรื่อง "$subtopic" ระบบกำลังหาพี่ไข่หวานที่ว่างให้นะ',
        ),
      ],
    );
    conv.studentReadCount = conv.messages.length;
    conversations.add(conv);
    notifyListeners();
    _scheduleReply(conv, greeting: true);
    return conv;
  }

  // ---------------------------------------------------------------- shared

  void send(Conversation conv, String text) {
    final me = currentUser!;
    final t = text.trim();
    if (t.isEmpty) return;
    conv.messages.add(Message(senderId: me.id, text: t));
    if (me.isStaff) {
      conv.staffId ??= me.id; // staff picks up an "any staff" chat
      conv.staffReadCount = conv.messages.length;
    } else {
      conv.studentReadCount = conv.messages.length;
      _scheduleReply(conv);
    }
    notifyListeners();
  }

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
    notifyListeners();
  }

  void closeConversation(Conversation conv) {
    conv.closed = true;
    conv.messages.add(
      Message(
        senderId: 'system',
        isSystem: true,
        text: 'การปรึกษานี้สิ้นสุดแล้ว ขอบคุณที่ใช้บริการ',
      ),
    );
    notifyListeners();
  }

  int unreadForStudent(Conversation c) => c.messages
      .skip(c.studentReadCount)
      .where((m) => m.senderId != c.studentId && !m.isSystem)
      .length;

  int unreadForStaff(Conversation c) => c.messages
      .skip(c.staffReadCount)
      .where((m) => m.senderId == c.studentId)
      .length;

  int get studentUnreadTotal =>
      myConversations().fold(0, (s, c) => s + unreadForStudent(c));

  // ---------------------------------------------------------------- staff

  /// Conversations a staff member can see: every "any staff" chat (ส่วนรวม)
  /// plus chats addressed to them specifically (ส่วนตัว).
  List<Conversation> staffConversations({
    String? categoryId,
    String? subtopic,
    bool? specific,
  }) {
    final me = currentUser!;
    final list = conversations.where((c) {
      if (c.isSpecific && c.staffId != me.id) return false;
      if (categoryId != null && c.categoryId != categoryId) return false;
      if (subtopic != null && c.subtopic != subtopic) return false;
      if (specific != null && c.isSpecific != specific) return false;
      return true;
    }).toList();
    list.sort((a, b) {
      final ua = unreadForStaff(a), ub = unreadForStaff(b);
      if ((ua > 0) != (ub > 0)) return ub > 0 ? 1 : -1;
      return (b.last?.time ?? DateTime(0)).compareTo(
        a.last?.time ?? DateTime(0),
      );
    });
    return list;
  }

  int staffUnread({String? categoryId, String? subtopic, bool? specific}) =>
      staffConversations(
        categoryId: categoryId,
        subtopic: subtopic,
        specific: specific,
      ).fold(0, (s, c) => s + unreadForStaff(c));

  void report(Conversation conv, String reason, String detail) {
    reports.insert(
      0,
      Report(
        conversationId: conv.id,
        reporterId: currentUser!.id,
        reason: reason,
        detail: detail,
      ),
    );
    conv.messages.add(
      Message(
        senderId: 'system',
        isSystem: true,
        text: 'เจ้าหน้าที่ได้รายงานการสนทนานี้ไปยังระบบรายงานแล้ว',
      ),
    );
    conv.staffReadCount = conv.messages.length;
    notifyListeners();
  }

  // ---------------------------------------------------------------- mock replies

  void _scheduleReply(Conversation conv, {bool greeting = false}) {
    if (!autoReply) return;
    Future.delayed(const Duration(milliseconds: 700), () {
      typing.add(conv.id);
      notifyListeners();
    });
    Future.delayed(Duration(milliseconds: 1800 + _rand.nextInt(900)), () {
      typing.remove(conv.id);
      if (conv.closed) {
        notifyListeners();
        return;
      }
      conv.staffId ??= staff[_rand.nextInt(staff.length)].id;
      final s = user(conv.staffId!);
      final text = greeting ? _greeting(conv, s) : _cannedReply(conv);
      conv.messages.add(Message(senderId: s.id, text: text));
      notifyListeners();
    });
  }

  String _greeting(Conversation conv, AppUser s) =>
      'สวัสดีค่ะ ${s.displayName} ยินดีให้คำปรึกษาเรื่อง "${conv.subtopic}" นะคะ 😊 เล่าให้พี่ฟังได้เลยค่ะ';

  String _cannedReply(Conversation conv) {
    final pool = switch (conv.categoryId) {
      'loan' => [
        'เอกสาร กยศ. ต้องมีสำเนาบัตรประชาชนผู้กู้และผู้แทนโดยชอบธรรม พร้อมเซ็นสำเนาถูกต้องนะคะ',
        'สามารถส่งเอกสารได้ที่ห้องกองพัฒนานักศึกษา ชั้น 1 ในวันและเวลาราชการค่ะ',
        'ถ้าเซ็นเอกสารแทนไม่ได้ ต้องมีหนังสือมอบอำนาจแนบมาด้วยนะคะ',
      ],
      'scholarship' => [
        'ตอนนี้มีทุนเรียนดีและทุนขาดแคลนทุนทรัพย์เปิดรับอยู่ค่ะ ปิดรับปลายเดือนนี้นะคะ',
        'เอกสารทุนต้องมีใบรับรองผลการเรียน และหนังสือรับรองรายได้ผู้ปกครองค่ะ',
        'ส่งเอกสารทุนได้ทางระบบออนไลน์ หรือยื่นที่ห้องทุนการศึกษาได้เลยค่ะ',
      ],
      'study' => [
        'การดรอปรายวิชาทำได้ภายในสัปดาห์ที่ 12 ของภาคเรียน ผ่านระบบทะเบียนนะคะ',
        'ยื่นเอกสารขอจบต้องตรวจสอบหน่วยกิตให้ครบก่อน แล้วยื่นคำร้องที่งานทะเบียนค่ะ',
        'ถ้าไม่แน่ใจ ลองปรึกษาอาจารย์ที่ปรึกษาเพื่อเซ็นรับรองด้วยนะคะ',
      ],
      _ => [
        'พี่เข้าใจความรู้สึกนะคะ ขอบคุณที่กล้าเล่าให้พี่ฟังค่ะ 💛',
        'ช่วงปรับตัวแรกๆ เป็นเรื่องปกติที่จะรู้สึกแบบนี้ เราค่อยๆ ไปด้วยกันนะคะ',
        'ถ้าอยากคุยแบบเจอตัว พี่นัดได้ที่ห้องให้คำปรึกษา ชั้น 2 ค่ะ',
      ],
    };
    return pool[_rand.nextInt(pool.length)];
  }

  // ---------------------------------------------------------------- seed data

  void _seed() {
    users.addAll([
      AppUser(
        id: 'stu1',
        email: 'student@kaiwan.ac.th',
        password: '1234',
        name: 'สมใจ ใจดี',
        major: 'วิศวกรรมคอมพิวเตอร์',
        role: Role.student,
      ),
      AppUser(
        id: 'stu2',
        email: 'stu2@kaiwan.ac.th',
        password: '1234',
        name: 'กิตติ ขยันเรียน',
        major: 'บริหารธุรกิจ',
        role: Role.student,
      ),
      AppUser(
        id: 'stu3',
        email: 'stu3@kaiwan.ac.th',
        password: '1234',
        name: 'มณีรัตน์ แสงทอง',
        major: 'นิเทศศาสตร์',
        role: Role.student,
      ),
      AppUser(
        id: 'st1',
        email: 'staff1@kaiwan.ac.th',
        password: '1234',
        name: 'อรอุมา ศรีสุข',
        nickname: 'แอน',
        specialty: 'กยศ / ทุนการศึกษา',
        avatarColor: const Color(0xFFB9D7E8),
        role: Role.staff,
      ),
      AppUser(
        id: 'st2',
        email: 'staff2@kaiwan.ac.th',
        password: '1234',
        name: 'ปิยะพร ทองดี',
        nickname: 'ฝ้าย',
        specialty: 'การเรียน / งานทะเบียน',
        avatarColor: const Color(0xFFF6C9D0),
        role: Role.staff,
      ),
      AppUser(
        id: 'st3',
        email: 'staff3@kaiwan.ac.th',
        password: '1234',
        name: 'ชนิดา วงศ์ใหญ่',
        nickname: 'เมย์',
        specialty: 'สุขภาพจิต / นักจิตวิทยา',
        avatarColor: const Color(0xFFCDE8C5),
        role: Role.staff,
      ),
      AppUser(
        id: 'st4',
        email: 'staff4@kaiwan.ac.th',
        password: '1234',
        name: 'นภัสสร มีสุข',
        nickname: 'บีม',
        specialty: 'ทุนการศึกษา / กิจการนักศึกษา',
        avatarColor: const Color(0xFFE5D4F2),
        role: Role.staff,
        online: false,
      ),
    ]);

    final now = DateTime.now();
    Conversation seed(
      String student,
      String cat,
      String sub,
      String? staffId,
      List<(String, String, int)> msgs, {
      int staffRead = 0,
    }) {
      final c = Conversation(
        id: _nextId('c'),
        studentId: student,
        categoryId: cat,
        subtopic: sub,
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

    // Unread chats waiting for staff so the bells light up.
    seed('stu2', 'loan', 'ปรึกษาเกี่ยวการส่งเอกสาร', null, [
      ('stu2', 'สวัสดีครับ ส่งเอกสาร กยศ. รอบนี้ต้องใช้อะไรบ้างครับ', 42),
      ('stu2', 'ผมต้องส่งภายในวันไหนครับ', 41),
    ]);
    seed('stu3', 'loan', 'สอบถามการเซ็นเอกสาร', 'st1', [
      ('stu3', 'พี่แอนคะ ผู้ปกครองอยู่ต่างจังหวัด เซ็นเอกสารแทนได้ไหมคะ', 30),
    ]);
    seed('stu2', 'scholarship', 'สอบถามเรื่องทุนการศึกษา', null, [
      ('stu2', 'ทุนเรียนดีปีนี้เปิดรับเมื่อไหร่ครับ', 18),
    ]);
    seed('stu3', 'study', 'การดรอปเรียน', 'st2', [
      ('stu3', 'พี่ฝ้ายคะ ดรอปวิชาตอนนี้ยังทันไหมคะ', 12),
      ('st2', 'ทันค่ะ ภายในสัปดาห์ที่ 12 นะคะ', 10),
      ('stu3', 'ต้องให้อาจารย์ที่ปรึกษาเซ็นด้วยไหมคะ', 6),
    ], staffRead: 2);
    seed('stu2', 'mental', 'ปัญหาการปรับตัวเข้ากับสังคมมหาลัย', null, [
      ('stu2', 'ช่วงนี้รู้สึกไม่มีเพื่อนเลยครับ ไม่รู้จะเริ่มยังไง', 5),
    ]);
    seed('stu3', 'mental', 'ปัญหาเกี่ยวกับการอยู่ในสังคมมหาลัย', 'st3', [
      ('stu3', 'พี่เมย์คะ หนูเครียดเรื่องงานกลุ่มมากเลยค่ะ', 3),
    ]);

    // A past chat for the demo student so "แชทของฉัน" isn't empty.
    seed('stu1', 'study', 'การยื่นเอกสารจบปีการศึกษา', 'st2', [
      ('stu1', 'ยื่นขอจบต้องทำยังไงบ้างคะ', 1440),
      ('st2', 'ตรวจหน่วยกิตให้ครบ แล้วยื่นคำร้องที่งานทะเบียนได้เลยค่ะ', 1430),
    ], staffRead: 2);
  }
}

final store = MockStore();
