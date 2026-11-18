import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/models/auth_models.dart';
import '../../../home/presentation/pages/home_page.dart';
import './register_page.dart';
import '../../../screening/domain/screening_state.dart';
import '../../../screening/presentation/pages/screening_step1_page.dart';

/// Halaman Login — mengikuti frame "Login - GlucoSafe" di Figma.
/// Simpan di: lib/pages/login_page.dart

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscureText = true;
  bool _isLoading = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _authService = AuthService();
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

  void _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || _emailErrorText != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Periksa kembali email Anda')),
        );
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Kata sandi wajib diisi')),
        );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final request = LoginRequest(email: email, password: password);
      final response = await _authService.login(request);

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (response.success && response.data != null) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(
              onStartScreening: () {
                resetScreeningForm();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ScreeningStep1Page(),
                  ),
                );
              },
            ),
          ),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(response.message)),
          );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: ${e.toString()}')),
        );
    }
  }

  OutlineInputBorder _border(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c, width: w),
      );

  InputDecoration _decoration(String hint, {Widget? suffix, String? error}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 14, color: AppColors.hint),
      errorText: error,
      errorStyle: const TextStyle(fontSize: 12),
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: EdgeInsets.fromLTRB(17, 15.5, suffix != null ? 4 : 17, 15.5),
      suffixIcon: suffix,
      suffixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      border: _border(AppColors.border),
      enabledBorder: _border(AppColors.border),
      focusedBorder: _border(AppColors.brand2, 1.5),
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
          color: AppColors.ink,
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
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Masuk ke akun Anda',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, height: 20 / 14, color: AppColors.slate),
                  ),
                  const SizedBox(height: 32),

                  // Email
                  _label('Email'),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
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
                    decoration: _decoration('nama@email.com', error: _emailErrorText),
                  ),
                  const SizedBox(height: 24),

                  // Kata sandi + lupa kata sandi
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: _label('Kata Sandi')), // #fix-overflow
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
                            color: AppColors.brand,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscureText,
                    style: const TextStyle(fontSize: 14, color: AppColors.ink),
                    decoration: _decoration(
                      '••••••••',
                      suffix: IconButton(
                        tooltip: 'Tampilkan kata sandi',
                        iconSize: 18,
                        color: AppColors.slate,
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
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brand2,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 1,
                      shadowColor: const Color(0x0D000000),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
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
                  Wrap( // #fix-overflow
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'Belum punya akun? ',
                        style: TextStyle(fontSize: 14, height: 20 / 14, color: AppColors.slate),
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