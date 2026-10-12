import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:kaiwan_chuaiduai/data/app_data.dart';
import 'package:kaiwan_chuaiduai/data/models.dart';
import 'package:kaiwan_chuaiduai/data/staff_account.dart';
import 'package:kaiwan_chuaiduai/main.dart';
import 'package:kaiwan_chuaiduai/providers/appointment_provider.dart';
import 'package:kaiwan_chuaiduai/providers/auth_provider.dart';
import 'package:kaiwan_chuaiduai/providers/chat_provider.dart';
import 'package:kaiwan_chuaiduai/providers/report_provider.dart';

import 'demo_data.dart';

/// แอปสำหรับทดสอบ: ข้อมูล (SQLite ผ่าน FFI) + Provider จริงทั้ง 4 ตัว ต่อกันแบบเดียวกับ AppProviders
/// เทสต์เรียกเมธอดผ่านตัวนี้ได้เลย (เช่น app.login(...)) ตัวนี้ส่งต่อไปยัง Provider ที่ดูแลเรื่องนั้น
/// และ [widget] ให้หน้าจอใช้ Provider ชุดเดียวกัน ข้อมูลที่เทสต์เปลี่ยนจึงเห็นบนจอทันที
class TestApp {
  TestApp(this.data, {this.demo = false}) {
    auth = AuthProvider(data);
    reportsP = ReportProvider(data, auth);
    appts = AppointmentProvider(data, auth);
    chat = ChatProvider(data, auth, reportsP);
    // ทำแบบเดียวกับ ChangeNotifierProxyProvider: ล็อกอินเปลี่ยน -> แจ้ง Provider ที่พึ่ง Auth
    auth.addListener(() {
      reportsP.update(auth);
      appts.update(auth);
      chat.update(auth, reportsP);
    });
  }

  final AppData data;

  /// ใช้ข้อมูลทดลอง (test/demo_data.dart) หรือไม่ — รีเซ็ตแล้วจะใส่กลับให้ด้วย
  final bool demo;
  late final AuthProvider auth;
  late final ReportProvider reportsP;
  late final AppointmentProvider appts;
  late final ChatProvider chat;

  /// แอปทั้งแอป (หน้าแรก = Login หรือหน้าตามผู้ที่ล็อกอินค้าง) ใช้ Provider ชุดนี้
  Widget widget([Widget child = const KaiwanMaterialApp()]) => MultiProvider(
    providers: [
      Provider<AppData>.value(value: data),
      ChangeNotifierProvider.value(value: auth),
      ChangeNotifierProvider.value(value: reportsP),
      ChangeNotifierProvider.value(value: appts),
      ChangeNotifierProvider.value(value: chat),
    ],
    child: child,
  );

  // ---- ข้อมูล
  List<AppUser> get users => data.users;
  List<Conversation> get conversations => data.conversations;
  List<Appointment> get appointments => data.appointments;
  List<CaseReport> get reports => data.reports;
  Future<void> flush() => data.flush();

  // ---- AuthProvider
  AppUser? get currentUser => auth.currentUser;
  List<AppUser> get staff => auth.staff;
  AppUser user(String id) => auth.user(id);
  String? login(String email, String password) => auth.login(email, password);
  void logout() => auth.logout();
  void resetData() {
    auth.resetData();
    if (demo) seedDemoData(data);
  }

  String? register({
    required String email,
    required String password,
    required String name,
    required String major,
    String studentId = '',
    String nameEn = '',
    String phone = '',
  }) => auth.register(
    email: email,
    password: password,
    name: name,
    major: major,
    studentId: studentId,
    nameEn: nameEn,
    phone: phone,
  );
  String? updateMyProfile({String? phone, String? major}) =>
      auth.updateMyProfile(phone: phone, major: major);

  // ---- ChatProvider
  Conversation conversation(String id) => chat.conversation(id);
  List<Conversation> myConversations() => chat.myConversations();
  Conversation openConversation({
    required String categoryId,
    String? staffId,
  }) => chat.openConversation(categoryId: categoryId, staffId: staffId);
  void send(Conversation c, String text) => chat.send(c, text);
  void sendAttachment(
    Conversation c, {
    required String file,
    required String name,
    required bool isImage,
  }) => chat.sendAttachment(c, file: file, name: name, isImage: isImage);
  void closeConversation(
    Conversation c, {
    String topic = '',
    String help = '',
    CaseLevel? level,
  }) => chat.closeConversation(c, topic: topic, help: help, level: level);
  void saveSummary(Conversation c, String t, String h, CaseLevel l) =>
      chat.saveSummary(c, t, h, l);
  int unreadForStaff(Conversation c) => chat.unreadForStaff(c);
  int staffUnread({String? categoryId, bool? specific}) =>
      chat.staffUnread(categoryId: categoryId, specific: specific);
  int staffConsultedCount(String categoryId) =>
      chat.staffConsultedCount(categoryId);
  List<Conversation> staffConversations({
    String? categoryId,
    bool? specific,
    bool? closed,
  }) => chat.staffConversations(
    categoryId: categoryId,
    specific: specific,
    closed: closed,
  );

