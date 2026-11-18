import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Model data riwayat pemeriksaan berkala.
class HistoryRecord {
  final int id;
  final String percentage;
  final String status;
  final String date;
  final double? bmi;
  final bool isLatest;
  final Color bgColor;
  final Color textColor;
  final IconData icon;

  const HistoryRecord({
    required this.id,
    required this.percentage,
    required this.status,
    required this.date,
    this.bmi,
    this.isLatest = false,
    required this.bgColor,
    required this.textColor,
    required this.icon,
  });

  factory HistoryRecord.fromJson(
    Map<String, dynamic> json, {
    required bool isLatest,
  }) {
    final id = json['id'];
    final riskPercentage = json['risk_percentage'] ?? json['risk_percent'];
    final riskLevel = json['risk_level'] ?? json['risk_label'];
    final createdAt = json['created_at'];
    final bmiValue = json['bmi'];
    if (id is! num ||
        !id.isFinite ||
        id < 1 ||
        id % 1 != 0 ||
        riskLevel is! String ||
        createdAt is! String ||
        (riskPercentage is! num && riskPercentage is! String) ||
        (bmiValue != null && bmiValue is! num && bmiValue is! String)) {
      throw const FormatException('Format riwayat pemeriksaan tidak valid.');
    }

    final percentageValue = double.tryParse(riskPercentage.toString());
    final parsedDate = DateTime.tryParse(createdAt);
    final parsedBmi = bmiValue == null
        ? null
        : double.tryParse(bmiValue.toString());
    if (percentageValue == null ||
        !percentageValue.isFinite ||
        percentageValue < 0 ||
        percentageValue > 100 ||
        parsedDate == null ||
        (bmiValue != null &&
            (parsedBmi == null || !parsedBmi.isFinite || parsedBmi <= 0))) {
      throw const FormatException(
        'Nilai risiko, BMI, atau tanggal riwayat tidak valid.',
      );
    }

    final (status, background, foreground, icon) = switch (riskLevel) {
      'Rendah' => (
        'Risiko Rendah',
        AppColors.greenBg,
        AppColors.greenText,
        Icons.health_and_safety_outlined,
      ),
      'Sedang' => (
        'Berisiko Sedang',
        AppColors.yellowBg,
        AppColors.yellowText,
        Icons.warning_amber_rounded,
      ),
      'Tinggi' => (
        'Berisiko Tinggi',
        AppColors.redBg,
        AppColors.redText,
        Icons.warning_amber_rounded,
      ),
      _ => throw const FormatException('Level risiko riwayat tidak dikenal.'),
    };
    final formattedPercentage = percentageValue
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'\.?0+$'), '');

    return HistoryRecord(
      id: id.toInt(),
      percentage: '$formattedPercentage%',
      status: status,
      date: _formatIndonesianDate(parsedDate),
      bmi: parsedBmi,
      isLatest: isLatest,
      bgColor: background,
      textColor: foreground,
      icon: icon,
    );
  }

  static String _formatIndonesianDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
