import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glucosafe/models/screening_state.dart';
import 'package:glucosafe/pages/screening_step2_page.dart';

void main() {
  setUp(resetScreeningForm);

  testWidgets('Lanjut aktif setelah kelima pertanyaan dijawab', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: ScreeningStep2Page()));

    ElevatedButton lanjut() => tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Lanjut'),
        );

    // Awal: belum ada jawaban, tombol nonaktif.
    expect(lanjut().onPressed, isNull);

    // Jawab empat pertanyaan pertama dengan "Tidak": masih nonaktif.
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text('Tidak').at(i));
      await tester.pump();
    }
    expect(lanjut().onPressed, isNull);

    // Jawab pertanyaan kelima dengan "Ya": tombol aktif.
    await tester.tap(find.text('Ya').at(4));
    await tester.pump();
    expect(lanjut().onPressed, isNotNull);

    final form = screeningFormNotifier.value;
    expect(
      [
        form.highBp,
        form.highChol,
        form.stroke,
        form.heartDiseaseOrAttack,
        form.diffWalk,
      ],
      [0, 0, 0, 0, 1],
    );
  });
}