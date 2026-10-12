// การ์ดเบอร์ฉุกเฉินในแชทเร่งด่วน (แตะแล้วเปิดหน้าโทรออก)
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/app_data.dart';
import '../../theme.dart';

/// การ์ดแจ้งเตือนสำคัญสีส้มกลางแชท (เบอร์ฉุกเฉินในแชทเร่งด่วน แตะเพื่อโทร)
class EmergencyCard extends StatelessWidget {
  const EmergencyCard({super.key, required this.text});
  final String text;

  /// แตะการ์ด -> เปิดหน้าโทรออกพร้อมเบอร์ฉุกเฉิน (ผู้ใช้กดโทรเองอีกที)
  /// iOS Simulator ไม่มีแอปโทรศัพท์ จึงโทรไม่ได้ จะขึ้นข้อความแจ้งแทน
  Future<void> _call(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    var ok = false;
    try {
      ok = await launchUrl(Uri(scheme: 'tel', path: AppData.emergencyPhone));
    } catch (_) {}
    if (!ok) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'อุปกรณ์นี้โทรออกไม่ได้ กรุณาโทร ${AppData.emergencyPhone}',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Material(
        color: AppColors.orange,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: const BorderSide(color: AppColors.orange),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: () => _call(context),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(Icons.phone_in_talk_rounded, color: AppColors.ink),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        text,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                      const Text(
                        'แตะเพื่อโทร',
                        style: TextStyle(fontSize: 12, color: AppColors.ink),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.ink),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
