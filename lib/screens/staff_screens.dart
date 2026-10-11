// หน้าจอฝั่งเจ้าหน้าที่
//
// ลำดับการใช้งาน (ตามไฟล์ UX/UI):
//   StaffHome: ตัวเลขสรุป + การ์ดประวัติการปรึกษาแยกหัวข้อ (ทั่วไป / เร่งด่วน)
//     - การ์ดหัวข้อ -> StaffConversationsScreen(closed: true) ประวัติแชทที่จบแล้วพร้อมสรุป
//   แท็บ “ข้อความ” (StaffInboxScreen) = แชทที่ยังคุยอยู่ เรียงลงมา
//   จบการปรึกษา: เจ้าหน้าที่กรอกสรุป (เรื่องที่ปรึกษา / ช่วยอะไรได้บ้าง) ใน chat_screen.dart
// แท็บอื่น: นัดหมาย (StaffAppointmentsScreen), โปรไฟล์
import 'package:flutter/material.dart';

import '../data/mock_store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'appointment_screens.dart';
import 'profile_screen.dart';
import 'report_screen.dart';
import 'student_screens.dart' show ConversationTile;

/// โครงหลักฝั่งเจ้าหน้าที่: แถบเมนูล่าง 4 แท็บ
/// (ข้อความ / นัดหมาย / ภาพรวม / โปรไฟล์) ล็อกอินแล้วเห็นแท็บข้อความก่อน
/// พร้อม badge ข้อความที่ยังไม่อ่าน และคำขอนัดที่รอยืนยัน
class StaffShell extends StatefulWidget {
  const StaffShell({super.key});

  @override
  State<StaffShell> createState() => _StaffShellState();
}

