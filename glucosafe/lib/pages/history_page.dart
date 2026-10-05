import 'package:flutter/material.dart';
import 'home_page.dart';

/// Halaman Riwayat GlucoSafe — Tampilan Riwayat Pemeriksaan Berkala.
/// Simpan di: lib/pages/history_page.dart

class HistoryColors {
  static const bg = Color(0xFFF0FDFA);
  static const ink = Color(0xFF131B2E);
  static const slate = Color(0xFF475569);
  static const mute = Color(0xFF64748B);
  static const brand = Color(0xFF00685F);

  // Merah: FEE2E2 dan DC2626
  static const redBg = Color(0xFFFEE2E2);
  static const redText = Color(0xFFDC2626);

  // Kuning: FEF3C7 & Coklat Kekuningan: 92400E
  static const yellowBg = Color(0xFFFEF3C7);
  static const yellowText = Color(0xFF92400E);

  // Hijau: 047857 dan D1FAE5
  static const greenText = Color(0xFF047857);
  static const greenBg = Color(0xFFD1FAE5);

  // Chevron & elemen pendukung
  static const chevronBg = Color(0xFFEEF2FF);
  static const chevronIcon = Color(0xFF475569);
}

/// Model data dummy riwayat pemeriksaan
class HistoryRecord {
  final String percentage;
  final String status;
  final String date;
  final bool isLatest;
  final Color bgColor;
  final Color textColor;
  final IconData icon;

  const HistoryRecord({
    required this.percentage,
    required this.status,
    required this.date,
    this.isLatest = false,
    required this.bgColor,
    required this.textColor,
    required this.icon,
  });
}

class HistoryPage extends StatefulWidget {
  const HistoryPage({
    super.key,
    this.onOpenHome,
    this.onOpenProfile,
    this.onSelectRecord,
  });

  final VoidCallback? onOpenHome;
  final VoidCallback? onOpenProfile;
  final ValueChanged<HistoryRecord>? onSelectRecord;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  // Data dummy riwayat pemeriksaan
  final List<HistoryRecord> dummyRecords = const [
    HistoryRecord(
      percentage: '80%',
      status: 'Berisiko Tinggi',
      date: '28 Okt 2023',
      isLatest: true,
      bgColor: HistoryColors.redBg,
      textColor: HistoryColors.redText,
      icon: Icons.warning_amber_rounded,
    ),
    HistoryRecord(
      percentage: '48%',
      status: 'Tidak Berisiko',
      date: '14 Okt 2023',
      isLatest: false,
      bgColor: HistoryColors.greenBg,
      textColor: HistoryColors.greenText,
      icon: Icons.health_and_safety_outlined,
    ),
    HistoryRecord(
      percentage: '62%',
      status: 'Berisiko Sedang',
      date: '12 Sep 2023',
      isLatest: false,
      bgColor: HistoryColors.yellowBg,
      textColor: HistoryColors.yellowText,
      icon: Icons.warning_amber_rounded,
    ),
    HistoryRecord(
      percentage: '25%',
      status: 'Tidak Berisiko',
      date: '10 Agu 2023',
      isLatest: false,
      bgColor: HistoryColors.greenBg,
      textColor: HistoryColors.greenText,
      icon: Icons.health_and_safety_outlined,
    ),
    HistoryRecord(
      percentage: '54%',
      status: 'Berisiko Sedang',
      date: '9 Jul 2023',
      isLatest: false,
      bgColor: HistoryColors.yellowBg,
      textColor: HistoryColors.yellowText,
      icon: Icons.warning_amber_rounded,
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
      backgroundColor: HistoryColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top Header
            _Header(
              onProfile: widget.onOpenProfile ??
                  () => _showMessage(context, 'Halaman Profil belum dihubungkan'),
            ),

            // Content Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Banner Pemantauan Mandiri
                    const _BannerCard(),
                    const SizedBox(height: 20),

                    // Section Title: Total 5 Pemeriksaan & Tren Membaik
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total ${dummyRecords.length} Pemeriksaan',
                          style: const TextStyle(
                            fontSize: 16,
                            height: 22 / 16,
                            fontWeight: FontWeight.w700,
                            color: HistoryColors.ink,
                          ),
                        ),
                        const Row(
                          children: [
                            Icon(
                              Icons.trending_down_rounded,
                              size: 18,
                              color: HistoryColors.greenText,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Tren Membaik',
                              style: TextStyle(
                                fontSize: 14,
                                height: 20 / 14,
                                fontWeight: FontWeight.w600,
                                color: HistoryColors.greenText,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // List Kartu Riwayat
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: dummyRecords.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final record = dummyRecords[index];
                        return _HistoryCard(
                          record: record,
                          onTap: () {
                            if (widget.onSelectRecord != null) {
                              widget.onSelectRecord!(record);
                            } else {
                              _showMessage(
                                context,
                                'Membuka detail skrining (${record.percentage} - ${record.date})',
                              );
                            }
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // Hint Text Dibawah Card
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.touch_app_outlined,
                            size: 22,
                            color: HistoryColors.greenText,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Ketuk salah satu kartu untuk melihat detail hasil skrining.',
                            style: TextStyle(
                              fontSize: 14,
                              height: 20 / 14,
                              color: HistoryColors.slate,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Navigation
            _BottomNav(
              onBeranda: widget.onOpenHome ??
                  () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const HomePage()),
                    );
                  },
            ),
          ],
        ),
      ),
    );
  }
}

