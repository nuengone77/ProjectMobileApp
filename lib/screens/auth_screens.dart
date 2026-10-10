// หน้าเข้าสู่ระบบ (Login) และหน้าสมัครสมาชิก (sign in) ตามแบบ “Login and Sign in”
// - Login: โลโก้ “ไข่หวานช่วยด้วย” + Email + password + ปุ่ม login + ลิงก์สมัครสมาชิก
// - Sign in: รูปแมวไข่หวาน + ฟอร์มสมัคร -> กด sign in แล้วเด้งหน้า License Agreement
//   กด Accept Terms ถึงจะสมัครสำเร็จ, กด Reject = ยังไม่สมัคร
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/mock_store.dart';
import '../data/registration_rules.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// โลโก้ตัวหนังสือ “ไข่หวานช่วยด้วย” (ใช้บนหน้า Login)
const _loginLogo = 'assets/images/login_logo.png';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

/// หน้า Login: โลโก้, ช่อง Email + password, ปุ่ม login, ลิงก์ไปสมัครสมาชิก
/// ด้านล่างมีปุ่มเล็ก “บัญชีทดลอง” (ซ่อนไว้) สำหรับเดโม
/// พอล็อกอินสำเร็จ _RoleGate ใน main.dart จะพาไปหน้านักศึกษา/เจ้าหน้าที่เอง
class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  bool _showDemo = false; // เปิด/ปิดกล่องบัญชีทดลอง
  String? _error; // ข้อความ error ที่แสดงใต้ช่องกรอก (null = ไม่มี)

  /// ตรวจว่ากรอกครบ แล้วส่งไปเช็กกับ store (หน่วง 0.5 วิ ให้ดูเหมือนรอ server)
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

  /// กรอกอีเมล + รหัสผ่านของบัญชีนั้นให้อัตโนมัติ เมื่อแตะชิปบัญชีทดลอง
  void _fill(String email) {
    setState(() {
      _email.text = email;
      // ฐานข้อมูลเก็บแค่ hash จึงใช้รหัสผ่านตัวจริงจากรายการบัญชีทดลอง
      _password.text = MockStore.demoPasswords[email] ?? '';
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              children: [
                Image.asset(_loginLogo, height: 170, fit: BoxFit.contain),
                const SizedBox(height: 32),
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
                    // เว้นซ้ายเท่าไอคอนตา ให้ข้อความอยู่กึ่งกลางจริง
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
                            color: AppColors.caramel,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // บัญชีทดลอง: ซ่อนไว้ กดแล้วค่อยแสดง (มีไว้เพื่อเดโมเท่านั้น)
                TextButton.icon(
                  onPressed: () => setState(() => _showDemo = !_showDemo),
                  icon: Icon(
                    _showDemo ? Icons.expand_less : Icons.science_outlined,
                    size: 16,
                    color: AppColors.muted,
                  ),
                  label: const Text(
                    'บัญชีทดลอง',
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                ),
                if (_showDemo) _DemoAccounts(onPick: _fill),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// กล่องชิปบัญชีทดลอง (นักศึกษา 1 + เจ้าหน้าที่ทุกคน) มีไว้เพื่อเดโมเท่านั้น
/// ลบออกได้เมื่อใช้งานจริง
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
            'แตะเพื่อกรอกอีเมลและรหัสผ่านอัตโนมัติ',
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
                onPressed: () => onPick('somjaij67@nu.ac.th'),
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

/// หน้าสมัครสมาชิก (sign in):
/// Email, password, รหัสนิสิต, ชื่อ-สกุล, ชื่อ-สกุลภาษาอังกฤษ, เบอร์โทร, ภาควิชา -> สาขา (dropdown)
/// กด sign in -> ตรวจฟอร์ม -> เด้ง License Agreement -> Accept Terms แล้วถึงสมัครและล็อกอินให้
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _studentId = TextEditingController();
  final _name = TextEditingController();
  final _nameEn = TextEditingController();
  final _phone = TextEditingController();
  String? _department; // ภาควิชาที่เลือก (ต้องเลือกก่อนเลือกสาขา)
  String? _major;
  String? _error;

  /// ตรวจฟอร์ม -> แสดงข้อตกลง -> ยอมรับแล้วสมัครใน store -> กลับหน้าแรก (เป็นหน้านักศึกษา)
  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate()) return;
    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const LicenseAgreementDialog(),
    );
    if (accepted != true || !mounted) return;
    final err = store.register(
      email: _email.text,
      password: _password.text,
      name: _name.text,
      major: _major!,
      studentId: _studentId.text,
      nameEn: _nameEn.text,
      phone: _phone.text,
    );
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final name = _name.text;
    Navigator.popUntil(context, (r) => r.isFirst);
    // รอให้แอนิเมชันสลับไปหน้านักศึกษาจบก่อน (ระหว่างสลับมี 2 หน้า ถ้าโชว์ตอนนั้นจะซ้อนกัน)
    Future.delayed(const Duration(milliseconds: 400), () {
      messenger.showSnackBar(
        SnackBar(content: Text('สมัครสมาชิกสำเร็จ ยินดีต้อนรับ $name 🎉')),
      );
    });
  }

  /// ช่องกรอกแบบแคปซูล ข้อความกึ่งกลาง (แบบเดียวกับหน้า Login)
  Widget _field(
    TextEditingController c,
    String hint, {
    String? Function(String?)? validator,
    TextInputType? keyboard,
    bool obscure = false,
    List<TextInputFormatter>? formatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: c,
        obscureText: obscure,
        keyboardType: keyboard,
        inputFormatters: formatters,
        textAlign: TextAlign.center,
        decoration: InputDecoration(hintText: hint, errorMaxLines: 3),
        validator:
            validator ??
            (v) => (v == null || v.trim().isEmpty) ? 'กรุณากรอก$hint' : null,
      ),
    );
  }

  /// ช่องเลือกแบบ dropdown ทรงแคปซูล (ใช้กับ ภาควิชา / สาขา)
  /// ในเมนูชื่อยาวขึ้นได้ 2 บรรทัด, ในช่องที่เลือกแล้วแสดงบรรทัดเดียว
  Widget _choice({
    Key? key,
    required String hint,
    required String? value,
    required List<String> options,
    required ValueChanged<String?>? onChanged,
    required String error,
  }) {
    return DropdownButtonFormField<String>(
      key: key,
      initialValue: value,
      isExpanded: true,
      itemHeight: null,
      alignment: Alignment.center,
      hint: Center(child: Text(hint)),
      borderRadius: BorderRadius.circular(16),
      decoration: const InputDecoration(errorMaxLines: 2),
      selectedItemBuilder: (_) => [
        for (final o in options)
          Center(child: Text(o, maxLines: 1, overflow: TextOverflow.ellipsis)),
      ],
      items: [
        for (final o in options)
          DropdownMenuItem(
            value: o,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(o, maxLines: 2),
            ),
          ),
      ],
      onChanged: onChanged,
      validator: (v) => v == null ? error : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final digitsOnly = [FilteringTextInputFormatter.digitsOnly];
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        title: const Text('sign in'),
      ),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            children: [
              const Center(child: CatAvatar(size: 96)),
              const SizedBox(height: 10),
              const Text(
                'ไข่หวานช่วยด้วย',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const Text(
                'ปรึกษาพี่ไข่หวานได้ทุกเรื่อง',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 24),
              _field(
                _email,
                'Email',
                keyboard: TextInputType.emailAddress,
                // อีเมลมหาลัย @nu.ac.th และต้องตรงกับชื่ออังกฤษ + รหัสนิสิต (ดู registration_rules.dart)
                validator: (v) => RegistrationRules.emailError(
                  v,
                  nameEn: _nameEn.text,
                  studentId: _studentId.text,
                ),
              ),
              _field(
                _password,
                'password',
                obscure: true,
                validator: (v) => (v == null || v.length < 4)
                    ? 'รหัสผ่านอย่างน้อย 4 ตัวอักษร'
                    : null,
              ),
              _field(
                _studentId,
                'รหัสนิสิต',
                keyboard: TextInputType.number,
                formatters: [
                  ...digitsOnly,
                  LengthLimitingTextInputFormatter(8),
                ],
                validator: RegistrationRules.studentIdError,
              ),
              _field(_name, 'ชื่อ-สกุล'),
              _field(
                _nameEn,
                'ชื่อ-สกุล (ภาษาอังกฤษ)',
                keyboard: TextInputType.name,
                validator: RegistrationRules.nameEnError,
              ),
              _field(
                _phone,
                'เบอร์โทรศัพท์',
                keyboard: TextInputType.phone,
                formatters: [
                  ...digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: (v) =>
                    (v == null || !RegExp(r'^0\d{9}$').hasMatch(v))
                    ? 'เบอร์โทร 10 หลัก ขึ้นต้นด้วย 0'
                    : null,
              ),
              // ภาควิชา -> สาขา (รายการสาขาเปลี่ยนตามภาควิชาที่เลือก)
              _choice(
                hint: 'ภาควิชา',
                value: _department,
                options: MockStore.departments.keys.toList(),
                onChanged: (v) => setState(() {
                  _department = v;
                  _major = null; // เปลี่ยนภาควิชาแล้วให้เลือกสาขาใหม่
                }),
                error: 'กรุณาเลือกภาควิชา',
              ),
              const SizedBox(height: 14),
              _choice(
                // key ตามภาควิชา: เปลี่ยนภาควิชาแล้วล้างสาขาที่เลือกไว้
                key: ValueKey(_department),
                hint: _department == null ? 'สาขา (เลือกภาควิชาก่อน)' : 'สาขา',
                value: _major,
                options: MockStore.departments[_department] ?? const [],
                onChanged: _department == null
                    ? null
                    : (v) => setState(() => _major = v),
                error: 'กรุณาเลือกสาขา',
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
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

/// หน้าต่างข้อตกลงการใช้งาน (License Agreement) ที่เด้งขึ้นตอนกด sign in
/// ซ้าย/บน = โลโก้ ไข่หวานช่วยด้วย, ขวา/ล่าง = Terms and Conditions (เลื่อนอ่านได้)
/// Reject = ปิด (คืน false), Accept Terms = ยอมรับ (คืน true)
class LicenseAgreementDialog extends StatelessWidget {
  const LicenseAgreementDialog({super.key});

  /// ข้อความข้อตกลง (ข้อความตัวอย่าง แก้เป็นข้อความจริงได้ที่นี่)
  static const terms = [
    'ข้อมูลที่ใช้สมัคร (อีเมล รหัสนิสิต ชื่อ-สกุล เบอร์โทร สาขา) ใช้เพื่อยืนยันตัวตนและติดต่อกลับในการให้คำปรึกษาเท่านั้น',
    'ข้อความและรายละเอียดการปรึกษาถือเป็นความลับ เปิดเผยเฉพาะเจ้าหน้าที่ที่เกี่ยวข้อง',
    'เจ้าหน้าที่อาจบันทึกสรุปการปรึกษาเพื่อใช้ติดตามและปรับปรุงการให้บริการ',
    'กรณีเร่งด่วนหรือมีความเสี่ยงต่อความปลอดภัย เจ้าหน้าที่อาจติดต่อกลับหรือประสานหน่วยงานที่เกี่ยวข้องเพื่อช่วยเหลือ',
    'ผู้ใช้ต้องใช้ถ้อยคำสุภาพ และไม่ใช้บริการในทางที่ผิดหรือก่อความเดือดร้อนแก่ผู้อื่น',
    '(ข้อความตัวอย่าง จะปรับเป็นข้อตกลงฉบับจริงภายหลัง)',
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 640),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Text(
                'License Agreement',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: LayoutBuilder(
                builder: (context, c) {
                  // จอกว้าง: รูปซ้าย ข้อความขวา (ตามแบบ) / จอแคบ: รูปบน ข้อความล่าง
                  final wide = c.maxWidth > 520;
                  // โลโก้ “ไข่หวานช่วยด้วย” แบบเดียวกับหน้า Login
                  // contain = แสดงครบทั้งรูปไม่ถูกตัด, จอแคบจัดกึ่งกลาง
                  final image = Image.asset(
                    _loginLogo,
                    fit: BoxFit.contain,
                    height: wide ? 140 : 100,
                    width: wide ? 220 : double.infinity,
                  );
                  final text = _TermsBox(terms: terms);
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              image,
                              const SizedBox(width: 16),
                              Expanded(child: text),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              image,
                              const SizedBox(height: 12),
                              Flexible(child: text),
                            ],
                          ),
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              // Wrap: จอแคบแล้วปุ่มไม่พอจะขึ้นบรรทัดใหม่แทนการล้นจอ
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 10,
                runSpacing: 8,
                children: [
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE5E5E5),
                      foregroundColor: AppColors.muted,
                      minimumSize: const Size(96, 42),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Reject'),
                  ),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2EC27E),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(130, 42),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    iconAlignment: IconAlignment.end,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Accept Terms'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// กล่องข้อความ Terms and Conditions (มีกรอบ เลื่อนอ่านได้)
class _TermsBox extends StatelessWidget {
  const _TermsBox({required this.terms});
  final List<String> terms;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(4),
        color: AppColors.cream,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Terms and Conditions',
              style: TextStyle(fontSize: 18, color: AppColors.ink),
            ),
            const SizedBox(height: 10),
            for (final (i, t) in terms.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  i == terms.length - 1 ? t : '${i + 1}. $t',
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: AppColors.muted,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
