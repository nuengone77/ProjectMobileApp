// Widget ที่ใช้ซ้ำหลายหน้า: การ์ดเมนู, รูปโปรไฟล์, ป้ายกราฟิก, แผงเหลือง, กันออกจากฟอร์ม,
// หัวข้อของแต่ละขั้นตอน และฟังก์ชันแสดงเวลา
import 'package:flutter/material.dart';

import '../data/app_data.dart';
import '../data/models.dart';
import '../theme.dart';

/// การ์ดเมนูสีเหลืองเข้มที่ใช้ในทุกหน้าเลือก (หมวด / เรื่อง / รูปแบบการปรึกษา / เลือกพี่)
/// - ใส่ [icon], [iconAsset] (รูปไอคอน) หรือ [leading] (เช่นรูปเจ้าหน้าที่) ได้ทางซ้าย
/// - [label] = หัวข้อเล็กเหนือการ์ด (ตามแบบ)
///   ถ้าไม่ใส่เลย ข้อความจะจัดกึ่งกลาง
/// - ไม่ใส่ [onTap] = กดไม่ได้ และจะไม่มีลูกศร >
class MenuCard extends StatelessWidget {
  const MenuCard({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.leading,
    this.onTap,
    this.color,
    this.iconAsset,
    this.label,
  });

  /// รูปไอคอนจาก assets (ใช้แทน [icon]) เช่น รูปฟองแชท / ป้ายเตือน
  final String? iconAsset;

  /// หัวข้อเล็กเหนือการ์ด
  final String? label;

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? leading;
  final VoidCallback? onTap;

  /// สีพื้นการ์ด (ไม่ใส่ = เหลืองเข้มปกติ) เช่น หัวข้อเร่งด่วนใช้สีส้ม
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final hasLeading = leading != null || icon != null || iconAsset != null;
    final card = Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: color ?? AppColors.yellowDeep,
          borderRadius: BorderRadius.circular(24),
          elevation: 0,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: onTap,
            child: Container(
              constraints: const BoxConstraints(minHeight: 84),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                children: [
                  if (leading != null) ...[leading!, const SizedBox(width: 14)],
                  if (leading == null && iconAsset != null) ...[
                    Image.asset(iconAsset!, width: 46, height: 46),
                    const SizedBox(width: 14),
                  ],
                  if (leading == null && iconAsset == null && icon != null) ...[
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: AppColors.ink),
                    ),
                    const SizedBox(width: 14),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: hasLeading
                          ? CrossAxisAlignment.start
                          : CrossAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          textAlign: hasLeading
                              ? TextAlign.start
                              : TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            textAlign: hasLeading
                                ? TextAlign.start
                                : TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.ink.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (onTap != null)
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.ink.withValues(alpha: 0.5),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, right: 8),
      child: label == null
          ? card
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 6),
                  child: Text(
                    label!,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                card,
              ],
            ),
    );
  }
}

/// รูปโปรไฟล์วงกลม
/// เจ้าหน้าที่ = รูปจริงจาก [AppData.staffPhotos] (ถ้าไม่มีรูปใช้ emoji 👩🏻‍💼)
/// นักศึกษา = รูปแมวโบกมือ [studentAvatarImage] บนพื้นขาว (เห็นเฉพาะฝั่งเจ้าหน้าที่:
/// รายการแชท หัวห้องแชท บับเบิล และแผ่นโปรไฟล์นิสิต)
class StaffAvatar extends StatelessWidget {
  const StaffAvatar({super.key, required this.user, this.size = 48});
  final AppUser user;
  final double size;

  @override
  Widget build(BuildContext context) {
    final emoji = Text('👩🏻‍💼', style: TextStyle(fontSize: size * 0.55));
    final photo = AppData.staffPhotos[user.id];
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: user.isStaff ? user.avatarColor : AppColors.surface,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          // นักศึกษา (ผู้มาปรึกษา) ใช้รูปแมวโบกมือทั้งหมด
          // เจ้าหน้าที่ใช้รูปจริง ถ้าไม่มีรูป (หรือโหลดไม่ได้) ใช้ emoji แทน
          child: user.isStaff
              ? (photo == null
                    ? emoji
                    : ClipOval(
                        child: Image.asset(
                          photo,
                          width: size,
                          height: size,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => emoji,
                        ),
                      ))
              : Padding(
                  padding: EdgeInsets.all(size * 0.08),
                  child: Image.asset(studentAvatarImage),
                ),
        ),
      ],
    );
  }
}

