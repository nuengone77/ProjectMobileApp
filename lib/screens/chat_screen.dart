// หน้าแชท ใช้ร่วมกันทั้งนักศึกษาและเจ้าหน้าที่
// บับเบิลฟ้า = ข้อความฝั่งเรา, บับเบิลเทา = อีกฝั่ง (ตามไฟล์ UX/UI)
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/attachments.dart';
import '../data/app_store.dart';
import '../data/models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'profile_screen.dart' show showStudentProfile;

/// หน้าแชทของห้อง [conversationId]
/// - หัวหน้า: รูป + ชื่ออีกฝ่าย และหัวข้อการปรึกษา
/// - เมนู … = จบการปรึกษา
/// - เปิดหน้าแล้วถือว่าอ่านทุกข้อความแล้ว (เลขแจ้งเตือนหาย)
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.conversationId});
  final String conversationId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  int _lastCount = 0;

  Conversation get conv => store.conversation(widget.conversationId);

  @override
  void initState() {
    super.initState();
    store.addListener(_onStore);
    WidgetsBinding.instance.addPostFrameCallback((_) => store.markRead(conv));
  }

  @override
  void dispose() {
    store.removeListener(_onStore);
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// ถูกเรียกทุกครั้งที่ store เปลี่ยน: ถ้ามีข้อความใหม่เข้าห้องนี้
  /// ให้ถือว่าอ่านแล้ว และเลื่อนลงไปข้อความล่าสุด
  void _onStore() {
    if (!mounted || store.currentUser == null) return;
    if (conv.messages.length != _lastCount) {
      _lastCount = conv.messages.length;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        store.markRead(conv);
        if (_scroll.hasClients) {
          _scroll.animateTo(
            0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  /// ส่งข้อความจากช่องพิมพ์
  void _send() {
    store.send(conv, _input.text);
    _input.clear();
  }

  /// ปุ่มแนบ: เลือกได้ 3 แบบ คลังรูป (หลายรูป) / ถ่ายรูป / ไฟล์ (หลายไฟล์)
  Future<void> _attach() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (value, icon, label) in const [
              ('gallery', Icons.photo_library_outlined, 'เลือกรูปจากคลังรูป'),
              ('camera', Icons.photo_camera_outlined, 'ถ่ายรูป'),
              ('file', Icons.attach_file, 'แนบไฟล์'),
            ])
              ListTile(
                leading: Icon(icon, color: AppColors.caramel),
                title: Text(label),
                onTap: () => Navigator.pop(context, value),
              ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    void say(String text) =>
        messenger.showSnackBar(SnackBar(content: Text(text)));

    // (path ของไฟล์ที่เลือก, ชื่อที่แสดง, เป็นรูปไหม)
    final picked = <(String, String, bool)>[];
    try {
      // ย่อรูปให้ยาวสุด 1600px เพื่อไม่ให้แชทกินพื้นที่เครื่อง
      final picker = ImagePicker();
      switch (choice) {
        case 'gallery':
          for (final x in await picker.pickMultiImage(
            maxWidth: 1600,
            imageQuality: 85,
          )) {
            picked.add((x.path, x.name, true));
          }
        case 'camera':
          final x = await picker.pickImage(
            source: ImageSource.camera,
            maxWidth: 1600,
            imageQuality: 85,
          );
          if (x != null) picked.add((x.path, x.name, true));
        case 'file':
          for (final f in await FilePicker.pickFiles()) {
            if (f.path == null) continue;
            final size = f.lengthSync() ?? await f.length() ?? 0;
            if (size > Attachments.maxBytes) {
              say(
                '${f.name} ใหญ่เกิน '
                '${Attachments.sizeText(Attachments.maxBytes)}',
              );
              continue;
            }
            picked.add((f.path!, f.name, _isImageName(f.name)));
          }
      }
    } catch (e) {
      // เช่น iOS Simulator ไม่มีกล้อง หรือผู้ใช้ไม่อนุญาตให้เข้าถึงรูป
      say(
        choice == 'camera'
            ? 'เปิดกล้องไม่ได้ (Simulator ไม่มีกล้อง ต้องลองบนเครื่องจริง)'
            : 'เลือกไฟล์ไม่สำเร็จ: $e',
      );
      return;
    }
    for (final (path, name, isImage) in picked) {
      final file = await Attachments.import(path);
      if (!mounted) return;
      store.sendAttachment(conv, file: file, name: name, isImage: isImage);
    }
  }

  static bool _isImageName(String name) => const {
    '.jpg',
    '.jpeg',
    '.png',
    '.gif',
    '.webp',
    '.heic',
  }.contains(p.extension(name).toLowerCase());

  /// ถามยืนยันก่อนจบการปรึกษา
  /// เปิดฟอร์มสรุปการปรึกษา (เจ้าหน้าที่) คืนค่า (เรื่องที่ปรึกษา, ช่วยอะไรได้บ้าง)
  Future<(String, String, CaseLevel)?> _askSummary({required bool closing}) =>
      showModalBottomSheet<(String, String, CaseLevel)>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => _SummarySheet(conv: conv, closing: closing),
      );

  /// เจ้าหน้าที่บันทึก/แก้ไขสรุปของแชทที่จบแล้ว
  Future<void> _editSummary() async {
    final r = await _askSummary(closing: false);
    if (r != null) store.saveSummary(conv, r.$1, r.$2, r.$3);
  }

  /// จบการปรึกษา
  /// - เจ้าหน้าที่: ต้องกรอกสรุป 2 ช่องก่อน (เก็บเป็นประวัติ)
  /// - นักศึกษา: กดยืนยันอย่างเดียว
  Future<void> _close() async {
    if (store.currentUser!.isStaff) {
      final r = await _askSummary(closing: true);
      if (r != null) {
        store.closeConversation(conv, topic: r.$1, help: r.$2, level: r.$3);
      }
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('จบการสนทนา?'),
        content: const Text('สามารถเริ่มการถาม/ตอบใหม่ได้ทุกเมื่อจากหน้าแรก'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('จบการสนทนา'),
          ),
        ],
      ),
    );
    if (ok == true) store.closeConversation(conv);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final me = store.currentUser;
        if (me == null) return const SizedBox();
        final c = conv;
        final cat = AppStore.category(c.categoryId);
        final AppUser? other = me.isStaff
            ? store.user(c.studentId)
            : (c.staffId == null ? null : store.user(c.staffId!));
        // นักศึกษาเห็นแชทส่วนรวม (คนไหนก็ได้ / เร่งด่วน) เป็น “แชทรวมเจ้าหน้าที่” พร้อมรูปแมวไข่หวาน
        // แทนชื่อพี่คนใดคนหนึ่ง เพราะพี่ทุกคนเห็นและตอบได้
        final sharedForStudent = !me.isStaff && !c.isSpecific;
        final title = sharedForStudent
            ? 'แชทรวมเจ้าหน้าที่'
            : other == null
            ? 'พี่ไข่หวาน (คนไหนก็ได้)'
            : (me.isStaff ? other.name : other.displayName);
        final msgs = c.messages.reversed.toList();

        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            centerTitle: false,
            titleSpacing: 0,
            // ฝั่งเจ้าหน้าที่: แตะรูป/ชื่อนักศึกษาบนหัวแชทเพื่อดูโปรไฟล์
            title: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: me.isStaff && other != null
                  ? () => showStudentProfile(context, other)
                  : null,
              child: Row(
                children: [
                  if (sharedForStudent)
                    const CatAvatar(size: 38)
                  else if (other != null)
                    StaffAvatar(user: other, size: 38)
                  else
                    const CatAvatar(size: 38),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          cat.title,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              // ปุ่มดูโปรไฟล์นักศึกษา (เฉพาะเจ้าหน้าที่)
              if (me.isStaff && other != null)
                IconButton(
                  tooltip: 'ดูโปรไฟล์นิสิต',
                  icon: const Icon(Icons.badge_outlined),
                  onPressed: () => showStudentProfile(context, other),
                ),
              // ปุ่มกลับหน้าหลัก อยู่ข้างปุ่ม 3 จุด (ปุ่ม 3 จุดอยู่ขวาสุด)
              const HomeButton(),
              if (!c.closed)
                PopupMenuButton<String>(
                  onSelected: (v) => v == 'close' ? _close() : null,
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'close', child: Text('จบการสนทนา')),
                  ],
                ),
            ],
          ),
          body: Column(
            children: [
              _TopicBanner(conv: c, isStaff: me.isStaff),
              Expanded(
                child: ListView.builder(
                  controller: _scroll,
                  // reverse = ข้อความล่าสุดอยู่ล่างสุด และเปิดมาเห็นล่างสุดทันที
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  itemCount: msgs.length,
                  itemBuilder: (context, i) {
                    final m = msgs[i];
                    // แสดงเบอร์ฉุกเฉินจากค่าปัจจุบันเสมอ (ไม่ใช้ข้อความที่บันทึกไว้ตอนเปิดห้อง)
                    // แก้ emergencyPhone แล้วห้องเก่าก็แสดงเบอร์ใหม่ด้วย
                    if (m.isAlert) {
                      return const _AlertNote(text: AppStore.emergencyMessage);
                    }
                    if (m.isSystem) return _SystemNote(text: m.text);
                    final mine =
                        m.senderId == me.id ||
                        (me.isStaff && m.senderId != c.studentId); // ฝั่งเจ้าหน้าที่: ข้อความของเจ้าหน้าที่ทุกคนอยู่ขวา
                    return _Bubble(
                      message: m,
                      mine: mine,
                      sender: store.user(m.senderId),
                      // ฝั่งเจ้าหน้าที่: ถ้าเพื่อนเจ้าหน้าที่เป็นคนตอบ ให้แสดงชื่อกำกับ
                      showSender: mine && m.senderId != me.id,
                    );
                  },
                ),
              ),
              if (c.closed && me.isStaff)
                _SummaryPanel(conv: c, onEdit: _editSummary)
              else if (c.closed)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: AppColors.cream,
                  child: const SafeArea(
                    top: false,
                    child: Text(
                      'การปรึกษานี้สิ้นสุดแล้ว',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ),
                )
              else
                _Composer(controller: _input, onSend: _send, onAttach: _attach),
            ],
          ),
        );
      },
    );
  }
}

