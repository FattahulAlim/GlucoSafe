import 'package:flutter/material.dart';

/// Halaman Beranda GlucoSafe — nilai diambil langsung dari frame
/// "Beranda - GlucoSafe" di Figma (warna, ukuran, jarak, font Inter).
/// Simpan di: lib/pages/home_page.dart

// ───────────────────────── Warna (dari Figma) ─────────────────────────
class AppColors {
  static const bg = Color(0xFFF0FDFA);
  static const ink = Color(0xFF131B2E);
  static const mute = Color(0xFF3D4947);
  static const slate = Color(0xFF475569);
  static const brand = Color(0xFF00685F);
  static const brand2 = Color(0xFF0D9488);
  static const pillLav = Color(0xFFEAEDFF);
  static const infoBg = Color(0xFFF2F3FF);
  static const track = Color(0xFFE2E8F0);
  static const ok = Color(0xFF16A34A);
  static const okBg = Color(0xFFDCFCE7);
  static const mid = Color(0xFFF59E0B);
  static const midText = Color(0xFFD97706);
  static const midBg = Color(0xFFFEF3C7);
  static const midInk = Color(0xFFB45309);
  static const hi = Color(0xFFDC2626);
  static const hiBg = Color(0xFFFEE2E2);
  static const tipBg = Color(0xFFE0F2FE);
  static const tipTitle = Color(0xFF0369A1);
  static const tipDot = Color(0xFF0284C7);
  static const tipBody = Color(0xFF0C4A6E);
}

// ───────────────────────── Tingkat risiko ─────────────────────────
enum Risk { rendah, sedang, tinggi }

Risk riskOf(double percent) =>
    percent >= 60 ? Risk.tinggi : (percent >= 30 ? Risk.sedang : Risk.rendah);

extension RiskStyle on Risk {
  String get label => switch (this) {
        Risk.rendah => 'Risiko Rendah',
        Risk.sedang => 'Risiko Sedang',
        Risk.tinggi => 'Risiko Tinggi',
      };
  Color get color => switch (this) {
        Risk.rendah => AppColors.ok,
        Risk.sedang => AppColors.mid,
        Risk.tinggi => AppColors.hi,
      };
  Color get bgColor => switch (this) {
        Risk.rendah => AppColors.okBg,
        Risk.sedang => AppColors.midBg,
        Risk.tinggi => AppColors.hiBg,
      };
  Color get badgeText => switch (this) {
        Risk.rendah => AppColors.ok,
        Risk.sedang => AppColors.midInk,
        Risk.tinggi => AppColors.hi,
      };
  Color get chartText => switch (this) {
        Risk.rendah => AppColors.ok,
        Risk.sedang => AppColors.midText,
        Risk.tinggi => AppColors.hi,
      };
  String get message => switch (this) {
        Risk.rendah =>
          'Kondisi metabolik Anda terpantau stabil\ndalam batas aman.',
        Risk.sedang =>
          'Ada kecenderungan risiko sedang yang\ndapat dicegah dengan perbaikan gaya hidup.',
        Risk.tinggi =>
          'Sangat dianjurkan berkonsultasi dengan\ndokter atau fasilitas kesehatan.',
      };
}

