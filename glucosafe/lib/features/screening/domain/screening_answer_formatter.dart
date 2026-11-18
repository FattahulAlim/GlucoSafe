import 'screening_options.dart';

const Map<String, String> _answerLabels = {
  'sex': 'Jenis kelamin',
  'age': 'Rentang usia',
  'height_cm': 'Tinggi badan',
  'weight_kg': 'Berat badan',
  'bmi': 'Indeks Massa Tubuh (BMI)',
  'high_bp': 'Pernah didiagnosis tekanan darah tinggi',
  'high_chol': 'Pernah didiagnosis kolesterol tinggi',
  'stroke': 'Pernah terkena stroke',
  'heart_disease': 'Penyakit jantung atau serangan jantung',
  'diff_walk': 'Kesulitan berjalan atau naik tangga',
  'smoker': 'Pernah merokok minimal 100 batang seumur hidup',
  'phys_activity': 'Aktif berolahraga dalam 30 hari terakhir',
  'fruits': 'Konsumsi buah minimal 1 kali sehari',
  'veggies': 'Konsumsi sayur minimal 1 kali sehari',
  'gen_hlth': 'Penilaian kesehatan secara umum',
  'ment_hlth': 'Jumlah hari kesehatan mental kurang baik',
  'phys_hlth': 'Jumlah hari kesehatan fisik kurang baik',
};

const Set<String> _yesNoFields = {
  'high_bp',
  'high_chol',
  'stroke',
  'heart_disease',
  'diff_walk',
  'smoker',
  'phys_activity',
  'fruits',
  'veggies',
};

String screeningAnswerLabel(String key) {
  final knownLabel = _answerLabels[key];
  if (knownLabel != null) return knownLabel;

  final spaced = key
      .replaceAll('_', ' ')
      .replaceAllMapped(
        RegExp(r'([a-z])([A-Z])'),
        (match) => '${match[1]} ${match[2]}',
      );
  return spaced
      .split(' ')
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
}

String formatScreeningAnswer(String key, dynamic value) {
  if (value == null) return 'Tidak tersedia';

  final number = value is num ? value.toInt() : int.tryParse('$value');
  if (key == 'sex' && number != null) {
    return switch (number) {
      0 => 'Perempuan',
      1 => 'Laki-laki',
      _ => 'Data tidak dikenali',
    };
  }
  if (key == 'age' && number != null) {
    for (final option in ageOptions) {
      if (option.value == number) return option.label;
    }
    return 'Kategori usia tidak dikenali';
  }
  if (_yesNoFields.contains(key) && number != null) {
    return switch (number) {
      0 => 'Tidak',
      1 => 'Ya',
      _ => 'Data tidak dikenali',
    };
  }
  if (key == 'gen_hlth' && number != null) {
    return switch (number) {
      1 => 'Sangat baik',
      2 => 'Baik',
      3 => 'Cukup',
      4 => 'Kurang',
      5 => 'Buruk',
      _ => 'Data tidak dikenali',
    };
  }
  if ((key == 'ment_hlth' || key == 'phys_hlth') && number != null) {
    return '$number hari dari 30 hari terakhir';
  }
  if ((key == 'height_cm' || key == 'weight_kg') && value is num) {
    final unit = key == 'height_cm' ? 'cm' : 'kg';
    return '${_formatNumber(value)} $unit';
  }
  if (value is num) {
    return _formatNumber(value);
  }
  return value.toString();
}

String _formatNumber(num value) {
  final number = value.toDouble();
  return number == number.roundToDouble()
      ? number.toInt().toString()
      : number.toString();
}
