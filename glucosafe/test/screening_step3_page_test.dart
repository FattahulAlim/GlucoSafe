import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glucosafe/features/screening/domain/screening_state.dart';
import 'package:glucosafe/features/screening/presentation/pages/screening_step_3_page.dart';
import 'package:glucosafe/features/screening/presentation/pages/screening_step_4_page.dart';

void main() {
  setUp(resetScreeningForm);

  void useTallScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Future<void> pumpStep3(WidgetTester tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(const MaterialApp(home: ScreeningStep3Page()));
  }

  Future<void> openStep3FromHost(WidgetTester tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ScreeningStep3Page()),
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

  ElevatedButton button(WidgetTester tester, String label) =>
      tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, label));

  testWidgets('menampilkan judul, indikator langkah, dan empat pertanyaan', (tester) async {
    await pumpStep3(tester);

    expect(find.text('Pola Gaya Hidup'), findsOneWidget);
    expect(find.text('LANGKAH 3 DARI 4'), findsOneWidget);
    expect(find.text('75% Selesai'), findsOneWidget);
    expect(find.text('Tidak'), findsNWidgets(4));
    expect(find.text('Ya'), findsNWidgets(4));
  });

  testWidgets('Lanjut baru aktif setelah keempat pertanyaan dijawab dan jawaban tersimpan',
      (tester) async {
    await pumpStep3(tester);
    expect(button(tester, 'Lanjut').onPressed, isNull);

    await tester.tap(find.text('Tidak').at(0)); // merokok
    await tester.pump();
    await tester.tap(find.text('Ya').at(1)); // olahraga
    await tester.pump();
    await tester.tap(find.text('Ya').at(2)); // buah
    await tester.pump();
    expect(button(tester, 'Lanjut').onPressed, isNull);

    await tester.tap(find.text('Tidak').at(3)); // sayur
    await tester.pump();
    expect(button(tester, 'Lanjut').onPressed, isNotNull);

    final form = screeningFormNotifier.value;
    expect([form.smoker, form.physActivity, form.fruits, form.veggies], [0, 1, 1, 0]);
  });

  testWidgets('mengubah jawaban menimpa jawaban sebelumnya', (tester) async {
    await pumpStep3(tester);

    await tester.tap(find.text('Ya').at(0));
    await tester.pump();
    expect(screeningFormNotifier.value.smoker, 1);

    await tester.tap(find.text('Tidak').at(0));
    await tester.pump();
    expect(screeningFormNotifier.value.smoker, 0);
  });

  testWidgets('jawaban yang sudah tersimpan dimuat saat halaman dibuka', (tester) async {
    updateScreeningForm(
      (f) => f.copyWith(smoker: 1, physActivity: 0, fruits: 1, veggies: 1),
    );

    await pumpStep3(tester);

    expect(button(tester, 'Lanjut').onPressed, isNotNull);
    final form = screeningFormNotifier.value;
    expect([form.smoker, form.physActivity, form.fruits, form.veggies], [1, 0, 1, 1]);
  });

  testWidgets('Lanjut membuka langkah 4', (tester) async {
    await pumpStep3(tester);

    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text('Ya').at(i));
      await tester.pump();
    }
    await tester.tap(find.widgetWithText(ElevatedButton, 'Lanjut'));
    await tester.pumpAndSettle();

    expect(find.byType(ScreeningStep4Page), findsOneWidget);
    expect(find.text('LANGKAH 4 DARI 4'), findsOneWidget);
  });

  testWidgets('tombol Kembali menyimpan jawaban lalu menutup halaman', (tester) async {
    await openStep3FromHost(tester);

    await tester.tap(find.text('Ya').at(0));
    await tester.pump();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Kembali'));
    await tester.pumpAndSettle();

    expect(find.byType(ScreeningStep3Page), findsNothing);
    expect(find.text('Buka'), findsOneWidget);
    expect(screeningFormNotifier.value.smoker, 1);
  });

  testWidgets('panah kembali di bagian atas juga menyimpan jawaban lalu menutup halaman',
      (tester) async {
    await openStep3FromHost(tester);

    await tester.tap(find.text('Tidak').at(1));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.byType(ScreeningStep3Page), findsNothing);
    expect(screeningFormNotifier.value.physActivity, 0);
  });
}