import 'package:flutter/material.dart';

/// ชุดสีกลางของแอป เปลี่ยนที่นี่ที่เดียวแล้วมีผลทุกหน้า
/// ธีม: ครีม–น้ำตาล–เหลืองทอง (อ้างอิงสีจาก design/theme_reference.webp)
class AppColors {
  // ---- พื้นหลัง / พื้นผิว
  static const cream = Color(0xFFFEF6E9); // พื้นหลังหน้าทั่วไป
  static const surface = Color(0xFFFFFAF4); // การ์ด/แถบ/แผ่นเลื่อน (ขาวอมครีม)
  static const peach = Color(0xFFFCE3BE); // การ์ดเมนู (OrangeCard)
  static const line = Color(0xFFEADBC8); // เส้นขอบ/เส้นคั่นสีอ่อน
  static const field = Color(0xFFF6EDE1); // พื้นช่องพิมพ์ข้อความในแชท

  // ---- สีหลัก
  static const honey = Color(
    0xFFF5C26B,
  ); // เหลืองทอง: ตัวที่ถูกเลือก/ไฮไลต์/แถบเมนูที่เลือก
  static const caramel = Color(
    0xFF9A6740,
  ); // น้ำตาล: ปุ่มหลัก ลิงก์ ไอคอน บับเบิลแชทฝั่งเรา
  static const ink = Color(0xFF4A3426); // น้ำตาลเข้ม: ตัวอักษรหลัก/หัวข้อ
  static const muted = Color(0xFF9C8670); // ตัวอักษรรอง/คำอธิบาย

  // ---- แชท
  static const bubbleOther = Color(
    0xFFF3E6D3,
  ); // บับเบิลแชทฝั่งอีกคน (ครีมเข้ม)

  // ---- สีที่มีความหมาย (คงไว้ตามที่ตกลง ไม่เปลี่ยนตามธีม)
  static const alert = Color(0xFFE53935); // แดง: แจ้งเตือน/เร่งด่วน/error
  static const info = Color(
    0xFF2F7FD1,
  ); // น้ำเงิน: ตัวเลขให้คำปรึกษาทั่วไป (หน้าภาพรวม)
  // แดงอ่อน: พื้นหลังหัวข้อ/ห้องเร่งด่วน
  static const urgentSoft = Color(0xFFFFD9D6);
  // เขียวอ่อน: พื้นหลังแชทถาม/ตอบทั่วไป (ฝั่งเจ้าหน้าที่)
  static const generalSoft = Color(0xFFE2F3DF);
}

/// ธีมหลักของแอป (Material 3)
/// - ช่องกรอกข้อมูลเป็นทรงแคปซูลขอบน้ำตาลเข้ม ตามแบบหน้า Login
/// - ปุ่มหลัก (FilledButton) สีน้ำตาล ตัวอักษรขาว มุมโค้งเต็ม
ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.honey,
    primary: AppColors.caramel,
    surface: AppColors.surface,
    // เส้นขอบปุ่มกรอง/เส้นคั่นรายการแชทเจ้าหน้าที่ใช้สีนี้
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
      indicatorColor: AppColors.honey,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: AppColors.honey.withValues(alpha: 0.45),
        selectedForegroundColor: AppColors.ink,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(40),
        borderSide: const BorderSide(color: AppColors.ink, width: 1.6),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(40),
        borderSide: const BorderSide(color: AppColors.ink, width: 1.6),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(40),
        borderSide: const BorderSide(color: AppColors.honey, width: 2.4),
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