/// หัวข้อใหญ่ + คำอธิบายเล็กด้านบนของหน้าเลือก เช่น “ขั้นที่ 1 จาก 2”
class StepHeader extends StatelessWidget {
  const StepHeader({super.key, required this.title, this.caption});
  final String title;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 6),
            Text(
              caption!,
              style: const TextStyle(fontSize: 14, color: AppColors.muted),
            ),
          ],
        ],
      ),
    );
  }
}

/// แปลงเวลาเป็นข้อความ: วันนี้แสดงแค่ “14:05”, วันอื่นแสดง “7/10 14:05”
String timeLabel(DateTime t) {
  final now = DateTime.now();
  final hm =
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  if (now.difference(t).inHours < 24 && now.day == t.day) return hm;
  return '${t.day}/${t.month} $hm';
}

const _thaiDays = ['จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.', 'ส.', 'อา.'];
const _thaiMonths = [
  'ม.ค.',
  'ก.พ.',
  'มี.ค.',
  'เม.ย.',
  'พ.ค.',
  'มิ.ย.',
  'ก.ค.',
  'ส.ค.',
  'ก.ย.',
  'ต.ค.',
  'พ.ย.',
  'ธ.ค.',
];

/// วันที่แบบไทย (ปี พ.ศ.) เช่น “ศ. 9 ต.ค. 2569”
String thaiDate(DateTime d) =>
    '${_thaiDays[d.weekday - 1]} ${d.day} ${_thaiMonths[d.month - 1]} ${d.year + 543}';

/// ช่วงเวลานัด 30 นาที เช่น “10:00–10:30”
String timeRange(DateTime start) {
  String hm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  return '${hm(start)}–${hm(start.add(const Duration(minutes: 30)))}';
}

/// รูปแมวไข่หวาน: รูปของ “แชทรวมเจ้าหน้าที่” ที่นิสิตเห็น (ใช้ผ่าน [CatAvatar])
const kaiwanCatImage = 'assets/images/banner_kaiwan_logo.png';

/// รูปแมวโบกมือ: รูปโปรไฟล์ของนิสิต (ใช้ผ่าน [StaffAvatar] และหน้าโปรไฟล์นิสิต)
const studentAvatarImage = 'assets/images/cat_wave.png';

/// รูปแมวไข่หวานในกรอบวงกลม (ครอปให้ตัวแมวอยู่กลาง)
class CatAvatar extends StatelessWidget {
  const CatAvatar({super.key, this.size = 96});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      // พื้นวงกลมสีขาว แมวอยู่กลางวง เห็นครบทั้งตัว (รูปครอปเป็นสี่เหลี่ยมจัตุรัสแล้ว)
      padding: EdgeInsets.all(size * 0.1),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
      ),
      child: Image.asset(kaiwanCatImage, fit: BoxFit.contain),
    );
  }
}

const _thaiMonthsFull = [
  'มกราคม',
  'กุมภาพันธ์',
  'มีนาคม',
  'เมษายน',
  'พฤษภาคม',
  'มิถุนายน',
  'กรกฎาคม',
  'สิงหาคม',
  'กันยายน',
  'ตุลาคม',
  'พฤศจิกายน',
  'ธันวาคม',
];

/// เดือนและปีแบบไทย (พ.ศ.) เช่น “ตุลาคม 2569”
String thaiMonthYear(DateTime d) =>
    '${_thaiMonthsFull[d.month - 1]} ${d.year + 543}';

/// วันที่แบบสั้นไม่มีชื่อวัน เช่น “9 ต.ค. 2569”
String thaiDateShort(DateTime d) =>
    '${d.day} ${_thaiMonths[d.month - 1]} ${d.year + 543}';

/// สัญญาณให้โครงหลัก (StudentShell / StaffShell) สลับกลับไปแท็บแรก
/// เพิ่มค่าเมื่อกดปุ่มกลับหน้าหลัก แล้ว Shell ที่ฟังอยู่จะตั้งแท็บเป็น 0
final homeTabSignal = ValueNotifier<int>(0);

/// ปิดทุกหน้าที่ซ้อนอยู่ แล้วกลับไปแท็บแรกของแอป
void goHome(BuildContext context) {
  Navigator.of(context).popUntil((r) => r.isFirst);
  homeTabSignal.value++;
}

