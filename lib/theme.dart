import 'package:flutter/material.dart';

/// ชุดสีกลางของแอป เปลี่ยนที่นี่ที่เดียวแล้วมีผลทุกหน้า
/// ธีม: เหลือง – ดำ – ขาว และส้ม (ส้มใช้เฉพาะเรื่องเร่งด่วนเท่านั้น)
/// อ้างอิงแบบ: ~/Downloads/อธิบายการเปลี่ยนธีม/รูปแบบ Ui_UX ที่จะเปลี่ยน.pdf
class AppColors {
  // ---- โทนเหลืองหลัก (โค้ดสีตามแบบ)
  static const yellow = Color(
    0xFFFFD26F,
  ); // พื้นหลังส่วนล่างหน้า login/สมัคร, แถบกรอง, ปุ่มรอง
  static const yellowDeep = Color(0xFFFFDF60); // การ์ดเมนูหลัก (เหลืองเข้ม)
  static const yellowLight = Color(
    0xFFFFF0B3,
  ); // การ์ดเรื่องทั่วไป (เหลืองอ่อน)
  static const orange = Color(0xFFFB8600); // เฉพาะเรื่องเร่งด่วน

  // ---- พื้นหลัง / พื้นผิว
  static const cream = Color(0xFFFFF8E8); // พื้นหลังหน้าทั่วไป
  static const surface = Color(
    0xFFFFFFFF,
  ); // การ์ด/แถบ/แผ่นเลื่อน/ช่องกรอก (ขาว)
  static const peach = yellowDeep; // การ์ดเมนู (OrangeCard) ใช้เหลืองเข้ม
  static const line = Color(0xFFF1E3BF); // เส้นขอบ/เส้นคั่นสีอ่อน
  static const field = Color(0xFFFFF4D6); // พื้นช่องพิมพ์ข้อความในแชท

  // ---- สีหลัก
  static const honey = yellow; // ตัวที่ถูกเลือก/ไฮไลต์/แถบเมนูที่เลือก
  static const caramel = Color(
    0xFF1C1C1C,
  ); // ดำ: ปุ่มหลัก ลิงก์ ไอคอน บับเบิลแชทฝั่งเรา
  static const ink = Color(0xFF1C1C1C); // ดำ: ตัวอักษรหลัก/หัวข้อ
  static const muted = Color(0xFF7D7466); // เทาอมน้ำตาล: ตัวอักษรรอง/คำอธิบาย

  // ---- แชท
  static const bubbleOther = yellowLight; // บับเบิลแชทฝั่งอีกคน

  // ---- สีที่มีความหมาย
  static const alert = Color(0xFFE53935); // แดง: error / ปุ่มออกจากระบบ / ลบ
  static const info = Color(0xFF1C1C1C); // ตัวเลขเรื่องทั่วไป (หน้าภาพรวม)
  static const urgentSoft =
      orange; // พื้นหลังห้อง/การ์ดเร่งด่วน (ฝั่งเจ้าหน้าที่)
  static const generalSoft =
      yellowLight; // พื้นหลังห้อง/การ์ดเรื่องทั่วไป (ฝั่งเจ้าหน้าที่)
}

/// ธีมหลักของแอป (Material 3)
/// - ช่องกรอกข้อมูลเป็นทรงแคปซูลพื้นขาวขอบดำ
/// - ปุ่มหลัก (FilledButton) สีดำ ตัวอักษรขาว มุมโค้งเต็ม
ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.yellow,
    primary: AppColors.caramel,
    secondary: AppColors.yellow,
    surface: AppColors.surface,
    // เส้นขอบปุ่มกรอง/เส้นคั่นใช้สีนี้
    outline: AppColors.ink,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.cream,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.cream,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.yellow,
    ),
    // แถบกรอง ทั้งหมด/ส่วนรวม/ส่วนตัว: พื้นเหลือง ตัวที่เลือกเหลืองเข้มขึ้น ไม่มีขอบดำ
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        backgroundColor: AppColors.yellow.withValues(alpha: 0.55),
        foregroundColor: AppColors.ink,
        selectedBackgroundColor: AppColors.yellow,
        selectedForegroundColor: AppColors.ink,
        side: const BorderSide(color: Color(0x33000000)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.yellow,
      foregroundColor: AppColors.ink,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(40),
        borderSide: const BorderSide(color: AppColors.ink, width: 1.4),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(40),
        borderSide: const BorderSide(color: AppColors.ink, width: 1.4),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(40),
        borderSide: const BorderSide(color: AppColors.ink, width: 2.4),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.caramel,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.caramel),
    ),
  );
}