  // ---- AppointmentProvider
  Appointment requestAppointment(DateTime s, String note, {String? staffId}) =>
      appts.requestAppointment(s, note, staffId: staffId);
  List<Appointment> myAppointments() => appts.myAppointments();
  int get studentAppointmentUpdates => appts.studentAppointmentUpdates;
  List<Appointment> staffAppointments({AppointmentStatus? status}) =>
      appts.staffAppointments(status: status);
  void proposeAppointmentTime(Appointment a, DateTime t, String m) =>
      appts.proposeAppointmentTime(a, t, m);
  void acceptProposedTime(Appointment a) => appts.acceptProposedTime(a);

  // ---- ReportProvider
  List<CaseReport> myReports({
    DateTime? from,
    DateTime? to,
    ConsultChannel? channel,
  }) => reportsP.myReports(from: from, to: to, channel: channel);
  AppUser? studentByIdNo(String idNo) => reportsP.studentByIdNo(idNo);
  CaseReport addOnsiteReport({
    required DateTime date,
    required String studentIdNo,
    required String studentName,
    required String categoryId,
    String topic = '',
    String advice = '',
    CaseLevel? level,
  }) => reportsP.addOnsiteReport(
    date: date,
    studentIdNo: studentIdNo,
    studentName: studentName,
    categoryId: categoryId,
    topic: topic,
    advice: advice,
    level: level,
  );
  void updateReport(
    CaseReport r, {
    required String categoryId,
    required String topic,
    required String advice,
    CaseLevel? level,
  }) => reportsP.updateReport(
    r,
    categoryId: categoryId,
    topic: topic,
    advice: advice,
    level: level,
  );
  void deleteReport(CaseReport r) => reportsP.deleteReport(r);
}

/// เปิดแอปสำหรับทดสอบ: ใช้ SQLite ผ่าน FFI (รันบนเครื่องคอมได้)
/// ไม่ส่ง [path] = ฐานข้อมูลในหน่วยความจำ (ใหม่ทุกครั้ง)
/// [demoData] = ใส่นักศึกษา/แชท/นัด/เคสตัวอย่าง (เทสต์ส่วนใหญ่ใช้)
Future<TestApp> openTestStore({
  String? path,
  bool demoData = true,
  List<StaffAccount> staff = StaffAccount.samples,
}) async {
  sqfliteFfiInit();
  final data = await AppData.open(
    factory: databaseFactoryFfi,
    path: path ?? inMemoryDatabasePath,
    staffAccounts: staff,
  );
  // ฐานข้อมูลใหม่ (ยังไม่มีนักศึกษาทดลอง) -> ใส่ข้อมูลทดลอง; เปิดไฟล์เดิมซ้ำจะไม่ใส่ซ้ำ
  if (demoData && !data.users.any((u) => u.id == 'stu1')) {
    seedDemoData(data);
  }
  final app = TestApp(data, demo: demoData);
  _opened.add(app);
  return app;
}

final _opened = <TestApp>[];

/// รอให้ทุกแอปทดสอบที่เปิดไว้เขียนฐานข้อมูลเสร็จแล้วปิด
/// (เรียกก่อนลบโฟลเดอร์ทดสอบ ไม่งั้นคำสั่งเขียนที่ค้างอยู่จะสร้างไฟล์ขึ้นมาใหม่จนลบโฟลเดอร์ไม่ได้)
Future<void> closeTestApps() async {
  for (final a in _opened) {
    try {
      await a.data.db.close();
    } catch (_) {
      // ปิดไปแล้ว
    }
  }
  _opened.clear();
}

/// เทสต์ใช้บัญชีเจ้าหน้าที่ตัวอย่าง (StaffAccount.samples) รันได้ทุกเครื่องโดยไม่ต้องมีไฟล์บัญชีจริง
const staffAccounts = StaffAccount.samples;
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
  AppData.testStudentEmail: AppData.testStudentPassword,
  for (final a in staffAccounts) a.email: a.password,
};
