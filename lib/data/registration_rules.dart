// เงื่อนไขการลงทะเบียน (สมัครสมาชิก) ของนักศึกษา
//
// ตัวอย่างที่ถูกต้อง:
//   อีเมล       nanthitb67@nu.ac.th
//   ชื่ออังกฤษ  nanthit bunmee
//   รหัสนิสิต   67313318
//
// กติกา:
//   - อีเมลต้องเป็นอีเมลมหาลัย ลงท้ายด้วย @nu.ac.th
//   - อีเมล = ชื่อภาษาอังกฤษ + ตัวแรกของนามสกุลอังกฤษ + เลขปี 2 หลัก (66–69)
//     และเลขปีต้องตรงกับ 2 ตัวแรกของรหัสนิสิต
//   - รหัสนิสิต 8 หลัก: 2 ตัวแรก = ปีที่เข้าศึกษา (66–69), 2 ตัวถัดมา = คณะ ต้องเป็น 31 (วิทยาศาสตร์)
//   - ตัวอักษรภาษาอังกฤษแปลงเป็นตัวพิมพ์เล็กก่อนตรวจทุกครั้ง
//
// ทุกฟังก์ชันคืน null ถ้าผ่าน หรือคืนข้อความ error (ภาษาไทย) ไปแสดงใต้ช่องกรอก

class RegistrationRules {
  static const emailDomain = '@nu.ac.th';
  static const minYear = 66; // ปีที่เข้าศึกษาที่รับ (2 หลักของ พ.ศ.)
  static const maxYear = 69;
  static const scienceFacultyCode = '31'; // รหัสคณะวิทยาศาสตร์

  /// ตรวจรหัสนิสิต: 8 หลัก, ปี 66–69, คณะ 31
  static String? studentIdError(String? input) {
    final id = (input ?? '').trim();
    if (id.isEmpty) return 'กรุณากรอกรหัสนิสิต';
    if (!RegExp(r'^\d{8}$').hasMatch(id)) {
      return 'รหัสนิสิตต้องเป็นตัวเลข 8 หลัก';
    }
    final year = int.parse(id.substring(0, 2));
    if (year < minYear || year > maxYear) {
      return 'จำกัดให้ใช้แค่ปีการศึกษาแค่ 66-69 เท่านั้น';
    }
    if (id.substring(2, 4) != scienceFacultyCode) {
      return 'แอปนี้ใช้ได้เฉพาะนิสิตคณะวิทยาศาสตร์';
    }
    return null;
  }

  /// แยกชื่อ-นามสกุลภาษาอังกฤษ (ตัวพิมพ์เล็ก) คืน null ถ้ารูปแบบไม่ถูกต้อง
  /// ชื่อ = คำแรก, นามสกุล = คำสุดท้าย (เผื่อมีชื่อกลาง)
  static ({String first, String last})? parseNameEn(String? input) {
    final name = (input ?? '').trim().toLowerCase();
    if (!RegExp(r"^[a-z .'-]+$").hasMatch(name)) return null;
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length < 2) return null;
    // ตัดอักขระที่ไม่ใช่ a–z ออก (เช่น - หรือ ') ก่อนเอาไปเทียบกับอีเมล
    String letters(String s) => s.replaceAll(RegExp(r'[^a-z]'), '');
    final first = letters(parts.first);
    final last = letters(parts.last);
    if (first.isEmpty || last.isEmpty) return null;
    return (first: first, last: last);
  }

  /// ตรวจชื่อ-นามสกุลภาษาอังกฤษ: ตัวอักษรอังกฤษ และต้องมีทั้งชื่อและนามสกุล
  static String? nameEnError(String? input) {
    final name = (input ?? '').trim();
    if (name.isEmpty) return 'กรุณากรอกชื่อ-สกุลภาษาอังกฤษ';
    if (!RegExp(r"^[A-Za-z .'-]+$").hasMatch(name)) {
      return 'กรอกเป็นตัวอักษรภาษาอังกฤษ';
    }
    if (parseNameEn(name) == null) {
      return 'กรอกทั้งชื่อและนามสกุล';
    }
    return null;
  }

  /// ตรวจอีเมล (ต้องรู้ชื่ออังกฤษและรหัสนิสิตเพื่อเทียบกัน)
  /// ถ้าชื่อหรือรหัสยังผิดอยู่ จะข้ามการเทียบส่วนนั้น (error จะไปขึ้นที่ช่องนั้นเอง)
  static String? emailError(
    String? input, {
    required String nameEn,
    required String studentId,
  }) {
    final email = (input ?? '').trim().toLowerCase();
    if (email.isEmpty) return 'กรุณากรอกอีเมล';
    if (!email.endsWith(emailDomain) || email.length == emailDomain.length) {
      return 'โปรดใช้อีเมลของมหาลัยในการลงทะเบียน';
    }
    final local = email.substring(0, email.length - emailDomain.length);
    final m = RegExp(r'^([a-z]+)(\d{2})$').firstMatch(local);
    if (m == null) {
      return 'รูปแบบอีเมลไม่ถูกต้อง';
    }
    final letters = m.group(1)!;
    final year = int.parse(m.group(2)!);
    if (year < minYear || year > maxYear) {
      return 'เลขปีในอีเมลไม่ถูกต้อง';
    }
    final name = parseNameEn(nameEn);
    if (name != null) {
      final expected = '${name.first}${name.last[0]}';
      if (letters != expected) {
        return 'อีเมลไม่ตรงกับชื่อภาษาอังกฤษ';
      }
    }
    if (studentIdError(studentId) == null &&
        studentId.trim().substring(0, 2) != m.group(2)) {
      return 'เลขปีในอีเมลไม่ตรงกับรหัสนิสิต';
    }
    return null;
  }
}
