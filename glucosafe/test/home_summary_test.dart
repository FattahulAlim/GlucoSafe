import 'package:flutter_test/flutter_test.dart';
import 'package:glucosafe/features/home/domain/home_summary.dart';
import 'package:glucosafe/features/screening/domain/risk_level.dart';
import 'package:glucosafe/features/screening/domain/screening_result.dart';

ScreeningResult _rec(
  int id,
  DateTime date,
  double percent, {
  double? bmi = 25.7,
  double? height = 165,
}) =>
    ScreeningResult(
      id: id,
      createdAt: date,
      riskPercent: percent,
      riskLabel: 'Rendah',
      bmi: bmi,
      heightCm: height,
    );

void main() {
  test('tanpa riwayat menghasilkan null', () {
    expect(HomeSummary.fromHistory(const []), isNull);
  });

  test('rekaman terakhir diambil dari yang paling baru', () {
    final summary = HomeSummary.fromHistory([
      _rec(1, DateTime(2026, 9, 12), 31),
      _rec(2, DateTime(2026, 10, 14), 28),
    ])!;

    expect(summary.lastPercent, 28);
    expect(summary.lastDate, '14 Okt 2026');
    expect(summary.risk, Risk.rendah);
  });

  test('grafik memakai 5 terbaru dengan urutan lama ke baru', () {
    final records = [
      for (var i = 1; i <= 7; i++) _rec(i, DateTime(2026, i, 10), i * 10.0),
    ];
    final summary = HomeSummary.fromHistory(records)!;

    expect(summary.trendValues, [30, 40, 50, 60, 70]);
    expect(summary.trendLabels, ['Mar', 'Apr', 'Mei', 'Jun', 'Jul']);
  });

  test('label memakai tanggal jika ada bulan yang sama', () {
    final summary = HomeSummary.fromHistory([
      _rec(1, DateTime(2026, 10, 3), 30),
      _rec(2, DateTime(2026, 10, 14), 28),
    ])!;

    expect(summary.trendLabels, ['3 Okt', '14 Okt']);
  });

  test('urutan input acak tetap menghasilkan yang terbaru', () {
    final summary = HomeSummary.fromHistory([
      _rec(2, DateTime(2026, 10, 14), 28),
      _rec(1, DateTime(2026, 6, 1), 40),
      _rec(3, DateTime(2026, 8, 1), 35),
    ])!;

    expect(summary.lastPercent, 28);
    expect(summary.trendValues, [40, 35, 28]);
  });

  test('berat badan ideal dihitung dari tinggi', () {
    final summary =
        HomeSummary.fromHistory([_rec(1, DateTime(2026, 10, 14), 28)])!;

    expect(summary.infoLabel, 'Berat badan ideal: ');
    expect(summary.infoValue, '50–68 kg');
    expect(summary.infoNote, 'BMI 25.7 • Berlebih');
  });

  test('tanpa tinggi, baris info memakai BMI terakhir', () {
    final summary = HomeSummary.fromHistory(
        [_rec(1, DateTime(2026, 10, 14), 28, height: null)])!;

    expect(summary.infoLabel, 'BMI terakhir: ');
    expect(summary.infoValue, '25.7');
    expect(summary.infoNote, 'Berlebih');
  });

  test('ScreeningResult.fromJson menerima angka berupa teks', () {
    final result = ScreeningResult.fromJson({
      'id': 1,
      'created_at': '2026-10-14T03:00:00.000Z',
      'risk_percent': '28.00',
      'risk_label': 'Rendah',
      'bmi': '25.7',
      'height_cm': '165.00',
    });

    expect(result.riskPercent, 28.0);
    expect(result.bmi, 25.7);
    expect(result.heightCm, 165.0);
    expect(result.weightKg, isNull);
  });
}