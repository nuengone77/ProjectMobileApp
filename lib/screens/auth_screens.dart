import 'package:flutter/material.dart';

import '../data/mock_store.dart';
import '../theme.dart';

class Logo extends StatelessWidget {
  const Logo({super.key, this.size = 96});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: AppColors.orange,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text('🥚', style: TextStyle(fontSize: size * 0.5)),
        ),
        const SizedBox(height: 12),
        const Text(
          'ไข่หวานช่วยได้',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'ปรึกษาพี่ไข่หวานได้ทุกเรื่อง',
          style: TextStyle(color: AppColors.muted),
        ),
      ],
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() => _error = 'กรุณากรอก Email และ password');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    await Future.delayed(const Duration(milliseconds: 500));
    final err = store.login(_email.text, _password.text);
    if (mounted) {
      setState(() {
        _loading = false;
        _error = err;
      });
    }
  }

  void _fill(String email) {
    setState(() {
      _email.text = email;
      _password.text = '1234';
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              children: [
                const Logo(),
                const SizedBox(height: 40),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(hintText: 'Email'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _password,
                  obscureText: _obscure,
                  textAlign: TextAlign.center,
                  onSubmitted: (_) => _login(),
                  decoration: InputDecoration(
                    hintText: 'password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                    prefixIcon: const SizedBox(width: 48),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppColors.alert)),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _loading ? null : _login,
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text('login'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SignUpScreen()),
                  ),
                  child: const Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'ยังไม่มีบัญชี? ',
                          style: TextStyle(color: AppColors.muted),
                        ),
                        TextSpan(
                          text: 'สมัครสมาชิก (sign in)',
                          style: TextStyle(
                            color: AppColors.orangeDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                _DemoAccounts(onPick: _fill),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DemoAccounts extends StatelessWidget {
  const _DemoAccounts({required this.onPick});
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'บัญชีทดลอง (แตะเพื่อกรอกอัตโนมัติ · รหัส 1234)',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                avatar: const Text('🧑‍🎓'),
                label: const Text('นักศึกษา'),
                onPressed: () => onPick('student@kaiwan.ac.th'),
              ),
              for (final s in store.staff)
                ActionChip(
                  avatar: const Text('👩🏻‍💼'),
                  label: Text('จนท. ${s.nickname}'),
                  onPressed: () => onPick(s.email),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  String? _major;
  String? _error;

  void _submit() {
    if (!_form.currentState!.validate()) return;
    final err = store.register(
      email: _email.text,
      password: _password.text,
      name: _name.text,
      major: _major!,
    );
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    Navigator.popUntil(context, (r) => r.isFirst);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('สมัครสมาชิกสำเร็จ ยินดีต้อนรับ ${_name.text} 🎉'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('sign in'),
      ),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            children: [
              const Logo(size: 72),
              const SizedBox(height: 28),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(hintText: 'Email'),
                validator: (v) => (v == null || !v.contains('@'))
                    ? 'กรุณากรอกอีเมลให้ถูกต้อง'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _password,
                obscureText: true,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(hintText: 'password'),
                validator: (v) => (v == null || v.length < 4)
                    ? 'รหัสผ่านอย่างน้อย 4 ตัวอักษร'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _name,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(hintText: 'ชื่อ-สกุล'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'กรุณากรอกชื่อ-สกุล'
                    : null,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _major,
                isExpanded: true,
                alignment: Alignment.center,
                hint: const Center(child: Text('สาขา')),
                borderRadius: BorderRadius.circular(16),
                items: [
                  for (final m in MockStore.majors)
                    DropdownMenuItem(
                      value: m,
                      child: Center(child: Text(m)),
                    ),
                ],
                onChanged: (v) => setState(() => _major = v),
                validator: (v) => v == null ? 'กรุณาเลือกสาขา' : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.alert),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(onPressed: _submit, child: const Text('sign in')),
            ],
          ),
        ),
      ),
    );
  }
}
