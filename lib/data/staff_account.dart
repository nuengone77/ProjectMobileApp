// บัญชีเจ้าหน้าที่ที่สร้างไว้ให้ตอนเปิดแอปครั้งแรก (เจ้าหน้าที่สมัครเองไม่ได้)
//
// บัญชีจริง (อีเมล/รหัสผ่าน/ชื่อ) อยู่ในไฟล์ assets/config/staff_accounts.json
// ซึ่ง “ไม่ได้ commit” (อยู่ใน .gitignore) เพราะมีรหัสผ่าน — ส่งให้กันทางช่องทางส่วนตัว
// ถ้าเครื่องไหนไม่มีไฟล์นี้ แอปใช้บัญชีตัวอย่าง [StaffAccount.samples] แทน จึงรันได้เสมอ
// รูปแบบไฟล์ดูได้ที่ assets/config/staff_accounts.sample.json
import 'dart:convert';

import 'package:flutter/services.dart';

class StaffAccount {
  const StaffAccount({
    required this.email,
    required this.password,
    required this.name,
    required this.nickname,
  });

  final String email;

  /// รหัสผ่านตั้งต้น (ตอนบันทึกลงฐานข้อมูลจะเก็บเป็น hash เท่านั้น)
  final String password;

  /// ชื่อ-สกุลเจ้าหน้าที่
  final String name;

  /// ชื่อที่แสดงในแอป จะขึ้นเป็น "พี่ไข่หวาน" ตามด้วย nickname เช่น พี่ไข่หวาน มะนาว
  final String nickname;

  /// แปลงข้อมูล JSON 1 คน ({"email": ..., "password": ..., "name": ..., "nickname": ...})
  /// เป็น [StaffAccount] แบบเดียวกับ Map -> Model ในบทที่ 12–13
  factory StaffAccount.fromJson(Map<String, dynamic> json) => StaffAccount(
    email: json['email'] as String,
    password: json['password'] as String,
    name: json['name'] as String,
    nickname: json['nickname'] as String,
  );

  /// ที่อยู่ไฟล์บัญชีจริงใน assets (ประกาศโฟลเดอร์ assets/config/ ไว้ใน pubspec.yaml)
  static const assetPath = 'assets/config/staff_accounts.json';

  /// บัญชีตัวอย่าง ใช้เมื่อไม่มีไฟล์บัญชีจริง (เช่น เพิ่ง clone repo) และใช้ในเทสต์
  static const samples = [
    StaffAccount(
      email: 'staff1@nu.ac.th',
      password: 'changeme1',
      name: 'เจ้าหน้าที่คนที่ 1',
      nickname: '1',
    ),
    StaffAccount(
      email: 'staff2@nu.ac.th',
      password: 'changeme2',
      name: 'เจ้าหน้าที่คนที่ 2',
      nickname: '2',
    ),
    StaffAccount(
      email: 'staff3@nu.ac.th',
      password: 'changeme3',
      name: 'เจ้าหน้าที่คนที่ 3',
      nickname: '3',
    ),
  ];

  /// อ่านบัญชีเจ้าหน้าที่จากไฟล์ JSON ใน assets (งานอสมวาร บทที่ 12)
  /// ไม่มีไฟล์ / อ่านไม่ได้ / รูปแบบผิด -> ใช้ [samples] แทน แอปจึงไม่พัง
  static Future<List<StaffAccount>> load([AssetBundle? bundle]) async {
    try {
      final text = await (bundle ?? rootBundle).loadString(assetPath);
      final list = jsonDecode(text) as List<dynamic>;
      final accounts = [
        for (final item in list)
          StaffAccount.fromJson(item as Map<String, dynamic>),
      ];
      return accounts.isEmpty ? samples : accounts;
    } catch (e) {
      // ignore: avoid_print
      print('ไม่พบหรืออ่านไฟล์ $assetPath ไม่ได้ ใช้บัญชีตัวอย่างแทน ($e)');
      return samples;
    }
  }
}
