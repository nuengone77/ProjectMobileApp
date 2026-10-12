// จุดเริ่มต้นของแอป "ไข่หวานช่วยด้วย" (ข้อมูลเก็บใน SQLite บนเครื่อง)
//
// โครงสร้างโฟลเดอร์:
//   lib/data/      ข้อมูลกลาง (AppData), models, ฐานข้อมูล SQLite, กติกาการสมัคร
//   lib/providers/ Provider แยกตามฟีเจอร์ (Auth / Chat / Appointment / Report) บทที่ 10–11
//   lib/screens/  หน้าจอแต่ละส่วน (login, นักศึกษา, เจ้าหน้าที่, แชท, โปรไฟล์)
//   lib/widgets/  widget ที่ใช้ซ้ำหลายหน้า (การ์ดเมนูสีพีช, กระดิ่งแจ้งเตือน, avatar)
//   lib/theme.dart สี ฟอนต์ และสไตล์กลางของทั้งแอป
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'data/attachments.dart';
import 'data/app_data.dart';
import 'providers/app_providers.dart';
import 'providers/auth_provider.dart';
import 'screens/auth_screens.dart';
import 'screens/staff_screens.dart';
import 'screens/student_screens.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // ไม่รอโหลดข้อมูลก่อน runApp: ให้ [AppStartup] แสดงหน้า “กำลังโหลด” ด้วย FutureBuilder (บทที่ 12)
  runApp(const AppStartup());
}

/// เปิดฐานข้อมูล SQLite และโหลดข้อมูลทั้งหมด (รวมถึงผู้ที่ล็อกอินค้างไว้)
/// เป็นงานอสมวาร (async) ใช้เวลาสักครู่ จึงรอด้วย FutureBuilder ใน [AppStartup]
Future<AppData> loadAppData() async {
  await Attachments.init();
  final data = await AppData.open();
  // รีเซ็ตข้อมูลทดลอง: รันด้วย flutter run --dart-define=RESET_DB=true
  // ไม่มีปุ่มในแอปให้ผู้ใช้กด
  if (const bool.fromEnvironment('RESET_DB')) {
    data.resetData();
    await data.flush();
  }
  // บันทึกลงฐานข้อมูลไม่สำเร็จ (เช่น พื้นที่เครื่องเต็ม) -> แจ้งผู้ใช้ด้วยแถบล่างจอ ไม่เงียบหายไปเฉยๆ
  data.onSaveFailed = (_) => appMessengerKey.currentState
    ?..hideCurrentSnackBar()
    ..showSnackBar(
      const SnackBar(
        content: Text(
          'บันทึกข้อมูลไม่สำเร็จ กรุณาลองใหม่ '
          '(ข้อมูลล่าสุดอาจหายเมื่อปิดแอป)',
        ),
      ),
    );
  return data;
}

/// หน้าเริ่มแอป: รอโหลดข้อมูลด้วย FutureBuilder (บทที่ 12)
/// - กำลังโหลด -> โลโก้ + วงกลมหมุน
/// - โหลดไม่สำเร็จ -> ข้อความ error + ปุ่มลองใหม่
/// - สำเร็จ -> เข้าแอป ([KaiwanApp])
class AppStartup extends StatefulWidget {
  const AppStartup({super.key, this.load = loadAppData});

  /// ฟังก์ชันโหลดข้อมูล (เปลี่ยนได้ตอนทดสอบ)
  final Future<AppData> Function() load;

  @override
  State<AppStartup> createState() => _AppStartupState();
}

class _AppStartupState extends State<AppStartup> {
  // สร้าง Future ครั้งเดียวตอนสร้าง State (ห้ามสร้างใน build ไม่งั้นจะโหลดซ้ำทุกครั้งที่วาดใหม่)
  late Future<AppData> _future = widget.load();

  /// ลองโหลดใหม่ (ปุ่ม “ลองใหม่” ตอน error)
  void _retry() {
    setState(() {
      _future = widget.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasData) return KaiwanApp(data: snapshot.data!);
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildTheme(),
          home: Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/images/login_logo.png', height: 120),
                    const SizedBox(height: 28),
                    if (snapshot.hasError) ...[
                      const Text(
                        'เปิดข้อมูลไม่สำเร็จ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.muted),
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _retry,
                        child: const Text('ลองใหม่'),
                      ),
                    ] else ...[
                      const CircularProgressIndicator(color: AppColors.caramel),
                      const SizedBox(height: 14),
                      const Text('กำลังโหลด...'),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// ใช้แสดงแถบแจ้งเตือน (SnackBar) จากนอกหน้าจอ เช่น ตอนบันทึกข้อมูลไม่สำเร็จ
final appMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Widget รากของแอป: ครอบด้วย Provider ทุกตัว ([AppProviders]) แล้วแสดง [KaiwanMaterialApp]
class KaiwanApp extends StatelessWidget {
  const KaiwanApp({super.key, required this.data});
  final AppData data;

  @override
  Widget build(BuildContext context) =>
      AppProviders(data: data, child: const KaiwanMaterialApp());
}

/// MaterialApp ของแอป (ธีม ภาษา หน้าแรก) อ่านข้อมูลจาก Provider ที่ครอบอยู่ด้านบน
class KaiwanMaterialApp extends StatelessWidget {
  const KaiwanMaterialApp({super.key});

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
/// ใช้ `context.watch<AuthProvider>()` (บทที่ 10) จึงสลับหน้าเองทันทีเมื่อ login/logout
class _RoleGate extends StatelessWidget {
  const _RoleGate();

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthProvider>().currentUser;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: me == null
          ? const LoginScreen(key: ValueKey('login'))
          : me.isStaff
          ? StaffShell(key: ValueKey('staff-${me.id}'))
          : StudentShell(key: ValueKey('student-${me.id}')),
    );
  }
}
