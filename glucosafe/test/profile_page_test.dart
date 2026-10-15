import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glucosafe/features/profile/presentation/pages/profile_page.dart';

void main() {
  testWidgets('Menampilkan komponen dan informasi profil pengguna dengan lengkap', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ProfilePage(),
      ),
    );

    // Verifikasi header
    expect(find.text('Profil'), findsOneWidget);

    // Verifikasi data pengguna
    expect(find.text('Rahmawati'), findsOneWidget);
    expect(find.text('rahmawati.santoso@email.com'), findsOneWidget);
    expect(find.text('RW'), findsOneWidget);

    // Verifikasi ringkasan pemeriksaan
    expect(find.text('Jumlah pemeriksaan'), findsOneWidget);
    expect(find.text('5 kali'), findsOneWidget);
    expect(find.text('Pemeriksaan terakhir'), findsOneWidget);
    expect(find.text('14 Okt 2023'), findsOneWidget);
    expect(find.text('Tidak Berisiko'), findsOneWidget);

    // Verifikasi tombol aksi
    expect(find.text('Edit Profil'), findsOneWidget);
    expect(find.text('Keluar dari Akun'), findsOneWidget);
  });

  testWidgets('Mengarahkan ke halaman Edit Profil saat tombol Edit Profil ditekan', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ProfilePage(),
      ),
    );

    // Tekan tombol Edit Profil
    await tester.tap(find.text('Edit Profil'));
    await tester.pumpAndSettle();

    // Pastikan halaman Edit Profil terbuka
    expect(find.text('Nama Lengkap'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Ketuk kamera untuk mengubah foto'), findsOneWidget);
    expect(find.text('Simpan Perubahan'), findsOneWidget);
    expect(find.text('Batal'), findsOneWidget);
  });

  testWidgets('Menampilkan pop up konfirmasi keluar di tengah dengan efek blur saat tombol Keluar dari Akun ditekan', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ProfilePage(),
      ),
    );

    // Tekan tombol Keluar dari Akun
    await tester.tap(find.text('Keluar dari Akun'));
    await tester.pumpAndSettle();

    // Pastikan efek BackdropFilter untuk blur ada
    expect(find.byType(BackdropFilter), findsOneWidget);

    // Pastikan dialog konfirmasi keluar sesuai desain muncul
    expect(
      find.text('Keluar dari akun?'),
      findsOneWidget,
    );
    expect(
      find.text('Anda perlu masuk lagi untuk melihat hasil pemeriksaan Anda.'),
      findsOneWidget,
    );
    expect(find.text('Keluar'), findsOneWidget);
    expect(find.text('Batal'), findsOneWidget);
  });
}
