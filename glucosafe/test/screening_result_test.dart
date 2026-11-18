import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glucosafe/features/screening/domain/screening_answer_formatter.dart';
import 'package:glucosafe/features/screening/domain/screening_form.dart';
import 'package:glucosafe/features/screening/domain/screening_result.dart';
import 'package:glucosafe/features/screening/presentation/pages/screening_result_page.dart';

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

  test('ScreeningResult mempertahankan field detail tambahan dari backend', () {
    final result = ScreeningResult.fromJson({
      'id': 5,
      'risk_percent': 38,
      'risk_label': 'Sedang',
      'age': 52,
      'smoking_history': 'never',
    });

    expect(result.additionalFields, {'age': 52, 'smoking_history': 'never'});
  });

  test('jawaban skrining menampilkan kategori usia, bukan kode model', () {
    expect(screeningAnswerLabel('age'), 'Rentang usia');
    expect(formatScreeningAnswer('age', 2), '25–29 tahun');
    expect(formatScreeningAnswer('sex', 0), 'Perempuan');
    expect(formatScreeningAnswer('high_bp', 1), 'Ya');
    expect(
      formatScreeningAnswer('ment_hlth', 4),
      '4 hari dari 30 hari terakhir',
    );
  });

  testWidgets('hasil menjelaskan skor dan merangkum jawaban dengan jelas', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: ScreeningResultPage(
          result: const ScreeningResult(
            id: 1,
            riskPercent: 42.5,
            riskLabel: 'Sedang',
          ),
          form: const ScreeningForm(
            sex: 1,
            age: 2,
            heightCm: 168,
            weightKg: 70,
            highBp: 0,
            highChol: 0,
            stroke: 0,
            heartDiseaseOrAttack: 0,
            diffWalk: 0,
            smoker: 0,
            physActivity: 1,
            fruits: 1,
            veggies: 1,
            genHlth: 2,
            mentHlth: 4,
            physHlth: 2,
          ),
        ),
      ),
    );

    expect(find.text('Skor skrining\noleh model'), findsOneWidget);
    expect(find.text('Ringkasan jawaban skrining'), findsOneWidget);
    expect(find.text('Rentang usia'), findsOneWidget);
    expect(find.text('25–29 tahun'), findsOneWidget);
    expect(find.text('43%'), findsOneWidget);
    expect(
      find.textContaining('bukan kepastian atau diagnosis diabetes'),
      findsOneWidget,
    );
    expect(find.text('2'), findsNothing);
  });
}
