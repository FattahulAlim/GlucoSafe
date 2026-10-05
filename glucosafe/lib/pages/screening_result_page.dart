import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'history_page.dart';
import 'home_page.dart';

/// Halaman Hasil Skrining GlucoSafe.
/// Simpan di: lib/pages/screening_result_page.dart

class ResultColors {
  static const bg = Color(0xFFF0FDFA);
  static const ink = Color(0xFF131B2E);
  static const slate = Color(0xFF475569);
  static const mute = Color(0xFF64748B);
  static const brand = Color(0xFF00685F);
  static const brandDark = Color(0xFF00534C);

  // Status & Aksentuasi
  static const greenText = Color(0xFF047857);
  static const greenBg = Color(0xFFD1FAE5);
  static const greenCircle = Color(0xFF16A34A);

  // Alert Box (Orange/Peach)
  static const alertBg = Color(0xFFFFF7ED);
  static const alertBorder = Color(0xFFFED7AA);
  static const alertText = Color(0xFFC2410C);

  // Lavender / Pill
  static const pillBg = Color(0xFFF1F5F9);
  static const cardBg = Colors.white;

  // Recommendation Card Colors
  static const nutrisiBg = Color(0xFFD1FAE5);
  static const nutrisiIcon = Color(0xFF047857);

  static const fisikBg = Color(0xFFE0F2FE);
  static const fisikIcon = Color(0xFF0284C7);

  static const periksaBg = Color(0xFFF3E8FF);
  static const periksaIcon = Color(0xFF7E22CE);
}

/// Model data rekomendasi
class RecommendationItem {
  final String title;
  final String category;
  final String description;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  const RecommendationItem({
    required this.title,
    required this.category,
    required this.description,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });
}

class ScreeningResultPage extends StatelessWidget {
  const ScreeningResultPage({
    super.key,
    this.percent = 48.0,
    this.statusText = 'Tidak Berisiko',
    this.indicatorCount = 15,
    this.onSaveToHistory,
    this.onRestartScreening,
  });

  final double percent;
  final String statusText;
  final int indicatorCount;
  final VoidCallback? onSaveToHistory;
  final VoidCallback? onRestartScreening;

