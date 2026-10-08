import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kaiwan_chuaiduai/data/mock_store.dart';
import 'package:kaiwan_chuaiduai/main.dart';

void main() {
  testWidgets('student consults, staff sees the message', (tester) async {
    await tester.pumpWidget(const KaiwanApp());
    expect(find.text('ไข่หวานช่วยได้'), findsOneWidget);

    // log in as the demo student
    await tester.tap(find.text('นักศึกษา'));
    await tester.tap(find.text('login'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('กยศ'), findsOneWidget);

    // กยศ -> subtopic -> specific staff -> พี่ไข่หวาน แอน -> chat
    await tester.tap(find.text('กยศ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('สอบถามการเซ็นเอกสาร'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.text('ปรึกษากับพี่ไข่หวาน\n(เจ้าหน้าที่แบบเลือกเฉพาะเจาะจง)'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('พี่ไข่หวาน แอน'));
    await tester.pumpAndSettle();

    store.setAutoReply(false);
    await tester.enterText(find.byType(TextField), 'ทดสอบข้อความ');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('ทดสอบข้อความ'), findsOneWidget);

    // staff แอน should now have an unread specific message for this topic
    store.logout();
    store.login('staff1@kaiwan.ac.th', '1234');
    final convs = store.staffConversations(
      categoryId: 'loan',
      subtopic: 'สอบถามการเซ็นเอกสาร',
      specific: true,
    );
    expect(
      convs.any((c) => c.studentId == 'stu1' && store.unreadForStaff(c) == 1),
      isTrue,
    );
    // and other staff can't see it
    store.logout();
    store.login('staff2@kaiwan.ac.th', '1234');
    expect(
      store.staffConversations(categoryId: 'loan', specific: true),
      isEmpty,
    );
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });
}