/// ปุ่มบ้านมุมขวาบนของ AppBar: กดแล้วกลับหน้าหลักทันที
class HomeButton extends StatelessWidget {
  const HomeButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'กลับหน้าหลัก',
    icon: const Icon(Icons.home_outlined),
    onPressed: () => goHome(context),
  );
}

/// แผงสีเหลืองที่ขอบบนโค้งขึ้นเป็นเนิน (หน้า Login / สมัครสมาชิก ตามแบบ)
class YellowArcPanel extends StatelessWidget {
  const YellowArcPanel({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _ArcTopClipper(),
      child: Container(
        width: double.infinity,
        color: AppColors.yellow,
        padding: const EdgeInsets.fromLTRB(28, 64, 28, 28),
        child: child,
      ),
    );
  }
}

/// ตัดขอบบนเป็นเส้นโค้ง: มุมซ้าย/ขวาต่ำกว่า กลางนูนขึ้น
class _ArcTopClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const rise = 44.0;
    return Path()
      ..moveTo(0, rise)
      ..quadraticBezierTo(size.width / 2, -rise, size.width, rise)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// ปุ่มหลักทรงแคปซูลสีดำ ความกว้างพอดีข้อความ (ปุ่ม login / sign in / ยอมรับ)
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.color = AppColors.black,
    this.foreground = Colors.white,
  });
  final VoidCallback? onPressed;
  final Widget child;
  final Color color;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: foreground,
        minimumSize: const Size(180, 48),
        padding: const EdgeInsets.symmetric(horizontal: 36),
      ),
      onPressed: onPressed,
      child: child,
    );
  }
}

/// ป้ายกราฟิกด้านบนของหน้า (เช่น “ทุกปัญหา มีคนรับฟังเสมอ”) มุมโค้ง กว้างเต็มแถว
class AppBanner extends StatelessWidget {
  const AppBanner({super.key, required this.image});
  final String image;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.asset(image, width: double.infinity, fit: BoxFit.fitWidth),
    );
  }
}

/// กันออกจากฟอร์มที่กรอกค้างไว้โดยไม่ตั้งใจ (บทที่ 9: PopScope)
/// - [isDirty] = กรอกอะไรไปแล้วหรือยัง; ถ้ายังไม่กรอกก็ย้อนกลับได้ปกติ (ปัดขอบจอได้)
/// - ถ้ากรอกแล้ว กดย้อนกลับจะถามก่อนว่า “ทิ้งข้อมูลที่กรอกไว้ไหม?”
/// - [listenable] = ตัวที่เปลี่ยนเมื่อผู้ใช้พิมพ์ (เช่น TextEditingController หลายตัวรวมกัน)
///   ใช้ให้ค่า canPop อัปเดตทันทีตอนพิมพ์
class UnsavedChangesGuard extends StatelessWidget {
  const UnsavedChangesGuard({
    super.key,
    required this.isDirty,
    required this.child,
    this.listenable,
  });
  final bool Function() isDirty;
  final Listenable? listenable;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    Widget guard(BuildContext context) => PopScope(
      // canPop: false = ยังไม่ให้ออก ระบบจะเรียก onPopInvokedWithResult ให้เราตัดสินใจเอง
      canPop: !isDirty(),
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return; // ออกไปแล้ว (ฟอร์มว่าง)
        final leave = await confirmDiscard(context);
        if (leave && context.mounted) Navigator.of(context).pop();
      },
      child: child,
    );
    final l = listenable;
    return l == null
        ? guard(context)
        : ListenableBuilder(listenable: l, builder: (c, _) => guard(c));
  }
}

/// หน้าต่างถาม “ทิ้งข้อมูลที่กรอกไว้ไหม?” คืน true = ทิ้งแล้วออก
Future<bool> confirmDiscard(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: const Text('ทิ้งข้อมูลที่กรอกไว้ไหม?'),
      content: const Text('ข้อมูลที่กรอกในหน้านี้จะไม่ถูกบันทึก'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c, false),
          child: const Text('กรอกต่อ'),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: AppColors.alert),
          onPressed: () => Navigator.pop(c, true),
          child: const Text('ทิ้งข้อมูล'),
        ),
      ],
    ),
  );
  return ok ?? false;
}
