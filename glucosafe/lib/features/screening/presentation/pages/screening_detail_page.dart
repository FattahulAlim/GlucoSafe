import 'package:flutter/material.dart';

import '../../../../core/models/api_response.dart';
import '../../../../core/services/screening_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/headbar.dart';
import '../../domain/screening_answer_formatter.dart';
import '../../domain/recommendation_item.dart';
import '../../domain/screening_result.dart';

class ScreeningDetailPage extends StatefulWidget {
  const ScreeningDetailPage({super.key, required this.screeningId});

  final int screeningId;

  @override
  State<ScreeningDetailPage> createState() => _ScreeningDetailPageState();
}

class _ScreeningDetailPageState extends State<ScreeningDetailPage> {
  final ScreeningService _screeningService = ScreeningService();
  ScreeningResult? _screening;
  List<RecommendationItem> _recommendations = const [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final responses = await Future.wait<Object>([
        _screeningService.getDetail(widget.screeningId),
        _screeningService.getRecommendations(widget.screeningId),
      ]);
      final detailResponse = responses[0];
      final recommendationResponse = responses[1];

      if (detailResponse is! ApiResponse<ScreeningResult> ||
          recommendationResponse is! ApiResponse<List<RecommendationItem>>) {
        throw const FormatException('Respons detail skrining tidak valid.');
      }

      final screening = detailResponse.data;
      final recommendations = recommendationResponse.data;
      if (!detailResponse.success || screening == null) {
        throw Exception(
          detailResponse.message.isEmpty
              ? 'Detail skrining tidak dapat dimuat.'
              : detailResponse.message,
        );
      }
      if (!recommendationResponse.success || recommendations == null) {
        throw Exception(
          recommendationResponse.message.isEmpty
              ? 'Rekomendasi tidak dapat dimuat.'
              : recommendationResponse.message,
        );
      }

      if (!mounted) return;
      setState(() {
        _screening = screening;
        _recommendations = recommendations;
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            HeadBar(
              title: 'Detail Skrining',
              showBackButton: true,
              onBack: () => Navigator.maybePop(context),
            ),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildExitButtons() {
    return Column(
      children: [
        // Tombol Kembali
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.maybePop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brand,
              foregroundColor: Colors.white,
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.arrow_back_rounded, size: 20),
            label: const Text(
              'Kembali',
              style: TextStyle(
                fontSize: 16,
                height: 22 / 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Tombol Beranda
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.brand,
              side: const BorderSide(color: AppColors.brand, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.home_rounded, size: 20),
            label: const Text(
              'Beranda',
              style: TextStyle(
                fontSize: 16,
                height: 22 / 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: AppColors.error,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.slate),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _loadDetail,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    final screening = _screening!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ScreeningSummaryCard(screening: screening),
          if (screening.additionalFields.isNotEmpty) ...[
            const SizedBox(height: 16),
            _AdditionalFieldsCard(fields: screening.additionalFields),
          ],
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Rekomendasi',
                  style: TextStyle(
                    fontSize: 16,
                    height: 22 / 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
              Text(
                '${_recommendations.length} rekomendasi',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.greenText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_recommendations.isEmpty)
            const _EmptyRecommendations()
          else
            ..._recommendations.map(
              (recommendation) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _RecommendationCard(item: recommendation),
              ),
            ),
          const SizedBox(height: 12),
          _buildExitButtons(),
        ],
      ),
    );
  }
}

class _ScreeningSummaryCard extends StatelessWidget {
  const _ScreeningSummaryCard({required this.screening});

  final ScreeningResult screening;

  @override
  Widget build(BuildContext context) {
    final date = screening.createdAt == null
        ? 'Tanggal tidak tersedia'
        : _formatDate(screening.createdAt!);

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: AppColors.greenText,
              ),
              const SizedBox(width: 8),
              Text(date, style: const TextStyle(color: AppColors.mute)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${_formatNumber(screening.riskPercent)}%',
            style: const TextStyle(
              fontSize: 32,
              height: 38 / 32,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _riskBackground(screening.riskLabel),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Risiko ${screening.riskLabel}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: _riskForeground(screening.riskLabel),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Persentase adalah perkiraan model dari jawaban, bukan diagnosis medis.',
              style: TextStyle(fontSize: 13, color: AppColors.slate),
            ),
          ),
          if (screening.bmi != null) ...[
            const SizedBox(height: 16),
            _SummaryField(
              label: 'Indeks Massa Tubuh (BMI)',
              value: _formatNumber(screening.bmi!),
            ),
          ],
          if (screening.heightCm != null)
            _SummaryField(
              label: 'Tinggi badan',
              value: '${_formatNumber(screening.heightCm!)} cm',
            ),
          if (screening.weightKg != null)
            _SummaryField(
              label: 'Berat badan',
              value: '${_formatNumber(screening.weightKg!)} kg',
            ),
        ],
      ),
    );
  }
}

class _AdditionalFieldsCard extends StatelessWidget {
  const _AdditionalFieldsCard({required this.fields});

  final Map<String, dynamic> fields;

  @override
  Widget build(BuildContext context) {
    final visibleFields = fields.entries
        .where(
          (entry) =>
              entry.value != null &&
              !const {
                'id',
                'user_id',
                'updated_at',
                'created_at',
                'risk_percent',
                'risk_label',
                'bmi',
                'height_cm',
                'weight_kg',
              }.contains(entry.key),
        )
        .toList();
    if (visibleFields.isEmpty) return const SizedBox.shrink();

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Jawaban skrining',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Data berikut adalah jawaban yang digunakan dalam penilaian.',
            style: TextStyle(fontSize: 13, color: AppColors.slate),
          ),
          for (final field in visibleFields)
            _SummaryField(
              label: screeningAnswerLabel(field.key),
              value: formatScreeningAnswer(field.key, field.value),
            ),
        ],
      ),
    );
  }
}

class _SummaryField extends StatelessWidget {
  const _SummaryField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: AppColors.slate)),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.item});

  final RecommendationItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: item.iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: item.iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.category,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: item.iconColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                if (item.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    item.description,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 20 / 14,
                      color: AppColors.slate,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyRecommendations extends StatelessWidget {
  const _EmptyRecommendations();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            color: AppColors.hint,
            size: 32,
          ),
          SizedBox(height: 8),
          Text(
            'Belum ada rekomendasi untuk hasil skrining ini.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.slate),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  const months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

String _formatNumber(double number) =>
    number.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');

Color _riskBackground(String riskLabel) => switch (riskLabel.toLowerCase()) {
  'tinggi' => AppColors.redBg,
  'sedang' => AppColors.yellowBg,
  _ => AppColors.greenBg,
};

Color _riskForeground(String riskLabel) => switch (riskLabel.toLowerCase()) {
  'tinggi' => AppColors.redText,
  'sedang' => AppColors.yellowText,
  _ => AppColors.greenText,
};
