import 'package:flutter/material.dart';

import '../data/mock_store.dart';
import '../data/models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';
import 'student_screens.dart' show ConversationTile;

class StaffShell extends StatefulWidget {
  const StaffShell({super.key});

  @override
  State<StaffShell> createState() => _StaffShellState();
}

class _StaffShellState extends State<StaffShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final unread = store.staffUnread();
        final reports = store.reports.length;
        return Scaffold(
          body: IndexedStack(
            index: _tab,
            children: const [
              StaffHome(),
              StaffInboxScreen(),
              ReportsScreen(),
              ProfileScreen(),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tab,
            backgroundColor: Colors.white,
            indicatorColor: AppColors.orange,
            onDestinationSelected: (i) => setState(() => _tab = i),
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: 'หัวข้อ',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: unread > 0,
                  label: Text('$unread'),
                  child: const Icon(Icons.inbox_outlined),
                ),
                selectedIcon: Badge(
                  isLabelVisible: unread > 0,
                  label: Text('$unread'),
                  child: const Icon(Icons.inbox),
                ),
                label: 'ข้อความ',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: reports > 0,
                  label: Text('$reports'),
                  child: const Icon(Icons.report_outlined),
                ),
                selectedIcon: Badge(
                  isLabelVisible: reports > 0,
                  label: Text('$reports'),
                  child: const Icon(Icons.report),
                ),
                label: 'ระบบรายงาน',
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

class StaffHome extends StatelessWidget {
  const StaffHome({super.key});

  @override
  Widget build(BuildContext context) {
    final me = store.currentUser!;
    final total = store.staffUnread();
    final mine = store.staffUnread(specific: true);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          Row(
            children: [
              StaffAvatar(user: me, size: 52, showOnline: true),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      me.displayName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      'เจ้าหน้าที่ · ${me.specialty}',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _Stat(
                label: 'ข้อความใหม่ทั้งหมด',
                value: total,
                color: AppColors.alert,
              ),
              const SizedBox(width: 12),
              _Stat(
                label: 'ส่งถึงฉันโดยตรง',
                value: mine,
                color: AppColors.bubbleMe,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'หัวข้อการปรึกษา',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 14),
          for (final c in MockStore.categories)
            OrangeCard(
              title: c.title,
              subtitle:
                  '${store.staffConversations(categoryId: c.id).length} การสนทนา',
              icon: c.icon,
              badge: store.staffUnread(categoryId: c.id),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StaffSubtopicScreen(category: c),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class StaffSubtopicScreen extends StatelessWidget {
  const StaffSubtopicScreen({super.key, required this.category});
  final ConsultCategory category;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(category.title)),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const StepHeader(
              title: 'เรื่องที่นักศึกษาปรึกษา',
              caption: 'กระดิ่งแสดงจำนวนข้อความที่ยังไม่ได้อ่าน',
            ),
            for (final s in category.subtopics)
              OrangeCard(
                title: s,
                subtitle:
                    '${store.staffConversations(categoryId: category.id, subtopic: s).length} การสนทนา',
                badge: store.staffUnread(categoryId: category.id, subtopic: s),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        StaffScopeScreen(category: category, subtopic: s),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class StaffScopeScreen extends StatelessWidget {
  const StaffScopeScreen({
    super.key,
    required this.category,
    required this.subtopic,
  });
  final ConsultCategory category;
  final String subtopic;

  void _open(BuildContext context, bool specific) {
    final list = store.staffConversations(
      categoryId: category.id,
      subtopic: subtopic,
      specific: specific,
    );
    if (list.length == 1) {
      // Only one chat waiting: jump straight into it, as in the UX flow.
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(conversationId: list.first.id),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StaffConversationListScreen(
          title: specific ? 'ส่วนตัว · $subtopic' : 'ส่วนรวม · $subtopic',
          categoryId: category.id,
          subtopic: subtopic,
          specific: specific,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(category.title)),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          int count(bool s) => store
              .staffConversations(
                categoryId: category.id,
                subtopic: subtopic,
                specific: s,
              )
              .length;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              StepHeader(title: subtopic, caption: 'เลือกกล่องข้อความ'),
              OrangeCard(
                title: 'ปรึกษากับพี่ไข่หวาน\n(เจ้าหน้าที่คนไหนก็ได้)',
                subtitle: 'ส่วนรวม · ${count(false)} การสนทนา',
                icon: Icons.groups_rounded,
                badge: store.staffUnread(
                  categoryId: category.id,
                  subtopic: subtopic,
                  specific: false,
                ),
                onTap: () => _open(context, false),
              ),
              OrangeCard(
                title: 'ปรึกษากับพี่ไข่หวาน\n(เจ้าหน้าที่แบบเลือกเฉพาะเจาะจง)',
                subtitle: 'ส่วนตัว (ส่งถึงฉัน) · ${count(true)} การสนทนา',
                icon: Icons.lock_person_rounded,
                badge: store.staffUnread(
                  categoryId: category.id,
                  subtopic: subtopic,
                  specific: true,
                ),
                onTap: () => _open(context, true),
              ),
            ],
          );
        },
      ),
    );
  }
}

class StaffConversationListScreen extends StatelessWidget {
  const StaffConversationListScreen({
    super.key,
    required this.title,
    this.categoryId,
    this.subtopic,
    this.specific,
  });
  final String title;
  final String? categoryId;
  final String? subtopic;
  final bool? specific;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _ConversationList(
        categoryId: categoryId,
        subtopic: subtopic,
        specific: specific,
      ),
    );
  }
}

class _ConversationList extends StatelessWidget {
  const _ConversationList({this.categoryId, this.subtopic, this.specific});
  final String? categoryId;
  final String? subtopic;
  final bool? specific;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final list = store.staffConversations(
          categoryId: categoryId,
          subtopic: subtopic,
          specific: specific,
        );
        if (list.isEmpty) {
          return const Center(
            child: Text(
              'ยังไม่มีข้อความในหมวดนี้',
              style: TextStyle(color: AppColors.muted),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: list.length,
          separatorBuilder: (_, _) => const Divider(height: 1, indent: 84),
          itemBuilder: (_, i) =>
              ConversationTile(conv: list[i], forStaff: true),
        );
      },
    );
  }
}

