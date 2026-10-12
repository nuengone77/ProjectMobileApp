import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:kaiwan_chuaiduai/data/app_data.dart';
import 'package:kaiwan_chuaiduai/main.dart';
import 'package:kaiwan_chuaiduai/providers/auth_provider.dart';
import 'package:kaiwan_chuaiduai/providers/chat_provider.dart';
import 'package:kaiwan_chuaiduai/providers/report_provider.dart';

import 'test_store.dart';

// ทดสอบการต่อ Provider จริงใน main.dart (AppProviders: MultiProvider + ProxyProvider)
// ล็อกอินผ่านหน้าจอ -> Provider ที่พึ่ง Auth ต้องเห็นผู้ใช้คนเดียวกัน -> ส่งข้อความ -> ออกจากระบบ
void main() {
  // เปิดฐานข้อมูลนอก testWidgets (งาน I/O จริงไม่ทำงานในเวลาจำลองของ testWidgets)
  late TestApp app;
  setUpAll(() async => app = await openTestStore());

  testWidgets('real AppProviders: login, chat, close -> report, logout', (
    tester,
  ) async {
    await tester.pumpWidget(KaiwanApp(data: app.data));
    T read<T>() =>
        Provider.of<T>(tester.element(find.byType(MaterialApp)), listen: false);

    // ล็อกอินเป็นนักศึกษาผ่านหน้า Login
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), AppData.testStudentEmail);
    await tester.enterText(fields.at(1), AppData.testStudentPassword);
    await tester.tap(find.text('login'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(read<AuthProvider>().currentUser!.email, AppData.testStudentEmail);
    expect(find.text('ถาม/ตอบเรื่องทั่วไป'), findsOneWidget);

    // ChatProvider (ต่อผ่าน ProxyProvider) รู้ว่าใครล็อกอิน -> เปิดห้องแชทของคนนี้
    final chat = read<ChatProvider>();
    final conv = chat.openConversation(categoryId: 'general', staffId: 'st1');
    expect(conv.studentId, 'tester');
    chat.send(conv, 'สวัสดีค่ะ');
    await tester.pumpAndSettle();
    expect(chat.myConversations().contains(conv), isTrue);

    // เปลี่ยนเป็นเจ้าหน้าที่: ProxyProvider ส่ง Auth ใหม่ให้ Chat/Report
    read<AuthProvider>().logout();
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('login'), findsOneWidget);
    read<AuthProvider>().login(staff1.email, staff1.password);
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(chat.staffConversations().contains(conv), isTrue);

    // จบแชทพร้อมสรุป -> ReportProvider ได้แถวในตารางของเจ้าหน้าที่คนนี้
    chat.closeConversation(conv, topic: 'ทดสอบ', help: 'ตอบแล้ว');
    expect(
      read<ReportProvider>().myReports().any(
        (r) => r.conversationId == conv.id,
      ),
      isTrue,
    );

    read<AuthProvider>().logout();
    await tester.pumpAndSettle(const Duration(seconds: 1));
  });
}
