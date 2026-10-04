import 'package:flutter/material.dart';
import 'home_page.dart';
import 'register_page.dart';
import '../models/screening_state.dart';
import 'screening_step1_page.dart';

/// Halaman Login — mengikuti frame "Login - GlucoSafe" di Figma.
/// Simpan di: lib/pages/login_page.dart

class _C {
  static const bg = Color(0xFFFAF8FF);
  static const ink = Color(0xFF131B2E);
  static const slate = Color(0xFF505F76);
  static const hint = Color(0xFF6D7A77);
  static const border = Color(0xFFE2E8F0);
  static const brand = Color(0xFF00685F);
  static const brand2 = Color(0xFF0D9488);
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscureText = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _emailErrorText;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _goToRegister() {
    _emailController.clear();
    _passwordController.clear();
    setState(() {
      _emailErrorText = null;
    });
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterPage()),
    );
  }

  void _login() {
    final email = _emailController.text.trim();
    if (email.isEmpty || _emailErrorText != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Periksa kembali email Anda')),
        );
      return;
    }
    // TODO: panggil API login (Anggota 3) sebelum pindah halaman.
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomePage(
          onStartScreening: () {
            resetScreeningForm(); // mulai dari isian kosong
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ScreeningStep1Page(),
              ),
            );
          },
        ),
      ),
    );
  }

  OutlineInputBorder _border(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c, width: w),
      );

  InputDecoration _decoration(String hint, {Widget? suffix, String? error}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 14, color: _C.hint),
      errorText: error,
      errorStyle: const TextStyle(fontSize: 12),
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: EdgeInsets.fromLTRB(17, 15.5, suffix != null ? 4 : 17, 15.5),
      suffixIcon: suffix,
      suffixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      border: _border(_C.border),
      enabledBorder: _border(_C.border),
      focusedBorder: _border(_C.brand2, 1.5),
      errorBorder: _border(Colors.red.shade400),
      focusedErrorBorder: _border(Colors.red.shade400, 1.5),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          height: 16 / 13,
          letterSpacing: .13,
          fontWeight: FontWeight.w500,
          color: _C.ink,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo + judul
                  const Center(child: _LogoBox(size: 48, radius: 8, padding: 6)),
                  const SizedBox(height: 16),
                  const Text(
                    'GlucoSafe',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      height: 32 / 26,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -.65,
                      color: _C.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Masuk ke akun Anda',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, height: 20 / 14, color: _C.slate),
                  ),
                  const SizedBox(height: 32),

                  // Email
                  _label('Email'),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(fontSize: 14, color: _C.ink),
                    onChanged: (value) {
                      setState(() {
                        if (value.isNotEmpty && !value.endsWith('@gmail.com')) {
                          _emailErrorText = 'Email harus berakhiran @gmail.com';
                        } else {
                          _emailErrorText = null;
                        }
                      });
                    },
                    decoration: _decoration('nama@email.com', error: _emailErrorText),
                  ),
                  const SizedBox(height: 24),

                  // Kata sandi + lupa kata sandi
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _label('Kata Sandi'),
                      GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(const SnackBar(
                                content: Text('Halaman lupa kata sandi belum dibuat')));
                        },
                        child: const Text(
                          'Lupa kata sandi?',
                          style: TextStyle(
                            fontSize: 11,
                            height: 14 / 11,
                            letterSpacing: .44,
                            fontWeight: FontWeight.w600,
                            color: _C.brand,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscureText,
                    style: const TextStyle(fontSize: 14, color: _C.ink),
                    decoration: _decoration(
                      '••••••••',
                      suffix: IconButton(
                        tooltip: 'Tampilkan kata sandi',
                        iconSize: 18,
                        color: _C.slate,
                        icon: Icon(
                          _obscureText
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () => setState(() => _obscureText = !_obscureText),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tombol Masuk
                  ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _C.brand2,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 1,
                      shadowColor: const Color(0x0D000000),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Masuk',
                      style: TextStyle(
                        fontSize: 16,
                        height: 24 / 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Belum punya akun? ',
                        style: TextStyle(fontSize: 14, height: 20 / 14, color: _C.slate),
                      ),
                      GestureDetector(
                        onTap: _goToRegister,
                        child: const Text(
                          'Daftar',
                          style: TextStyle(
                            fontSize: 13,
                            height: 16 / 13,
                            letterSpacing: .13,
                            fontWeight: FontWeight.w600,
                            color: _C.brand2,
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

/// Kotak logo putih. Jika file logo belum ada, tampil logo pengganti.
/// Untuk logo asli: taruh PNG di assets/images/logo.png lalu daftarkan di pubspec.yaml.
class _LogoBox extends StatelessWidget {
  const _LogoBox({required this.size, required this.radius, required this.padding});
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
        boxShadow: const [
          BoxShadow(color: Color(0x0D000000), blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: Image.asset(
        'assets/images/logo.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stack) => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius * .7),
            gradient: const LinearGradient(
              colors: [Color(0xFF14B8A6), Color(0xFF0F766E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Icon(Icons.water_drop_rounded, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}