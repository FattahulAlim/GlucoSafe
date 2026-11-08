import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:glucosafe/core/models/api_response.dart';
import 'package:glucosafe/features/home/presentation/pages/home_page.dart';
import 'package:glucosafe/features/screening/domain/screening_result.dart';

Future<void> _pumpHome(
  WidgetTester tester,
  Future<ApiResponse<List<ScreeningResult>>> Function() loader,
) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(home: HomePage(userName: 'Rahma', loadHistory: loader)),
  );
  await tester.pumpAndSettle();
}

ScreeningResult _rec(int id, DateTime date, double percent) => ScreeningResult(
      id: id,
      createdAt: date,
      riskPercent: percent,
      riskLabel: 'Rendah',
      bmi: 25.7,
      heightCm: 165,
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('menampilkan pemeriksaan terakhir dari riwayat', (tester) async {
    await _pumpHome(
      tester,
      () async => ApiResponse<List<ScreeningResult>>(
        success: true,
        message: 'ok',
        data: [
          _rec(2, DateTime(2026, 10, 14), 28),
          _rec(1, DateTime(2026, 9, 12), 36),
        ],
      ),
    );

    expect(find.text('28%'), findsOneWidget);
    expect(find.text('Risiko Rendah'), findsOneWidget);
    expect(find.text('Pemeriksaan Terakhir • 14 Okt 2026'), findsOneWidget);
    expect(find.text('2 Pemeriksaan Terakhir'), findsOneWidget);
  });

  testWidgets('pengguna baru melihat tampilan kosong', (tester) async {
    await _pumpHome(
      tester,
      () async => const ApiResponse<List<ScreeningResult>>(
        success: true,
        message: 'ok',
        data: [],
      ),
    );

    expect(find.text('Belum ada pemeriksaan'), findsOneWidget);
    expect(find.text('Perkembangan Anda'), findsNothing);
  });

  testWidgets('gagal memuat menampilkan pesan dan bisa dicoba lagi',
      (tester) async {
    var calls = 0;
    await _pumpHome(tester, () async {
      calls++;
      if (calls == 1) {
        return const ApiResponse<List<ScreeningResult>>(
          success: false,
          message: 'Tidak dapat terhubung ke server.',
        );
      }
      return ApiResponse<List<ScreeningResult>>(
        success: true,
        message: 'ok',
        data: [_rec(1, DateTime(2026, 10, 14), 28)],
      );
    });

    expect(find.text('Tidak dapat terhubung ke server.'), findsOneWidget);

    await tester.tap(find.text('Coba Lagi'));
    await tester.pumpAndSettle();

    expect(find.text('Ringkasan belum bisa dimuat'), findsNothing);
    expect(find.text('28%'), findsOneWidget);
    expect(calls, 2);
  });
}