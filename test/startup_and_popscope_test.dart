import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kaiwan_chuaiduai/data/app_data.dart';
import 'package:kaiwan_chuaiduai/main.dart';

import 'test_store.dart';

void main() {
  late TestApp app;
  setUpAll(() async => app = await openTestStore());

  // บทที่ 12: FutureBuilder แสดงสถานะ กำลังโหลด -> สำเร็จ / error -> ลองใหม่
  testWidgets('startup: loading, then error with retry, then app', (
    tester,
  ) async {
    var attempt = 0;
    final first = Completer<AppData>();
    await tester.pumpWidget(
      AppStartup(
        load: () {
          attempt++;
          return attempt == 1 ? first.future : Future.value(app.data);
        },
      ),
    );
    expect(find.text('กำลังโหลด...'), findsOneWidget);

    first.completeError('ฐานข้อมูลเสีย');
    await tester.pumpAndSettle();
    expect(find.text('เปิดข้อมูลไม่สำเร็จ'), findsOneWidget);
    expect(find.text('ฐานข้อมูลเสีย'), findsOneWidget);

    await tester.tap(find.text('ลองใหม่'));
    await tester.pumpAndSettle();
    expect(attempt, 2);
    expect(find.text('login'), findsOneWidget); // เข้าแอปแล้ว (หน้า Login)
  });

  // บทที่ 9: PopScope กรอกฟอร์มค้างแล้วกดย้อนกลับ -> ถามก่อนทิ้ง
  testWidgets('sign-up asks before discarding typed data', (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app.widget());
    await tester.tap(find.textContaining('สมัครสมาชิก', findRichText: true));
    await tester.pumpAndSettle();

    // ยังไม่กรอก -> ย้อนกลับได้เลย ไม่ถาม
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('login'), findsOneWidget);

    await tester.tap(find.textContaining('สมัครสมาชิก', findRichText: true));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'abck67@nu.ac.th');
    await tester.pump();

    // กรอกแล้ว -> ถาม, กด “กรอกต่อ” = ยังอยู่หน้าเดิม ข้อมูลไม่หาย
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('ทิ้งข้อมูลที่กรอกไว้ไหม?'), findsOneWidget);
    await tester.tap(find.text('กรอกต่อ'));
    await tester.pumpAndSettle();
    expect(find.text('abck67@nu.ac.th'), findsOneWidget);

    // กด “ทิ้งข้อมูล” = ออกจากหน้าสมัคร
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ทิ้งข้อมูล'));
    await tester.pumpAndSettle();
    expect(find.text('login'), findsOneWidget);
  });
}
