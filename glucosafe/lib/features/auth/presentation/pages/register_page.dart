import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Warna dari Figma (frame "Daftar - GlucoSafe").
  // Nanti bisa dipindah ke core/theme/app_colors.dart
  static const Color _bg = Color(0xFFFAF8FF);
  static const Color _textDark = Color(0xFF131B2E);
  static const Color _textSecondary = Color(0xFF3D4947);
  static const Color _hint = Color(0xFF6D7A77);
  static const Color _primary = Color(0xFF00685F);

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
        backgroundColor: Colors.green.shade600,
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
      hintStyle: const TextStyle(color: _hint, fontSize: 16),
      errorText: errorText,
      filled: true,
      fillColor: Colors.white,
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: border(Colors.transparent),
      enabledBorder: border(Colors.transparent),
      focusedBorder: border(_primary, 1.5),
      errorBorder: border(Colors.redAccent),
      focusedErrorBorder: border(Colors.redAccent, 1.5),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(fontSize: 14, color: _textDark, height: 20 / 14),
        ),
      );

  Widget _eye(bool obscure, VoidCallback onTap) => IconButton(
        onPressed: onTap,
        icon: Icon(
          obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          size: 20,
          color: _hint,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  Center(
                    child: Container(
                      width: 56,
                      height: 56,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0D000000),
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      // TODO: samakan path logo dengan login_page.dart
                      child: Image.asset(
                        'assets/images/logo.png',
                        errorBuilder: (_, _, _) => const Icon(Icons.water_drop, color: _primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'Buat Akun',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: _textDark,
                      letterSpacing: -0.65,
                      height: 32 / 26,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Isi data berikut untuk mulai memeriksa kesehatan Anda.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: _textSecondary,
                      height: 22.75 / 14,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Nama Lengkap
                  _label('Nama Lengkap'),
                  TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: _decoration(
                      'Masukkan nama lengkap',
                      errorText: _nameErrorText,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Email
                  _label('Email'),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
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
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
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
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    textInputAction: TextInputAction.done,
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
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: const Color(0x1A000000),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Daftar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
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
                        style: TextStyle(fontSize: 14, color: _textSecondary),
                      ),
                      GestureDetector(
                        onTap: () {
                          _clearFields();
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Masuk',
                          style: TextStyle(fontSize: 14, color: _primary),
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