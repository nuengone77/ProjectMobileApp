// ข้อมูลทดลองสำหรับเทสต์เท่านั้น (ไม่อยู่ในแอปจริง)
//
// นักศึกษาทดลอง 3 คน (รหัสผ่าน 1234) + แชท นัดหมาย และเคส onsite ตัวอย่าง
// ใช้สร้างสถานการณ์ให้เทสต์ เช่น นัดที่เจ้าหน้าที่เสนอเวลาใหม่ แชทที่จบแล้วพร้อมสรุป
// แอปจริงเริ่มจากข้อมูลว่าง (มีแค่บัญชีเจ้าหน้าที่ + นักศึกษาทดสอบ testerk67)

import 'package:kaiwan_chuaiduai/data/app_data.dart';
import 'package:kaiwan_chuaiduai/data/models.dart';
import 'package:kaiwan_chuaiduai/data/passwords.dart';

/// ใส่ข้อมูลทดลองลงใน [data] (เรียกหลังเปิดฐานข้อมูลใหม่ที่ยังว่าง)
void seedDemoData(AppData data) {
  data.users.addAll([
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
      id: data.newId('c'),
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
    data.conversations.add(c);
    return c;
  }

  // แชทที่ยังไม่ได้อ่าน เพื่อให้กระดิ่งฝั่งเจ้าหน้าที่มีตัวเลขให้เห็น
  // รูปแบบข้อความ: (ผู้ส่ง, ข้อความ, กี่นาทีที่แล้ว)
  seed('stu2', 'general', null, [
    ('stu2', 'สวัสดีครับ ส่งเอกสาร กยศ. รอบนี้ต้องใช้อะไรบ้างครับ', 42),
    ('stu2', 'ผมต้องส่งภายในวันไหนครับ', 41),
  ]);
  seed('stu3', 'general', 'st1', [
    ('stu3', 'พี่คะ ผู้ปกครองอยู่ต่างจังหวัด เซ็นเอกสาร กยศ. แทนได้ไหมคะ', 30),
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
      if (AppData.isOfficeDay(d) && left-- == 0) return d;
    }
  }

  DateTime at(DateTime day, int h, int m) =>
      DateTime(day.year, day.month, day.day, h, m);
  data.appointments.addAll([
    Appointment(
      id: data.newId('a'),
      studentId: 'stu2',
      start: at(nextOfficeDay(0), 10, 0),
      note: 'อยากปรึกษาเรื่องเอกสาร กยศ. แบบเจอตัว',
    ),
    Appointment(
      id: data.newId('a'),
      studentId: 'stu3',
      start: at(nextOfficeDay(1), 13, 30),
      note: 'ปรึกษาเรื่องการปรับตัว',
      requestedStaffId: 'st1', // ขอนัดกับเจ้าหน้าที่คนที่ 1 โดยตรง
    ),
    Appointment(
      id: data.newId('a'),
      studentId: 'stu3',
      start: at(nextOfficeDay(0), 14, 0),
      status: AppointmentStatus.confirmed,
      staffId: 'st3',
    ),
    // นัดของนักศึกษาทดลองที่พี่ไม่ว่าง เลยเสนอเวลาใหม่ (ไว้เดโมฝั่งนักศึกษา)
    Appointment(
        id: data.newId('a'),
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
        .map((m) => data.user(m.senderId))
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
      ('st2', 'ตรวจหน่วยกิตให้ครบ แล้วยื่นคำร้องที่งานทะเบียนได้เลยค่ะ', 1430),
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
  data.reports.add(
    CaseReport(
      id: data.newId('r'),
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

  // บันทึกลงฐานข้อมูล + สร้างแถวตารางสรุปเคสของแชทที่จบแล้ว (เหมือนตอนแชทจบจริง)
  data.saveAll();
  data.conversations.forEach(data.syncChatReport);
}
