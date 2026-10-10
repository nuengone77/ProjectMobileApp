// หน้าโปรไฟล์ ใช้ร่วมกันทั้งนักศึกษาและเจ้าหน้าที่ (แท็บขวาสุด)
import 'package:flutter/material.dart';

import '../data/mock_store.dart';
import '../data/models.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// แสดงข้อมูลผู้ใช้, ปุ่มรีเซ็ตข้อมูลทดลอง และปุ่มออกจากระบบ
/// นักศึกษาเห็น รหัสนิสิต/ชื่ออังกฤษ/เบอร์/สาขา ส่วนเจ้าหน้าที่เห็น “ชื่อ-สกุล”
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('โปรไฟล์')),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final me = store.currentUser;
          if (me == null) return const SizedBox();
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(child: StaffAvatar(user: me, size: 96)),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  me.isStaff ? me.displayName : me.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Center(
                child: Text(
                  me.isStaff ? 'เจ้าหน้าที่' : 'นักศึกษา',
                  style: const TextStyle(color: AppColors.muted),
                ),
              ),
              const SizedBox(height: 24),
              _Info(
                icon: Icons.email_outlined,
                label: 'Email',
                value: me.email,
              ),
              if (me.isStaff) ...[
                _Info(
                  icon: Icons.badge_outlined,
                  label: 'ชื่อ-สกุล',
                  value: me.name,
                ),
              ] else ...[
                if (me.studentId.isNotEmpty)
                  _Info(
                    icon: Icons.badge_outlined,
                    label: 'รหัสนิสิต',
                    value: me.studentId,
                  ),
                if (me.name.isNotEmpty)
                  _Info(
                    icon: Icons.translate,
                    label: 'ชื่อ-สกุล ',
                    value: me.name,
                  ),
                if (me.phone.isNotEmpty)
                  _Info(
                    icon: Icons.phone_outlined,
                    label: 'เบอร์โทรศัพท์',
                    value: me.phone,
                  ),
                if (MockStore.departmentOf(me.major) != null)
                  _Info(
                    icon: Icons.account_balance_outlined,
                    label: 'ภาควิชา',
                    value: MockStore.departmentOf(me.major)!,
                  ),
                _Info(
                  icon: Icons.school_outlined,
                  label: 'สาขา',
                  value: me.major,
                ),
              ],
              const SizedBox(height: 12),
              // รีเซ็ตข้อมูลทดลอง: ล้างฐานข้อมูลแล้วใส่ข้อมูลตั้งต้นใหม่ (สำหรับเดโม)
              TextButton.icon(
                onPressed: () => _confirmReset(context),
                icon: const Icon(Icons.restart_alt, size: 18),
                label: const Text('รีเซ็ตข้อมูลทดลอง'),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  foregroundColor: AppColors.alert,
                  side: const BorderSide(color: AppColors.alert),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40),
                  ),
                ),
                onPressed: () {
                  // ปิดทุกหน้าที่ซ้อนอยู่ก่อน แล้ว logout -> _RoleGate จะพากลับหน้า Login
                  Navigator.of(context).popUntil((r) => r.isFirst);
                  store.logout();
                },
                icon: const Icon(Icons.logout),
                label: const Text('ออกจากระบบ'),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// ถามยืนยันก่อนรีเซ็ตข้อมูลทดลอง (ลบแชท/นัด/บัญชีที่สมัครเพิ่มทั้งหมด แล้วออกจากระบบ)
Future<void> _confirmReset(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('รีเซ็ตข้อมูลทดลอง?'),
      content: const Text(
        'ข้อมูลทั้งหมดในเครื่อง (แชท นัดหมาย บัญชีที่สมัครเพิ่ม) จะถูกลบ '
        'และกลับเป็นข้อมูลตั้งต้น จากนั้นจะออกจากระบบ',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('ยกเลิก'),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: AppColors.alert),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('รีเซ็ต'),
        ),
      ],
    ),
  );
  if (ok == true && context.mounted) {
    Navigator.of(context).popUntil((r) => r.isFirst);
    store.resetDemoData();
  }
}

/// เปิดดูโปรไฟล์นักศึกษา (ผู้มาปรึกษา) แบบแผ่นเลื่อนขึ้นจากด้านล่าง
/// ใช้ในห้องแชทฝั่งเจ้าหน้าที่: กดที่รูป/ชื่อนักศึกษาบนหัวแชท
/// แสดง รหัสนิสิต, ชื่อ-สกุล, เบอร์โทรศัพท์, สาขา (แบบเดียวกับหน้าโปรไฟล์)
Future<void> showStudentProfile(BuildContext context, AppUser student) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.cream,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
            // หัว: รูป + ชื่อ แบบแถวเดียว ไม่กินพื้นที่จอมาก
            Row(
              children: [
                StaffAvatar(user: student, size: 52),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Text(
                        'โปรไฟล์ผู้มาปรึกษา',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // แสดงครบทุกช่องเสมอ ถ้าไม่มีข้อมูลขึ้นว่า “ไม่ได้ระบุ”
            _Info(
              icon: Icons.badge_outlined,
              label: 'รหัสนิสิต',
              value: _orDash(student.studentId),
            ),
            _Info(
              icon: Icons.translate,
              label: 'ชื่อ-สกุล',
              value: _orDash(student.name),
            ),
            _Info(
              icon: Icons.phone_outlined,
              label: 'เบอร์โทรศัพท์',
              value: _orDash(student.phone),
            ),
            _Info(
              icon: Icons.account_balance_outlined,
              label: 'ภาควิชา',
              value: MockStore.departmentOf(student.major) ?? 'ไม่ได้ระบุ',
            ),
            _Info(
              icon: Icons.school_outlined,
              label: 'สาขา',
              value: _orDash(student.major),
            ),
          ],
        ),
      ),
    ),
  );
}

String _orDash(String v) => v.trim().isEmpty ? 'ไม่ได้ระบุ' : v;

/// แถวแสดงข้อมูล 1 รายการ (ไอคอน + หัวข้อ + ค่า)
class _Info extends StatelessWidget {
  const _Info({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          leading: Icon(icon, color: AppColors.caramel),
          title: Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          subtitle: Text(
            value,
            style: const TextStyle(fontSize: 15, color: AppColors.ink),
          ),
        ),
      ),
    );
  }
}
