import 'package:flutter_test/flutter_test.dart';
import 'package:glucosafe/models/screening_form.dart';
import 'package:glucosafe/models/screening_options.dart';

ScreeningForm _complete() => const ScreeningForm(
      sex: 1,
      age: 6,
      heightCm: 168,
      weightKg: 70,
      highBp: 0,
      highChol: 0,
      stroke: 0,
      heartDiseaseOrAttack: 0,
      diffWalk: 0,
      smoker: 0,
      physActivity: 1,
      fruits: 1,
      veggies: 1,
      genHlth: 2,
      mentHlth: 3,
      physHlth: 2,
    );

void main() {
  test('BMI 168 cm dan 70 kg bernilai 24.8', () {
    const form = ScreeningForm(heightCm: 168, weightKg: 70);
    expect(form.bmiRounded, closeTo(24.8, 0.001));
  });

  test('BMI null jika tinggi atau berat di luar batas atau kosong', () {
    expect(const ScreeningForm(heightCm: 50, weightKg: 70).bmi, isNull);
    expect(const ScreeningForm(heightCm: 168, weightKg: 400).bmi, isNull);
    expect(const ScreeningForm(heightCm: 168).bmi, isNull);
    expect(const ScreeningForm().bmi, isNull);
  });

  test('kategori BMI pada nilai batas', () {
    expect(bmiCategoryOf(18.4), BmiCategory.kurang);
    expect(bmiCategoryOf(18.5), BmiCategory.normal);
    expect(bmiCategoryOf(24.9), BmiCategory.normal);
    expect(bmiCategoryOf(25), BmiCategory.berlebih);
    expect(bmiCategoryOf(29.9), BmiCategory.berlebih);
    expect(bmiCategoryOf(30), BmiCategory.obesitas);
  });

  test('langkah 1 valid hanya jika semua terisi dan BMI valid', () {
    expect(const ScreeningForm().isStep1Valid, isFalse);
    expect(
      const ScreeningForm(sex: 1, age: 6, heightCm: 168).isStep1Valid,
      isFalse,
    );
    expect(
      const ScreeningForm(sex: 1, age: 6, heightCm: 168, weightKg: 70)
          .isStep1Valid,
      isTrue,
    );
  });

  test('opsi usia: 13 kode berurutan sesuai dataset', () {
    expect(ageOptions.length, 13);
    expect(ageOptions.map((o) => o.value).toList(),
        [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13]);
    expect(ageOptions.first.label, '18–24 tahun');
    expect(ageOptions[5].label, '45–49 tahun'); // kode 6
    expect(ageOptions.last.label, '80 tahun atau lebih');
  });

  test('opsi jenis kelamin: laki-laki 1, perempuan 0', () {
    expect(sexOptions.firstWhere((o) => o.label == 'Laki-laki').value, 1);
    expect(sexOptions.firstWhere((o) => o.label == 'Perempuan').value, 0);
  });

  test('parseLocalizedDouble menerima koma dan titik', () {
    expect(parseLocalizedDouble('70,5'), 70.5);
    expect(parseLocalizedDouble('70.5'), 70.5);
    expect(parseLocalizedDouble(''), isNull);
    expect(parseLocalizedDouble('abc'), isNull);
  });

  test('toJson memakai 15 key dengan urutan feature_columns', () {
    final json = _complete().toJson();
    expect(json.keys.toList(), [
      'HighBP',
      'HighChol',
      'BMI',
      'Smoker',
      'Stroke',
      'HeartDiseaseorAttack',
      'PhysActivity',
      'Fruits',
      'Veggies',
      'GenHlth',
      'MentHlth',
      'PhysHlth',
      'DiffWalk',
      'Sex',
      'Age',
    ]);
    expect(json['BMI'], closeTo(24.8, 0.001));
    expect(json['Age'], 6);
    expect(json['Sex'], 1);
  });

  test('toJson melempar error jika isian belum lengkap', () {
    expect(() => const ScreeningForm(sex: 1).toJson(), throwsStateError);
  });

  test('copyWith: tidak diisi = tetap, null = dikosongkan', () {
    final form = _complete();
    expect(form.copyWith(age: 7).age, 7);
    expect(form.copyWith(age: 7).sex, 1);
    expect(form.copyWith(heightCm: null).heightCm, isNull);
  });
}