import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/dummy_user_database.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  String? _nameErrorText;
  String? _emailErrorText;
  String? _passwordErrorText;
  String? _confirmErrorText;

  void _clearFields() {
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    setState(() {
      _nameErrorText = null;
      _emailErrorText = null;
      _passwordErrorText = null;
      _confirmErrorText = null;
    });
  }

  bool _validate() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final pass = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    setState(() {
      _nameErrorText = name.isEmpty ? 'Nama lengkap wajib diisi' : null;
      _emailErrorText = email.isEmpty
          ? 'Email wajib diisi'
          : (!email.endsWith('@gmail.com')
              ? 'Email harus berakhiran @gmail.com'
              : null);
      _passwordErrorText = pass.length < 8 ? 'Minimal 8 karakter' : null;
      _confirmErrorText = confirm != pass ? 'Kata sandi tidak sama' : null;
    });

    return _nameErrorText == null &&
        _emailErrorText == null &&
        _passwordErrorText == null &&
        _confirmErrorText == null;
  }

  void _submit() {
    if (!_validate()) return;

    final user = DummyUser(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (!DummyUserDatabase.instance.register(user)) {
      setState(() {
        _emailErrorText = 'Email sudah terdaftar';
      });
      return;
    }

    // #fix-overflow: margin bawah dihitung dari tinggi layar; nilainya bisa
    // negatif saat keyboard terbuka sehingga menuSnackBar gagal dirender.
    // Batasi agar tidak pernah negatif.
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomMargin = (screenHeight - 150).clamp(0.0, double.infinity);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Pendaftaran berhasil! Silakan login.',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        backgroundColor: AppColors.brand2,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: bottomMargin, // #fix-overflow
          left: 20,
          right: 20,
        ),
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );

    _clearFields();
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  InputDecoration _decoration(
    String hint, {
    String? errorText,
    Widget? suffix,
  }) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: color == Colors.transparent
              ? BorderSide.none
              : BorderSide(color: color, width: width),
        );

    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.hint, fontSize: 14),
      errorText: errorText,
      errorStyle: const TextStyle(fontSize: 12),
      filled: true,
      fillColor: Colors.white,
      suffixIcon: suffix,
      isDense: true,
      contentPadding: EdgeInsets.fromLTRB(17, 15.5, suffix != null ? 4 : 17, 15.5),
      suffixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      border: border(AppColors.border),
      enabledBorder: border(AppColors.border),
      focusedBorder: border(AppColors.brand2, 1.5),
      errorBorder: border(Colors.red.shade400),
      focusedErrorBorder: border(Colors.red.shade400, 1.5),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          height: 16 / 13,
          letterSpacing: .13,
          fontWeight: FontWeight.w500,
          color: AppColors.ink,
        ),
      );

  Widget _eye(bool obscure, VoidCallback onTap) => IconButton(
        onPressed: onTap,
        icon: Icon(
          obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          size: 20,
          color: AppColors.slate,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.formBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: _LogoBox(size: 48, radius: 8, padding: 6)),
                  const SizedBox(height: 16),
                  const Text(
                    'GlucoSafe',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      height: 32 / 26,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.65,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Isi data berikut untuk mulai memeriksa kesehatan Anda.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 20 / 14,
                      color: AppColors.slate,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Nama Lengkap
                  _label('Nama Lengkap'),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(fontSize: 14, color: AppColors.ink),
                    decoration: _decoration(
                      'Masukkan nama lengkap',
                      errorText: _nameErrorText,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Email
                  _label('Email'),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(fontSize: 14, color: AppColors.ink),
                    onChanged: (value) {
                      setState(() {
                        if (value.isNotEmpty && !value.endsWith('@gmail.com')) {
                          _emailErrorText = 'Email harus berakhiran @gmail.com';
                        } else {
                          _emailErrorText = null;
                        }
                      });
                    },
                    decoration: _decoration(
                      'nama@email.com',
                      errorText: _emailErrorText,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Kata Sandi
                  _label('Kata Sandi'),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(fontSize: 14, color: AppColors.ink),
                    decoration: _decoration(
                      'Minimal 8 karakter',
                      errorText: _passwordErrorText,
                      suffix: _eye(
                        _obscurePassword,
                        () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Ulangi Kata Sandi
                  _label('Ulangi Kata Sandi'),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    textInputAction: TextInputAction.done,
                    style: const TextStyle(fontSize: 14, color: AppColors.ink),
                    onSubmitted: (_) => _submit(),
                    decoration: _decoration(
                      'Ulangi kata sandi',
                      errorText: _confirmErrorText,
                      suffix: _eye(
                        _obscureConfirmPassword,
                        () => setState(() =>
                            _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tombol Daftar
                  SizedBox(
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brand2,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 1,
                        shadowColor: AppColors.border,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Daftar',
                        style: TextStyle(
                          fontSize: 16,
                          height: 24 / 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Footer Login
                  Wrap( // #fix-overflow
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'Sudah punya akun? ',
                        style: TextStyle(
                          fontSize: 14,
                          height: 20 / 14,
                          color: AppColors.slate,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          _clearFields();
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Masuk',
                          style: TextStyle(
                            fontSize: 13,
                            height: 16 / 13,
                            letterSpacing: .13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.brand2,
                          ),
                        ),
                      ),
                    ],
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

class _LogoBox extends StatelessWidget {
  const _LogoBox({
    required this.size,
    required this.radius,
    required this.padding,
  });

  final double size;
  final double radius;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: AppColors.border.withValues(alpha: 0.5),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Image.asset(
        'assets/images/logo.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stack) => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius * .7),
            gradient: const LinearGradient(
              colors: [AppColors.brand2, AppColors.brandDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Icon(
            Icons.water_drop_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}