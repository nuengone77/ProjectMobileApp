// รวม Provider ทุกตัวของแอปไว้ที่เดียว (บทที่ 11: MultiProvider + ChangeNotifierProxyProvider)
//
// ลำดับสำคัญ: ตัวที่ถูกพึ่งพาต้องประกาศก่อน
//   1. AuthProvider            ใครล็อกอินอยู่ (ไม่พึ่งใคร)
//   2. ReportProvider          พึ่ง Auth (ตารางของเจ้าหน้าที่คนไหน)
//   3. AppointmentProvider     พึ่ง Auth (นัดของใคร)
//   4. ChatProvider            พึ่ง Auth + Report (จบแชทแล้วสร้างแถวในตารางสรุปเคส)
// ProxyProvider: เมื่อ Provider ที่พึ่งอยู่เปลี่ยน (เช่น ล็อกอินคนใหม่) จะเรียก update(...)
// ให้ Provider ตัวนั้นรู้และแจ้งหน้าจอให้วาดใหม่
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../data/app_data.dart';
import 'appointment_provider.dart';
import 'auth_provider.dart';
import 'chat_provider.dart';
import 'report_provider.dart';

class AppProviders extends StatelessWidget {
  const AppProviders({super.key, required this.data, required this.child});

  /// ข้อมูลกลางที่เปิดจาก SQLite แล้ว (AppData.open ใน main.dart)
  final AppData data;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ข้อมูลกลาง (ไม่ใช่ ChangeNotifier) ให้หน้าจอ/Provider อื่นอ่านได้
        Provider<AppData>.value(value: data),
        ChangeNotifierProvider(create: (_) => AuthProvider(data)),
        ChangeNotifierProxyProvider<AuthProvider, ReportProvider>(
          create: (context) =>
              ReportProvider(data, context.read<AuthProvider>()),
          update: (_, auth, reports) => reports!..update(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, AppointmentProvider>(
          create: (context) =>
              AppointmentProvider(data, context.read<AuthProvider>()),
          update: (_, auth, appts) => appts!..update(auth),
        ),
        ChangeNotifierProxyProvider2<
          AuthProvider,
          ReportProvider,
          ChatProvider
        >(
          create: (context) => ChatProvider(
            data,
            context.read<AuthProvider>(),
            context.read<ReportProvider>(),
          ),
          update: (_, auth, reports, chat) => chat!..update(auth, reports),
        ),
      ],
      child: child,
    );
  }
}
