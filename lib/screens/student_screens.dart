import 'package:flutter/material.dart';

import '../data/mock_store.dart';
import '../data/models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';

class StudentShell extends StatefulWidget {
  const StudentShell({super.key});

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final unread = store.studentUnreadTotal;
        return Scaffold(
          body: IndexedStack(
            index: _tab,
            children: const [StudentHome(), MyChatsScreen(), ProfileScreen()],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tab,
            backgroundColor: Colors.white,
            indicatorColor: AppColors.orange,
            onDestinationSelected: (i) => setState(() => _tab = i),
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'หน้าแรก',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: unread > 0,
                  label: Text('$unread'),
                  child: const Icon(Icons.chat_bubble_outline),
                ),
                selectedIcon: Badge(
                  isLabelVisible: unread > 0,
                  label: Text('$unread'),
                  child: const Icon(Icons.chat_bubble),
                ),
                label: 'แชทของฉัน',
              ),
              const NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'โปรไฟล์',
              ),
            ],
          ),
        );
      },
    );
  }
}

class StudentHome extends StatelessWidget {
  const StudentHome({super.key});

  @override
  Widget build(BuildContext context) {
    final me = store.currentUser!;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'สวัสดี, ${me.name.split(' ').first} 👋',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'วันนี้อยากปรึกษาพี่ไข่หวานเรื่องอะไรดี?',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: AppColors.orange,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text('🥚', style: TextStyle(fontSize: 26)),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.shield_moon_outlined,
                  color: AppColors.orangeDark,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'พี่ไข่หวานออนไลน์อยู่ ${store.staff.where((s) => s.online).length} คน · ข้อมูลการปรึกษาเป็นความลับ',
                    style: const TextStyle(fontSize: 13, color: AppColors.ink),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'เลือกหัวข้อที่ต้องการปรึกษา',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          for (final c in MockStore.categories)
            OrangeCard(
              title: c.title,
              subtitle: c.subtitle,
              icon: c.icon,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SubtopicScreen(category: c)),
              ),
            ),
        ],
      ),
    );
  }
}

class SubtopicScreen extends StatelessWidget {
  const SubtopicScreen({super.key, required this.category});
  final ConsultCategory category;

  Future<void> _pick(BuildContext context, String subtopic) async {
    String? note;
    if (subtopic == 'อื่นๆ') {
      note = await showDialog<String>(
        context: context,
        builder: (_) => const _OtherTopicDialog(),
      );
      if (note == null || !context.mounted) return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConsultModeScreen(
          category: category,
          subtopic: subtopic,
          firstMessage: note,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(category.title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const StepHeader(
            title: 'เรื่องที่ต้องการปรึกษา',
            caption: 'ขั้นที่ 1 จาก 2 · เลือกเรื่องที่ใกล้เคียงที่สุด',
          ),
          for (final s in category.subtopics)
            OrangeCard(title: s, onTap: () => _pick(context, s)),
        ],
      ),
    );
  }
}

class _OtherTopicDialog extends StatefulWidget {
  const _OtherTopicDialog();

  @override
  State<_OtherTopicDialog> createState() => _OtherTopicDialogState();
}

class _OtherTopicDialogState extends State<_OtherTopicDialog> {
  final _c = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('เรื่องอื่นๆ'),
      content: TextField(
        controller: _c,
        autofocus: true,
        maxLines: 3,
        decoration: InputDecoration(
          hintText: 'เล่าสั้นๆ ว่าอยากปรึกษาเรื่องอะไร (ไม่บังคับ)',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.all(12),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ยกเลิก'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
          onPressed: () => Navigator.pop(context, _c.text.trim()),
          child: const Text('ต่อไป'),
        ),
      ],
    );
  }
}

