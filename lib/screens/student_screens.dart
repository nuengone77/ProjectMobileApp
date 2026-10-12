// หน้าจอฝั่งนักศึกษา
//
// ลำดับการใช้งาน (ตามไฟล์ UX/UI):
//   StudentHome (เลือกหัวข้อ 2 แบบ)
//     - ขอความช่วยเหลือแบบเร่งด่วน -> เข้าแชททันที (ส่งถึงเจ้าหน้าที่ทุกคน)
//     - ถาม/ตอบเรื่องทั่วไป -> ConsultChannelScreen (เลือกช่องทาง)
//          - ที่ห้องกิจการนิสิต -> ConsultModeScreen(inPerson) (คนไหนก็ได้ / เลือกเจาะจง)
//               -> (StaffPickerScreen) -> AppointmentBookingScreen (นัดวัน/เวลา)
//          - ผ่านแอป -> ConsultModeScreen (คนไหนก็ได้ / เลือกเจาะจง)
//               - คนไหนก็ได้  -> เข้าแชททันที
//               - เลือกเจาะจง -> StaffPickerScreen (เลือกพี่) -> เข้าแชท
import 'package:flutter/material.dart';

import '../data/mock_store.dart';
import '../data/models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'appointment_screens.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';

/// โครงหลักฝั่งนักศึกษา: แถบเมนูล่าง 4 แท็บ (หน้าแรก / แชทของฉัน / นัดหมาย / โปรไฟล์)
/// แท็บ “แชทของฉัน” มี badge ข้อความที่ยังไม่อ่าน, แท็บ “นัดหมาย” มี badge เมื่อพี่ตอบคำขอนัด
class StudentShell extends StatefulWidget {
  const StudentShell({super.key});

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
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
        final unread = store.studentUnreadTotal;
        final apptUpdates = store.studentAppointmentUpdates;
        // อยู่ที่แท็บนัดหมายอยู่แล้ว = เห็นสถานะใหม่แล้ว ล้าง badge
        if (_tab == 2 && apptUpdates > 0) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => store.markAppointmentsSeen(),
          );
        }
        return Scaffold(
          body: IndexedStack(
            index: _tab,
            children: const [
              StudentHome(),
              MyChatsScreen(),
              MyAppointmentsScreen(),
              ProfileScreen(),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tab,
            backgroundColor: AppColors.surface,
            indicatorColor: AppColors.honey,
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
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: apptUpdates > 0,
                  label: Text('$apptUpdates'),
                  child: const Icon(Icons.event_outlined),
                ),
                selectedIcon: const Icon(Icons.event),
                label: 'นัดหมาย',
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

/// หน้าแรกนักศึกษา: คำทักทาย, แถบแจ้งว่าข้อมูลเป็นความลับ และการ์ดหัวข้อการปรึกษา 2 แบบ
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
                      'วันนี้อยากคุยกับพี่ไข่หวานเรื่องอะไรดี?',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              // โลโก้มุมขวาบน: รูปแมวไข่หวาน
              const CatAvatar(size: 52),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.shield_moon_outlined,
                  color: AppColors.caramel,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'ข้อมูลการสนทนาของคุณเป็นความลับ',
                    style: const TextStyle(fontSize: 13, color: AppColors.ink),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'เลือกหัวข้อที่ต้องการ',
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
              color: c.urgent ? AppColors.urgentSoft : null,
              onTap: () => c.urgent
                  // เร่งด่วน: ไม่ต้องเลือกเจ้าหน้าที่ ส่งถึงเจ้าหน้าที่ทุกคนแล้วเข้าแชทเลย
                  ? openChat(context, category: c)
                  : Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ConsultChannelScreen(category: c),
                      ),
                    ),
            ),
        ],
      ),
    );
  }
}

