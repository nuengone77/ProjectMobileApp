import 'package:flutter/material.dart';

import '../data/mock_store.dart';
import '../theme.dart';
import '../widgets/common.dart';

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
                _Info(
                  icon: Icons.star_outline,
                  label: 'ความเชี่ยวชาญ',
                  value: me.specialty,
                ),
              ] else
                _Info(
                  icon: Icons.school_outlined,
                  label: 'สาขา',
                  value: me.major,
                ),
              const SizedBox(height: 12),
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                child: SwitchListTile(
                  title: const Text('โหมดจำลองการตอบกลับ'),
                  subtitle: const Text(
                    'ให้พี่ไข่หวานตอบกลับอัตโนมัติ (สำหรับเดโม)',
                  ),
                  value: store.autoReply,
                  activeThumbColor: AppColors.orangeDark,
                  onChanged: store.setAutoReply,
                ),
              ),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          leading: Icon(icon, color: AppColors.orangeDark),
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