// ───────────────────────── Halaman ─────────────────────────
class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    this.userName = 'Rahmawati',
    this.lastPercent = 28,
    this.lastDate = '14 Okt 2023',
    this.idealWeight = '62–66 kg',
    this.bmiNote = 'BMI Terjaga',
    this.trendValues = const [36, 32, 30, 31, 28],
    this.trendLabels = const ['Jun', 'Jul', 'Agu', 'Sep', 'Okt'],
    this.tip =
        'Berjalan santai 30 menit sehari dapat meningkatkan sensitivitas insulin dan menjaga kebugaran tubuh.',
    this.onStartScreening,
    this.onOpenProfile,
    this.onOpenHistory,
  });

  // TODO: ganti nilai default ini dengan data dari API / penyimpanan riwayat.
  final String userName;
  final double lastPercent;
  final String lastDate;
  final String idealWeight;
  final String bmiNote;
  final List<double> trendValues;
  final List<String> trendLabels;
  final String tip;

  final VoidCallback? onStartScreening;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onOpenHistory;

  void _soon(BuildContext c, String msg) {
    ScaffoldMessenger.of(c)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final risk = riskOf(lastPercent);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(
              onProfile: onOpenProfile ??
                  () => _soon(context, 'Halaman Profil belum dihubungkan'),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sapaan
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Halo, Bu $userName',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 22,
                              height: 30 / 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -.22,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text('🌱', style: TextStyle(fontSize: 18)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Semangat sehat! Tubuh Anda dalam ritme yang sangat baik hari ini.',
                      style: TextStyle(
                          fontSize: 15, height: 22 / 15, color: AppColors.mute),
                    ),
                    const SizedBox(height: 16),
                    _LastCheckCard(
                      percent: lastPercent,
                      date: lastDate,
                      risk: risk,
                      idealWeight: idealWeight,
                      bmiNote: bmiNote,
                    ),
                    const SizedBox(height: 16),
                    _TrendCard(values: trendValues, labels: trendLabels),
                    const SizedBox(height: 16),
                    _TipCard(text: tip),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        height: 54,
                        decoration: BoxDecoration(
                          color: AppColors.brand,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                                color: Color(0x3300685F),
                                blurRadius: 6,
                                offset: Offset(0, 4)),
                            BoxShadow(
                                color: Color(0x3300685F),
                                blurRadius: 4,
                                offset: Offset(0, 2)),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: onStartScreening ??
                                () => _soon(
                                    context, 'Form skrining belum dihubungkan'),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_moderator_outlined,
                                    size: 18, color: Colors.white),
                                SizedBox(width: 8),
                                Text('Mulai Skrining Baru',
                                    style: TextStyle(
                                        fontSize: 16,
                                        height: 22 / 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white)),
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
            _BottomNav(
              onHistory: onOpenHistory ??
                  () => _soon(context, 'Halaman Riwayat belum dihubungkan'),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── Header & Navigasi ─────────────────────────
class _Header extends StatelessWidget {
  const _Header({required this.onProfile});
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xD9FFFFFF),
        boxShadow: [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 1)),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/logo.png',
              width: 32,
              height: 32,
              fit: BoxFit.cover,
              cacheWidth: 96,
              errorBuilder: (context, error, stack) => Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Color(0xFF14B8A6), Color(0xFF0F766E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                ),
                child: const Icon(Icons.water_drop_rounded,
                    size: 18, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('Beranda',
                style: TextStyle(
                    fontSize: 18,
                    height: 26 / 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink)),
          ),
          Semantics(
            button: true,
            label: 'Buka profil pengguna',
            child: InkWell(
              onTap: onProfile,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                        color: AppColors.brand, shape: BoxShape.circle),
                    child: const Icon(Icons.person_rounded,
                        size: 16, color: Colors.white),
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

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.onHistory});
  final VoidCallback onHistory;

  Widget _item(IconData icon, String label, bool active, VoidCallback? onTap) {
    final c = active ? AppColors.brand : AppColors.mute;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 64, minHeight: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: c),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    height: 16 / 12,
                    letterSpacing: .24,
                    fontWeight: FontWeight.w600,
                    color: c)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: Color(0xE6FFFFFF),
        boxShadow: [
          BoxShadow(
              color: Color(0x0D0F172A), blurRadius: 12, offset: Offset(0, -2)),
        ],
      ),
      child: SizedBox(
        height: 68,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _item(Icons.home_outlined, 'Beranda', true, null),
            _item(Icons.history_rounded, 'Riwayat', false, onHistory),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── Kartu ─────────────────────────
BoxDecoration _card() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: const [
        BoxShadow(
            color: Color(0x0F0F172A), blurRadius: 4, offset: Offset(0, 2)),
      ],
    );