class _StaffShellState extends State<StaffShell> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    homeTabSignal.addListener(_goFirstTab);
  }

  @override
  void dispose() {
    homeTabSignal.removeListener(_goFirstTab);
    super.dispose();
  }

  void _goFirstTab() => setState(() => _tab = 0);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final unread = store.staffUnread();
        final pendingAppts = store.pendingAppointmentCount;
        return Scaffold(
          body: IndexedStack(
            index: _tab,
            children: const [
              StaffInboxScreen(),
              StaffAppointmentsScreen(),
              StaffHome(),
              ProfileScreen(),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tab,
            backgroundColor: AppColors.surface,
            indicatorColor: AppColors.honey,
            onDestinationSelected: (i) => setState(() => _tab = i),
            destinations: [
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
                  isLabelVisible: pendingAppts > 0,
                  label: Text('$pendingAppts'),
                  child: const Icon(Icons.event_outlined),
                ),
                selectedIcon: Badge(
                  isLabelVisible: pendingAppts > 0,
                  label: Text('$pendingAppts'),
                  child: const Icon(Icons.event),
                ),
                label: 'นัดหมาย',
              ),
              const NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: 'ภาพรวม',
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

/// แท็บภาพรวมของเจ้าหน้าที่: ข้อมูลตัวเอง, ตัวเลขสรุป และการ์ดประวัติการปรึกษาแยกหัวข้อ
/// (นัดหมายดูที่แท็บ “นัดหมาย”)
class StaffHome extends StatelessWidget {
  const StaffHome({super.key});

  // ฟัง store เพื่อให้ตัวเลขบนกระดิ่งอัปเดตทันทีเมื่อมีข้อความใหม่เข้ามา
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) =>
        store.currentUser == null ? const SizedBox() : _content(context),
  );

  Widget _content(BuildContext context) {
    final me = store.currentUser!;
    // ตัวเลขสรุป: จำนวนที่ “ฉัน” ให้คำปรึกษาไปแล้ว (แชทที่จบแล้ว) แยกเร่งด่วน / ทั่วไป
    final urgentDone = store.staffConsultedCount('urgent');
    final generalDone = store.staffConsultedCount('general');
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          Row(
            children: [
              StaffAvatar(user: me, size: 52),
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
                      'เจ้าหน้าที่',
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
                label: 'ให้คำปรึกษาเร่งด่วนแล้ว',
                value: urgentDone,
                color: AppColors.alert,
              ),
              const SizedBox(width: 12),
              _Stat(
                label: 'ให้คำปรึกษาทั่วไปแล้ว',
                value: generalDone,
                color: AppColors.info,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _Heading('ประวัติการปรึกษา (จบแล้ว)'),
          // แต่ละหัวข้อ = ประวัติแชทที่จบการปรึกษาแล้ว (แชทที่ยังคุยอยู่ดูที่แท็บ “ข้อความ”)
          for (final c in MockStore.categories)
            Builder(
              builder: (context) {
                final done = store.staffConversations(
                  categoryId: c.id,
                  closed: true,
                );
                final noSummary = done.where((x) => !x.hasSummary).length;
                return OrangeCard(
                  title: c.title,
                  subtitle:
                      '${done.length} การสนทนาที่จบแล้ว'
                      '${noSummary > 0 ? ' · ยังไม่สรุป $noSummary' : ''}',
                  icon: c.icon,
                  color: c.urgent ? AppColors.urgentSoft : null,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StaffConversationsScreen(
                        title: 'ประวัติ · ${c.title}',
                        categoryId: c.id,
                        closed: true,
                      ),
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 10),
          const _Heading('รายงาน'),
          // ตารางสรุปเคสของฉัน (online + onsite) export ส่งส่วนกลางได้
          OrangeCard(
            title: 'ตารางสรุปเคส',
            subtitle: 'เคสของฉัน · export CSV / PDF',
            icon: Icons.table_chart_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StaffReportScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

/// การ์ดตัวเลขสรุป (ตัวเลขใหญ่ + คำอธิบาย) บนหน้าแรกเจ้าหน้าที่
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
          color: AppColors.surface,
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

/// หัวข้อกลุ่มบนหน้าแรกเจ้าหน้าที่
class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
    ),
  );
}

/// รายการแชทของเจ้าหน้าที่ เรียงลงมา พร้อมปุ่มกรอง ทั้งหมด / ส่วนรวม / ส่วนตัว
/// - [closed] = false: แชทที่ยังคุยอยู่ (แท็บ “ข้อความ”) เร่งด่วน/ยังไม่อ่านขึ้นก่อน
/// - [closed] = true: ประวัติแชทที่จบแล้ว (จากการ์ดบนหน้าแรก) จบล่าสุดขึ้นก่อน
class StaffConversationsScreen extends StatefulWidget {
  const StaffConversationsScreen({
    super.key,
    required this.title,
    required this.closed,
    this.categoryId,
  });
  final String title;
  final bool closed;
  final String? categoryId;

  @override
  State<StaffConversationsScreen> createState() =>
      _StaffConversationsScreenState();
}

class _StaffConversationsScreenState extends State<StaffConversationsScreen> {
  bool? _specific; // null = ทั้งหมด, false = ส่วนรวม, true = ส่วนตัว

  @override
  Widget build(BuildContext context) {
    // หัวข้อเร่งด่วนเป็นแชทรวมเสมอ ไม่ต้องมีตัวกรองส่วนรวม/ส่วนตัว
    final showFilter =
        widget.categoryId == null ||
        !MockStore.category(widget.categoryId!).urgent;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          if (showFilter)
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
          Expanded(
            child: ListenableBuilder(
              listenable: store,
              builder: (context, _) {
                final list = store.staffConversations(
                  categoryId: widget.categoryId,
                  specific: showFilter ? _specific : null,
                  closed: widget.closed,
                );
                if (list.isEmpty) {
                  return Center(
                    child: Text(
                      widget.closed
                          ? 'ยังไม่มีประวัติการปรึกษา'
                          : 'ยังไม่มีแชทที่รอคุย',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  );
                }
                // เส้นคั่นแต่ละแถว: สีเข้มเต็มความกว้าง แบบเดียวกับขอบปุ่มกรองด้านบน
                // มีเส้นบนแถวแรกและใต้แถวสุดท้ายด้วย
                final line = Divider(
                  height: 1,
                  thickness: 1,
                  color: Theme.of(context).colorScheme.outline,
                );
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => line,
                  itemBuilder: (_, i) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (i == 0) line,
                      ConversationTile(conv: list[i], forStaff: true),
                      if (i == list.length - 1) line,
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// แท็บ “ข้อความ”: แชทที่ยังไม่จบทั้งหมดที่เจ้าหน้าที่เห็นได้
class StaffInboxScreen extends StatelessWidget {
  const StaffInboxScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const StaffConversationsScreen(title: 'ข้อความ', closed: false);
}
