import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'login_page.dart';
import 'register_page.dart';

final BoxDecoration _cardDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: AppColors.mint),
);

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  void _goToLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  void _goToRegister(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    const buttonText = TextStyle(fontSize: 16, fontWeight: FontWeight.w600);

    return Scaffold(
      backgroundColor: AppColors.welcomeBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _Hero(),
                  const SizedBox(height: 20),
                  const _ExampleResultCard(),
                  const SizedBox(height: 12),
                  const _FeatureList(),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => _goToLogin(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brand2,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(56),
                      elevation: 0,
                      shape: buttonShape,
                      textStyle: buttonText,
                    ),
                    child: const Text('Masuk'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => _goToRegister(context),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.brand2,
                      minimumSize: const Size.fromHeight(56),
                      side: const BorderSide(color: AppColors.brand2, width: 2),
                      shape: buttonShape,
                      textStyle: buttonText,
                    ),
                    child: const Text('Daftar'),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Hasil hanya perkiraan, bukan diagnosis dokter.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 20 / 14,
                      color: AppColors.slate,
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

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.mint,
            shape: BoxShape.circle,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/images/logo.png',
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF14B8A6), Color(0xFF0F766E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(Icons.water_drop_rounded,
                    color: Colors.white, size: 32),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Selamat Datang di',
          style: TextStyle(fontSize: 18, color: AppColors.slate),
        ),
        const SizedBox(height: 2),
        const Text(
          'GlucoSafe',
          style: TextStyle(
            fontSize: 32,
            height: 40 / 32,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Periksa kemungkinan Anda terkena diabetes (kencing manis) dengan mudah dan cepat.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            height: 24 / 16,
            color: AppColors.slate,
          ),
        ),
      ],
    );
  }
}


class _ExampleResultCard extends StatelessWidget {
  const _ExampleResultCard();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Contoh hasil pemeriksaan: 28 persen, tidak berisiko',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration,
        child: Row(
          children: [
            const SizedBox(
              width: 72,
              height: 72,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: 0.28,
                      strokeWidth: 7,
                      strokeCap: StrokeCap.round,
                      color: AppColors.safe,
                      backgroundColor: AppColors.ringTrack,
                    ),
                  ),
                  Text(
                    '28%',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.safe,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.safeBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                            radius: 4, backgroundColor: AppColors.safe),
                        SizedBox(width: 6),
                        Text(
                          'Tidak Berisiko',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.safe,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Contoh hasil pemeriksaan',
                    style: TextStyle(fontSize: 14, color: AppColors.slate),
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

class _FeatureList extends StatelessWidget {
  const _FeatureList();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration,
      child: const Column(
        children: [
          _FeatureItem(
            icon: Icons.edit_note_rounded,
            iconColor: AppColors.infoBlue,
            background: AppColors.infoBlueBg,
            text: 'Jawab pertanyaan singkat dalam 4 langkah',
          ),
          SizedBox(height: 14),
          _FeatureItem(
            icon: Icons.bar_chart_rounded,
            iconColor: AppColors.warnOrange,
            background: AppColors.warnOrangeBg,
            text: 'Lihat hasil kemungkinan Anda',
          ),
          SizedBox(height: 14),
          _FeatureItem(
            icon: Icons.event_repeat_rounded,
            iconColor: AppColors.accentPurple,
            background: AppColors.accentPurpleBg,
            text: 'Pantau perkembangan Anda dari waktu ke waktu',
          ),
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({
    required this.icon,
    required this.iconColor,
    required this.background,
    required this.text,
  });

  final IconData icon;
  final Color iconColor;
  final Color background;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: background, shape: BoxShape.circle),
          child: Icon(icon, size: 22, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              height: 1.3,
              fontWeight: FontWeight.w500,
              color: AppColors.ink,
            ),
          ),
        ),
      ],
    );
  }
}