class _LastCheckCard extends StatelessWidget {
  const _LastCheckCard({
    required this.percent,
    required this.date,
    required this.risk,
    required this.idealWeight,
    required this.bmiNote,
  });
  final double percent;
  final String date;
  final Risk risk;
  final String idealWeight;
  final String bmiNote;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _card(),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.event_available_outlined,
                  size: 14, color: AppColors.brand),
              const SizedBox(width: 6),
              Expanded(
                child: Text('Pemeriksaan Terakhir • $date',
                    style: const TextStyle(
                        fontSize: 12,
                        height: 16 / 12,
                        letterSpacing: .24,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mute)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: AppColors.pillLav,
                    borderRadius: BorderRadius.circular(999)),
                child: const Text('Rutin',
                    style: TextStyle(
                        fontSize: 12,
                        height: 16 / 12,
                        letterSpacing: .24,
                        fontWeight: FontWeight.w500,
                        color: AppColors.ink)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                    size: const Size(160, 160),
                    painter: _RingPainter(percent: percent, color: risk.color)),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${percent.round()}%',
                        style: const TextStyle(
                            fontSize: 40,
                            height: 44 / 40,
                            letterSpacing: -1,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink)),
                    const SizedBox(
                      width: 86,
                      child: Text('Kemungkinan diabetes',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 13,
                              height: 18 / 13,
                              color: AppColors.slate)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Badge risiko
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
                color: risk.bgColor, borderRadius: BorderRadius.circular(999)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                      color: risk.color.withAlpha(191), shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(risk.label,
                    style: TextStyle(
                        fontSize: 14,
                        height: 18 / 14,
                        fontWeight: FontWeight.w600,
                        color: risk.badgeText)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(risk.message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 15, height: 22 / 15, color: AppColors.ink)),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            decoration: BoxDecoration(
                color: AppColors.infoBg, borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.monitor_weight_outlined,
                    size: 14, color: AppColors.ink),
                const SizedBox(width: 8),
                Flexible(
                  child: Text.rich(
                    TextSpan(
                      style: const TextStyle(
                          fontSize: 12,
                          height: 16 / 12,
                          letterSpacing: .24,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink),
                      children: [
                        const TextSpan(text: 'Berat badan ideal: '),
                        TextSpan(
                            text: idealWeight,
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        TextSpan(text: ' ($bmiNote)'),
                      ],
                    ),
                    textAlign: TextAlign.center,
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

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.values, required this.labels});
  final List<double> values;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final fontFamily = DefaultTextStyle.of(context).style.fontFamily;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Perkembangan Anda',
                          style: TextStyle(
                              fontSize: 18,
                              height: 26 / 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink)),
                      Text('${values.length} Pemeriksaan Terakhir',
                          style: const TextStyle(
                              fontSize: 13,
                              height: 18 / 13,
                              color: AppColors.mute)),
                    ],
                  ),
                ),
                const _Legend(color: AppColors.ok, text: 'Rendah'),
                const SizedBox(width: 8),
                const _Legend(color: AppColors.mid, text: 'Sedang'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SizedBox(
              height: 112,
              width: double.infinity,
              child: CustomPaint(
                  painter:
                      _TrendPainter(values: values, fontFamily: fontFamily)),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < labels.length; i++)
                  SizedBox(
                    width: 40,
                    child: Text(
                      labels[i],
                      textAlign: TextAlign.center,
                      style: i == labels.length - 1
                          ? const TextStyle(
                              fontSize: 14,
                              height: 18 / 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.brand)
                          : const TextStyle(
                              fontSize: 12,
                              height: 16 / 12,
                              letterSpacing: .24,
                              fontWeight: FontWeight.w600,
                              color: AppColors.mute),
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

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.text});
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(text,
              style: const TextStyle(
                  fontSize: 11, height: 16.5 / 11, color: AppColors.mute)),
        ],
      );
}

