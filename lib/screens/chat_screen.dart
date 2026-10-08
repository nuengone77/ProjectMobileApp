import 'package:flutter/material.dart';

import '../data/mock_store.dart';
import '../data/models.dart';
import '../theme.dart';
import '../widgets/common.dart';

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

  void _send([String? text]) {
    store.send(conv, text ?? _input.text);
    _input.clear();
  }

  Future<void> _report() async {
    final result = await showModalBottomSheet<(String, String)>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _ReportSheet(),
    );
    if (result == null || !mounted) return;
    store.report(conv, result.$1, result.$2);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ส่งรายงานเข้าระบบรายงานเรียบร้อยแล้ว'),
        backgroundColor: AppColors.alert,
      ),
    );
  }

  Future<void> _close() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('จบการปรึกษา?'),
        content: const Text('สามารถเริ่มปรึกษาใหม่ได้ทุกเมื่อจากหน้าแรก'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('จบการปรึกษา'),
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
        final cat = MockStore.category(c.categoryId);
        final AppUser? other = me.isStaff
            ? store.user(c.studentId)
            : (c.staffId == null ? null : store.user(c.staffId!));
        final title = other == null
            ? 'พี่ไข่หวาน (คนไหนก็ได้)'
            : (me.isStaff ? other.name : other.displayName);
        final typing = store.typing.contains(c.id);
        final reported = store.reports.any((r) => r.conversationId == c.id);
        final msgs = c.messages.reversed.toList();

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            centerTitle: false,
            titleSpacing: 0,
            title: Row(
              children: [
                if (other != null)
                  StaffAvatar(user: other, size: 38, showOnline: other.isStaff)
                else
                  const CircleAvatar(
                    radius: 19,
                    backgroundColor: AppColors.orange,
                    child: Text('🥚'),
                  ),
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
                        typing
                            ? 'กำลังพิมพ์...'
                            : '${cat.title} · ${c.subtopic}',
                        style: TextStyle(
                          fontSize: 12,
                          color: typing ? AppColors.bubbleMe : AppColors.muted,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              if (me.isStaff)
                IconButton(
                  tooltip: 'รายงาน (ระบบรายงาน)',
                  onPressed: _report,
                  icon: Text(
                    '!!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: reported ? Colors.grey : AppColors.alert,
                    ),
                  ),
                ),
              if (!c.closed)
                PopupMenuButton<String>(
                  onSelected: (v) => v == 'close' ? _close() : null,
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'close', child: Text('จบการปรึกษา')),
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
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  itemCount: msgs.length + (typing ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (typing && i == 0) return const _TypingBubble();
                    final m = msgs[i - (typing ? 1 : 0)];
                    if (m.isSystem) return _SystemNote(text: m.text);
                    final mine =
                        m.senderId == me.id ||
                        (me.isStaff && m.senderId != c.studentId); // staff side: all staff msgs on the right
                    return _Bubble(
                      message: m,
                      mine: mine,
                      sender: store.user(m.senderId),
                      // on the staff side, label replies written by a colleague
                      showSender: mine && m.senderId != me.id,
                    );
                  },
                ),
              ),
              if (c.closed)
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
              else ...[
                if (!me.isStaff &&
                    c.messages.where((m) => m.senderId == me.id).isEmpty)
                  _QuickReplies(subtopic: c.subtopic, onPick: _send),
                _Composer(controller: _input, onSend: _send),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _TopicBanner extends StatelessWidget {
  const _TopicBanner({required this.conv, required this.isStaff});
  final Conversation conv;
  final bool isStaff;

  @override
  Widget build(BuildContext context) {
    final scope = conv.isSpecific
        ? 'ปรึกษาแบบเจาะจง (ส่วนตัว)'
        : 'ปรึกษาเจ้าหน้าที่คนไหนก็ได้ (ส่วนรวม)';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.orange.withValues(alpha: 0.35),
      child: Row(
        children: [
          Icon(
            conv.isSpecific
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
    final bubble = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.72,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: mine ? AppColors.bubbleMe : AppColors.bubbleOther,
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
    final time = Text(
      timeLabel(message.time),
      style: const TextStyle(fontSize: 10, color: AppColors.muted),
    );
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

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(left: 36, top: 4, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.bubbleOther,
          borderRadius: BorderRadius.circular(20),
        ),
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final t = ((_c.value * 3) - i).clamp(0.0, 1.0);
              final up = t < 0.5 ? t * 2 : (1 - t) * 2;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                width: 8,
                height: 8,
                transform: Matrix4.translationValues(0, -4 * up, 0),
                decoration: BoxDecoration(
                  color: AppColors.muted.withValues(alpha: 0.4 + up * 0.6),
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _QuickReplies extends StatelessWidget {
  const _QuickReplies({required this.subtopic, required this.onPick});
  final String subtopic;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final options = [
      'สวัสดีค่ะ/ครับ',
      'ขอสอบถามเรื่อง$subtopicหน่อย',
      'ต้องเตรียมอะไรบ้าง?',
    ];
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => ActionChip(
          label: Text(options[i]),
          backgroundColor: AppColors.cream,
          side: const BorderSide(color: AppColors.orange),
          onPressed: () => onPick(options[i]),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.onSend});
  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEDE6DC))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('แนบไฟล์/รูปภาพ (ต้นแบบ - ยังไม่เปิดใช้งาน)'),
                ),
              ),
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
                  fillColor: const Color(0xFFF3F1EE),
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
              style: IconButton.styleFrom(backgroundColor: AppColors.bubbleMe),
              onPressed: onSend,
              icon: const Icon(Icons.send_rounded, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportSheet extends StatefulWidget {
  const _ReportSheet();

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  String? _reason;
  final _detail = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Text(
                    '!!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.alert,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'ระบบรายงาน',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'รายงานการสนทนานี้ให้ผู้ดูแลระบบตรวจสอบ',
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 12),
              RadioGroup<String>(
                groupValue: _reason,
                onChanged: (v) => setState(() => _reason = v),
                child: Column(
                  children: [
                    for (final r in MockStore.reportReasons)
                      RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        value: r,
                        title: Text(r),
                        activeColor: AppColors.alert,
                      ),
                  ],
                ),
              ),
              TextField(
                controller: _detail,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'รายละเอียดเพิ่มเติม (ไม่บังคับ)',
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.black26),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.alert),
                onPressed: _reason == null
                    ? null
                    : () => Navigator.pop(context, (
                        _reason!,
                        _detail.text.trim(),
                      )),
                child: const Text('ส่งรายงาน'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
