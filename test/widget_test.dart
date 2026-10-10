import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kaiwan_chuaiduai/data/mock_store.dart';
import 'package:kaiwan_chuaiduai/data/models.dart';
import 'package:kaiwan_chuaiduai/main.dart';
import 'package:kaiwan_chuaiduai/screens/auth_screens.dart';
import 'package:kaiwan_chuaiduai/widgets/common.dart';

import 'test_store.dart';

/// ล็อกอินด้วยบัญชีทดลองผ่านหน้า Login (เปิดกล่อง “บัญชีทดลอง” แล้วแตะชิป)
Future<void> loginWithDemo(WidgetTester tester, String chip) async {
  await tester.pumpWidget(const KaiwanApp());
  final demo = find.text('บัญชีทดลอง');
  await tester.ensureVisible(demo);
  await tester.tap(demo);
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text(chip));
  await tester.tap(find.text(chip));
  final login = find.text('login');
  await tester.ensureVisible(login);
  await tester.tap(login);
  await tester.pumpAndSettle(const Duration(seconds: 1));
}

/// ล็อกอินเป็นนักศึกษาทดลองผ่านหน้า Login
Future<void> loginAsStudent(WidgetTester tester) =>
    loginWithDemo(tester, 'นักศึกษา');

void main() {
  // ฐานข้อมูลทดสอบ (SQLite ในหน่วยความจำ) ใช้ร่วมกันทุก test ในไฟล์นี้
  setUpAll(() async => store = await openTestStore());

  setUp(() {
    store.logout();
  });

  // ทดสอบ flow หลัก: นักศึกษาส่งข้อความแบบเจาะจงถึงเจ้าหน้าที่คนที่ 1
  // แล้วตรวจว่าเจ้าหน้าที่คนที่ 1เห็นข้อความที่ยังไม่อ่าน แต่เจ้าหน้าที่คนอื่นมองไม่เห็นห้องนี้
  testWidgets('general topic: specific staff only', (tester) async {
    await loginAsStudent(tester);
    expect(find.text('ถาม/ตอบเรื่องทั่วไป'), findsOneWidget);
    expect(find.text('ขอความช่วยเหลือแบบเร่งด่วน'), findsOneWidget);

    // ทั่วไป -> ผ่านแอป -> เลือกเจาะจง -> พี่ไข่หวาน 1 -> แชท
    await tester.tap(find.text('ถาม/ตอบเรื่องทั่วไป'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ถามตอบกับพี่ไข่หวาน\nผ่านแอป'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.text('ปรึกษากับพี่ไข่หวาน\n(เจ้าหน้าที่แบบเลือกเฉพาะเจาะจง)'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('พี่ไข่หวาน 1'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'ทดสอบข้อความ');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('ทดสอบข้อความ'), findsOneWidget);

    bool hasMyMessage(Conversation c) =>
        c.studentId == 'stu1' &&
        c.messages.any((m) => m.text == 'ทดสอบข้อความ');

    store.logout();
    store.login('piyaromk@nu.ac.th', 'kaiwanpiyaromk');
    final convs = store.staffConversations(
      categoryId: 'general',
      specific: true,
    );
    expect(
      convs.any((c) => hasMyMessage(c) && store.unreadForStaff(c) == 1),
      isTrue,
    );

    store.logout();
    store.login('khuwnruanep@nu.ac.th', 'kaiwankhuwnruanep');
    expect(store.staffConversations().any(hasMyMessage), isFalse);
    store.logout();
    await tester.pumpAndSettle(const Duration(seconds: 1));
  });

  // เร่งด่วน: กดแล้วเข้าแชททันที และเจ้าหน้าที่ทุกคนเห็น โดยขึ้นเป็นอันดับแรก
  testWidgets('urgent topic: straight to chat, every staff sees it', (
    tester,
  ) async {
    await loginAsStudent(tester);
    await tester.tap(find.text('ขอความช่วยเหลือแบบเร่งด่วน'));
    await tester.pumpAndSettle();
    // ข้อความอัตโนมัติแจ้งเบอร์ฉุกเฉินขึ้นทันที
    expect(find.text(MockStore.emergencyMessage), findsOneWidget);
    // แชทส่วนรวม: นักศึกษาเห็นชื่อ “แชทรวมเจ้าหน้าที่” + รูปแมวไข่หวาน
    expect(find.text('แชทรวมเจ้าหน้าที่'), findsOneWidget);
    expect(find.byType(CatAvatar), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'ต้องการความช่วยเหลือด่วน');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump(const Duration(seconds: 1));

    for (final (email, pw) in [
      ('piyaromk@nu.ac.th', 'kaiwanpiyaromk'),
      ('chonnikank@nu.ac.th', 'kaiwanchonnikank'),
    ]) {
      store.logout();
      store.login(email, pw);
      final top = store.staffConversations().first;
      expect(top.categoryId, 'urgent');
      expect(store.unreadForStaff(top), greaterThan(0));
      expect(
        store
            .staffConversations(categoryId: 'urgent')
            .any((c) => c.studentId == 'stu1'),
        isTrue,
      );
    }
    store.logout();
    await tester.pumpAndSettle(const Duration(seconds: 1));
  });

  // นัดหมายห้องกิจการนิสิต: นักศึกษาเลือกเวลาจาก dropdown -> รอยืนยัน
  // -> เจ้าหน้าที่ไม่ว่าง เสนอเวลาใหม่ -> นักศึกษาได้ badge และกดตกลงเวลาใหม่
  testWidgets('office appointment: request, staff proposes, student accepts', (
    tester,
  ) async {
    // หน้าจองยาว: ขยายจอทดสอบให้เห็นทั้งหน้า
    tester.view.physicalSize = const Size(800, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await loginAsStudent(tester);
    await tester.tap(find.text('ถาม/ตอบเรื่องทั่วไป'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ถามตอบกับพี่ไข่หวาน\nที่ห้องกิจการนิสิต'));
    await tester.pumpAndSettle();
    // ที่ห้อง -> คนไหนก็ได้ (แจ้งเตือนทุกคน) -> หน้าจอง
    await tester.tap(find.text('ปรึกษากับพี่ไข่หวาน\n(เจ้าหน้าที่คนไหนก็ได้)'));
    await tester.pumpAndSettle();
    expect(find.byType(CalendarDatePicker), findsOneWidget);
    expect(find.text('นัดกับพี่ไข่หวานคนไหนก็ได้'), findsOneWidget);

    // เปิด dropdown แล้วเลือกเวลาแรกในรายการ
    await tester.tap(find.text('เลือกเวลา'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining(' น.').last);
    await tester.pumpAndSettle();
    final submit = find.textContaining('ส่งคำขอนัด');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    // นัดที่เพิ่งสร้าง = นัดที่รอยืนยันของนักศึกษา (มีนัดตัวอย่างอยู่แล้ว 1 นัดที่สถานะอื่น)
    final mine = store.myAppointments().singleWhere(
      (a) => a.status == AppointmentStatus.pending,
    );
    expect(find.text('รอยืนยัน'), findsWidgets);

    // เจ้าหน้าที่เห็นคำขอ แต่ไม่ว่าง -> เสนอเวลาใหม่
    store.logout();
    store.login('piyaromk@nu.ac.th', 'kaiwanpiyaromk');
    expect(
      store.staffAppointments(status: AppointmentStatus.pending).contains(mine),
      isTrue,
    );
    final newTime = mine.start.add(const Duration(days: 7));
    store.proposeAppointmentTime(mine, newTime, 'ช่วงนั้นพี่ไม่อยู่นะ');

    // นักศึกษาเห็นแจ้งเตือน แล้วตกลงเวลาใหม่ -> ยืนยันตามเวลาใหม่
    store.logout();
    store.login('somjaij67@nu.ac.th', '1234');
    expect(mine.status, AppointmentStatus.proposed);
    expect(store.studentAppointmentUpdates, greaterThan(0));
    store.acceptProposedTime(mine);
    expect(mine.status, AppointmentStatus.confirmed);
    expect(mine.start, newTime);
    expect(mine.staffId, 'st1');
    store.logout();
    await tester.pumpAndSettle(const Duration(seconds: 1));
  });

  // นัดแบบเลือกพี่เอง: แจ้งเตือนเฉพาะพี่คนนั้น เจ้าหน้าที่คนอื่นไม่เห็นคำขอ
  testWidgets('office appointment with a chosen staff reaches only them', (
    tester,
  ) async {
    await loginAsStudent(tester);
    await tester.tap(find.text('ถาม/ตอบเรื่องทั่วไป'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ถามตอบกับพี่ไข่หวาน\nที่ห้องกิจการนิสิต'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.text('ปรึกษากับพี่ไข่หวาน\n(เจ้าหน้าที่แบบเลือกเฉพาะเจาะจง)'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('พี่ไข่หวาน 2'));
    await tester.pumpAndSettle();
    expect(find.text('นัดกับ พี่ไข่หวาน 2'), findsOneWidget);

    final start = MockStore.slotsOf(firstDayForTest()).last;
    final a = store.requestAppointment(start, '', staffId: 'st2');

    store.logout();
    store.login('khuwnruanep@nu.ac.th', 'kaiwankhuwnruanep');
    expect(store.staffAppointments().contains(a), isTrue);
    store.logout();
    store.login('piyaromk@nu.ac.th', 'kaiwanpiyaromk');
    expect(store.staffAppointments().contains(a), isFalse);
    store.logout();
    await tester.pumpAndSettle(const Duration(seconds: 1));
  });
  // เจ้าหน้าที่จบการปรึกษา: ต้องกรอกสรุป 2 ช่องก่อน แล้วแชทย้ายไปอยู่ในประวัติ
  testWidgets('staff closes chat with summary -> moves to history', (
    tester,
  ) async {
    await loginWithDemo(tester, 'จนท. 1');

    // แท็บข้อความ -> เปิดแชทแรก
    await tester.tap(find.text('ข้อความ').last);
    await tester.pumpAndSettle();
    final conv = store.staffConversations(closed: false).first;
    final doneBefore = store.staffConsultedCount(conv.categoryId);
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();

    // เมนู … -> จบการปรึกษา -> กดบันทึกทั้งที่ยังไม่กรอก = ไม่ผ่าน
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('จบการปรึกษา'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('บันทึกและจบการปรึกษา'));
    await tester.pumpAndSettle();
    expect(find.text('กรุณากรอกช่องนี้'), findsNWidgets(2));
    expect(find.text('กรุณาเลือกระดับเคส'), findsOneWidget);
    expect(conv.closed, isFalse);

    await tester.enterText(find.byType(TextFormField).at(0), 'ถามเรื่องเอกสาร');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'แจ้งรายการเอกสาร',
    );
    // เลือกระดับเคส “กลาง 🟡”
    await tester.tap(find.text('เลือกระดับเคส'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('กลาง 🟡').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('บันทึกและจบการปรึกษา'));
    await tester.pumpAndSettle();

    expect(conv.closed, isTrue);
    expect(conv.summaryTopic, 'ถามเรื่องเอกสาร');
    expect(conv.summaryHelp, 'แจ้งรายการเอกสาร');
    expect(conv.caseLevel, CaseLevel.medium);
    // ตัวเลข “ให้คำปรึกษาแล้ว” บนหน้าแรกเพิ่มขึ้น 1
    expect(store.staffConsultedCount(conv.categoryId), doneBefore + 1);
    expect(store.staffConversations(closed: true).contains(conv), isTrue);
    expect(store.staffConversations(closed: false).contains(conv), isFalse);
    store.logout();
    await tester.pumpAndSettle(const Duration(seconds: 1));
  });
  // สมัครสมาชิก: กรอกครบ -> กด sign in -> License Agreement
  // กด Reject = ยังไม่สมัคร, กด Accept Terms = สมัครและล็อกอินเป็นนักศึกษา
  testWidgets('sign up requires accepting the license agreement', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const KaiwanApp());
    await tester.tap(find.textContaining('สมัครสมาชิก', findRichText: true));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'MaiT67@nu.ac.th');
    await tester.enterText(fields.at(1), 'abcd');
    await tester.enterText(fields.at(2), '67319999');
    await tester.enterText(fields.at(3), 'ใหม่ ทดสอบ');
    await tester.enterText(fields.at(4), 'Mai Thodsob');
    await tester.enterText(fields.at(5), '0899999999');
    // เลือกภาควิชาก่อน แล้วเลือกสาขาในภาควิชานั้น
    await tester.tap(find.text('ภาควิชา'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ภาควิชาเคมี').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('สาขา'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('สาขาวิชาเคมี').last);
    await tester.pumpAndSettle();

    final signIn = find.widgetWithText(FilledButton, 'sign in');
    await tester.ensureVisible(signIn);
    await tester.tap(signIn);
    await tester.pumpAndSettle();
    expect(find.text('License Agreement'), findsOneWidget);

    await tester.tap(find.text('Reject'));
    await tester.pumpAndSettle();
    expect(store.currentUser, isNull);

    await tester.tap(signIn);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Accept Terms'));
    await tester.pumpAndSettle();
    final me = store.currentUser!;
    expect(me.email, 'mait67@nu.ac.th');
    expect(me.studentId, '67319999');
    expect(me.nameEn, 'Mai Thodsob');
    expect(me.phone, '0899999999');
    expect(me.major, 'สาขาวิชาเคมี');
    expect(MockStore.departmentOf(me.major), 'ภาควิชาเคมี');
    store.logout();
    await tester.pumpAndSettle(const Duration(seconds: 1));
  });
  // หน้าต่าง License Agreement บนจอขนาด iPhone (แคบ) ต้องแสดงได้ไม่ล้นจอ
  testWidgets('license dialog fits on a phone screen', (tester) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => showDialog<bool>(
                  context: context,
                  builder: (_) => const LicenseAgreementDialog(),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Terms and Conditions'), findsOneWidget);
    expect(find.text('Accept Terms'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  // นักศึกษายกเลิกนัดที่พี่เสนอเวลาใหม่ (ยังไม่ยืนยัน) ได้ โดยต้องกดยืนยันก่อน
  testWidgets('student can cancel an unconfirmed (proposed) appointment', (
    tester,
  ) async {
    await loginAsStudent(tester);
    final proposed = store.myAppointments().firstWhere(
      (a) => a.status == AppointmentStatus.proposed,
    );
    await tester.tap(find.text('นัดหมาย').last);
    await tester.pumpAndSettle();

    final cancel = find.widgetWithText(TextButton, 'ยกเลิกนัด');
    expect(cancel, findsOneWidget);
    await tester.tap(cancel);
    await tester.pumpAndSettle();
    // กด “ไม่ยกเลิก” = นัดยังอยู่
    await tester.tap(find.text('ไม่ยกเลิก'));
    await tester.pumpAndSettle();
    expect(proposed.status, AppointmentStatus.proposed);

    await tester.tap(cancel);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'ยกเลิกนัด').last);
    await tester.pumpAndSettle();
    expect(proposed.status, AppointmentStatus.cancelled);
    expect(find.text('ยกเลิกแล้ว'), findsOneWidget);
    store.logout();
    await tester.pumpAndSettle(const Duration(seconds: 1));
  });
  // เจ้าหน้าที่กดดูโปรไฟล์ผู้มาปรึกษาจากหัวแชทได้ (รหัสนิสิต/ชื่อ/เบอร์/สาขา)
  testWidgets('staff can view the student profile from the chat', (
    tester,
  ) async {
    await loginWithDemo(tester, 'จนท. 1');
    await tester.tap(find.text('ข้อความ').last);
    await tester.pumpAndSettle();
    final conv = store.staffConversations(closed: false).first;
    final student = store.user(conv.studentId);
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('ดูโปรไฟล์ผู้มาปรึกษา'));
    await tester.pumpAndSettle();
    expect(find.text('โปรไฟล์ผู้มาปรึกษา'), findsOneWidget);
    expect(find.text(student.studentId), findsOneWidget);
    expect(find.text('เบอร์โทรศัพท์'), findsOneWidget);
    expect(find.text(student.phone), findsOneWidget);
    expect(find.text(student.major), findsOneWidget);
    store.logout();
    await tester.pumpAndSettle(const Duration(seconds: 1));
  });
  // ตารางสรุปเคส: เปิดจากหน้าภาพรวม -> กรอง onsite -> เพิ่มเคส onsite -> แก้แถว
  testWidgets('staff case report table: filter, add onsite, edit', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await loginWithDemo(tester, 'จนท. 1');
    final card = find.text('ตารางสรุปเคส');
    await tester.ensureVisible(card);
    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(find.byType(DataTable), findsOneWidget);

    // กรองเฉพาะ onsite
    await tester.tap(find.text('onsite').first);
    await tester.pumpAndSettle();
    final before = store.myReports(channel: ConsultChannel.onsite).length;

    // เพิ่มเคส onsite: รหัสนิสิตที่มีในระบบ -> ชื่อกรอกให้อัตโนมัติ
    await tester.tap(find.text('เพิ่มเคส onsite'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'รหัสนิสิต'),
      '68313303',
    );
    await tester.pump();
    expect(find.text('มณีรัตน์ แสงทอง'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'เรื่องที่ปรึกษา'),
      'ปรึกษาเรื่องเพื่อน',
    );
    final add = find.text('เพิ่มลงตาราง');
    await tester.ensureVisible(add);
    await tester.tap(add);
    await tester.pumpAndSettle();

    // เพิ่มวันนี้ -> ต้องอยู่ในตารางเดือนนี้
    final onsite = store.myReports(channel: ConsultChannel.onsite);
    expect(onsite.length, before + 1);
    expect(find.text('ปรึกษาเรื่องเพื่อน'), findsOneWidget);

    // แตะแถว (ที่คอลัมน์ชื่อ ซึ่งอยู่ในจอ) เพื่อแก้ “เรื่องที่ปรึกษา”
    await tester.tap(find.text('มณีรัตน์ แสงทอง'));
    await tester.pumpAndSettle();
    expect(find.text('แก้ไขแถวในตาราง'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'เรื่องที่ปรึกษา'),
      'แก้แล้ว',
    );
    await tester.tap(find.text('บันทึก'));
    await tester.pumpAndSettle();
    expect(find.text('แก้แล้ว'), findsOneWidget);
    store.logout();
    await tester.pumpAndSettle(const Duration(seconds: 1));
  });
}

/// วันทำการถัดไป (ใช้สร้างเวลานัดในอนาคตแน่นอน)
DateTime firstDayForTest() {
  var d = DateTime.now().add(const Duration(days: 1));
  while (!MockStore.isOfficeDay(d)) {
    d = d.add(const Duration(days: 1));
  }
  return d;
}
