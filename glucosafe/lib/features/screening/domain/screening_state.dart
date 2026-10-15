import 'package:flutter/foundation.dart';
import 'screening_form.dart';

/// Isian pemeriksaan yang dipakai bersama langkah 1 sampai 4.
final ValueNotifier<ScreeningForm> screeningFormNotifier =
    ValueNotifier<ScreeningForm>(const ScreeningForm());

/// Contoh: updateScreeningForm((f) => f.copyWith(highBp: 1));
void updateScreeningForm(
    ScreeningForm Function(ScreeningForm current) change) {
  screeningFormNotifier.value = change(screeningFormNotifier.value);
}

/// Panggil saat pemeriksaan selesai atau dimulai dari awal.
void resetScreeningForm() {
  screeningFormNotifier.value = const ScreeningForm();
}