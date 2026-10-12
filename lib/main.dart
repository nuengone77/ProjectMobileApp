// จุดเริ่มต้นของแอป "ไข่หวานช่วยด้วย" (ข้อมูลเก็บใน SQLite บนเครื่อง)
//
// โครงสร้างโฟลเดอร์:
//   lib/data/     ข้อมูลและ logic (models + AppStore + ฐานข้อมูล SQLite)
//   lib/screens/  หน้าจอแต่ละส่วน (login, นักศึกษา, เจ้าหน้าที่, แชท, โปรไฟล์)
//   lib/widgets/  widget ที่ใช้ซ้ำหลายหน้า (การ์ดเมนูสีพีช, กระดิ่งแจ้งเตือน, avatar)
//   lib/theme.dart สี ฟอนต์ และสไตล์กลางของทั้งแอป
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/attachments.dart';
import 'data/app_store.dart';
import 'screens/auth_screens.dart';
import 'screens/staff_screens.dart';
import 'screens/student_screens.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // เปิดฐานข้อมูล SQLite และโหลดข้อมูล (รวมถึงผู้ที่ล็อกอินค้างไว้) ก่อนแสดงหน้าแรก
  await Attachments.init();
  store = await AppStore.open();
  // รีเซ็ตข้อมูลทดลอง: รันด้วย flutter run --dart-define=RESET_DB=true
  // ไม่มีปุ่มในแอปให้ผู้ใช้กด
  if (const bool.fromEnvironment('RESET_DB')) {
    store.resetData();
    await store.flush();
  }
  // บันทึกลงฐานข้อมูลไม่สำเร็จ (เช่น พื้นที่เครื่องเต็ม) -> แจ้งผู้ใช้ด้วยแถบล่างจอ ไม่เงียบหายไปเฉยๆ
  store.onSaveFailed = (_) => appMessengerKey.currentState
    ?..hideCurrentSnackBar()
    ..showSnackBar(
      const SnackBar(
        content: Text(
          'บันทึกข้อมูลไม่สำเร็จ กรุณาลองใหม่ '
          '(ข้อมูลล่าสุดอาจหายเมื่อปิดแอป)',
        ),
      ),
    );
  runApp(const KaiwanApp());
}

/// ใช้แสดงแถบแจ้งเตือน (SnackBar) จากนอกหน้าจอ เช่น ตอนบันทึกข้อมูลไม่สำเร็จ
final appMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Widget รากของแอป: ตั้งค่าธีมและกำหนดหน้าแรกเป็น [_RoleGate]
class KaiwanApp extends StatelessWidget {
  const KaiwanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ไข่หวานช่วยด้วย',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: appMessengerKey,
      theme: buildTheme(),
      // ภาษาไทยสำหรับ widget มาตรฐาน (เช่น ปฏิทินเลือกวันนัดหมาย)
      locale: const Locale('th'),
      supportedLocales: const [Locale('th'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const _RoleGate(),
    );
  }
}

/// ตัวสลับหน้าตามสถานะการล็อกอิน:
/// - ยังไม่ล็อกอิน      -> หน้า Login
/// - ล็อกอินเป็นเจ้าหน้าที่ -> [StaffShell] (แอปฝั่งเจ้าหน้าที่)
/// - ล็อกอินเป็นนักศึกษา  -> [StudentShell] (แอปฝั่งนักศึกษา)
/// ฟังการเปลี่ยนแปลงจาก `store` จึงสลับหน้าเองทันทีเมื่อ login/logout
class _RoleGate extends StatelessWidget {
  const _RoleGate();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final me = store.currentUser;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: me == null
              ? const LoginScreen(key: ValueKey('login'))
              : me.isStaff
              ? StaffShell(key: ValueKey('staff-${me.id}'))
              : StudentShell(key: ValueKey('student-${me.id}')),
        );
      },
    );
  }
}
