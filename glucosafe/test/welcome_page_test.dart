import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glucosafe/features/auth/presentation/pages/login_page.dart';
import 'package:glucosafe/features/auth/presentation/pages/register_page.dart';
import 'package:glucosafe/features/auth/presentation/pages/welcome_page.dart';

void main() {
  Future<void> pumpWelcome(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: WelcomePage()));
  }

  testWidgets('menampilkan sapaan, contoh hasil, dan dua tombol',
      (tester) async {
    await pumpWelcome(tester);

    expect(find.text('Selamat Datang di'), findsOneWidget);
    expect(find.text('GlucoSafe'), findsOneWidget);
    expect(find.text('28%'), findsOneWidget);
    expect(find.text('Tidak Berisiko'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
    expect(find.text('Daftar'), findsOneWidget);
  });

  testWidgets('tombol Masuk membuka halaman Login', (tester) async {
    await pumpWelcome(tester);

    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('tombol Daftar membuka halaman Daftar', (tester) async {
    await pumpWelcome(tester);

    await tester.tap(find.text('Daftar'));
    await tester.pumpAndSettle();

    expect(find.byType(RegisterPage), findsOneWidget);
  });
}