/// แถบใต้หัวหน้า บอกว่าเป็นการปรึกษาแบบส่วนรวม / ส่วนตัว / เร่งด่วน
/// ห้องเร่งด่วนเป็นแถบสีแดง (ฝั่งเจ้าหน้าที่เห็นด้วยว่าใครเป็นผู้รับเรื่อง)
class _TopicBanner extends StatelessWidget {
  const _TopicBanner({required this.conv, required this.isStaff});
  final Conversation conv;
  final bool isStaff;

  @override
  Widget build(BuildContext context) {
    final urgent = AppStore.category(conv.categoryId).urgent;
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
              'ดูแลโดย ${store.user(conv.staffId!).nickname}',
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
        ],
      ),
    );
  }
}

/// บับเบิลข้อความ 1 อัน: [mine] = ฝั่งเรา (ขวา/ฟ้า) ไม่ใช่ = อีกฝั่ง (ซ้าย/เทา มีรูป)
class _Bubble extends StatelessWidget {
  const _Bubble({
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
        ? _ImageAttachment(message: message)
        : _FileAttachment(message: message, mine: mine);
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
        color: mine ? AppColors.caramel : AppColors.bubbleOther,
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

/// รูปที่แนบในแชท: แสดงรูปย่อ แตะเพื่อดูเต็มจอ
class _ImageAttachment extends StatelessWidget {
  const _ImageAttachment({required this.message});
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
class _FileAttachment extends StatelessWidget {
  const _FileAttachment({required this.message, required this.mine});
  final Message message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final file = File(Attachments.pathOf(message.attachment!));
    final exists = file.existsSync();
    final fg = mine ? Colors.white : AppColors.ink;
    return Material(
      color: mine ? AppColors.caramel : AppColors.bubbleOther,
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

/// การ์ดแจ้งเตือนสำคัญสีแดงกลางแชท (เช่น เบอร์ฉุกเฉินในแชทเร่งด่วน)
class _AlertNote extends StatelessWidget {
  const _AlertNote({required this.text});
  final String text;

  /// แตะการ์ด -> เปิดหน้าโทรออกพร้อมเบอร์ฉุกเฉิน (ผู้ใช้กดโทรเองอีกที)
  /// iOS Simulator ไม่มีแอปโทรศัพท์ จึงโทรไม่ได้ จะขึ้นข้อความแจ้งแทน
  Future<void> _call(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    var ok = false;
    try {
      ok = await launchUrl(Uri(scheme: 'tel', path: AppStore.emergencyPhone));
    } catch (_) {}
    if (!ok) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'อุปกรณ์นี้โทรออกไม่ได้ กรุณาโทร ${AppStore.emergencyPhone}',
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

/// ข้อความจากระบบ แสดงเป็นแถบเล็กกลางจอ เช่น “เริ่มการปรึกษา...”
class _SystemNote extends StatelessWidget {
  const _SystemNote({required this.text});
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

/// แถบพิมพ์ข้อความด้านล่าง: ปุ่มแนบรูป (ยังไม่เปิดใช้), ช่องพิมพ์, ปุ่มส่ง
class _Composer extends StatelessWidget {
  const _Composer({
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
              style: IconButton.styleFrom(backgroundColor: AppColors.caramel),
              onPressed: onSend,
              icon: const Icon(Icons.send_rounded, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

/// ฟอร์มสรุปการปรึกษา (เลื่อนขึ้นจากด้านล่าง) ให้เจ้าหน้าที่กรอกตอนจบการปรึกษา
/// ต้องกรอกครบ: เรื่องที่ปรึกษา / คำปรึกษาที่เจ้าหน้าที่ให้ / ระดับเคส (เล็ก/กลาง/ใหญ่)
/// [closing] = true ตอนกดจบ, false ตอนแก้ไขสรุปทีหลัง (เติมค่าเดิมไว้ให้)
class _SummarySheet extends StatefulWidget {
  const _SummarySheet({required this.conv, required this.closing});
  final Conversation conv;
  final bool closing;

  @override
  State<_SummarySheet> createState() => _SummarySheetState();
}

class _SummarySheetState extends State<_SummarySheet> {
  final _form = GlobalKey<FormState>();
  late final _topic = TextEditingController(text: widget.conv.summaryTopic);
  late final _help = TextEditingController(text: widget.conv.summaryHelp);
  late CaseLevel? _level = widget.conv.caseLevel; // ระดับเคส (ต้องเลือก)

  InputDecoration _box(String label, String hint) => InputDecoration(
    labelText: label,
    hintText: hint,
    alignLabelWithHint: true,
    floatingLabelBehavior: FloatingLabelBehavior.always,
    contentPadding: const EdgeInsets.all(16),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.line),
    ),
  );

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'กรุณากรอกช่องนี้' : null;

  @override
  Widget build(BuildContext context) {
    final student = store.user(widget.conv.studentId);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.closing ? 'จบการสนทนา' : 'สรุปการสนทนา',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'บันทึกสรุปเก็บเป็นประวัติ · ${student.name}',
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _topic,
                  maxLines: 3,
                  validator: _required,
                  decoration: _box(
                    'เรื่องที่ถาม/ตอบ',
                    'เช่น สอบถามเอกสาร กยศ. ที่ต้องใช้',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _help,
                  maxLines: 3,
                  validator: _required,
                  decoration: _box(
                    'คำตอบที่เจ้าหน้าที่ให้',
                    'เช่น แจ้งรายการเอกสารและกำหนดส่ง',
                  ),
                ),
                const SizedBox(height: 16),
                // ระดับเคส: เล็ก 🟢 / กลาง 🟡 / ใหญ่ 🔴
                DropdownButtonFormField<CaseLevel>(
                  initialValue: _level,
                  borderRadius: BorderRadius.circular(16),
                  decoration: _box('ระดับเคส', ''),
                  hint: const Text('เลือกระดับเคส'),
                  items: [
                    for (final l in CaseLevel.values)
                      DropdownMenuItem(value: l, child: Text(l.display)),
                  ],
                  onChanged: (v) => setState(() => _level = v),
                  validator: (v) => v == null ? 'กรุณาเลือกระดับเคส' : null,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () {
                    if (!_form.currentState!.validate()) return;
                    Navigator.pop(context, (_topic.text, _help.text, _level!));
                  },
                  child: Text(
                    widget.closing ? 'บันทึกและจบการสนทนา' : 'บันทึกสรุป',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// แถบล่างของแชทที่จบแล้ว (ฝั่งเจ้าหน้าที่): แสดงสรุปการปรึกษา + ปุ่มแก้ไข
/// ถ้านักศึกษากดจบเองจะยังไม่มีสรุป -> แสดงปุ่ม “บันทึกสรุป”
class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({required this.conv, required this.onEdit});
  final Conversation conv;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final closer = conv.closedById == null
        ? null
        : store.user(conv.closedById!);
    Widget field(String label, String value) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          Text(value),
        ],
      ),
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.cream,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.assignment_turned_in_outlined,
                  size: 18,
                  color: AppColors.caramel,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'จบการสนทนาแล้ว'
                    '${conv.closedAt != null ? ' · ${timeLabel(conv.closedAt!)}' : ''}'
                    '${closer != null ? ' · โดย ${closer.isStaff ? closer.displayName : 'นักศึกษา'}' : ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onEdit,
                  child: Text(conv.hasSummary ? 'แก้ไขสรุป' : 'บันทึกสรุป'),
                ),
              ],
            ),
            if (conv.hasSummary) ...[
              if (conv.caseLevel != null)
                field('ระดับเคส', conv.caseLevel!.display),
              field('เรื่องที่ถามตอบ', conv.summaryTopic),
              field('คำตอบที่เจ้าหน้าที่ให้', conv.summaryHelp),
            ] else
              const Text(
                'ยังไม่ได้บันทึกสรุป (นักศึกษากดจบการสนทนาเอง)',
                style: TextStyle(color: AppColors.alert),
              ),
          ],
        ),
      ),
    );
  }
}