/// Alias class name jika dipanggil sebagai `RiwayatPage`
typedef RiwayatPage = HistoryPage;

// Header
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
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
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
          const Expanded(
            child: Text(
              'Riwayat',
              style: TextStyle(
                fontSize: 18,
                height: 26 / 18,
                fontWeight: FontWeight.w700,
                color: HistoryColors.ink,
              ),
            ),
          ),

          // Tombol Profil User
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
                      color: HistoryColors.brand,
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
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Banner Pemantauan Mandiri ─────────────────────────
class _BannerCard extends StatelessWidget {
  const _BannerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.assignment_outlined,
                      size: 18,
                      color: HistoryColors.greenText,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'PEMANTAUAN MANDIRI',
                      style: TextStyle(
                        fontSize: 13,
                        height: 16 / 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .5,
                        color: HistoryColors.greenText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Catatan riwayat pemeriksaan berkala Anda.',
                  style: TextStyle(
                    fontSize: 15,
                    height: 22 / 15,
                    color: HistoryColors.ink,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Icon chart pada kanan atas
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: HistoryColors.greenBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.bar_chart_rounded,
              size: 24,
              color: HistoryColors.greenText,
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Kartu Item Riwayat ─────────────────────────
class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.record,
    required this.onTap,
  });

  final HistoryRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      shadowColor: const Color(0x0F0F172A),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              // Icon Box Kiri (Sesuai status warna)
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: record.bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  record.icon,
                  size: 24,
                  color: record.textColor,
                ),
              ),
              const SizedBox(width: 14),

              // Bagian Tengah: Nilai Persentase, Status Badge & Tanggal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          record.percentage,
                          style: const TextStyle(
                            fontSize: 22,
                            height: 26 / 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.3,
                            color: HistoryColors.ink,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Badge Status Risiko
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: record.bgColor,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            record.status,
                            style: TextStyle(
                              fontSize: 12,
                              height: 16 / 12,
                              fontWeight: FontWeight.w700,
                              color: record.textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 13,
                          color: HistoryColors.mute,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          record.date,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 18 / 13,
                            color: HistoryColors.mute,
                          ),
                        ),
                        if (record.isLatest) ...[
                          const Text(
                            '  •  ',
                            style: TextStyle(
                              fontSize: 13,
                              color: HistoryColors.mute,
                            ),
                          ),
                          const Text(
                            'Terbaru',
                            style: TextStyle(
                              fontSize: 13,
                              height: 18 / 13,
                              fontWeight: FontWeight.w700,
                              color: HistoryColors.greenText,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Tombol Chevron Kanan
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: HistoryColors.chevronBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: HistoryColors.chevronIcon,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//  Bottom Navigation Bar
class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.onBeranda});
  final VoidCallback onBeranda;

  Widget _item({
    required IconData icon,
    required String label,
    required bool active,
    VoidCallback? onTap,
  }) {
    final color = active ? HistoryColors.brand : HistoryColors.mute;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 64, minHeight: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                height: 16 / 12,
                letterSpacing: .24,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
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
            color: Color(0x0D0F172A),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        height: 68,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _item(
              icon: Icons.home_outlined,
              label: 'Beranda',
              active: false,
              onTap: onBeranda,
            ),
            _item(
              icon: Icons.history_rounded,
              label: 'Riwayat',
              active: true,
              onTap: null,
            ),
          ],
        ),
      ),
    );
  }
}
