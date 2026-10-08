import 'package:flutter/material.dart';

import 'data/mock_store.dart';
import 'screens/auth_screens.dart';
import 'screens/staff_screens.dart';
import 'screens/student_screens.dart';
import 'theme.dart';

void main() {
  runApp(const KaiwanApp());
}

class KaiwanApp extends StatelessWidget {
  const KaiwanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ไข่หวานช่วยได้',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const _RoleGate(),
    );
  }
}

/// Switches between login, the student app and the staff app based on who
/// is signed in to the mock store.
class _RoleGate extends StatelessWidget {
  const _RoleGate();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final me = store.currentUser;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: me == null
              ? const LoginScreen(key: ValueKey('login'))
              : me.isStaff
              ? StaffShell(key: ValueKey('staff-${me.id}'))
              : StudentShell(key: ValueKey('student-${me.id}')),
        );
      },
    );
  }
}
