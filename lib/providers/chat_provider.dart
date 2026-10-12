// Provider ด้านแชท: เปิดห้อง / ส่งข้อความ-ไฟล์ / อ่านแล้ว / จบการสนทนา / รายการแชทสองฝั่ง
//
// ต้องรู้ว่าใครล็อกอินอยู่ (AuthProvider) และตอนจบแชทต้องสร้างแถวในตารางสรุปเคส (ReportProvider)
// จึงรับทั้งสองตัวผ่าน ChangeNotifierProxyProvider2 ใน main.dart (บทที่ 11)
// ทุกครั้งที่ข้อมูลแชทเปลี่ยนจะ notifyListeners() หน้าจอที่ context.watch<ChatProvider>() วาดใหม่
import 'package:flutter/foundation.dart';

import '../data/app_data.dart';
import '../data/models.dart';
import 'auth_provider.dart';
import 'report_provider.dart';

class ChatProvider extends ChangeNotifier {
  ChatProvider(this.data, this._auth, this.reports);

  final AppData data;
  AuthProvider _auth;
  ReportProvider reports;

  /// ผู้ที่ล็อกอินอยู่ (อ่านจาก AuthProvider)
  AppUser? get _me => _auth.currentUser;

  /// ProxyProvider เรียกเมื่อ AuthProvider/ReportProvider เปลี่ยน (เช่น มีคนล็อกอินใหม่)
  /// รายการแชทขึ้นกับว่าใครล็อกอิน จึงแจ้งหน้าจอให้วาดใหม่ด้วย
  void update(AuthProvider auth, ReportProvider reportProvider) {
    _auth = auth;
    reports = reportProvider;
    notifyListeners();
  }

  /// หาห้องแชทจาก id
  Conversation conversation(String id) => data.conversation(id);

  /// แชททั้งหมดของนักศึกษาที่ล็อกอินอยู่ เรียงจากข้อความล่าสุด (หน้า “แชทของฉัน”)
  List<Conversation> myConversations() {
    // ไม่มีผู้ใช้ (เช่น ระหว่างแอนิเมชันตอน logout) คืนรายการว่างแทนการ crash
    final me = _me;
    if (me == null) return [];
    // ห้องที่กดเข้าไปแต่ยังไม่ได้พิมพ์/ส่งอะไรเลย ไม่ต้องขึ้นในรายการ (กันรายการรก)
    // กดเลือกหัวข้อ/พี่คนเดิมอีกครั้งจะเปิดห้องเดิมให้
    final list = data.conversations
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
    final me = _me!;
    final existing = data.conversations.where(
      (c) =>
          !c.closed &&
          c.studentId == me.id &&
          c.categoryId == categoryId &&
          c.isSpecific == (staffId != null) &&
          (staffId == null || c.staffId == staffId),
    );
    if (existing.isNotEmpty) return existing.first;

    final title = AppData.category(categoryId).title;
    final conv = Conversation(
      id: data.newId('c'),
      studentId: me.id,
      categoryId: categoryId,
      isSpecific: staffId != null,
      staffId: staffId,
      messages: [
        Message(
          senderId: 'system',
          isSystem: true,
          text: staffId != null
              ? 'เลือก "$title" กับ ${data.user(staffId).displayName}'
              : AppData.category(categoryId).urgent
              ? 'ส่งคำขอความช่วยเหลือเร่งด่วนถึงพี่ไข่หวานทุกคนแล้ว พี่จะรีบตอบนะ'
              : 'เลือก "$title" ระบบกำลังหาพี่ไข่หวานที่ว่างให้นะ',
        ),
        // แชทเร่งด่วน: แจ้งเบอร์ฉุกเฉินอัตโนมัติทันทีที่เปิดห้อง
        if (AppData.category(categoryId).urgent)
          Message(
            senderId: 'system',
            isSystem: true,
            isAlert: true,
            text: AppData.emergencyMessage,
          ),
      ],
    );
    conv.studentReadCount = conv.messages.length;
    data.conversations.add(conv);
    data.db.saveConversation(conv);
    notifyListeners();
    return conv;
  }

  // ---------------------------------------------------------------- shared
  // ฟังก์ชันแชทที่ใช้ทั้งสองฝั่ง

  /// ส่งข้อความในนามผู้ที่ล็อกอินอยู่
  void send(Conversation conv, String text) {
    final t = text.trim();
    if (t.isEmpty) return;
    _post(conv, Message(senderId: _me!.id, text: t));
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
      senderId: _me!.id,
      text: '',
      attachment: file,
      attachmentName: name,
      isImage: isImage,
    ),
  );

  /// เพิ่มข้อความของผู้ที่ล็อกอินอยู่ลงห้อง แล้วบันทึก
  void _post(Conversation conv, Message m) {
    final me = _me!;
    conv.messages.add(m);
    if (me.isStaff) {
      conv.staffId ??=
          me.id; // เจ้าหน้าที่คนแรกที่ตอบห้องส่วนรวม = ผู้รับเรื่อง
      conv.staffReadCount = conv.messages.length;
    } else {
      conv.studentReadCount = conv.messages.length;
    }
    data.db.saveConversation(conv);
    notifyListeners();
  }

  /// ทำเครื่องหมายว่าผู้ที่ล็อกอินอยู่อ่านทุกข้อความในห้องนี้แล้ว (เรียกตอนเปิดห้องแชท)
  void markRead(Conversation conv) {
    final me = _me;
    if (me == null) return;
    if (me.isStaff) {
      if (conv.staffReadCount == conv.messages.length) return;
      conv.staffReadCount = conv.messages.length;
    } else {
      if (conv.studentReadCount == conv.messages.length) return;
      conv.studentReadCount = conv.messages.length;
    }
    data.db.saveConversation(conv);
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
    conv.closedById = _me?.id;
    // เจ้าหน้าที่กดจบห้องส่วนรวมที่ยังไม่มีผู้รับเรื่อง = นับเป็นคนให้คำปรึกษาห้องนี้
    if (_me?.isStaff ?? false) conv.staffId ??= _me!.id;
    conv.summaryTopic = topic.trim();
    conv.summaryHelp = help.trim();
    reports.syncChatReport(conv);
    conv.messages.add(
      Message(
        senderId: 'system',
        isSystem: true,
        text: 'การถามตอบสิ้นสุดแล้ว ขอบคุณที่ใช้บริการ',
      ),
    );
    data.db.saveConversation(conv);
    notifyListeners();
  }

  /// จำนวนข้อความจากเจ้าหน้าที่ที่นักศึกษายังไม่อ่าน
  int unreadForStudent(Conversation c) => c.messages
      .skip(c.studentReadCount)
      .where((m) => m.senderId != c.studentId && !m.isSystem)
      .length;

  /// จำนวนข้อความจากนักศึกษาที่เจ้าหน้าที่ยังไม่อ่าน (ตัวเลขแจ้งเตือนบนแท็บ/การ์ด)
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
    final me = _me;
    if (me == null) return [];
    final list = data.conversations.where((c) {
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
        return AppData.category(c.categoryId).urgent ? 0 : 1;
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
    final me = _me;
    if (me == null) return 0;
    return data.conversations
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
    data.db.saveConversation(conv);
    reports.syncChatReport(conv);
    notifyListeners();
  }
}
