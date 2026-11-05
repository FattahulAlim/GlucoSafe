import 'package:flutter_test/flutter_test.dart';
import 'package:glucosafe/features/screening/domain/screening_result.dart';

void main() {
  test('ScreeningResult mempertahankan rekomendasi kosong dari backend', () {
    final result = ScreeningResult.fromJson({
      'id': 1,
      'risk_percent': 42.5,
      'risk_label': 'Sedang',
      'recommendations': [],
    });

    expect(result.riskPercent, 42.5);
    expect(result.riskLabel, 'Sedang');
    expect(result.recommendations, isEmpty);
  });

  test('ScreeningResult membaca rekomendasi nyata dari backend', () {
    final result = ScreeningResult.fromJson({
      'id': 1,
      'risk_percent': 70,
      'risk_label': 'Tinggi',
      'recommendations': [
        {
          'category': 'Pemeriksaan',
          'title': 'Segera Konsultasi ke Dokter',
          'description': 'Lakukan pemeriksaan lebih lanjut.',
        },
      ],
    });

    expect(result.recommendations, hasLength(1));
    expect(result.recommendations.single.title, 'Segera Konsultasi ke Dokter');
    expect(result.recommendations.single.category, 'Pemeriksaan');
  });
}