/// เลือกช่องทางถามตอบ (หลังกดหัวข้อถาม/ตอบเรื่องทั่วไป)
/// - ที่ห้องกิจการนิสิต -> เลือกคนไหนก็ได้/เลือกพี่เอง -> หน้านัดหมาย (วัน/เวลา 30 นาที)
/// - ผ่านแอป          -> หน้าเลือกแชทกลุ่ม (คนไหนก็ได้) หรือแบบเดี่ยว (เจาะจง)
class ConsultChannelScreen extends StatelessWidget {
  const ConsultChannelScreen({super.key, required this.category});
  final ConsultCategory category;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(category.title),
        actions: const [HomeButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const StepHeader(
            title: 'อยากถามตอบแบบไหน?',
            caption: 'เจอพี่ตัวจริงที่ห้อง หรือคุยผ่านแอปก็ได้',
          ),
          OrangeCard(
            title: 'ถามตอบกับพี่ไข่หวานที่ห้องกิจการนิสิต',
            subtitle: 'นัดวันและเวลา ครั้งละ 30 นาที',
            icon: Icons.meeting_room_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ConsultModeScreen(category: category, inPerson: true),
              ),
            ),
          ),
          OrangeCard(
            title: 'ถามตอบกับพี่ไข่หวานผ่านแอปพลิเคชัน',
            subtitle: 'แชทได้ทันที',
            icon: Icons.chat_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ConsultModeScreen(category: category),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// เลือกว่าจะคุยกับเจ้าหน้าที่คนไหนก็ได้ หรือเลือกเจ้าหน้าที่เอง
/// ใช้ทั้ง 2 ช่องทาง ([inPerson]):
/// - ผ่านแอป (inPerson = false)
///     - คนไหนก็ได้ -> เข้าแชทกลุ่มทันที
///     - เลือกเอง   -> หน้าเลือกพี่ -> แชทเดี่ยว
/// - ที่ห้องกิจการนิสิต (inPerson = true)
///     - คนไหนก็ได้ -> หน้าจองนัด (แจ้งเตือนเจ้าหน้าที่ทุกคน)
///     - เลือกเอง   -> หน้าเลือกพี่ -> หน้าจองนัด (แจ้งเตือนเฉพาะคนที่เลือก)
class ConsultModeScreen extends StatelessWidget {
  const ConsultModeScreen({
    super.key,
    required this.category,
    this.inPerson = false,
  });
  final ConsultCategory category;
  final bool inPerson;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(inPerson ? 'นัดที่ห้องกิจการนิสิต' : category.title),
        actions: const [HomeButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          StepHeader(
            title: inPerson ? 'อยากนัดกับพี่คนไหน?' : 'เลือกรูปแบบการถามคอบ',
            caption: inPerson
                ? 'ให้พี่คนไหนก็ได้ที่ว่างรับนัด หรือเลือกพี่เอง'
                : 'อยากคุยกับพี่ไข่หวานแบบไหนดี?',
          ),
          OrangeCard(
            title: 'ถามตอบกับพี่ไข่หวาน\n(เจ้าหน้าที่คนไหนก็ได้)',
            subtitle: inPerson
                ? 'แจ้งเวลานัดถึงพี่ไข่หวานทุกคน'
                : 'เข้าแชทได้ทันที ตอบเร็วที่สุด',
            icon: Icons.groups_rounded,
            onTap: () => inPerson
                ? Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AppointmentBookingScreen(),
                    ),
                  )
                : openChat(context, category: category),
          ),
          OrangeCard(
            title: 'ถามตอบกับพี่ไข่หวาน\n(เจ้าหน้าที่แบบเลือกเฉพาะเจาะจง)',
            subtitle: inPerson
                ? 'แจ้งเวลานัดถึงพี่คนที่เลือกเท่านั้น'
                : 'เลือกพี่ที่อยากคุยด้วยเอง',
            icon: Icons.person_search_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    StaffPickerScreen(category: category, inPerson: inPerson),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// หน้าเลือกเจ้าหน้าที่ (พี่ไข่หวาน) แสดงรูปและชื่อ
/// แตะคนไหนแล้ว: ผ่านแอป -> เข้าแชทกับคนนั้น, ที่ห้อง ([inPerson]) -> จองนัดกับคนนั้น
class StaffPickerScreen extends StatelessWidget {
  const StaffPickerScreen({
    super.key,
    required this.category,
    this.inPerson = false,
  });
  final ConsultCategory category;
  final bool inPerson;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เลือกพี่ไข่หวาน'),
        actions: const [HomeButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          StepHeader(
            title: inPerson ? 'อยากนัดกับพี่คนไหน?' : 'อยากคุยกับพี่คนไหน?',
            caption: inPerson
                ? 'เฉพาะพี่ที่เลือกเท่านั้นที่จะได้รับแจ้งเตือนเวลานัด'
                : 'หัวข้อ: ${category.title}',
          ),
          for (final s in store.staff)
            OrangeCard(
              leading: StaffAvatar(user: s, size: 54),
              title: s.displayName,
              // แสดงแค่รูป + ชื่อ (ไม่แสดงความเชี่ยวชาญ/สถานะออนไลน์)
              onTap: () => inPerson
                  ? Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AppointmentBookingScreen(staffId: s.id),
                      ),
                    )
                  : openChat(context, category: category, staffId: s.id),
            ),
        ],
      ),
    );
  }
}

