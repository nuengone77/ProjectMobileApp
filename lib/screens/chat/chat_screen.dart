// หน้าแชท ใช้ร่วมกันทั้งนักศึกษาและเจ้าหน้าที่
// หัวแชท + รายการข้อความ + แนบรูป/ไฟล์ + จบการสนทนา
// ชิ้นส่วนย่อยของหน้าแชทอยู่ในไฟล์อื่นในโฟลเดอร์นี้ (บับเบิล, ไฟล์แนบ, การ์ดฉุกเฉิน, ช่องพิมพ์, สรุป)
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../../data/attachments.dart';
import '../../data/app_data.dart';
import '../../data/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../profile_screen.dart' show showStudentProfile;
import 'message_bubble.dart';
import 'emergency_card.dart';
import 'composer.dart';
import 'summary_sheet.dart';

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

  /// Provider ของแชท เก็บไว้ใช้ตอน addListener/removeListener (initState/dispose)
  late final ChatProvider _chat;

  Conversation get conv => _chat.conversation(widget.conversationId);

  @override
  void initState() {
    super.initState();
    // context.read ใน initState: ดึง Provider มาครั้งเดียว แล้วฟังเองด้วย addListener
    _chat = context.read<ChatProvider>();
    _chat.addListener(_onStore);
    WidgetsBinding.instance.addPostFrameCallback((_) => _chat.markRead(conv));
  }

  @override
  void dispose() {
    _chat.removeListener(_onStore);
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// ถูกเรียกทุกครั้งที่ ChatProvider เปลี่ยน: ถ้ามีข้อความใหม่เข้าห้องนี้
  /// ให้ถือว่าอ่านแล้ว และเลื่อนลงไปข้อความล่าสุด
  void _onStore() {
    if (!mounted || context.read<AuthProvider>().currentUser == null) return;
    if (conv.messages.length != _lastCount) {
      _lastCount = conv.messages.length;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _chat.markRead(conv);
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
    _chat.send(conv, _input.text);
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
                leading: Icon(icon, color: AppColors.black),
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
      _chat.sendAttachment(conv, file: file, name: name, isImage: isImage);
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
        builder: (_) => SummarySheet(conv: conv, closing: closing),
      );

  /// เจ้าหน้าที่บันทึก/แก้ไขสรุปของแชทที่จบแล้ว
  Future<void> _editSummary() async {
    final r = await _askSummary(closing: false);
    if (r != null) _chat.saveSummary(conv, r.$1, r.$2, r.$3);
  }

  /// จบการปรึกษา
  /// - เจ้าหน้าที่: ต้องกรอกสรุป 2 ช่องก่อน (เก็บเป็นประวัติ)
  /// - นักศึกษา: กดยืนยันอย่างเดียว
  Future<void> _close() async {
    if (context.read<AuthProvider>().currentUser!.isStaff) {
      final r = await _askSummary(closing: true);
      if (r != null) {
        _chat.closeConversation(conv, topic: r.$1, help: r.$2, level: r.$3);
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
    if (ok == true) _chat.closeConversation(conv);
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        // watch ทั้งสองตัว: ข้อความใหม่ (Chat) และสถานะล็อกอิน (Auth) ทำให้หน้านี้วาดใหม่
        context.watch<ChatProvider>();
        final me = context.watch<AuthProvider>().currentUser;
        if (me == null) return const SizedBox();
        final c = conv;
        final cat = AppData.category(c.categoryId);
        final AppUser? other = me.isStaff
            ? context.watch<AuthProvider>().user(c.studentId)
            : (c.staffId == null
                  ? null
                  : context.watch<AuthProvider>().user(c.staffId!));
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
              TopicBanner(conv: c, isStaff: me.isStaff),
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
                      return const EmergencyCard(
                        text: AppData.emergencyMessage,
                      );
                    }
                    if (m.isSystem) return SystemNote(text: m.text);
                    final mine =
                        m.senderId == me.id ||
                        (me.isStaff && m.senderId != c.studentId); // ฝั่งเจ้าหน้าที่: ข้อความของเจ้าหน้าที่ทุกคนอยู่ขวา
                    return MessageBubble(
                      message: m,
                      mine: mine,
                      sender: context.watch<AuthProvider>().user(m.senderId),
                      // ฝั่งเจ้าหน้าที่: ถ้าเพื่อนเจ้าหน้าที่เป็นคนตอบ ให้แสดงชื่อกำกับ
                      showSender: mine && m.senderId != me.id,
                    );
                  },
                ),
              ),
              if (c.closed && me.isStaff)
                SummaryPanel(conv: c, onEdit: _editSummary)
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
                MessageComposer(
                  controller: _input,
                  onSend: _send,
                  onAttach: _attach,
                ),
            ],
          ),
        );
      },
    );
  }
}