  final List<RecommendationItem> dummyRecommendations = const [
    RecommendationItem(
      title: 'Kurangi Gula &\nKarbohidrat Olahan',
      category: 'Nutrisi',
      description:
          'Mulai batasi makanan manis dan minuman kemasan untuk mencegah kenaikan kadar glukosa.',
      icon: Icons.restaurant_rounded,
      iconBg: ResultColors.nutrisiBg,
      iconColor: ResultColors.nutrisiIcon,
    ),
    RecommendationItem(
      title: 'Tingkatkan Aktivitas\nFisik',
      category: 'Aktivitas Fisik',
      description:
          'Rutin bergerak 30 menit per hari, seperti jalan cepat atau bersepeda santai.',
      icon: Icons.fitness_center_rounded,
      iconBg: ResultColors.fisikBg,
      iconColor: ResultColors.fisikIcon,
    ),
    RecommendationItem(
      title: 'Skrining Mandiri Lebih\nAwal',
      category: 'Pemeriksaan',
      description:
          'Lakukan pemeriksaan berkala dalam 1-2 bulan ke depan untuk memantau perubahan tren.',
      icon: Icons.calendar_month_rounded,
      iconBg: ResultColors.periksaBg,
      iconColor: ResultColors.periksaIcon,
    ),
  ];

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ResultColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header Bar
            _Header(
              onBack: () => Navigator.maybePop(context),
              onProfile: () => _showMessage(context, 'Halaman Profil belum dihubungkan'),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main Result Summary Card
                    _ResultSummaryCard(
                      percent: percent,
                      statusText: statusText,
                      indicatorCount: indicatorCount,
                    ),

                    const SizedBox(height: 24),

                    // Section Title: Rekomendasi Langkah Nyata
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Rekomendasi Langkah Nyata',
                          style: TextStyle(
                            fontSize: 16,
                            height: 22 / 16,
                            fontWeight: FontWeight.w700,
                            color: ResultColors.ink,
                          ),
                        ),
                        Text(
                          '${dummyRecommendations.length} Rekomendasi',
                          style: const TextStyle(
                            fontSize: 13,
                            height: 18 / 13,
                            fontWeight: FontWeight.w600,
                            color: ResultColors.greenText,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Recommendation Cards List
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: dummyRecommendations.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _RecommendationCard(
                          item: dummyRecommendations[index],
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // Medical Disclaimer Note
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: ResultColors.mute,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Ini adalah alat skrining awal berbasis data survei mandiri, bukan pengganti diagnosis medis.',
                            style: TextStyle(
                              fontSize: 12,
                              height: 16 / 12,
                              color: ResultColors.mute,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Action Button: Simpan ke Riwayat
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: onSaveToHistory ??
                            () {
                              _showMessage(context, 'Hasil skrining disimpan ke riwayat');
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const HistoryPage(),
                                ),
                              );
                            },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ResultColors.brand,
                          foregroundColor: Colors.white,
                          elevation: 1,
                          shadowColor: const Color(0x1F000000),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(
                          Icons.bookmark_outline_rounded,
                          size: 20,
                        ),
                        label: const Text(
                          'Simpan ke Riwayat',
                          style: TextStyle(
                            fontSize: 16,
                            height: 22 / 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Action Button: Skrining Ulang
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: onRestartScreening ??
                            () {
                              _showMessage(context, 'Memulai skrining ulang');
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const HomePage(),
                                ),
                              );
                            },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ResultColors.brand,
                          side: const BorderSide(
                            color: ResultColors.brand,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(
                          Icons.refresh_rounded,
                          size: 20,
                        ),
                        label: const Text(
                          'Skrining Ulang',
                          style: TextStyle(
                            fontSize: 16,
                            height: 22 / 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Alias class name jika dipanggil sebagai `HasilSkriningPage`
typedef HasilSkriningPage = ScreeningResultPage;

// ───────────────────────── Header ─────────────────────────
class _Header extends StatelessWidget {
  const _Header({
    required this.onBack,
    required this.onProfile,
  });

  final VoidCallback onBack;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: Color(0xD9FFFFFF),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Tombol Kembali
          IconButton(
            onPressed: onBack,
            icon: const Icon(
              Icons.chevron_left_rounded,
              size: 28,
              color: ResultColors.ink,
            ),
            tooltip: 'Kembali',
          ),

          // Logo App
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: const LinearGradient(
                colors: [Color(0xFF14B8A6), Color(0xFF0F766E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(
              Icons.water_drop_rounded,
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),

          // Judul Halaman
          const Expanded(
            child: Text(
              'Hasil Skrining',
              style: TextStyle(
                fontSize: 18,
                height: 26 / 18,
                fontWeight: FontWeight.w700,
                color: ResultColors.ink,
              ),
            ),
          ),

          // Tombol Profil User
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Semantics(
              button: true,
              label: 'Buka profil pengguna',
              child: InkWell(
                onTap: onProfile,
                customBorder: const CircleBorder(),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: ResultColors.brand,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Card Ringkasan Hasil ─────────────────────────
class _ResultSummaryCard extends StatelessWidget {
  const _ResultSummaryCard({
    required this.percent,
    required this.statusText,
    required this.indicatorCount,
  });

  final double percent;
  final String statusText;
  final int indicatorCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ResultColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Donut Progress Chart
          SizedBox(
            width: 170,
            height: 170,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(170, 170),
                  painter: _ResultGaugePainter(
                    percent: percent,
                    color: ResultColors.greenCircle,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${percent.round()}%',
                      style: const TextStyle(
                        fontSize: 40,
                        height: 44 / 40,
                        letterSpacing: -1,
                        fontWeight: FontWeight.w800,
                        color: ResultColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const SizedBox(
                      width: 90,
                      child: Text(
                        'Kemungkinan\ndiabetes',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          height: 16 / 12,
                          color: ResultColors.slate,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Status Badge Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: ResultColors.greenBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: ResultColors.greenCircle,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  statusText,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 18 / 14,
                    fontWeight: FontWeight.w700,
                    color: ResultColors.greenText,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Alert Warning Box (Orange/Peach)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ResultColors.alertBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ResultColors.alertBorder,
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: const BoxDecoration(
                    color: ResultColors.alertText,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'i',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Hasil Anda mendekati ambang batas. Meski saat ini belum masuk kategori berisiko, tetap jaga gaya hidup sehat.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 18 / 13,
                      color: ResultColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Paragraph Penjelasan
          const Text(
            'Hasil skrining saat ini masih berada dalam kategori tidak berisiko, namun perlu kewaspadaan ekstra terhadap konsumsi gula harian dan riwayat kebugaran tubuh.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 20 / 14,
              color: ResultColors.slate,
            ),
          ),

          const SizedBox(height: 16),

          // Indicator Count Chip
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: ResultColors.pillBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: ResultColors.greenBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.fact_check_outlined,
                    size: 18,
                    color: ResultColors.greenText,
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    'Berdasarkan $indicatorCount Indikator Kesehatan Lengkap',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 18 / 13,
                      fontWeight: FontWeight.w600,
                      color: ResultColors.slate,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Recommendation Card ─────────────────────────
class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.item});

  final RecommendationItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ResultColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Box Kiri
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: item.iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  item.icon,
                  size: 24,
                  color: item.iconColor,
                ),
              ),
              const SizedBox(width: 12),

              // Title
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 20 / 15,
                    fontWeight: FontWeight.w700,
                    color: ResultColors.ink,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Category Badge Pill Right
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: ResultColors.pillBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.category,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 14 / 11,
                    fontWeight: FontWeight.w600,
                    color: ResultColors.slate,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Description Text
          Text(
            item.description,
            style: const TextStyle(
              fontSize: 13,
              height: 18 / 13,
              color: ResultColors.slate,
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Painter Ring ─────────────────────────
class _ResultGaugePainter extends CustomPainter {
  _ResultGaugePainter({required this.percent, required this.color});

  final double percent;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 16.0;
    final center = size.center(Offset.zero);
    final radius = (size.width - stroke) / 2;

    // Track Background
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = const Color(0xFFE2E8F0),
    );

    // Progress Sweep (memutar dari atas / -pi/2)
    final sweep = 2 * math.pi * (percent.clamp(0, 100) / 100);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_ResultGaugePainter old) =>
      old.percent != percent || old.color != color;
}