/// สร้าง/เปิดห้องแชท แล้วพาเข้าหน้าแชททันที
/// ซ้อนต่อจากหน้าเลือก: กดย้อนกลับจากแชทจะกลับไปหน้าที่ผ่านมา
/// (ถ้าจะกลับหน้าหลักเลย ใช้ปุ่มบ้านมุมขวาบน)
void openChat(
  BuildContext context, {
  required ConsultCategory category,
  String? staffId,
}) {
  final conv = store.openConversation(
    categoryId: category.id,
    staffId: staffId,
  );
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => ChatScreen(conversationId: conv.id)),
  );
}

/// แท็บ “แชทของฉัน”: รายการแชททั้งหมดของนักศึกษา เรียงจากล่าสุด
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
                'ยังไม่มีการถามตอบ\nเลือกหัวข้อที่หน้าแรกเพื่อเริ่มแชทได้เลย',
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

/// แถวรายการแชท 1 ห้อง ใช้ทั้งสองฝั่ง ([forStaff] = มุมมองเจ้าหน้าที่)
/// แสดงชื่ออีกฝ่าย, หัวข้อ (เร่งด่วนเป็นสีแดง), ข้อความล่าสุด, เวลา และเลขที่ยังไม่อ่าน
/// ฝั่งนักศึกษา: ห้องที่มีข้อความใหม่พื้นหลังเหลืองทองอ่อน
/// ฝั่งเจ้าหน้าที่: พื้นหลังตามหัวข้อ เร่งด่วน = แดงอ่อน, ทั่วไป = เขียวอ่อน
/// ห้องที่จบแล้ว (ฝั่งเจ้าหน้าที่) แสดงสรุปการปรึกษาแทนข้อความล่าสุด
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
    // ฝั่งนักศึกษา แชทส่วนรวม = “แชทรวมเจ้าหน้าที่” + รูปแมวไข่หวาน (เหมือนหัวห้องแชท)
    final sharedForStudent = !forStaff && !conv.isSpecific;
    final title = forStaff
        ? '${other!.name} · ${other.major}'
        : sharedForStudent
        ? 'แชทรวมเจ้าหน้าที่'
        : (other?.displayName ?? 'พี่ไข่หวาน (คนไหนก็ได้)');
    final last = conv.last;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      // ฝั่งเจ้าหน้าที่: แยกหัวข้อด้วยสีพื้นหลัง (เร่งด่วน = แดงอ่อน, ทั่วไป = เขียวอ่อน)
      // ฝั่งนักศึกษา: ไฮไลต์เหลืองทองอ่อนเมื่อมีข้อความใหม่
      tileColor: forStaff
          ? (cat.urgent ? AppColors.urgentSoft : AppColors.generalSoft)
          : (unread > 0 ? AppColors.honey.withValues(alpha: 0.15) : null),
      leading: sharedForStudent
          ? const CatAvatar(size: 52)
          : other != null
          ? StaffAvatar(user: other, size: 52)
          : const CatAvatar(size: 52),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ป้ายหัวข้อ: ฝั่งเจ้าหน้าที่ไม่แสดงป้าย “เร่งด่วน” (ใช้พื้นหลังแดงอ่อนแทน)
          if (!(forStaff && cat.urgent))
            Text(
              cat.urgent
                  ? '🚨 ${cat.title}'
                  : '${cat.title}${conv.isSpecific ? ' · ส่วนตัว' : ''}',
              style: TextStyle(
                fontSize: 12,
                color: cat.urgent ? AppColors.alert : AppColors.caramel,
                fontWeight: FontWeight.w600,
              ),
            ),
          // ประวัติฝั่งเจ้าหน้าที่: แสดงสรุปการปรึกษาแทนข้อความล่าสุด
          if (forStaff && conv.closed)
            Text(
              conv.hasSummary
                  ? '${conv.caseLevel?.emoji ?? ''} สรุป: ${conv.summaryTopic}'
                        .trim()
                  : 'ยังไม่ได้บันทึกสรุป',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: conv.hasSummary ? AppColors.ink : AppColors.alert,
              ),
            )
          else if (last != null)
            Text(
              last.isAlert ? MockStore.emergencyMessage : last.preview,
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
