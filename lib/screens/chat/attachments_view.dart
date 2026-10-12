// แสดงไฟล์แนบในแชท: รูป (แตะดูเต็มจอ) และไฟล์ (แตะเพื่อเปิด/แชร์)
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/attachments.dart';
import '../../data/models.dart';
import '../../theme.dart';

/// รูปที่แนบในแชท: แสดงรูปย่อ แตะเพื่อดูเต็มจอ
class ImageAttachment extends StatelessWidget {
  const ImageAttachment({super.key, required this.message});
  final Message message;

  @override
  Widget build(BuildContext context) {
    final file = File(Attachments.pathOf(message.attachment!));
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              _ImageViewer(file: file, name: message.attachmentName),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(
          file,
          width: 200,
          height: 200,
          fit: BoxFit.cover,
          cacheWidth: 400,
          errorBuilder: (_, _, _) => Container(
            width: 200,
            height: 120,
            color: AppColors.bubbleOther,
            alignment: Alignment.center,
            child: const Text(
              'ไม่พบรูปในเครื่องนี้',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ),
        ),
      ),
    );
  }
}

/// ดูรูปเต็มจอ ซูม/เลื่อนได้ และปุ่มแชร์/บันทึก
class _ImageViewer extends StatelessWidget {
  const _ImageViewer({required this.file, this.name});
  final File file;
  final String? name;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'แชร์/บันทึกรูป',
            icon: const Icon(Icons.ios_share),
            onPressed: () => _shareFile(context, file),
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(maxScale: 5, child: Image.file(file)),
      ),
    );
  }
}

/// ไฟล์ที่แนบในแชท: ไอคอน + ชื่อไฟล์ + ขนาด แตะเพื่อเปิด/แชร์
class FileAttachment extends StatelessWidget {
  const FileAttachment({super.key, required this.message, required this.mine});
  final Message message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final file = File(Attachments.pathOf(message.attachment!));
    final exists = file.existsSync();
    final fg = mine ? Colors.white : AppColors.ink;
    return Material(
      color: mine ? AppColors.black : AppColors.bubbleOther,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: exists ? () => _shareFile(context, file) : null,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.72,
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.insert_drive_file_outlined, color: fg, size: 30),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.attachmentName ?? 'ไฟล์',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: fg, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      exists
                          ? '${Attachments.sizeText(file.lengthSync())} · แตะเพื่อเปิด'
                          : 'ไม่พบไฟล์ในเครื่องนี้',
                      style: TextStyle(
                        color: fg.withValues(alpha: 0.75),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// เปิดเมนูแชร์ของระบบ (ดูตัวอย่างไฟล์ / บันทึกลง Files / ส่งต่อแอปอื่น)
Future<void> _shareFile(BuildContext context, File file) async {
  final box = context.findRenderObject() as RenderBox?;
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path)],
      sharePositionOrigin: box == null
          ? null
          : box.localToGlobal(Offset.zero) & box.size,
    ),
  );
}
