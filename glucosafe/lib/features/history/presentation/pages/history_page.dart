import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/history_record.dart';
import '../../../../core/models/api_response.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/headbar.dart';
import '../../../../core/widgets/navbar.dart';
import '../../data/history_service.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../screening/presentation/pages/screening_detail_page.dart';

/// Halaman Riwayat GlucoSafe — Tampilan Riwayat Pemeriksaan Berkala.
/// Simpan di: lib/pages/history_page.dart

class HistoryPage extends StatefulWidget {
  const HistoryPage({
    super.key,
    this.onOpenHome,
    this.onOpenProfile,
    this.onSelectRecord,
    this.loadHistory,
  });

  final VoidCallback? onOpenHome;
  final VoidCallback? onOpenProfile;
  final ValueChanged<HistoryRecord>? onSelectRecord;
  final Future<ApiResponse<List<Map<String, dynamic>>>> Function({
    int? page,
    int? limit,
  })? loadHistory;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final HistoryService _historyService = HistoryService();
  final ScrollController _scrollController = ScrollController();
  final int _pageSize = 20;

  List<HistoryRecord> _records = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  int? _totalCount;
  String? _errorMessage;
  String? _loadMoreError;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadHistory();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (maxScroll - currentScroll <= 200) {
      if (!_isLoading && !_isLoadingMore && _hasMore) {
        _loadMore();
      }
    }
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _loadMoreError = null;
      _currentPage = 1;
      _hasMore = true;
    });

    try {
      final fetcher = widget.loadHistory ?? _historyService.getHistory;
      final response = await fetcher(
        page: 1,
        limit: _pageSize,
      );
      if (!mounted) return;
      if (!response.success || response.data == null) {
        setState(() => _errorMessage = response.message);
        return;
      }
      final records = [
        for (var index = 0; index < response.data!.length; index++)
          HistoryRecord.fromJson(response.data![index], isLatest: index == 0),
      ];

      final hasMore = response.pagination != null
          ? (response.pagination!['hasMore'] as bool? ?? false)
          : (records.length >= _pageSize);
      final total = (response.pagination?['total'] as num?)?.toInt();

      setState(() {
        _records = records;
        _hasMore = hasMore;
        _totalCount = total ?? records.length;
        _currentPage = 1;
      });
    } on FormatException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } on PlatformException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            error.message ?? 'Token autentikasi gagal dibaca dari penyimpanan.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;

    setState(() {
      _isLoadingMore = true;
      _loadMoreError = null;
    });

    final nextPage = _currentPage + 1;

    try {
      final fetcher = widget.loadHistory ?? _historyService.getHistory;
      final response = await fetcher(
        page: nextPage,
        limit: _pageSize,
      );
      if (!mounted) return;
      if (!response.success || response.data == null) {
        setState(() => _loadMoreError = response.message);
        _showMessage(context, 'Gagal memuat riwayat: ${response.message}');
        return;
      }

      final newRecords = [
        for (var item in response.data!)
          HistoryRecord.fromJson(item, isLatest: false),
      ];

      final hasMore = response.pagination != null
          ? (response.pagination!['hasMore'] as bool? ?? false)
          : (newRecords.length >= _pageSize);
      final total = (response.pagination?['total'] as num?)?.toInt();

      setState(() {
        _records.addAll(newRecords);
        _currentPage = nextPage;
        _hasMore = hasMore;
        if (total != null) _totalCount = total;
      });
    } on FormatException catch (error) {
      if (!mounted) return;
      setState(() => _loadMoreError = error.message);
      _showMessage(context, 'Format data tidak valid: ${error.message}');
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadMoreError = error.toString());
      _showMessage(context, 'Gagal memuat riwayat tambahan.');
    } finally {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

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
              onProfile:
                  widget.onOpenProfile ??
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfilePage(),
                      ),
                    );
                  },
            ),

            // Content Body
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadHistory,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Banner Pemantauan Mandiri
                      const _BannerCard(),
                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Total ${_totalCount ?? _records.length} Pemeriksaan',
                              style: const TextStyle(
                                fontSize: 16,
                                height: 22 / 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Row(
                            mainAxisSize: MainAxisSize.min,
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
                      _buildHistoryContent(),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Navigation
            NavBar(
              currentIndex: 1,
              onBeranda:
                  widget.onOpenHome ??
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

  Widget _buildHistoryContent() {
    if (_isLoading && _records.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_errorMessage != null) {
      return SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.slate),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _loadHistory,
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      );
    }
    if (_records.isEmpty) {
      return const SizedBox(
        width: double.infinity,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Text(
            'Belum ada riwayat pemeriksaan',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.slate),
          ),
        ),
      );
    }

    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _records.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final record = _records[index];
            return _HistoryCard(
              record: record,
              onTap: () {
                if (widget.onSelectRecord != null) {
                  widget.onSelectRecord!(record);
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ScreeningDetailPage(screeningId: record.id),
                    ),
                  );
                }
              },
            );
          },
        ),
        if (_isLoadingMore) ...[
          const SizedBox(height: 16),
          const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ),
        ],
        if (_loadMoreError != null) ...[
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: _loadMore,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Gagal memuat riwayat berikutnya. Coba lagi'),
            ),
          ),
        ],
        if (!_hasMore && _records.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Semua riwayat telah dimuat',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.mute,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
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
                    const Flexible(
                      // #fix-overflow
                      child: Text(
                        'PEMANTAUAN MANDIRI',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          height: 16 / 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: .5,
                          color: AppColors.greenText,
                        ),
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
  const _HistoryCard({required this.record, required this.onTap});

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
                child: Icon(record.icon, size: 24, color: record.textColor),
              ),
              const SizedBox(width: 14),

              // Bagian Tengah: Nilai Persentase, Status Badge & Tanggal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          // #fix-overflow
                          child: Text(
                            record.percentage,
                            style: const TextStyle(
                              fontSize: 22,
                              height: 26 / 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -.3,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Badge Status Risiko
                        Flexible(
                          // #fix-overflow
                          child: Container(
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
                              maxLines: 1, // #fix-overflow
                              overflow: TextOverflow.ellipsis, // #fix-overflow
                              style: TextStyle(
                                fontSize: 12,
                                height: 16 / 12,
                                fontWeight: FontWeight.w700,
                                color: record.textColor,
                              ),
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
                        Flexible(
                          // #fix-overflow
                          child: Text(
                            record.date,
                            maxLines: 1, // #fix-overflow
                            overflow: TextOverflow.ellipsis, // #fix-overflow
                            style: const TextStyle(
                              fontSize: 13,
                              height: 18 / 13,
                              color: AppColors.mute,
                            ),
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
