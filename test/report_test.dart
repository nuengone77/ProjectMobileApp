import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:kaiwan_chuaiduai/data/app_database.dart';
import 'package:kaiwan_chuaiduai/data/models.dart';
import 'package:kaiwan_chuaiduai/data/report_export.dart';

import 'test_store.dart';

// ทดสอบตารางสรุปเคส (case_reports): ที่มาของแถว, การแก้ไข, ตัวกรอง, การเก็บลงฐานข้อมูล, CSV
void main() {
  /// ล็อกอินเจ้าหน้าที่คนที่ 1
  void loginStaff1(TestApp s) {
    s.logout();
    s.login(staff1.email, staff1.password);
  }

  /// นักศึกษาทดลองเปิดแชทเจาะจงกับเจ้าหน้าที่คนที่ 1 แล้วเจ้าหน้าที่จบพร้อมสรุป
  Conversation closedChat(TestApp s) {
    s.logout();
    s.login('somjaij67@nu.ac.th', '1234');
    final c = s.openConversation(categoryId: 'urgent');
    s.send(c, 'ช่วยด้วยค่ะ');
    loginStaff1(s);
    s.send(c, 'พี่อยู่ตรงนี้');
    s.closeConversation(
      c,
      topic: 'เครียดเรื่องเรียน',
      help: 'รับฟังและแนะนำ',
      level: CaseLevel.medium,
    );
    return c;
  }

  test('แชทที่จบแล้วขึ้นในตารางของเจ้าหน้าที่ผู้ดูแลอัตโนมัติ', () async {
    final s = await openTestStore();
    final c = closedChat(s);
    final row = s.myReports().firstWhere((r) => r.conversationId == c.id);
    expect(row.channel, ConsultChannel.online);
    expect(row.categoryId, 'urgent');
    expect(row.studentIdNo, '67313301');
    expect(row.studentName, 'สมใจ ใจดี');
    expect(row.topic, 'เครียดเรื่องเรียน');
    expect(row.advice, 'รับฟังและแนะนำ');
    expect(row.level, CaseLevel.medium);
    expect(row.date, c.messages.first.time); // วันที่ = เวลาที่เปิดแชท

    // เจ้าหน้าที่คนอื่นไม่เห็นแถวนี้
    s.logout();
    s.login(staff2.email, staff2.password);
    expect(s.myReports().any((r) => r.conversationId == c.id), isFalse);
  });

  test('แก้ในตารางไม่กระทบแชท และสรุปในแชทไม่ทับแถวที่แก้แล้ว', () async {
    final s = await openTestStore();
    final c = closedChat(s);
    final row = s.myReports().firstWhere((r) => r.conversationId == c.id);

    // ยังไม่เคยแก้ในตาราง -> แก้สรุปในแชทแล้วตารางอัปเดตตาม
    s.saveSummary(c, 'หัวข้อใหม่', 'คำแนะนำใหม่', CaseLevel.large);
    expect(row.topic, 'หัวข้อใหม่');
    expect(row.level, CaseLevel.large);

    // แก้ในตาราง -> แชทไม่เปลี่ยน
    s.updateReport(
      row,
      categoryId: 'general',
      topic: 'แก้ในรายงาน',
      advice: 'ตามรายงาน',
      level: CaseLevel.small,
    );
    expect(c.summaryTopic, 'หัวข้อใหม่');
    expect(c.caseLevel, CaseLevel.large);
    expect(c.categoryId, 'urgent');

    // แก้สรุปในแชทอีกรอบ -> ไม่ทับค่าที่แก้ในตารางแล้ว
    s.saveSummary(c, 'แชทแก้อีก', 'x', CaseLevel.medium);
    expect(row.topic, 'แก้ในรายงาน');
    expect(row.categoryId, 'general');
    expect(row.level, CaseLevel.small);
  });

  test('เพิ่ม/ลบแถว onsite เอง และแถวจากแชทลบไม่ได้', () async {
    final s = await openTestStore();
    loginStaff1(s);
    final r = s.addOnsiteReport(
      date: DateTime(2026, 10, 5, 14),
      studentIdNo: '68313303',
      studentName: 'มณีรัตน์ แสงทอง',
      categoryId: 'general',
      topic: 'ปรับตัว',
      advice: 'แนะนำกิจกรรม',
      level: CaseLevel.small,
    );
    expect(s.myReports(channel: ConsultChannel.onsite), contains(r));
    expect(s.studentByIdNo('68313303')?.name, 'มณีรัตน์ แสงทอง');
    s.deleteReport(r);
    expect(s.myReports(), isNot(contains(r)));

    final chatRow = s.myReports(channel: ConsultChannel.online).first;
    s.deleteReport(chatRow);
    expect(s.myReports(), contains(chatRow));
  });

  test('กรองช่วงวันที่ (รวมทั้งวันสุดท้าย) และช่องทาง', () async {
    final s = await openTestStore();
    loginStaff1(s);
    CaseReport add(DateTime d) => s.addOnsiteReport(
      date: d,
      studentIdNo: '66313302',
      studentName: 'กิตติ ขยันเรียน',
      categoryId: 'general',
    );
    final sep = add(DateTime(2025, 9, 30, 23, 59));
    final oct1 = add(DateTime(2025, 10, 1, 8));
    final oct31 = add(DateTime(2025, 10, 31, 23, 30));
    final rows = s.myReports(
      from: DateTime(2025, 10, 1),
      to: DateTime(2025, 10, 31),
    );
    expect(rows, containsAllInOrder([oct1, oct31]));
    expect(rows, isNot(contains(sep)));
    expect(
      s
          .myReports(
            from: DateTime(2025, 10, 1),
            to: DateTime(2025, 10, 31),
            channel: ConsultChannel.online,
          )
          .any((r) => r.channel == ConsultChannel.onsite),
      isFalse,
    );
  });

  test('ตารางเก็บลงฐานข้อมูล และอัปเกรดจากฐานข้อมูลเวอร์ชันเก่าได้', () async {
    final dir = Directory.systemTemp.createTempSync('kaiwan_report_test');
    addTearDown(() async {
      await closeTestApps();
      dir.deleteSync(recursive: true);
    });
    final path = '${dir.path}/kaiwan.db';

    // จำลองเครื่องที่มีฐานข้อมูลเวอร์ชัน 1 (ยังไม่มีตาราง case_reports)
    sqfliteFfiInit();
    final old = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) => AppDatabase.createV1Tables(db),
      ),
    );
    await old.close();

    var s = await openTestStore(path: path); // เปิดแล้วอัปเกรดเป็นเวอร์ชัน 2
    s.resetData();
    final c = closedChat(s);
    final row = s.myReports().firstWhere((r) => r.conversationId == c.id);
    s.updateReport(
      row,
      categoryId: 'urgent',
      topic: 'เก็บไว้',
      advice: 'ok',
      level: CaseLevel.large,
    );
    await s.flush();

    s = await openTestStore(path: path);
    final again = s.reports.firstWhere((r) => r.id == row.id);
    expect(again.topic, 'เก็บไว้');
    expect(again.edited, isTrue);
    expect(again.level, CaseLevel.large);
    // แถว onsite ตัวอย่างจากข้อมูลตั้งต้นก็อยู่ด้วย
    expect(s.reports.any((r) => r.channel == ConsultChannel.onsite), isTrue);
  });

  test('CSV: มี BOM, หัวคอลัมน์ครบ, ครอบเครื่องหมายคำพูดเมื่อจำเป็น', () {
    final csv = ReportExport.buildCsv([
      CaseReport(
        id: 'x',
        staffId: 'st1',
        date: DateTime(2026, 10, 9, 10, 5),
        studentIdNo: '67313318',
        studentName: 'นันทิต บุญมี',
        categoryId: 'urgent',
        channel: ConsultChannel.online,
        topic: 'เรื่อง, ที่มี "เครื่องหมาย"',
        advice: 'บรรทัด1\nบรรทัด2',
        level: CaseLevel.large,
      ),
    ]);
    expect(csv.startsWith('﻿'), isTrue);
    final lines = csv.substring(1).split('\r\n');
    expect(lines.first, ReportExport.headers.join(','));
    expect(
      lines[1],
      startsWith('09/10/2569 10:05,67313318,นันทิต บุญมี,เร่งด่วน,online,'),
    );
    expect(csv, contains('"เรื่อง, ที่มี ""เครื่องหมาย"""'));
    expect(csv, contains('"บรรทัด1\nบรรทัด2"'));
    expect(lines[1], endsWith(',ใหญ่'));
  });
}
