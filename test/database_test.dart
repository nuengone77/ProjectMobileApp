import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:kaiwan_chuaiduai/data/mock_store.dart';
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
    expect(s.users.length, 6);
    final staff1 = s.users.firstWhere((u) => u.email == 'piyaromk@nu.ac.th');
    expect(staff1.passwordHash, isNot('kaiwanpiyaromk'));
    expect(
      staff1.passwordHash,
      hashPassword('piyaromk@nu.ac.th', 'kaiwanpiyaromk'),
    );
    expect(s.login('piyaromk@nu.ac.th', 'wrong'), 'รหัสผ่านไม่ถูกต้อง');
  });

  test('ข้อมูลยังอยู่หลังปิด-เปิดแอปใหม่ (รวมถึงล็อกอินค้างไว้)', () async {
    var s = await openTestStore(path: path);

    // นักศึกษาสมัครใหม่ -> แชทแบบเจาะจง -> นัดหมาย
    expect(
      s.register(
        email: 'nanthitb67@nu.ac.th',
        password: 'abcd',
        name: 'นันทิต บุญมี',
        major: MockStore.majors.first,
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
    s.login('piyaromk@nu.ac.th', 'kaiwanpiyaromk');
    s.send(conv, 'ยินดีครับ');
    s.closeConversation(
      conv,
      topic: 'สอบถามทั่วไป',
      help: 'ตอบคำถาม',
      level: CaseLevel.large,
    );
    s.logout();
    s.login('khuwnruanep@nu.ac.th', 'kaiwankhuwnruanep');
    final newTime = appt.start.add(const Duration(days: 1));
    s.proposeAppointmentTime(appt, newTime, 'ช่วงนั้นไม่ว่าง');
    await s.flush();

    // เปิดใหม่จากไฟล์เดิม = เหมือนปิดแอปแล้วเปิดใหม่
    s = await openTestStore(path: path);
    expect(s.currentUser?.email, 'khuwnruanep@nu.ac.th'); // ล็อกอินค้างไว้

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

  test('รีเซ็ตข้อมูลทดลอง: กลับเป็นข้อมูลตั้งต้นและออกจากระบบ', () async {
    var s = await openTestStore(path: path);
    s.register(
      email: 'nanthitb67@nu.ac.th',
      password: 'abcd',
      name: 'นันทิต บุญมี',
      major: MockStore.majors.first,
      studentId: '67313318',
      nameEn: 'Nanthit Bunmee',
    );
    s.resetDemoData();
    expect(s.currentUser, isNull);
    expect(s.users.any((u) => u.email == 'nanthitb67@nu.ac.th'), isFalse);
    await s.flush();

    s = await openTestStore(path: path);
    expect(s.users.length, 6);
    expect(s.users.any((u) => u.email == 'nanthitb67@nu.ac.th'), isFalse);
  });
}
