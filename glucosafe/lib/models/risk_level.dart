import 'package:flutter/material.dart';

import '../widgets/app_colors.dart';

/// Tingkat risiko diabetes
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
    Risk.rendah => 'Kondisi metabolik Anda terpantau stabil\ndalam batas aman.',
    Risk.sedang => 'Ada kecenderungan risiko sedang yang\ndapat dicegah dengan perbaikan gaya hidup.',
    Risk.tinggi => 'Sangat dianjurkan berkonsultasi dengan\ndokter atau fasilitas kesehatan.',
  };
}