class _TipCard extends StatelessWidget {
  const _TipCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.tipBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0D000000), blurRadius: 1, offset: Offset(0, 1)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration:
                const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.directions_walk_rounded,
                size: 22, color: AppColors.tipTitle),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Tips Hari Ini',
                        style: TextStyle(
                            fontSize: 14,
                            height: 18 / 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.tipTitle)),
                    const SizedBox(width: 6),
                    Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                            color: AppColors.tipDot, shape: BoxShape.circle)),
                  ],
                ),
                const SizedBox(height: 3),
                Text(text,
                    style: const TextStyle(
                        fontSize: 15,
                        height: 20.63 / 15,
                        color: AppColors.tipBody)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Painter ─────────────────────────
class _RingPainter extends CustomPainter {
  _RingPainter({required this.percent, required this.color});
  final double percent;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 14.0; // Figma: diameter 160, stroke 14
    final center = size.center(Offset.zero);
    final radius = (size.width - stroke) / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = AppColors.track,
    );
    final sweep = 2 * 3.141592653589793 * (percent.clamp(0, 100) / 100);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.141592653589793 / 2,
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
  bool shouldRepaint(_RingPainter old) =>
      old.percent != percent || old.color != color;
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({required this.values, this.fontFamily});
  final List<double> values;
  final String? fontFamily;

  void _text(Canvas c, String s, double cx, double cy, TextStyle st, double maxW) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: st),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = (cx - tp.width / 2).clamp(0.0, maxW - tp.width).toDouble();
    tp.paint(c, Offset(dx, cy - tp.height / 2));
  }

  void _dashedLine(Canvas c, double x1, double x2, double y) {
    final p = Paint()
      ..color = AppColors.track
      ..strokeWidth = 1;
    for (var x = x1; x < x2; x += 8) {
      c.drawLine(Offset(x, y), Offset((x + 4).clamp(x1, x2).toDouble(), y), p);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final w = size.width, h = size.height;

    // Garis bantu putus-putus (posisi dari Figma)
    for (final f in [0.2634, 0.5946, 0.7839]) {
      _dashedLine(canvas, w * 0.0333, w * 0.9667, h * f);
    }

    final top = h * 0.311; // posisi titik tertinggi
    final bottom = h * 0.7839; // posisi titik terendah
    final areaBottom = h * 0.9259;

    var minV = values.reduce((a, b) => a < b ? a : b);
    var maxV = values.reduce((a, b) => a > b ? a : b);
    if (maxV - minV < 1) {
      maxV += 1;
      minV -= 1;
    }

    final n = values.length;
    final pts = List<Offset>.generate(n, (i) {
      final x = w * (0.0833 + i * (0.8334 / (n - 1)));
      final y = top + (maxV - values[i]) / (maxV - minV) * (bottom - top);
      return Offset(x, y);
    });

    // Area gradasi di bawah garis
    final area = Path()..moveTo(pts.first.dx, areaBottom);
    for (final p in pts) {
      area.lineTo(p.dx, p.dy);
    }
    area
      ..lineTo(pts.last.dx, areaBottom)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x4D0D9488), Color(0x000D9488)],
        ).createShader(Rect.fromLTWH(0, top, w, areaBottom - top)),
    );

    // Garis tren
    final line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      line.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = AppColors.brand2,
    );

    // Titik + label persen
    for (var i = 0; i < n; i++) {
      final risk = riskOf(values[i]);
      final isLast = i == n - 1;
      canvas.drawCircle(pts[i], isLast ? 5.5 : 4.5, Paint()..color = risk.color);
      _text(
        canvas,
        '${values[i].round()}%',
        pts[i].dx + (isLast ? 6 : 0),
        pts[i].dy - 15.5,
        TextStyle(
          fontFamily: fontFamily,
          fontSize: isLast ? 11.66 : 10.6,
          fontWeight: FontWeight.w700,
          color: risk.chartText,
        ),
        w,
      );
    }
  }

  @override
  bool shouldRepaint(_TrendPainter old) =>
      old.values != values || old.fontFamily != fontFamily;
}