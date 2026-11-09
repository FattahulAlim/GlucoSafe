import '../../screening/domain/risk_level.dart';
import '../../screening/domain/screening_options.dart';
import '../../screening/domain/screening_result.dart';

const List<String> _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

/// Ringkasan Beranda, dihitung dari daftar riwayat skrining pengguna.
class HomeSummary {
  const HomeSummary({
    required this.lastPercent,
    required this.lastDate,
    required this.infoLabel,
    required this.infoValue,
    required this.infoNote,
    required this.trendValues,
    required this.trendLabels,
  });

  final double lastPercent;
  final String lastDate;

  /// Baris info di bawah cincin: "`<infoLabel><infoValue> (<infoNote>)`".
  final String infoLabel;
  final String infoValue;
  final String infoNote;

  /// Persentase dari yang paling lama ke yang paling baru (maksimal 5).
  final List<double> trendValues;
  final List<String> trendLabels;

  Risk get risk => riskOf(lastPercent);

  /// Null jika belum ada riwayat.
  static HomeSummary? fromHistory(
    List<ScreeningResult> records, {
    int trendCount = 5,
  }) {
    if (records.isEmpty) return null;

    final sorted = [...records]..sort(_newestFirst);
    final latest = sorted.first;

    // Ambil beberapa terbaru, lalu balik agar urutannya lama ke baru.
    final recent = sorted.take(trendCount).toList().reversed.toList();
    final dates = [for (final r in recent) r.createdAt?.toLocal()];

    final months = [
      for (final d in dates) d == null ? '-' : _monthNames[d.month - 1],
    ];
    // Jika ada bulan yang sama, pakai "tanggal bulan" agar label tidak kembar.
    final hasDuplicate = months.toSet().length != months.length;

    String label(DateTime? d) {
      if (d == null) return '-';
      final month = _monthNames[d.month - 1];
      return hasDuplicate ? '${d.day} $month' : month;
    }

    String infoLabel;
    String infoValue;
    String infoNote;
    final bmi = latest.bmi;
    if (bmi == null) {
      infoLabel = 'BMI terakhir: ';
      infoValue = '-';
      infoNote = 'belum tersedia';
    } else {
      final category = bmiCategoryOf(bmi).label;
      final height = latest.heightCm;
      if (height != null && height > 0) {
        final m2 = (height / 100) * (height / 100);
        final low = (18.5 * m2).round();
        final high = (24.9 * m2).round();
        infoLabel = 'Berat badan ideal: ';
        infoValue = '$low–$high kg';
        infoNote = 'BMI ${bmi.toStringAsFixed(1)} • $category';
      } else {
        infoLabel = 'BMI terakhir: ';
        infoValue = bmi.toStringAsFixed(1);
        infoNote = category;
      }
    }

    return HomeSummary(
      lastPercent: latest.riskPercent,
      lastDate: _formatDate(latest.createdAt?.toLocal()),
      infoLabel: infoLabel,
      infoValue: infoValue,
      infoNote: infoNote,
      trendValues: [for (final r in recent) r.riskPercent],
      trendLabels: [for (final d in dates) label(d)],
    );
  }

  static String _formatDate(DateTime? d) {
    if (d == null) return '-';
    return '${d.day} ${_monthNames[d.month - 1]} ${d.year}';
  }

  /// Paling baru dulu. Rekaman tanpa tanggal dianggap paling lama.
  static int _newestFirst(ScreeningResult a, ScreeningResult b) {
    final da = a.createdAt;
    final db = b.createdAt;
    if (da != null && db != null) {
      final c = db.compareTo(da);
      if (c != 0) return c;
    } else if (da != null) {
      return -1;
    } else if (db != null) {
      return 1;
    }
    return b.id.compareTo(a.id);
  }
}