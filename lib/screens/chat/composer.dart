// ช่องพิมพ์ข้อความ + ปุ่มแนบรูป/ไฟล์ + ปุ่มส่ง (ด้านล่างหน้าแชท)
import 'package:flutter/material.dart';

import '../../theme.dart';

/// แถบพิมพ์ข้อความด้านล่าง: ปุ่มแนบรูป (ยังไม่เปิดใช้), ช่องพิมพ์, ปุ่มส่ง
class MessageComposer extends StatelessWidget {
  const MessageComposer({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onAttach,
  });
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onAttach;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              tooltip: 'แนบรูป/ไฟล์',
              onPressed: onAttach,
              icon: const Icon(
                Icons.add_photo_alternate_outlined,
                color: AppColors.muted,
              ),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: 'พิมพ์ข้อความ...',
                  isDense: true,
                  filled: true,
                  fillColor: AppColors.field,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            IconButton.filled(
              style: IconButton.styleFrom(backgroundColor: AppColors.black),
              onPressed: onSend,
              icon: const Icon(Icons.send_rounded, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