class StaffInboxScreen extends StatefulWidget {
  const StaffInboxScreen({super.key});

  @override
  State<StaffInboxScreen> createState() => _StaffInboxScreenState();
}

class _StaffInboxScreenState extends State<StaffInboxScreen> {
  bool? _specific;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ข้อความทั้งหมด')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SegmentedButton<bool?>(
              segments: const [
                ButtonSegment(value: null, label: Text('ทั้งหมด')),
                ButtonSegment(value: false, label: Text('ส่วนรวม')),
                ButtonSegment(value: true, label: Text('ส่วนตัว')),
              ],
              selected: {_specific},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _specific = s.first),
            ),
          ),
          Expanded(child: _ConversationList(specific: _specific)),
        ],
      ),
    );
  }
}

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ระบบรายงาน')),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final list = store.reports;
          if (list.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'ยังไม่มีรายงาน\nกดปุ่ม !! สีแดงมุมขวาบนในห้องแชท เพื่อรายงานการสนทนา',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted),
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final r = list[i];
              final conv = store.conversation(r.conversationId);
              final student = store.user(conv.studentId);
              final reporter = store.user(r.reporterId);
              return Card(
                color: Colors.white,
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: AppColors.alert.withValues(alpha: 0.3),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(14),
                  leading: const Text(
                    '!!',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppColors.alert,
                    ),
                  ),
                  title: Text(
                    r.reason,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    'นักศึกษา: ${student.name}\n'
                    'เรื่อง: ${MockStore.category(conv.categoryId).title} · ${conv.subtopic}\n'
                    'รายงานโดย ${reporter.displayName} · ${timeLabel(r.time)}'
                    '${r.detail.isNotEmpty ? '\nรายละเอียด: ${r.detail}' : ''}',
                  ),
                  isThreeLine: true,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(conversationId: conv.id),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
