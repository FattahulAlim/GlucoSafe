import 'package:flutter/material.dart';

/// Halaman Daftar — mengikuti frame "Daftar - GlucoSafe" di Figma.
/// Simpan di: lib/pages/register_page.dart

class _C {
  static const bg = Color(0xFFFAF8FF);
  static const ink = Color(0xFF131B2E);
  static const mute = Color(0xFF3D4947);
  static const hint = Color(0xFF6D7A77);
  static const brand = Color(0xFF00685F);
}

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
  final TextEditingController _confirmPasswordController = TextEditingController();
  String? _emailErrorText;

  void _clearFields() {
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    setState(() {
      _emailErrorText = null;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red.shade600),
      );
  }

  void _register() {
    if (_nameController.text.trim().isEmpty) {
      _showError('Nama lengkap wajib diisi');
      return;
    }
    if (_emailController.text.isEmpty || _emailErrorText != null) {
      _showError('Periksa kembali email Anda');
      return;
    }
    if (_passwordController.text.length < 8) {
      _showError('Kata sandi minimal 8 karakter');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Kata sandi dan ulangi kata sandi tidak sama');
      return;
    }

    // TODO: panggil API register (Anggota 3) sebelum menampilkan notifikasi.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Pendaftaran berhasil! Silakan login.',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          // Menempatkan SnackBar di bagian atas layar
          bottom: MediaQuery.of(context).size.height - 150,
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

  /// Satu field: label + kotak putih (tinggi 50, sudut 12, bayangan tipis) + pesan error.
  Widget _field({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType? keyboardType,
    bool obscure = false,
    VoidCallback? onToggle,
    bool? toggleState,
    ValueChanged<String>? onChanged,
    String? error,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, height: 20 / 14, color: _C.ink),
        ),
        const SizedBox(height: 6),
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(color: Color(0x0D000000), blurRadius: 2, offset: Offset(0, 1)),
            ],
          ),
          alignment: Alignment.center,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscure,
            onChanged: onChanged,
            style: const TextStyle(fontSize: 16, color: _C.ink),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 16, color: _C.hint),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              suffixIcon: onToggle == null
                  ? null
                  : IconButton(
                      iconSize: 20,
                      color: const Color(0xFF505F76),
                      tooltip: 'Tampilkan atau sembunyikan kata sandi',
                      icon: Icon(
                        (toggleState ?? true)
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: onToggle,
                    ),
              suffixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 50),
            ),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              error,
              style: TextStyle(fontSize: 12, color: Colors.red.shade600),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: _LogoBox(size: 56, radius: 16, padding: 8)),
                  const SizedBox(height: 20),
                  const Text(
                    'Buat Akun',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      height: 32 / 26,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -.65,
                      color: _C.ink,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Isi data berikut untuk mulai memeriksa kesehatan Anda.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, height: 22.75 / 14, color: _C.mute),
                  ),
                  const SizedBox(height: 24),

                  _field(
                    label: 'Nama Lengkap',
                    hint: 'Masukkan nama lengkap',
                    controller: _nameController,
                  ),
                  const SizedBox(height: 16),
                  _field(
                    label: 'Email',
                    hint: 'nama@email.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    error: _emailErrorText,
                    onChanged: (value) {
                      setState(() {
                        if (value.isNotEmpty && !value.endsWith('@gmail.com')) {
                          _emailErrorText = 'Email harus berakhiran @gmail.com';
                        } else {
                          _emailErrorText = null;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _field(
                    label: 'Kata Sandi',
                    hint: 'Minimal 8 karakter',
                    controller: _passwordController,
                    obscure: _obscurePassword,
                    toggleState: _obscurePassword,
                    onToggle: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  const SizedBox(height: 16),
                  _field(
                    label: 'Ulangi Kata Sandi',
                    hint: 'Ulangi kata sandi',
                    controller: _confirmPasswordController,
                    obscure: _obscureConfirmPassword,
                    toggleState: _obscureConfirmPassword,
                    onToggle: () => setState(
                        () => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                  const SizedBox(height: 24),

                  // Tombol Daftar
                  Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: _C.brand,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 4)),
                        BoxShadow(color: Color(0x1A000000), blurRadius: 4, offset: Offset(0, 2)),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _register,
                        child: const Center(
                          child: Text(
                            'Daftar',
                            style: TextStyle(
                              fontSize: 16,
                              height: 24 / 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: .4,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Sudah punya akun? ',
                        style: TextStyle(fontSize: 14, height: 20 / 14, color: _C.mute),
                      ),
                      GestureDetector(
                        onTap: () {
                          _clearFields();
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Masuk',
                          style: TextStyle(fontSize: 14, height: 20 / 14, color: _C.brand),
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
            borderRadius: BorderRadius.circular(radius * .6),
            gradient: const LinearGradient(
              colors: [Color(0xFF14B8A6), Color(0xFF0F766E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Icon(Icons.water_drop_rounded, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}