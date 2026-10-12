// Widget ที่ใช้ซ้ำหลายหน้า: การ์ดเมนูสีพีช, กระดิ่งแจ้งเตือน, รูปโปรไฟล์,
// หัวข้อของแต่ละขั้นตอน และฟังก์ชันแสดงเวลา
import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../data/models.dart';
import '../theme.dart';

/// การ์ดเมนูสีพีชที่ใช้ในทุกหน้าเลือก (หมวด / เรื่อง / รูปแบบการปรึกษา / เลือกพี่)
/// - ใส่ [icon] หรือ [leading] (เช่นรูปเจ้าหน้าที่) ได้ทางซ้าย
///   ถ้าไม่ใส่ทั้งคู่ ข้อความจะจัดกึ่งกลางเหมือนในไฟล์ UX/UI
/// - [badge] > 0 จะแสดงกระดิ่ง + ตัวเลขสีแดงที่มุมขวาบน (แจ้งเตือนฝั่งเจ้าหน้าที่)
/// - ไม่ใส่ [onTap] = กดไม่ได้ และจะไม่มีลูกศร >
class OrangeCard extends StatelessWidget {
  const OrangeCard({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.leading,
    this.badge = 0,
    this.onTap,
    this.color,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? leading;
  final int badge;
  final VoidCallback? onTap;

  /// สีพื้นการ์ด (ไม่ใส่ = สีพีชปกติ) เช่น หัวข้อเร่งด่วนใช้สีแดงอ่อน
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14, right: 8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: color ?? AppColors.peach,
            borderRadius: BorderRadius.circular(16),
            elevation: 0,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              child: Container(
                constraints: const BoxConstraints(minHeight: 78),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    if (leading != null) ...[
                      leading!,
                      const SizedBox(width: 14),
                    ],
                    if (leading == null && icon != null) ...[
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
                        crossAxisAlignment: (leading == null && icon == null)
                            ? CrossAxisAlignment.center
                            : CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            textAlign: (leading == null && icon == null)
                                ? TextAlign.center
                                : TextAlign.start,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle!,
                              textAlign: (leading == null && icon == null)
                                  ? TextAlign.center
                                  : TextAlign.start,
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
          if (badge > 0)
            Positioned(right: -8, top: -12, child: BellBadge(count: badge)),
        ],
      ),
    );
  }
}

/// กระดิ่งแจ้งเตือน + วงกลมแดงแสดงจำนวนข้อความที่ยังไม่อ่าน
/// มีแอนิเมชันเด้งตอนปรากฏ
class BellBadge extends StatelessWidget {
  const BellBadge({super.key, required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.6, end: 1),
      duration: const Duration(milliseconds: 400),
      curve: Curves.elasticOut,
      builder: (context, s, child) => Transform.scale(scale: s, child: child),
      child: SizedBox(
        width: 42,
        height: 42,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Transform.rotate(
              angle: -0.35,
              child: const Icon(
                Icons.notifications_rounded,
                size: 38,
                color: Color(0xFFF2A93B),
              ),
            ),
            Positioned(
              left: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                decoration: BoxDecoration(
                  color: AppColors.alert,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// รูปโปรไฟล์วงกลม
/// เจ้าหน้าที่ = รูปจริงจาก [AppStore.staffPhotos] (ถ้าไม่มีรูปใช้ emoji 👩🏻‍💼), นักศึกษา = รูปแมวไข่หวาน
class StaffAvatar extends StatelessWidget {
  const StaffAvatar({super.key, required this.user, this.size = 48});
  final AppUser user;
  final double size;

  @override
  Widget build(BuildContext context) {
    final emoji = Text('👩🏻‍💼', style: TextStyle(fontSize: size * 0.55));
    final photo = AppStore.staffPhotos[user.id];
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: user.avatarColor,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          // นักศึกษา (ผู้มาปรึกษา) ใช้รูปแมวไข่หวานทั้งหมด
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
              : ClipOval(
                  child: Image.asset(
                    kaiwanCatImage,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    alignment: const Alignment(0, -0.25),
                  ),
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

/// รูปแมวไข่หวาน (หน้าสมัครสมาชิก, License Agreement, รูปของแชทรวมเจ้าหน้าที่)
const kaiwanCatImage = 'assets/images/kaiwan_cat.png';

/// รูปแมวไข่หวานในกรอบวงกลม (ครอปให้ตัวแมวอยู่กลาง)
class CatAvatar extends StatelessWidget {
  const CatAvatar({super.key, this.size = 96});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.caramel.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          kaiwanCatImage,
          fit: BoxFit.cover,
          // รูปต้นฉบับแมวอยู่ค่อนไปทางบน เลื่อนจุดกึ่งกลางขึ้นเล็กน้อย
          alignment: const Alignment(0, -0.25),
        ),
      ),
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
