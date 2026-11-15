import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:glucosafe/core/models/api_response.dart';
import 'package:glucosafe/features/history/presentation/pages/history_page.dart';

Map<String, dynamic> _makeRecordJson(int id) => {
      'id': id,
      'created_at': '2026-11-0${(id % 8) + 1} 10:00:00',
      'risk_percent': '25.00',
      'risk_label': 'Rendah',
      'bmi': '22.0',
    };

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('HistoryPage initial load & infinite scroll load more test', (tester) async {
    final requestedPages = <int>[];

    Future<ApiResponse<List<Map<String, dynamic>>>> mockLoader({
      int? page,
      int? limit,
    }) async {
      final p = page ?? 1;
      requestedPages.add(p);

      if (p == 1) {
        return ApiResponse(
          success: true,
          message: 'ok',
          data: List.generate(20, (i) => _makeRecordJson(100 - i)),
          pagination: {
            'page': 1,
            'limit': 20,
            'total': 25,
            'hasMore': true,
          },
        );
      } else if (p == 2) {
        return ApiResponse(
          success: true,
          message: 'ok',
          data: List.generate(5, (i) => _makeRecordJson(80 - i)),
          pagination: {
            'page': 2,
            'limit': 20,
            'total': 25,
            'hasMore': false,
          },
        );
      }

      return const ApiResponse(
        success: true,
        message: 'ok',
        data: [],
        pagination: {'page': 3, 'limit': 20, 'total': 25, 'hasMore': false},
      );
    }

    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: HistoryPage(
          loadHistory: mockLoader,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Pastikan page 1 dipanggil dan total langsung tampil statis
    expect(requestedPages, contains(1));
    expect(find.text('Total 25 Pemeriksaan'), findsOneWidget);

    // Scroll ke bawah untuk memicu load more
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -3000));
    await tester.pump();
    await tester.pumpAndSettle();

    // Pastikan page 2 terpanggil
    expect(requestedPages, contains(2));

    // Setelah page 2 dimuat, total item adalah 25 dan hasMore = false
    expect(find.text('Total 25 Pemeriksaan'), findsOneWidget);
    expect(find.text('Semua riwayat telah dimuat'), findsOneWidget);
  });
}