class ConsultModeScreen extends StatelessWidget {
  const ConsultModeScreen({
    super.key,
    required this.category,
    required this.subtopic,
    this.firstMessage,
  });
  final ConsultCategory category;
  final String subtopic;
  final String? firstMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(category.title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          StepHeader(
            title: 'เลือกรูปแบบการปรึกษา',
            caption: 'ขั้นที่ 2 จาก 2 · เรื่อง: $subtopic',
          ),
          OrangeCard(
            title: 'ปรึกษากับพี่ไข่หวาน\n(เจ้าหน้าที่คนไหนก็ได้)',
            subtitle: 'เข้าแชทได้ทันที ตอบเร็วที่สุด',
            icon: Icons.groups_rounded,
            onTap: () => openChat(
              context,
              category: category,
              subtopic: subtopic,
              firstMessage: firstMessage,
            ),
          ),
          OrangeCard(
            title: 'ปรึกษากับพี่ไข่หวาน\n(เจ้าหน้าที่แบบเลือกเฉพาะเจาะจง)',
            subtitle: 'เลือกพี่ที่อยากคุยด้วยเอง',
            icon: Icons.person_search_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StaffPickerScreen(
                  category: category,
                  subtopic: subtopic,
                  firstMessage: firstMessage,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StaffPickerScreen extends StatelessWidget {
  const StaffPickerScreen({
    super.key,
    required this.category,
    required this.subtopic,
    this.firstMessage,
  });
  final ConsultCategory category;
  final String subtopic;
  final String? firstMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เลือกพี่ไข่หวาน')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          StepHeader(
            title: 'อยากคุยกับพี่คนไหน?',
            caption: 'เรื่อง: $subtopic',
          ),
          for (final s in store.staff)
            OrangeCard(
              leading: StaffAvatar(user: s, size: 54, showOnline: true),
              title: s.displayName,
              subtitle:
                  '${s.specialty}\n${s.online ? '● ออนไลน์' : '○ ออฟไลน์ · จะตอบกลับเมื่อออนไลน์'}',
              onTap: () => openChat(
                context,
                category: category,
                subtopic: subtopic,
                staffId: s.id,
                firstMessage: firstMessage,
              ),
            ),
        ],
      ),
    );
  }
}

/// Starts the conversation and jumps straight into the chat, replacing the
/// selection steps so "back" returns to the home screen.
void openChat(
  BuildContext context, {
  required ConsultCategory category,
  required String subtopic,
  String? staffId,
  String? firstMessage,
}) {
  final conv = store.openConversation(
    categoryId: category.id,
    subtopic: subtopic,
    staffId: staffId,
  );
  if (firstMessage != null && firstMessage.isNotEmpty) {
    store.send(conv, firstMessage);
  }
  Navigator.of(context).popUntil((r) => r.isFirst);
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => ChatScreen(conversationId: conv.id)),
  );
}

class MyChatsScreen extends StatelessWidget {
  const MyChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('แชทของฉัน')),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final list = store.myConversations();
          if (list.isEmpty) {
            return const Center(
              child: Text(
                'ยังไม่มีการปรึกษา\nเลือกหัวข้อที่หน้าแรกเพื่อเริ่มแชทได้เลย',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: list.length,
            separatorBuilder: (_, _) => const Divider(height: 1, indent: 84),
            itemBuilder: (context, i) =>
                ConversationTile(conv: list[i], forStaff: false),
          );
        },
      ),
    );
  }
}

class ConversationTile extends StatelessWidget {
  const ConversationTile({
    super.key,
    required this.conv,
    required this.forStaff,
  });
  final Conversation conv;
  final bool forStaff;

  @override
  Widget build(BuildContext context) {
    final cat = MockStore.category(conv.categoryId);
    final unread = forStaff
        ? store.unreadForStaff(conv)
        : store.unreadForStudent(conv);
    final AppUser? other = forStaff
        ? store.user(conv.studentId)
        : (conv.staffId == null ? null : store.user(conv.staffId!));
    final title = forStaff
        ? '${other!.name} · ${other.major}'
        : (other?.displayName ?? 'พี่ไข่หวาน (คนไหนก็ได้)');
    final last = conv.last;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      tileColor: unread > 0 ? AppColors.orange.withValues(alpha: 0.15) : null,
      leading: other != null
          ? StaffAvatar(user: other, size: 52)
          : const CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.orange,
              child: Text('🥚', style: TextStyle(fontSize: 24)),
            ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${cat.title} · ${conv.subtopic}${conv.isSpecific ? ' · ส่วนตัว' : ''}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.orangeDark,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (last != null)
            Text(
              last.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (last != null)
            Text(
              timeLabel(last.time),
              style: const TextStyle(fontSize: 11, color: AppColors.muted),
            ),
          const SizedBox(height: 4),
          if (unread > 0)
            Badge(label: Text('$unread'), backgroundColor: AppColors.alert)
          else if (conv.closed)
            const Text(
              'จบแล้ว',
              style: TextStyle(fontSize: 11, color: AppColors.muted),
            ),
        ],
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatScreen(conversationId: conv.id)),
      ),
    );
  }
}
