import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:kaiwan_chuaiduai/data/app_database.dart';

import 'package:kaiwan_chuaiduai/data/attachments.dart';
import 'package:kaiwan_chuaiduai/config/staff_accounts.dart';
import 'package:kaiwan_chuaiduai/data/app_store.dart';
import 'package:kaiwan_chuaiduai/data/models.dart';
import 'package:kaiwan_chuaiduai/data/passwords.dart';

import 'test_store.dart';

// ทดสอบว่าข้อมูลเก็บลง SQLite จริง: เขียน -> ปิด -> เปิดใหม่จากไฟล์เดิม -> ข้อมูลยังอยู่
void main() {
  late Directory dir;
  late String path;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('kaiwan_db_test');
    path = '${dir.path}/kaiwan.db';
  });
  tearDown(() => dir.deleteSync(recursive: true));

  test('เปิดครั้งแรกใส่ข้อมูลตั้งต้น และเก็บรหัสผ่านเป็น hash', () async {
    final s = await openTestStore(path: path);
    expect(s.staff.length, 3);
    expect(
      s.users.length,
      7,
    ); // เจ้าหน้าที่ 3 + นักศึกษาทดสอบ 1 + นักศึกษาทดลอง 3
    final u = s.users.firstWhere((u) => u.email == staff1.email);
    expect(u.passwordHash, isNot(staff1.password));
    expect(u.passwordHash, hashPassword(staff1.email, staff1.password));
    expect(s.login(staff1.email, 'wrong'), 'รหัสผ่านไม่ถูกต้อง');
  });

  test(
    'แอปจริงเริ่มจากข้อมูลว่าง: มีแค่บัญชีเจ้าหน้าที่ + นักศึกษาทดสอบ 1 บัญชี',
    () async {
      final s = await openTestStore(path: path, demoData: false);
      expect(s.users.length, 4);
      expect(s.staff.length, staffAccounts.length);
      // นักศึกษาทดสอบล็อกอินได้ทันทีโดยไม่ต้องสมัคร
      expect(
        s.login(AppStore.testStudentEmail, AppStore.testStudentPassword),
        isNull,
      );
      expect(s.currentUser!.studentId, '67310001');
      s.logout();
      expect(s.conversations, isEmpty);
      expect(s.appointments, isEmpty);
      expect(s.reports, isEmpty);
      // รีเซ็ตแล้วก็ยังว่างเหมือนเดิม
      s.resetData();
      expect(s.users.length, 4);
      expect(s.conversations, isEmpty);
    },
  );

  test('ข้อมูลยังอยู่หลังปิด-เปิดแอปใหม่ (รวมถึงล็อกอินค้างไว้)', () async {
    var s = await openTestStore(path: path);

    // นักศึกษาสมัครใหม่ -> แชทแบบเจาะจง -> นัดหมาย
    expect(
      s.register(
        email: 'nanthitb67@nu.ac.th',
        password: 'abcd',
        name: 'นันทิต บุญมี',
        major: AppStore.majors.first,
        studentId: '67313318',
        nameEn: 'Nanthit Bunmee',
        phone: '0899999999',
      ),
      isNull,
    );
    final conv = s.openConversation(categoryId: 'general', staffId: 'st1');
    s.send(conv, 'สวัสดีครับ');
    final appt = s.requestAppointment(
      DateTime.now().add(const Duration(days: 3)),
      'ขอนัด',
      staffId: 'st2',
    );
    // เจ้าหน้าที่จบแชทพร้อมสรุป + เสนอเวลานัดใหม่
    s.logout();
    s.login(staff1.email, staff1.password);
    s.send(conv, 'ยินดีครับ');
    s.closeConversation(
      conv,
      topic: 'สอบถามทั่วไป',
      help: 'ตอบคำถาม',
      level: CaseLevel.large,
    );
    s.logout();
    s.login(staff2.email, staff2.password);
    final newTime = appt.start.add(const Duration(days: 1));
    s.proposeAppointmentTime(appt, newTime, 'ช่วงนั้นไม่ว่าง');
    await s.flush();

    // เปิดใหม่จากไฟล์เดิม = เหมือนปิดแอปแล้วเปิดใหม่
    s = await openTestStore(path: path);
    expect(s.currentUser?.email, staff2.email); // ล็อกอินค้างไว้

    final student = s.users.firstWhere((u) => u.email == 'nanthitb67@nu.ac.th');
    expect(student.studentId, '67313318');
    expect(student.phone, '0899999999');

    final c = s.conversation(conv.id);
    expect(c.closed, isTrue);
    expect(c.summaryTopic, 'สอบถามทั่วไป');
    expect(c.summaryHelp, 'ตอบคำถาม');
    expect(c.caseLevel, CaseLevel.large);
    expect(c.staffId, 'st1');
    expect(
      c.messages.map((m) => m.text),
      containsAllInOrder(['สวัสดีครับ', 'ยินดีครับ']),
    );
    expect(c.messages.length, conv.messages.length);

    final a = s.appointments.firstWhere((x) => x.id == appt.id);
    expect(a.status, AppointmentStatus.proposed);
    expect(a.proposedStart, newTime.copyWith(microsecond: 0));
    expect(a.staffMessage, 'ช่วงนั้นไม่ว่าง');
    expect(a.requestedStaffId, 'st2');

    // ออกจากระบบแล้วเปิดใหม่ -> ไม่ล็อกอินค้าง
    s.logout();
    await s.flush();
    s = await openTestStore(path: path);
    expect(s.currentUser, isNull);
  });

  test('ไฟล์แนบ: คัดลอกเข้าแอป ส่งในแชท และยังอยู่หลังเปิดแอปใหม่', () async {
    await Attachments.init('${dir.path}/attachments');
    final src = File('${dir.path}/ใบรับรอง.pdf')..writeAsStringSync('pdf');
    final img = File('${dir.path}/photo.JPG')..writeAsStringSync('img');

    var s = await openTestStore(path: path);
    s.login('somjaij67@nu.ac.th', testPasswords['somjaij67@nu.ac.th']!);
    final conv = s.openConversation(categoryId: 'general', staffId: 'st2');
    final pdf = await Attachments.import(src.path);
    final jpg = await Attachments.import(img.path);
    expect(jpg, endsWith('.jpg'));
    s.sendAttachment(conv, file: pdf, name: 'ใบรับรอง.pdf', isImage: false);
    s.sendAttachment(conv, file: jpg, name: 'photo.JPG', isImage: true);
    expect(conv.last!.preview, '📷 รูปภาพ');

    // ส่งแค่ไฟล์ (ไม่พิมพ์) ก็นับว่าทักแล้ว เจ้าหน้าที่เห็นห้อง
    s.logout();
    s.login(staff2.email, staff2.password);
    expect(s.staffConversations().any((c) => c.id == conv.id), isTrue);
    await s.flush();

    s = await openTestStore(path: path);
    final msgs = s.conversation(conv.id).messages;
    final file = msgs.firstWhere((m) => m.attachment == pdf);
    expect(file.isImage, isFalse);
    expect(file.preview, '📎 ใบรับรอง.pdf');
    expect(msgs.firstWhere((m) => m.attachment == jpg).isImage, isTrue);
    expect(File(Attachments.pathOf(pdf)).readAsStringSync(), 'pdf');

    // รีเซ็ตข้อมูลทดลอง -> ไฟล์แนบถูกลบด้วย
    s.resetData();
    expect(File(Attachments.pathOf(pdf)).existsSync(), isFalse);
    await s.flush();
  });

  test(
    'นักศึกษาแก้เบอร์โทร/สาขาในโปรไฟล์ได้ และยังอยู่หลังเปิดแอปใหม่',
    () async {
      var s = await openTestStore(path: path);
      s.login('kittik66@nu.ac.th', testPasswords['kittik66@nu.ac.th']!);
      expect(
        s.updateMyProfile(phone: '12345'),
        'เบอร์โทร 10 หลัก ขึ้นต้นด้วย 0',
      );
      expect(s.updateMyProfile(major: 'วิศวกรรมคอมพิวเตอร์'), 'กรุณาเลือกสาขา');
      expect(s.updateMyProfile(phone: '0891112222'), isNull);
      expect(s.updateMyProfile(major: 'สาขาวิชาวิทยาการข้อมูล'), isNull);
      await s.flush();

      s = await openTestStore(path: path);
      final me = s.currentUser!;
      expect(me.phone, '0891112222');
      expect(me.major, 'สาขาวิชาวิทยาการข้อมูล');
      expect(AppStore.departmentOf(me.major), 'ภาควิชาคณิตศาสตร์');
    },
  );

  test('เขียนฐานข้อมูลไม่สำเร็จ -> แจ้ง onWriteError (ไม่เงียบหาย)', () async {
    sqfliteFfiInit();
    final db = await AppDatabase.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    final errors = <Object>[];
    db.onWriteError = errors.add;
    await db.close(); // ปิดแล้วเขียนต่อ = เขียนไม่สำเร็จแน่นอน
    db.setSetting('x', '1');
    await db.flush();
    expect(errors, hasLength(1));
    // คิวยังใช้ต่อได้หลัง error (ไม่ค้าง)
    db.setSetting('y', '2');
    await db.flush();
    expect(errors, hasLength(2));
  });

  test('รีเซ็ตข้อมูลทดลอง: กลับเป็นข้อมูลตั้งต้นและออกจากระบบ', () async {
    var s = await openTestStore(path: path);
    s.register(
      email: 'nanthitb67@nu.ac.th',
      password: 'abcd',
      name: 'นันทิต บุญมี',
      major: AppStore.majors.first,
      studentId: '67313318',
      nameEn: 'Nanthit Bunmee',
    );
    s.resetData();
    expect(s.currentUser, isNull);
    expect(s.users.any((u) => u.email == 'nanthitb67@nu.ac.th'), isFalse);
    await s.flush();

    s = await openTestStore(path: path);
    expect(s.users.length, 7);
    expect(s.users.any((u) => u.email == 'nanthitb67@nu.ac.th'), isFalse);
  });
}
