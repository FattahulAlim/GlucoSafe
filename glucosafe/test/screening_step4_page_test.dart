import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glucosafe/features/screening/domain/screening_state.dart';
import 'package:glucosafe/features/screening/presentation/pages/screening_result_page.dart';
import 'package:glucosafe/features/screening/presentation/pages/screening_step_4_page.dart';

void main() {
  setUp(resetScreeningForm);

  void useTallScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Future<void> pumpStep4(WidgetTester tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(const MaterialApp(home: ScreeningStep4Page()));
  }

  Future<void> openStep4FromHost(WidgetTester tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ScreeningStep4Page()),
                ),
                child: const Text('Buka'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Buka'));
    await tester.pumpAndSettle();
  }

  Future<void> moveSlider(WidgetTester tester, int index, double value) async {
    tester.widget<Slider>(find.byType(Slider).at(index)).onChanged!(value);
    await tester.pump();
  }

  testWidgets('menampilkan judul, indikator langkah, lima pilihan, dan dua slider', (tester) async {
    await pumpStep4(tester);

    expect(find.text('Kondisi Umum'), findsOneWidget);
    expect(find.text('LANGKAH 4 DARI 4'), findsOneWidget);
    expect(find.text('100% Selesai'), findsOneWidget);
    for (final label in ['Sangat\nBaik', 'Baik', 'Cukup', 'Kurang', 'Buruk']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.byType(Slider), findsNWidgets(2));
    expect(find.text('Cek Risiko Saya'), findsOneWidget);
  });

  testWidgets('nilai awal slider tampil 3 hari dan 2 hari', (tester) async {
    await pumpStep4(tester);

    expect(find.text('3 Hari'), findsOneWidget);
    expect(find.text('2 Hari'), findsOneWidget);
  });

  testWidgets('memilih kondisi kesehatan umum menyimpan kode 1 sampai 5', (tester) async {
    await pumpStep4(tester);

    final cases = {'Sangat\nBaik': 1, 'Baik': 2, 'Cukup': 3, 'Kurang': 4, 'Buruk': 5};
    for (final entry in cases.entries) {
      await tester.tap(find.text(entry.key));
      await tester.pump();
      expect(screeningFormNotifier.value.genHlth, entry.value, reason: entry.key);
    }
  });

  testWidgets('perilaku saat ini: nilai awal slider (3 dan 2 hari) ikut tersimpan walau slider belum disentuh',
      (tester) async {
    await pumpStep4(tester);

    await tester.tap(find.text('Baik'));
    await tester.pump();

    final form = screeningFormNotifier.value;
    expect(form.mentHlth, 3);
    expect(form.physHlth, 2);
  });

  testWidgets('menggeser slider mengubah label hari dan menyimpan nilainya', (tester) async {
    await pumpStep4(tester);

    await moveSlider(tester, 0, 10);
    await moveSlider(tester, 1, 25);

    expect(find.text('10 Hari'), findsOneWidget);
    expect(find.text('25 Hari'), findsOneWidget);
    expect(screeningFormNotifier.value.mentHlth, 10);
    expect(screeningFormNotifier.value.physHlth, 25);
  });

  testWidgets('Cek Risiko tanpa memilih kondisi umum menampilkan peringatan', (tester) async {
    await pumpStep4(tester);

    await tester.tap(find.text('Cek Risiko Saya'));
    await tester.pump();

    expect(find.text('Pilih kondisi kesehatan umum Anda terlebih dahulu.'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('Cek Risiko saat langkah sebelumnya belum lengkap menampilkan peringatan dan tidak pindah halaman',
      (tester) async {
    await pumpStep4(tester); 

    await tester.tap(find.text('Baik'));
    await tester.pump();
    await tester.tap(find.text('Cek Risiko Saya'));
    await tester.pump();

    expect(
      find.text('Mohon lengkapi seluruh langkah skrining sebelum melanjutkan.'),
      findsOneWidget,
    );
    expect(find.byType(ScreeningResultPage), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('nilai kesehatan umum di luar 1 sampai 5 diabaikan', (tester) async {
    updateScreeningForm((f) => f.copyWith(genHlth: 9));
    await pumpStep4(tester);

    await tester.tap(find.text('Cek Risiko Saya'));
    await tester.pump();

    expect(find.text('Pilih kondisi kesehatan umum Anda terlebih dahulu.'), findsOneWidget);
  });

  testWidgets('nilai tersimpan dimuat saat halaman dibuka', (tester) async {
    updateScreeningForm((f) => f.copyWith(genHlth: 4, mentHlth: 12, physHlth: 20));

    await pumpStep4(tester);

    expect(find.text('12 Hari'), findsOneWidget);
    expect(find.text('20 Hari'), findsOneWidget);
  });

  testWidgets('Kembali ke Langkah Sebelumnya menyimpan pilihan lalu menutup halaman', (tester) async {
    await openStep4FromHost(tester);

    await tester.tap(find.text('Cukup'));
    await tester.pump();
    await tester.tap(find.text('Kembali ke Langkah Sebelumnya'));
    await tester.pumpAndSettle();

    expect(find.byType(ScreeningStep4Page), findsNothing);
    expect(find.text('Buka'), findsOneWidget);
    expect(screeningFormNotifier.value.genHlth, 3);
  });
}