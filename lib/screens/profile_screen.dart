// หน้าโปรไฟล์ ใช้ร่วมกันทั้งนักศึกษาและเจ้าหน้าที่ (แท็บขวาสุด)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/app_store.dart';
import '../data/models.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// แสดงข้อมูลผู้ใช้ และปุ่มออกจากระบบ
/// นักศึกษาแก้ เบอร์โทร และ ภาควิชา/สาขา ได้เอง (ปุ่มดินสอท้ายแถว)
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
              // นิสิต: รูปแมวไข่หวานโบกมือ (แบบเดียวกับหน้าแรก), เจ้าหน้าที่: รูปเจ้าหน้าที่
              Center(
                child: me.isStaff
                    ? StaffAvatar(user: me, size: 96)
                    : Container(
                        width: 96,
                        height: 96,
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset(studentAvatarImage),
                      ),
              ),
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
                _Info(
                  icon: Icons.phone_outlined,
                  label: 'เบอร์โทรศัพท์',
                  value: me.phone.isEmpty ? 'ไม่ได้ระบุ' : me.phone,
                  onEdit: () => _editPhone(context, me.phone),
                ),
                _Info(
                  icon: Icons.account_balance_outlined,
                  label: 'ภาควิชา',
                  value: AppStore.departmentOf(me.major) ?? 'ไม่ได้ระบุ',
                  onEdit: () => _editMajor(context, me.major),
                ),
                _Info(
                  icon: Icons.school_outlined,
                  label: 'สาขา',
                  value: me.major.isEmpty ? 'ไม่ได้ระบุ' : me.major,
                  onEdit: () => _editMajor(context, me.major),
                ),
              ],
              const SizedBox(height: 28),
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
                        'โปรไฟล์ผู้มาถาม/ตอบ',
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
              value: AppStore.departmentOf(student.major) ?? 'ไม่ได้ระบุ',
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
  const _Info({
    required this.icon,
    required this.label,
    required this.value,
    this.onEdit,
  });
  final IconData icon;
  final String label;
  final String value;

  /// ใส่ = แสดงปุ่มดินสอท้ายแถวให้แก้ข้อมูลได้
  final VoidCallback? onEdit;

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
          trailing: onEdit == null
              ? null
              : IconButton(
                  tooltip: 'แก้ไข$label',
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: AppColors.caramel,
                    size: 20,
                  ),
                  onPressed: onEdit,
                ),
        ),
      ),
    );
  }
}

/// แก้เบอร์โทร: หน้าต่างกรอกเบอร์ใหม่ (10 หลัก ขึ้นต้นด้วย 0)
Future<void> _editPhone(BuildContext context, String current) async {
  final phone = await showDialog<String>(
    context: context,
    builder: (_) => _PhoneDialog(current: current),
  );
  if (phone == null || !context.mounted) return;
  store.updateMyProfile(phone: phone);
  ScaffoldMessenger.of(context)
      .showSnackBar(const SnackBar(content: Text('บันทึกเบอร์โทรแล้ว')));
}

class _PhoneDialog extends StatefulWidget {
  const _PhoneDialog({required this.current});
  final String current;

  @override
  State<_PhoneDialog> createState() => _PhoneDialogState();
}

class _PhoneDialogState extends State<_PhoneDialog> {
  late final _phone = TextEditingController(text: widget.current);
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  void _save() {
    if (!AppStore.isValidPhone(_phone.text)) {
      setState(() => _error = 'เบอร์โทร 10 หลัก ขึ้นต้นด้วย 0');
      return;
    }
    Navigator.pop(context, _phone.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('แก้ไขเบอร์โทรศัพท์'),
      content: TextField(
        controller: _phone,
        autofocus: true,
        keyboardType: TextInputType.phone,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(10),
        ],
        decoration: InputDecoration(hintText: '0xxxxxxxxx', errorText: _error),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ยกเลิก'),
        ),
        TextButton(onPressed: _save, child: const Text('บันทึก')),
      ],
    );
  }
}

/// แก้ภาควิชา/สาขา: เลือกภาควิชาก่อน แล้วเลือกสาขาในภาควิชานั้น (แบบเดียวกับตอนสมัคร)
Future<void> _editMajor(BuildContext context, String current) async {
  final major = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _MajorSheet(current: current),
  );
  if (major == null || !context.mounted) return;
  store.updateMyProfile(major: major);
  ScaffoldMessenger.of(context)
      .showSnackBar(const SnackBar(content: Text('บันทึกภาควิชา/สาขาแล้ว')));
}

class _MajorSheet extends StatefulWidget {
  const _MajorSheet({required this.current});
  final String current;

  @override
  State<_MajorSheet> createState() => _MajorSheetState();
}

class _MajorSheetState extends State<_MajorSheet> {
  late String? _department = AppStore.departmentOf(widget.current);
  late String? _major = _department == null ? null : widget.current;

  @override
  Widget build(BuildContext context) {
    Widget dropdown({
      required String label,
      required String? value,
      required List<String> options,
      required ValueChanged<String?> onChanged,
    }) => DropdownButtonFormField<String>(
      key: ValueKey('$label-$value'),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final o in options)
          DropdownMenuItem(
            value: o,
            child: Text(o, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: onChanged,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'แก้ไขภาควิชา/สาขา',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            dropdown(
              label: 'ภาควิชา',
              value: _department,
              options: AppStore.departments.keys.toList(),
              // เปลี่ยนภาควิชา -> ต้องเลือกสาขาใหม่
              onChanged: (v) => setState(() {
                _department = v;
                _major = null;
              }),
            ),
            const SizedBox(height: 12),
            dropdown(
              label: 'สาขา',
              value: _major,
              options: AppStore.departments[_department] ?? const [],
              onChanged: (v) => setState(() => _major = v),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _major == null
                  ? null
                  : () => Navigator.pop(context, _major),
              child: const Text('บันทึก'),
            ),
          ],
        ),
      ),
    );
  }
}
