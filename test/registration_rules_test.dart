import 'package:flutter_test/flutter_test.dart';

import 'package:kaiwan_chuaiduai/data/app_data.dart';
import 'package:kaiwan_chuaiduai/data/registration_rules.dart';

import 'test_store.dart';

// ทดสอบเงื่อนไขการลงทะเบียนนักศึกษา (lib/data/registration_rules.dart)
void main() {
  String? email(
    String e, {
    String name = 'nanthit bunmee',
    String id = '67313318',
  }) => RegistrationRules.emailError(e, nameEn: name, studentId: id);

  group('อีเมล', () {
    test('ตัวอย่างจากแบบ: nanthitb67@nu.ac.th ผ่าน', () {
      expect(email('nanthitb67@nu.ac.th'), isNull);
    });

    test('ตัวพิมพ์ใหญ่/เว้นวรรคหัวท้าย แปลงเป็นตัวเล็กก่อนตรวจ', () {
      expect(email('  NanthitB67@NU.AC.TH '), isNull);
      expect(email('nanthitb67@nu.ac.th', name: 'NANTHIT BUNMEE'), isNull);
    });

    test('ไม่ใช่อีเมลมหาลัย -> ข้อความสีแดงตามที่กำหนด', () {
      expect(
        email('nanthitb67@gmail.com'),
        'โปรดใช้อีเมลของมหาลัยในการลงทะเบียน',
      );
      expect(email('nanthitb67'), 'โปรดใช้อีเมลของมหาลัยในการลงทะเบียน');
      expect(email('@nu.ac.th'), 'โปรดใช้อีเมลของมหาลัยในการลงทะเบียน');
    });

    test('ชื่ออังกฤษ / ตัวแรกนามสกุลไม่ตรง', () {
      expect(email('nanthitk67@nu.ac.th'), contains('ไม่ตรงกับชื่อภาษาอังกฤษ'));
      expect(email('nanthb67@nu.ac.th'), contains('ไม่ตรงกับชื่อภาษาอังกฤษ'));
      expect(email('nanthit67@nu.ac.th'), contains('ไม่ตรงกับชื่อภาษาอังกฤษ'));
    });

    test('ชื่อซ้ำ: ใช้นามสกุลเพิ่มกี่ตัวก็ได้ ขอให้ตรงกับนามสกุลตามลำดับ', () {
      String? e(String v) =>
          email(v, name: 'PATTARANIT CHANGTHAMRONG', id: '67312222');
      expect(e('pattaranitc67@nu.ac.th'), isNull);
      expect(e('pattaranitch67@nu.ac.th'), isNull);
      expect(e('pattaranitchangthamrong67@nu.ac.th'), isNull);
      expect(e('pattaranitca67@nu.ac.th'), 'อีเมลไม่ตรงกับชื่อภาษาอังกฤษ');
      expect(
        e('pattaranitchangthamrongx67@nu.ac.th'),
        'อีเมลไม่ตรงกับชื่อภาษาอังกฤษ',
      );
    });

    test('เลขปีในอีเมลต้องอยู่ระหว่าง 66–69', () {
      expect(
        email('nanthitb65@nu.ac.th', id: '65313318'),
        'เลขปีในอีเมลไม่ถูกต้อง',
      );
      expect(email('nanthitb70@nu.ac.th'), 'เลขปีในอีเมลไม่ถูกต้อง');
      expect(email('nanthitb66@nu.ac.th', id: '66313318'), isNull);
      expect(email('nanthitb69@nu.ac.th', id: '69313318'), isNull);
    });

    test('เลขปีในอีเมลต้องตรงกับ 2 ตัวแรกของรหัสนิสิต', () {
      expect(email('nanthitb68@nu.ac.th'), 'เลขปีในอีเมลไม่ตรงกับรหัสนิสิต');
    });

    test('รูปแบบอีเมลผิด (ไม่มีเลขปี)', () {
      expect(email('nanthitb@nu.ac.th'), contains('รูปแบบอีเมลไม่ถูกต้อง'));
    });
  });

  test(
    'ผิดหลายจุด -> บอกทีละจุด: ชื่อก่อน แล้วค่อยเลขปี (กรณีจากหน้าจอจริง)',
    () {
      expect(
        email('qwert67@nu.ac.th', name: 'qwert asdf', id: '66312356'),
        'อีเมลไม่ตรงกับชื่อภาษาอังกฤษ',
      );
      // แก้ชื่อในอีเมลแล้ว เหลือจุดผิดถัดไปคือเลขปี
      expect(
        email('qwerta67@nu.ac.th', name: 'qwert asdf', id: '66312356'),
        'เลขปีในอีเมลไม่ตรงกับรหัสนิสิต',
      );
    },
  );

  test('บัญชีนักศึกษาทดสอบ (testerk67) ผ่านเงื่อนไขการลงทะเบียนทุกข้อ', () {
    expect(
      RegistrationRules.emailError(
        AppData.testStudentEmail,
        nameEn: 'Tester Kaiwan',
        studentId: '67310001',
      ),
      isNull,
    );
    expect(RegistrationRules.studentIdError('67310001'), isNull);
    expect(RegistrationRules.nameEnError('Tester Kaiwan'), isNull);
  });

  group('รหัสนิสิต', () {
    test('ตัวอย่างจากแบบ: 67313318 ผ่าน', () {
      expect(RegistrationRules.studentIdError('67313318'), isNull);
    });

    test('ต้องมี 8 หลักเท่านั้น', () {
      expect(RegistrationRules.studentIdError('6731331'), contains('8 หลัก'));
      expect(RegistrationRules.studentIdError('673133189'), contains('8 หลัก'));
    });

    test('2 ตัวแรก (ปีที่เข้าศึกษา) ต้องอยู่ระหว่าง 66–69', () {
      expect(
        RegistrationRules.studentIdError('65313318'),
        'รหัสนิสิตไม่ถูกต้อง',
      );
      expect(
        RegistrationRules.studentIdError('70313318'),
        'รหัสนิสิตไม่ถูกต้อง',
      );
    });

    test('2 ตัวถัดมาต้องเป็น 31 (คณะวิทยาศาสตร์)', () {
      expect(
        RegistrationRules.studentIdError('67323318'),
        contains('คณะวิทยาศาสตร์'),
      );
    });
  });

  group('ชื่อภาษาอังกฤษ', () {
    test('ต้องมีทั้งชื่อและนามสกุล เป็นตัวอักษรอังกฤษ', () {
      expect(RegistrationRules.nameEnError('Nanthit Bunmee'), isNull);
      expect(RegistrationRules.nameEnError('Nanthit'), contains('นามสกุล'));
      expect(
        RegistrationRules.nameEnError('นันทิต บุญมี'),
        contains('ภาษาอังกฤษ'),
      );
    });
  });

  test('store.register ตรวจเงื่อนไขซ้ำ (กันข้ามหน้าจอ)', () async {
    final s = await openTestStore();
    expect(
      s.register(
        email: 'nanthitb67@gmail.com',
        password: 'abcd',
        name: 'นันทิต บุญมี',
        major: AppData.majors.first,
        studentId: '67313318',
        nameEn: 'Nanthit Bunmee',
      ),
      'โปรดใช้อีเมลของมหาลัยในการลงทะเบียน',
    );
    expect(
      s.register(
        email: 'NanthitB67@nu.ac.th',
        password: 'abcd',
        name: 'นันทิต บุญมี',
        major: AppData.majors.first,
        studentId: '67313318',
        nameEn: 'Nanthit Bunmee',
      ),
      isNull,
    );
    expect(s.currentUser!.email, 'nanthitb67@nu.ac.th');
  });

  test('บัญชีเจ้าหน้าที่ 3 คนล็อกอินได้ด้วยรหัสที่กำหนด', () async {
    final s = await openTestStore();
    for (final (e, p) in [
      (staff1.email, staff1.password),
      (staff2.email, staff2.password),
      (staff3.email, staff3.password),
    ]) {
      expect(s.login(e, p), isNull);
      expect(s.currentUser!.isStaff, isTrue);
      s.logout();
    }
    expect(s.staff.length, 3);
  });

  test(
    'ภาควิชา/สาขา: หาภาควิชาจากสาขาได้ และสมัครด้วยสาขานอกรายการไม่ได้',
    () async {
      expect(
        AppData.departmentOf('สาขาวิชาวิทยาการข้อมูล'),
        'ภาควิชาคณิตศาสตร์',
      );
      expect(
        AppData.departmentOf('สาขาวิชาเทคโนโลยีสารสนเทศ'),
        'ภาควิชาวิทยาการคอมพิวเตอร์และเทคโนโลยีสารสนเทศ',
      );
      expect(AppData.departmentOf('วิศวกรรมคอมพิวเตอร์'), isNull);
      expect(AppData.majors.length, 11);
      final s = await openTestStore();
      expect(
        s.register(
          email: 'nanthitb67@nu.ac.th',
          password: 'abcd',
          name: 'นันทิต บุญมี',
          major: 'วิศวกรรมคอมพิวเตอร์',
          studentId: '67313318',
          nameEn: 'Nanthit Bunmee',
        ),
        'กรุณาเลือกสาขา',
      );
    },
  );
}
