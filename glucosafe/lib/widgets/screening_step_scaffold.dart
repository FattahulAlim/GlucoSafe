import 'package:flutter/material.dart';

/// Warna halaman pemeriksaan (mengikuti palet login dan home tim).
/// Dipakai juga oleh langkah 2 sampai 4.
class ScreeningColors {
  static const bg = Color(0xFFFAF8FF);
  static const ink = Color(0xFF131B2E);
  static const slate = Color(0xFF505F76);
  static const hint = Color(0xFF6D7A77);
  static const border = Color(0xFFE2E8F0);
  static const brand = Color(0xFF00685F);
  static const brand2 = Color(0xFF0D9488);
  static const track = Color(0xFFCCFBF1);
  static const okBg = Color(0xFFF0FDFA);
  static const okBorder = Color(0xFFCCFBF1);
  static const warn = Color(0xFFEA580C);
  static const warnBg = Color(0xFFFFEDD5);
  static const warnBorder = Color(0xFFFED7AA);
  static const error = Color(0xFFDC2626);
  static const disabled = Color(0xFFCBD5E1);
}

/// Kerangka halaman langkah pemeriksaan.
class ScreeningStepScaffold extends StatelessWidget {
  const ScreeningStepScaffold({
    super.key,
    required this.step,
    this.totalSteps = 4,
    required this.title,
    required this.subtitle,
    required this.child,
    this.onBack,
    this.onProfileTap,
  });

  final int step;
  final int totalSteps;
  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback? onBack;
  final VoidCallback? onProfileTap;

  void _soon(BuildContext c, String msg) {
    ScaffoldMessenger.of(c)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final percent = (step / totalSteps * 100).round();

    return Scaffold(
      backgroundColor: ScreeningColors.bg,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: Column(
            children: [
              _Header(
                onBack: onBack ?? () => Navigator.of(context).maybePop(),
                onProfile: onProfileTap ??
                    () => _soon(context, 'Halaman Profil belum dihubungkan'),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Semantics(
                            label:
                                'Langkah $step dari $totalSteps, $percent persen selesai',
                            excludeSemantics: true,
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'LANGKAH $step DARI $totalSteps',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                        color: ScreeningColors.brand2,
                                      ),
                                    ),
                                    Text(
                                      '$percent% Selesai',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: ScreeningColors.brand2,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: step / totalSteps,
                                    minHeight: 8,
                                    color: ScreeningColors.brand,
                                    backgroundColor: ScreeningColors.track,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 24,
                              height: 32 / 24,
                              fontWeight: FontWeight.w700,
                              color: ScreeningColors.ink,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 24 / 16,
                              color: ScreeningColors.slate,
                            ),
                          ),
                          const SizedBox(height: 24),
                          child,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack, required this.onProfile});
  final VoidCallback onBack;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: ScreeningColors.border)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            tooltip: 'Kembali',
            icon: const Icon(Icons.arrow_back, color: ScreeningColors.ink),
          ),
          const _Logo(),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GlucoSafe',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: ScreeningColors.brand,
                  ),
                ),
                Text(
                  'Skrining Mandiri',
                  style: TextStyle(fontSize: 14, color: ScreeningColors.brand2),
                ),
              ],
            ),
          ),
          Tooltip(
            message: 'Profil',
            child: Material(
              color: ScreeningColors.brand,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onProfile,
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(Icons.person, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Logo kecil. Jika assets/images/logo.png belum ada, tampil logo pengganti
/// (pola yang sama dengan halaman login dan daftar).
class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Image.asset(
        'assets/images/logo.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stack) => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(
              colors: [Color(0xFF14B8A6), Color(0xFF0F766E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Icon(Icons.water_drop_rounded,
              color: Colors.white, size: 22),
        ),
      ),
    );
  }
}