import 'package:flutter/material.dart';
import '../models/history_record.dart';
import '../widgets/app_colors.dart';
import '../widgets/headbar.dart';
import '../widgets/navbar.dart';
import 'home_page.dart';

/// Halaman Riwayat GlucoSafe — Tampilan Riwayat Pemeriksaan Berkala.
/// Simpan di: lib/pages/history_page.dart

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
      bgColor: AppColors.redBg,
      textColor: AppColors.redText,
      icon: Icons.warning_amber_rounded,
    ),
    HistoryRecord(
      percentage: '48%',
      status: 'Tidak Berisiko',
      date: '14 Okt 2023',
      isLatest: false,
      bgColor: AppColors.greenBg,
      textColor: AppColors.greenText,
      icon: Icons.health_and_safety_outlined,
    ),
    HistoryRecord(
      percentage: '62%',
      status: 'Berisiko Sedang',
      date: '12 Sep 2023',
      isLatest: false,
      bgColor: AppColors.yellowBg,
      textColor: AppColors.yellowText,
      icon: Icons.warning_amber_rounded,
    ),
    HistoryRecord(
      percentage: '25%',
      status: 'Tidak Berisiko',
      date: '10 Agu 2023',
      isLatest: false,
      bgColor: AppColors.greenBg,
      textColor: AppColors.greenText,
      icon: Icons.health_and_safety_outlined,
    ),
    HistoryRecord(
      percentage: '54%',
      status: 'Berisiko Sedang',
      date: '9 Jul 2023',
      isLatest: false,
      bgColor: AppColors.yellowBg,
      textColor: AppColors.yellowText,
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
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top Header
            HeadBar(
              title: 'Riwayat',
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
                            color: AppColors.ink,
                          ),
                        ),
                        const Row(
                          children: [
                            Icon(
                              Icons.trending_down_rounded,
                              size: 18,
                              color: AppColors.greenText,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Tren Membaik',
                              style: TextStyle(
                                fontSize: 14,
                                height: 20 / 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.greenText,
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
                            color: AppColors.greenText,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Ketuk salah satu kartu untuk melihat detail hasil skrining.',
                            style: TextStyle(
                              fontSize: 14,
                              height: 20 / 14,
                              color: AppColors.slate,
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
            NavBar(
              currentIndex: 1,
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
                      color: AppColors.greenText,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'PEMANTAUAN MANDIRI',
                      style: TextStyle(
                        fontSize: 13,
                        height: 16 / 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .5,
                        color: AppColors.greenText,
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
                    color: AppColors.ink,
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
              color: AppColors.greenBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.bar_chart_rounded,
              size: 24,
              color: AppColors.greenText,
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
                            color: AppColors.ink,
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
                          color: AppColors.mute,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          record.date,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 18 / 13,
                            color: AppColors.mute,
                          ),
                        ),
                        if (record.isLatest) ...[
                          const Text(
                            '  •  ',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.mute,
                            ),
                          ),
                          const Text(
                            'Terbaru',
                            style: TextStyle(
                              fontSize: 13,
                              height: 18 / 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.greenText,
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
                  color: AppColors.chevronBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: AppColors.chevronIcon,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
