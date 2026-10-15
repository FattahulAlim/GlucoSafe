// Pilihan dropdown dan fungsi bantu untuk halaman pemeriksaan.
// Kode angka mengikuti dataset BRFSS 2015 (Diabetes Health Indicators).

class Option<T> {
  const Option(this.value, this.label);
  final T value;
  final String label;
}

/// Sex pada dataset: 0 = perempuan, 1 = laki-laki.
const List<Option<int>> sexOptions = [
  Option(1, 'Laki-laki'),
  Option(0, 'Perempuan'),
];

/// Age pada dataset: 13 kategori usia lima tahunan (kode 1 sampai 13).
const List<Option<int>> ageOptions = [
  Option(1, '18–24 tahun'),
  Option(2, '25–29 tahun'),
  Option(3, '30–34 tahun'),
  Option(4, '35–39 tahun'),
  Option(5, '40–44 tahun'),
  Option(6, '45–49 tahun'),
  Option(7, '50–54 tahun'),
  Option(8, '55–59 tahun'),
  Option(9, '60–64 tahun'),
  Option(10, '65–69 tahun'),
  Option(11, '70–74 tahun'),
  Option(12, '75–79 tahun'),
  Option(13, '80 tahun atau lebih'),
];

enum BmiCategory {
  kurang('Kurang'),
  normal('Normal'),
  berlebih('Berlebih'),
  obesitas('Obesitas');

  const BmiCategory(this.label);
  final String label;
}

/// Kategori BMI standar WHO. Hanya untuk tampilan; model menerima angka BMI.
BmiCategory bmiCategoryOf(double bmi) {
  if (bmi < 18.5) return BmiCategory.kurang;
  if (bmi < 25) return BmiCategory.normal;
  if (bmi < 30) return BmiCategory.berlebih;
  return BmiCategory.obesitas;
}

/// Menerima "70,5" (koma) maupun "70.5" (titik). Null jika kosong atau tidak valid.
double? parseLocalizedDouble(String text) {
  final cleaned = text.trim().replaceAll(',', '.');
  if (cleaned.isEmpty) return null;
  return double.tryParse(cleaned);
}

/// 168.0 menjadi "168", 70.5 menjadi "70.5". Null menjadi teks kosong.
String formatNumber(double? value) {
  if (value == null) return '';
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString();
}