import 'package:flutter/material.dart';
import '../../../screening/domain/risk_level.dart';
import '../../../screening/domain/screening_result.dart';
import '../../../../core/models/api_response.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/headbar.dart';
import '../../../../core/widgets/navbar.dart';
import '../../../../core/services/screening_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../history/presentation/pages/history_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../screening/domain/screening_state.dart';
import '../../../screening/presentation/pages/screening_step1_page.dart';
import '../../domain/home_summary.dart';

/// Halaman Beranda GlucoSafe. Ringkasan (pemeriksaan terakhir, grafik
/// perkembangan, BMI) diambil dari riwayat skrining di backend.
/// Simpan di: lib/features/home/presentation/pages/home_page.dart

enum _LoadStatus { loading, success, error }

// ───────────────────────── Halaman ─────────────────────────
class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    this.userName,
    this.tip =
        'Berjalan santai 30 menit sehari dapat meningkatkan sensitivitas insulin dan menjaga kebugaran tubuh.',
    this.onStartScreening,
    this.onOpenProfile,
    this.onOpenHistory,
    this.loadHistory,
  });

  final String? userName;
  final String tip;

  final VoidCallback? onStartScreening;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onOpenHistory;

  /// Pengambil data riwayat. Bawaannya memanggil ScreeningService;
  /// bisa diganti saat test.
  final Future<ApiResponse<List<ScreeningResult>>> Function()? loadHistory;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _loadedName;
  _LoadStatus _status = _LoadStatus.loading;
  HomeSummary? _summary;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadSummary();
  }

  Future<void> _loadUser() async {
    final user = await StorageService().getUser();
    if (user != null && mounted) {
      setState(() {
        _loadedName = user.name;
      });
    }
  }

  Future<void> _loadSummary() async {
    final load = widget.loadHistory ?? ScreeningService().getHistory;
    try {
      final response = await load();
      if (!mounted) return;
      if (response.success) {
        setState(() {
          _summary = HomeSummary.fromHistory(response.data ?? const []);
          _status = _LoadStatus.success;
        });
      } else {
        setState(() {
          _errorMessage = response.message;
          _status = _LoadStatus.error;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Gagal memuat ringkasan. Coba lagi.';
        _status = _LoadStatus.error;
      });
    }
  }

  void _retry() {
    setState(() => _status = _LoadStatus.loading);
    _loadSummary();
  }

  String get _subtitle {
    final summary = _summary;
    if (_status != _LoadStatus.success) {
      return 'Pantau kondisi kesehatan Anda dengan pemeriksaan berkala.';
    }
    if (summary == null) {
      return 'Belum ada pemeriksaan. Mulai pemeriksaan pertama Anda.';
    }
    return switch (summary.risk) {
      Risk.rendah =>
        'Semangat sehat! Tubuh Anda dalam ritme yang sangat baik hari ini.',
      Risk.sedang || Risk.tinggi =>
        'Terus pantau kesehatan Anda dan lakukan pemeriksaan secara berkala.',
    };
  }

  List<Widget> _summarySection() {
    switch (_status) {
      case _LoadStatus.loading:
        return const [_LoadingCard(), SizedBox(height: 16)];
      case _LoadStatus.error:
        return [
          _ErrorCard(message: _errorMessage, onRetry: _retry),
          const SizedBox(height: 16),
        ];
      case _LoadStatus.success:
        final summary = _summary;
        if (summary == null) {
          return const [_EmptyCard(), SizedBox(height: 16)];
        }
        return [
          _LastCheckCard(
            percent: summary.lastPercent,
            date: summary.lastDate,
            risk: summary.risk,
            infoLabel: summary.infoLabel,
            infoValue: summary.infoValue,
            infoNote: summary.infoNote,
          ),
          const SizedBox(height: 16),
          _TrendCard(
              values: summary.trendValues, labels: summary.trendLabels),
          const SizedBox(height: 16),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.userName ?? _loadedName ?? 'Pengguna';

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            HeadBar(
              title: 'Beranda',
              onProfile: widget.onOpenProfile ??
                  () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfilePage(),
                      ),
                    );
                    _loadUser();
                  },
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadSummary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sapaan
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Halo, $displayName',
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
                      Text(
                        _subtitle,
                        style: const TextStyle(
                            fontSize: 15,
                            height: 22 / 15,
                            color: AppColors.mute),
                      ),
                      const SizedBox(height: 16),
                      ..._summarySection(),
                      _TipCard(text: widget.tip),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Container(
                          width: double.infinity, // #fix-overflow
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
                              onTap: widget.onStartScreening ??
                                  () {
                                    resetScreeningForm();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const ScreeningStep1Page(),
                                      ),
                                    );
                                  },
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_moderator_outlined,
                                      size: 18, color: Colors.white),
                                  SizedBox(width: 8),
                                  Flexible( // #fix-overflow
                                    child: Text('Mulai Skrining Baru',
                                        maxLines: 1, // #fix-overflow
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            fontSize: 16,
                                            height: 22 / 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white)),
                                  ),
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
            ),
            NavBar(
              currentIndex: 0,
              onHistory: widget.onOpenHistory ??
                  () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HistoryPage(),
                      ),
                    );
                  },
            ),
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

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Memuat ringkasan kesehatan',
      child: Container(
        width: double.infinity,
        height: 220,
        decoration: _card(),
        alignment: Alignment.center,
        child: const CircularProgressIndicator(color: AppColors.brand2),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _card(),
      child: const Column(
        children: [
          Icon(Icons.assignment_outlined, size: 40, color: AppColors.brand2),
          SizedBox(height: 12),
          Text('Belum ada pemeriksaan',
              style: TextStyle(
                  fontSize: 18,
                  height: 26 / 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink)),
          SizedBox(height: 6),
          Text(
            'Lakukan pemeriksaan pertama Anda untuk melihat hasil dan perkembangan kesehatan di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 15, height: 22 / 15, color: AppColors.slate),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _card(),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined, size: 40, color: AppColors.mute),
          const SizedBox(height: 12),
          const Text('Ringkasan belum bisa dimuat',
              style: TextStyle(
                  fontSize: 18,
                  height: 26 / 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink)),
          const SizedBox(height: 6),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 15, height: 22 / 15, color: AppColors.slate)),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 20),
            label: const Text('Coba Lagi'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.brand,
              side: const BorderSide(color: AppColors.brand, width: 1.5),
              minimumSize: const Size(0, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _LastCheckCard extends StatelessWidget {
  const _LastCheckCard({
    required this.percent,
    required this.date,
    required this.risk,
    required this.infoLabel,
    required this.infoValue,
    required this.infoNote,
  });
  final double percent;
  final String date;
  final Risk risk;
  final String infoLabel;
  final String infoValue;
  final String infoNote;

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
                        TextSpan(text: infoLabel),
                        TextSpan(
                            text: infoValue,
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        TextSpan(text: ' ($infoNote)'),
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
    final canDraw = values.length >= 2;
    // Legenda hanya untuk tingkat risiko yang muncul di grafik.
    final levels = <Risk>{for (final v in values) riskOf(v)};

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
                for (final level in Risk.values)
                  if (levels.contains(level)) ...[
                    const SizedBox(width: 8),
                    _Legend(
                      color: level.color,
                      text: level.label.replaceFirst('Risiko ', ''),
                    ),
                  ],
              ],
            ),
          ),
          if (!canDraw)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Lakukan minimal 2 pemeriksaan untuk melihat perkembangan Anda.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14, height: 20 / 14, color: AppColors.slate),
                ),
              ),
            )
          else ...[
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
                      width: 48,
                      child: Text(
                        labels[i],
                        textAlign: TextAlign.center,
                        maxLines: 1,
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