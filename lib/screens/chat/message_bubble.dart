// ชิ้นส่วนข้อความในหน้าแชท: แถบหัวข้อ, บับเบิลข้อความ, ข้อความระบบกลางจอ
// บับเบิลดำ = ข้อความฝั่งเรา, บับเบิลเหลืองอ่อน = อีกฝั่ง
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_data.dart';
import '../../data/models.dart';
import '../../providers/auth_provider.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'attachments_view.dart';

/// แถบใต้หัวหน้า บอกว่าเป็นการปรึกษาแบบส่วนรวม / ส่วนตัว / เร่งด่วน
/// ห้องเร่งด่วนเป็นแถบสีส้ม ทั่วไปเหลืองอ่อน (ฝั่งเจ้าหน้าที่เห็นด้วยว่าใครเป็นผู้รับเรื่อง)
class TopicBanner extends StatelessWidget {
  const TopicBanner({super.key, required this.conv, required this.isStaff});
  final Conversation conv;
  final bool isStaff;

  @override
  Widget build(BuildContext context) {
    final urgent = AppData.category(conv.categoryId).urgent;
    final scope = urgent
        ? 'ขอความช่วยเหลือแบบเร่งด่วน'
        : conv.isSpecific
        ? 'ถาม/ตอบแบบเจาะจง (ส่วนตัว)'
        : 'ถาม/ตอบกับเจ้าหน้าที่คนไหนก็ได้ (ส่วนรวม)';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: urgent ? AppColors.orange : AppColors.yellowLight,
      child: Row(
        children: [
          Icon(
            urgent
                ? Icons.sos_rounded
                : conv.isSpecific
                ? Icons.lock_person_outlined
                : Icons.groups_outlined,
            size: 18,
            color: AppColors.ink,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              scope,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          if (isStaff && !conv.isSpecific && conv.staffId != null)
            Text(
              'ดูแลโดย ${context.watch<AuthProvider>().user(conv.staffId!).nickname}',
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
        ],
      ),
    );
  }
}

/// บับเบิลข้อความ 1 อัน: [mine] = ฝั่งเรา (ขวา/ฟ้า) ไม่ใช่ = อีกฝั่ง (ซ้าย/เทา มีรูป)
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.mine,
    required this.sender,
    required this.showSender,
  });
  final Message message;
  final bool mine;
  final AppUser sender;
  final bool showSender;

  @override
  Widget build(BuildContext context) {
    final bubble = message.attachment == null
        ? _textBubble(context)
        : message.isImage
        ? ImageAttachment(message: message)
        : FileAttachment(message: message, mine: mine);
    final time = Text(
      timeLabel(message.time),
      style: const TextStyle(fontSize: 10, color: AppColors.muted),
    );
    return _layout(bubble, time);
  }

  Widget _textBubble(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.72,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: mine ? AppColors.black : AppColors.bubbleOther,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(mine ? 20 : 4),
          bottomRight: Radius.circular(mine ? 4 : 20),
        ),
      ),
      child: Text(
        message.text,
        style: TextStyle(
          color: mine ? Colors.white : AppColors.ink,
          fontSize: 15,
          height: 1.35,
        ),
      ),
    );
  }

  Widget _layout(Widget bubble, Widget time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: mine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (showSender)
            Padding(
              padding: const EdgeInsets.only(bottom: 2, right: 4),
              child: Text(
                sender.displayName,
                style: const TextStyle(fontSize: 11, color: AppColors.muted),
              ),
            ),
          Row(
            mainAxisAlignment: mine
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!mine) ...[
                StaffAvatar(user: sender, size: 30),
                const SizedBox(width: 6),
              ],
              if (mine) ...[time, const SizedBox(width: 6)],
              Flexible(child: bubble),
              if (!mine) ...[const SizedBox(width: 6), time],
            ],
          ),
        ],
      ),
    );
  }
}

/// ข้อความจากระบบ แสดงเป็นแถบเล็กกลางจอ เช่น “เริ่มการปรึกษา...”
class SystemNote extends StatelessWidget {
  const SystemNote({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
        ),
      ),
    );
  }
}
