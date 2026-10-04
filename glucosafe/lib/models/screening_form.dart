// Data isian pemeriksaan GlucoSafe.
//
// Berisi 15 fitur model. Nama key dan urutan di toJson() sama persis dengan
// feature_columns.json dari Colab. Kode angka mengikuti dataset BRFSS 2015
// (Diabetes Health Indicators). Nilai null berarti belum diisi.

const Object _unset = Object();

class ScreeningForm {
  const ScreeningForm({
    this.sex,
    this.age,
    this.heightCm,
    this.weightKg,
    this.highBp,
    this.highChol,
    this.stroke,
    this.heartDiseaseOrAttack,
    this.diffWalk,
    this.smoker,
    this.physActivity,
    this.fruits,
    this.veggies,
    this.genHlth,
    this.mentHlth,
    this.physHlth,
  });

  // Langkah 1: Data Diri
  final int? sex; // 0 = perempuan, 1 = laki-laki
  final int? age; // kode usia 1..13 (lihat ageOptions)
  final double? heightCm;
  final double? weightKg;

  // Langkah 2: Riwayat kesehatan (1 = ya, 0 = tidak)
  final int? highBp;
  final int? highChol;
  final int? stroke;
  final int? heartDiseaseOrAttack;
  final int? diffWalk;

  // Langkah 3: Kebiasaan sehari-hari (1 = ya, 0 = tidak)
  final int? smoker;
  final int? physActivity;
  final int? fruits;
  final int? veggies;

  // Langkah 4: Kondisi umum
  final int? genHlth; // 1..5, urutan sama dengan dataset (1 = paling baik)
  final int? mentHlth; // 0..30 hari
  final int? physHlth; // 0..30 hari

  // Batas input agar BMI tetap masuk akal dan sesuai rentang data latih.
  static const double minHeightCm = 100;
  static const double maxHeightCm = 220;
  static const double minWeightKg = 30;
  static const double maxWeightKg = 250;

  bool get isHeightValid {
    final h = heightCm;
    return h != null && h >= minHeightCm && h <= maxHeightCm;
  }

  bool get isWeightValid {
    final w = weightKg;
    return w != null && w >= minWeightKg && w <= maxWeightKg;
  }

  /// BMI = berat (kg) dibagi tinggi (m) kuadrat. Null jika input belum valid.
  double? get bmi {
    final h = heightCm;
    final w = weightKg;
    if (!isHeightValid || !isWeightValid || h == null || w == null) return null;
    final meter = h / 100;
    return w / (meter * meter);
  }

  /// BMI dibulatkan 1 desimal (untuk tampilan dan dikirim ke API).
  double? get bmiRounded {
    final value = bmi;
    if (value == null) return null;
    return (value * 10).roundToDouble() / 10;
  }

  bool get isStep1Valid => sex != null && age != null && bmi != null;

  bool get isStep2Valid =>
      highBp != null &&
      highChol != null &&
      stroke != null &&
      heartDiseaseOrAttack != null &&
      diffWalk != null;

  bool get isStep3Valid =>
      smoker != null &&
      physActivity != null &&
      fruits != null &&
      veggies != null;

  bool get isStep4Valid =>
      genHlth != null && mentHlth != null && physHlth != null;

  bool get isComplete =>
      isStep1Valid && isStep2Valid && isStep3Valid && isStep4Valid;

  /// Parameter yang tidak diisi tetap memakai nilai lama.
  /// Isi dengan null secara eksplisit untuk mengosongkan sebuah nilai.
  ScreeningForm copyWith({
    Object? sex = _unset,
    Object? age = _unset,
    Object? heightCm = _unset,
    Object? weightKg = _unset,
    Object? highBp = _unset,
    Object? highChol = _unset,
    Object? stroke = _unset,
    Object? heartDiseaseOrAttack = _unset,
    Object? diffWalk = _unset,
    Object? smoker = _unset,
    Object? physActivity = _unset,
    Object? fruits = _unset,
    Object? veggies = _unset,
    Object? genHlth = _unset,
    Object? mentHlth = _unset,
    Object? physHlth = _unset,
  }) {
    return ScreeningForm(
      sex: identical(sex, _unset) ? this.sex : sex as int?,
      age: identical(age, _unset) ? this.age : age as int?,
      heightCm:
          identical(heightCm, _unset) ? this.heightCm : heightCm as double?,
      weightKg:
          identical(weightKg, _unset) ? this.weightKg : weightKg as double?,
      highBp: identical(highBp, _unset) ? this.highBp : highBp as int?,
      highChol: identical(highChol, _unset) ? this.highChol : highChol as int?,
      stroke: identical(stroke, _unset) ? this.stroke : stroke as int?,
      heartDiseaseOrAttack: identical(heartDiseaseOrAttack, _unset)
          ? this.heartDiseaseOrAttack
          : heartDiseaseOrAttack as int?,
      diffWalk: identical(diffWalk, _unset) ? this.diffWalk : diffWalk as int?,
      smoker: identical(smoker, _unset) ? this.smoker : smoker as int?,
      physActivity: identical(physActivity, _unset)
          ? this.physActivity
          : physActivity as int?,
      fruits: identical(fruits, _unset) ? this.fruits : fruits as int?,
      veggies: identical(veggies, _unset) ? this.veggies : veggies as int?,
      genHlth: identical(genHlth, _unset) ? this.genHlth : genHlth as int?,
      mentHlth: identical(mentHlth, _unset) ? this.mentHlth : mentHlth as int?,
      physHlth: identical(physHlth, _unset) ? this.physHlth : physHlth as int?,
    );
  }

  /// Body request untuk API prediksi. Hanya boleh dipanggil jika isComplete.
  Map<String, num> toJson() {
    if (!isComplete) {
      throw StateError('Isian pemeriksaan belum lengkap');
    }
    return {
      'HighBP': highBp!,
      'HighChol': highChol!,
      'BMI': bmiRounded!,
      'Smoker': smoker!,
      'Stroke': stroke!,
      'HeartDiseaseorAttack': heartDiseaseOrAttack!,
      'PhysActivity': physActivity!,
      'Fruits': fruits!,
      'Veggies': veggies!,
      'GenHlth': genHlth!,
      'MentHlth': mentHlth!,
      'PhysHlth': physHlth!,
      'DiffWalk': diffWalk!,
      'Sex': sex!,
      'Age': age!,
    };
  }
}