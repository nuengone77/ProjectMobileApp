// แปลงรหัสผ่านเป็น hash ก่อนเก็บลงฐานข้อมูล (ไม่เก็บรหัสผ่านตัวจริง)
import 'dart:convert';

import 'package:crypto/crypto.dart';

/// hash = sha256 ของ “kaiwan:<อีเมลตัวเล็ก>:<รหัสผ่าน>”
/// ใช้อีเมลเป็น salt ทำให้รหัสผ่านเดียวกันของต่างบัญชีได้ hash ไม่เหมือนกัน
String hashPassword(String email, String password) => sha256
    .convert(utf8.encode('kaiwan:${email.trim().toLowerCase()}:$password'))
    .toString();
