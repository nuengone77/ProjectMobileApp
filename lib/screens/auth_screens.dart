// หน้าเข้าสู่ระบบ (Login) และหน้าสมัครสมาชิก (sign in) ตามแบบ “Login and Sign in”
// - Login: โลโก้ “ไข่หวานช่วยด้วย” + Email + password + ปุ่ม login + ลิงก์สมัครสมาชิก
// - Sign in: รูปแมวไข่หวาน + ฟอร์มสมัคร -> กด sign in แล้วเด้งหน้า License Agreement
//   กด Accept Terms ถึงจะสมัครสำเร็จ, กด Reject = ยังไม่สมัคร
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/app_data.dart';
import '../providers/auth_provider.dart';
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
/// พอล็อกอินสำเร็จ _RoleGate ใน main.dart จะพาไปหน้านักศึกษา/เจ้าหน้าที่เอง
class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error; // ข้อความ error ที่แสดงใต้ช่องกรอก (null = ไม่มี)

  /// ตรวจว่ากรอกครบ แล้วส่งไปเช็กกับ AuthProvider (หน่วง 0.5 วิ ให้ดูเหมือนรอ server)
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
    // ดึง Provider ก่อน await (หลัง await ไม่ควรใช้ context)
    final auth = context.read<AuthProvider>();
    await Future.delayed(const Duration(milliseconds: 500));
    final err = auth.login(_email.text, _password.text);
    if (mounted) {
      setState(() {
        _loading = false;
        _error = err;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ส่วนบนขาว = โลโก้, ส่วนล่างเหลือง (ขอบบนโค้ง) = ช่องกรอก + ปุ่ม
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: LayoutBuilder(
        builder: (context, box) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: box.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  SizedBox(height: MediaQuery.paddingOf(context).top + 40),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Image.asset(
                      _loginLogo,
                      height: 160,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Expanded(
                    child: YellowArcPanel(
                      child: Column(
                        children: [
                          TextField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              hintText: 'Email',
                            ),
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
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                              ),
                              // เว้นซ้ายเท่าไอคอนตา ให้ข้อความอยู่กึ่งกลางจริง
                              prefixIcon: const SizedBox(width: 48),
                            ),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.alert,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          PillButton(
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
                              MaterialPageRoute(
                                builder: (_) => const SignUpScreen(),
                              ),
                            ),
                            child: const Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'ยังไม่มีบัญชี? ',
                                    style: TextStyle(
                                      color: AppColors.ink,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  // ตัวหนากว่า “ยังไม่มีบัญชี?” (ตัวปกติ) ให้เห็นชัดว่ากดได้
                                  TextSpan(
                                    text: 'สมัครสมาชิก (sign in)',
                                    style: TextStyle(
                                      color: AppColors.ink,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Text(
                            'แอพพลิเคชันนี้ใช้ได้เฉพาะนิสิตของคณะวิทยาศาสตร์',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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

  /// ตรวจฟอร์ม -> แสดงข้อตกลง -> ยอมรับแล้วสมัครผ่าน AuthProvider -> กลับหน้าแรก (เป็นหน้านักศึกษา)
  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate()) return;
    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const LicenseAgreementDialog(),
    );
    if (accepted != true || !mounted) return;
    final err = context.read<AuthProvider>().register(
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
    // แบบเดียวกับหน้า Login: ส่วนบนขาว = โลโก้, ส่วนล่างเหลือง (ขอบบนโค้ง) = ฟอร์มสมัคร
    return UnsavedChangesGuard(
      // บทที่ 9 (PopScope): กรอกไปแล้วกดย้อนกลับ -> ถามก่อนทิ้งข้อมูล
      isDirty: () =>
          [
            _email,
            _password,
            _studentId,
            _name,
            _nameEn,
            _phone,
          ].any((c) => c.text.isNotEmpty) ||
          _department != null,
      listenable: Listenable.merge([
        _email,
        _password,
        _studentId,
        _name,
        _nameEn,
        _phone,
      ]),
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          title: const Text('sign in'),
        ),
        body: Form(
          key: _form,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                color: AppColors.surface,
                padding: const EdgeInsets.fromLTRB(28, 4, 28, 20),
                child: Column(
                  children: [
                    Image.asset(_loginLogo, height: 110, fit: BoxFit.contain),
                    const SizedBox(height: 6),
                    const Text(
                      'คุยกับพี่ไข่หวานได้ทุกเรื่อง',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              YellowArcPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                      validator: (v) => (v == null || !AppData.isValidPhone(v))
                          ? 'เบอร์โทร 10 หลัก ขึ้นต้นด้วย 0'
                          : null,
                    ),
                    // ภาควิชา -> สาขา (รายการสาขาเปลี่ยนตามภาควิชาที่เลือก)
                    _choice(
                      hint: 'ภาควิชา',
                      value: _department,
                      options: AppData.departments.keys.toList(),
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
                      hint: _department == null
                          ? 'สาขา (เลือกภาควิชาก่อน)'
                          : 'สาขา',
                      value: _major,
                      options: AppData.departments[_department] ?? const [],
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
                    Center(
                      child: PillButton(
                        onPressed: _submit,
                        child: const Text('sign in'),
                      ),
                    ),
                    SizedBox(height: 24 + MediaQuery.paddingOf(context).bottom),
                  ],
                ),
              ),
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

  /// ข้อตกลงและเงื่อนไข แบ่งเป็นหัวข้อ แต่ละหัวข้อมีหลายย่อหน้า
  /// ย่อหน้าที่มี label จะแสดงหัวข้อย่อยตัวหนานำหน้า
  static const terms = <TermsSection>[
    (
      title: 'การจัดเก็บข้อมูลส่วนบุคคลและการรักษาความลับข้อมูลการสมัคร',
      items: [
        (
          label: null,
          text:
              'ข้อมูลที่ใช้สมัคร (เช่น อีเมล รหัสนิสิต ชื่อ-สกุล เบอร์โทร สาขา) '
              'จะถูกนำมาใช้เพื่อยืนยันตัวตนและติดต่อกลับในการให้คำปรึกษาเท่านั้น',
        ),
        (
          label: 'วัตถุประสงค์การจัดเก็บ',
          text:
              'ทางแอปพลิเคชันจะทำการจัดเก็บข้อมูลส่วนบุคคลและประวัติการสนทนาของท่าน '
              'เพื่อใช้เป็นข้อมูลอ้างอิงและประกอบการให้คำปรึกษาในครั้งปัจจุบันและอนาคต '
              'นอกจากนี้ เจ้าหน้าที่อาจบันทึกสรุปการปรึกษาเพื่อใช้ติดตามและปรับปรุงการให้บริการ',
        ),
        (
          label: 'คำมั่นสัญญาด้านความปลอดภัย',
          text:
              'ข้อความและรายละเอียดการปรึกษาถือเป็นความลับ ซึ่งจะเปิดเผยเฉพาะเจ้าหน้าที่ที่เกี่ยวข้องเท่านั้น '
              'ข้อมูลและประวัติการสนทนาทั้งหมดจะถูกจัดเก็บด้วยระบบรักษาความปลอดภัยขั้นสูง '
              'และจะไม่มีการเปิดเผย ส่งต่อ หรือเผยแพร่สู่สาธารณะ '
              'ตลอดจนบุคคลที่สามที่ไม่เกี่ยวข้องโดยเด็ดขาด',
        ),
      ],
    ),
    (
      title: 'ข้อยกเว้นในกรณีฉุกเฉินความปลอดภัยของผู้ใช้',
      items: [
        (
          label: null,
          text:
              'กรณีเร่งด่วนหรือมีความเสี่ยงต่อความปลอดภัย เจ้าหน้าที่อาจติดต่อกลับ'
              'หรือประสานหน่วยงานที่เกี่ยวข้องเพื่อช่วยเหลือ',
        ),
      ],
    ),
    (
      title: 'การขออนุญาตเข้าถึงสิทธิ์บนอุปกรณ์ (Device Permissions)',
      items: [
        (
          label: 'การเข้าถึงไฟล์และคลังรูปภาพ (Photos & Files Access)',
          text:
              'เพื่อให้ท่านสามารถแนบไฟล์หรืออัปโหลดรูปภาพประกอบการสนทนา '
              'เพื่ออธิบายรายละเอียดหรือขอคำปรึกษาเพิ่มเติมได้อย่างสะดวกและครบถ้วน',
        ),
      ],
    ),
    (
      title: 'ข้อปฏิบัติในการใช้บริการ',
      items: [
        (
          label: 'ระเบียบการใช้งาน',
          text: 'ผู้ใช้ต้องใช้ถ้อยคำสุภาพ และไม่ใช้บริการในทางที่ผิดหรือก่อความเดือดร้อนแก่ผู้อื่น',
        ),
        (
          label: null,
          text:
              'การกด "ยอมรับและดำเนินการต่อ" ถือว่าท่านได้รับทราบ ทำความเข้าใจ '
              'และยินยอมให้ทางแอปพลิเคชันจัดเก็บข้อมูล เข้าถึงสิทธิ์บนอุปกรณ์ '
              'รวมถึงยินยอมปฏิบัติตามข้อตกลงและเงื่อนไขการให้บริการตามที่ระบุไว้ข้างต้นทุกประการ',
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // ตามแบบ: พื้นครีม FFF8E8 มีรูปทรงเหลืองย้อยลงจากด้านบน
    // แมวไข่หวานถือโทรโข่งเกาะขอบกล่องข้อความ ปุ่มปฏิเสธ (เทา) / ยอมรับ (ดำ)
    return Dialog(
      backgroundColor: AppColors.cream,
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 680),
        child: Stack(
          children: [
            // รูปทรงเหลืองย้อยด้านบน (กราฟิกตกแต่ง) ให้ชิดขอบบน/ซ้าย/ขวาของกล่อง
            // เลยขอบออกไปเล็กน้อย ส่วนปลายมนของรูปจะถูกตัดด้วยมุมโค้งของกล่องพอดี
            Positioned(
              top: -2,
              left: -12,
              right: -12,
              child: Image.asset(
                'assets/images/shape_drip.png',
                fit: BoxFit.fitWidth,
                alignment: Alignment.topCenter,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 64),
                // กล่องข้อตกลง + แมวถือโทรโข่งเกาะมุมขวาบน
                Flexible(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 30, 16, 0),
                        padding: const EdgeInsets.fromLTRB(4, 36, 4, 4),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.yellow, width: 3),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Padding(
                              padding: EdgeInsets.fromLTRB(14, 0, 14, 4),
                              child: Text(
                                'ขอความยินยอมในการเข้าถึงข้อมูลและนโยบายความเป็นส่วนตัว',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                            Flexible(child: _TermsBox(terms: terms)),
                          ],
                        ),
                      ),
                      Positioned(
                        top: -24,
                        right: 8,
                        child: Image.asset(
                          'assets/images/cat_megaphone.png',
                          height: 76,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  // Wrap: จอแคบแล้วปุ่มไม่พอจะขึ้นบรรทัดใหม่แทนการล้นจอ
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      PillButton(
                        color: const Color(0xFFBDB8AE),
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('ปฏิเสธ'),
                      ),
                      PillButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('ยอมรับและดำเนินการต่อ'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// หัวข้อ 1 ข้อของข้อตกลง: ชื่อหัวข้อ + ย่อหน้า (label = หัวข้อย่อย ไม่มีก็ได้)
typedef TermsSection = ({
  String title,
  List<({String? label, String text})> items,
});

/// กล่องข้อความ Terms and Conditions (มีกรอบ เลื่อนอ่านได้)
/// หัวข้อหลักมีเลขข้อ ตัวหนาสีเข้ม / หัวข้อย่อยตัวหนาสีน้ำตาล / เนื้อหาสีจาง
class _TermsBox extends StatelessWidget {
  const _TermsBox({required this.terms});
  final List<TermsSection> terms;

  @override
  Widget build(BuildContext context) {
    const body = TextStyle(fontSize: 13, height: 1.5, color: AppColors.muted);
    return Container(
      padding: const EdgeInsets.all(14),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ส่วนเนื้อหาการขออนุญาตมีดังนี้',
              style: TextStyle(fontSize: 18, color: AppColors.ink),
            ),
            for (final (i, section) in terms.indexed) ...[
              const SizedBox(height: 12),
              Text(
                '${i + 1}. ${section.title}',
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              for (final item in section.items)
                Padding(
                  padding: const EdgeInsets.only(left: 14, top: 6),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        if (item.label != null)
                          TextSpan(
                            text: '${item.label}: ',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.caramel,
                            ),
                          ),
                        TextSpan(text: item.text),
                      ],
                    ),
                    style: body,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
