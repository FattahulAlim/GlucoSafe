import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glucosafe/models/screening_state.dart';
import 'package:glucosafe/pages/screening_step1_page.dart';

void main() {
  setUp(resetScreeningForm);

  testWidgets('tombol Lanjut aktif setelah semua isian valid', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: ScreeningStep1Page()));

    ElevatedButton button() =>
        tester.widget<ElevatedButton>(find.byType(ElevatedButton));

    expect(button().onPressed, isNull);
    expect(find.textContaining('kg/m²'), findsNothing);

    await tester.tap(find.byType(DropdownButtonFormField<int>).at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Laki-laki').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<int>).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('18–24 tahun').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), '168');
    await tester.enterText(find.byType(TextField).at(1), '70');
    await tester.pump();

    expect(find.textContaining('24.8'), findsOneWidget);
    expect(button().onPressed, isNotNull);
  });
}