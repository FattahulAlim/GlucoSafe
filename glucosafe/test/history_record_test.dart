import 'package:flutter_test/flutter_test.dart';
import 'package:glucosafe/features/history/domain/history_record.dart';

void main() {
  test('maps history fields and formats the Indonesian date', () {
    final record = HistoryRecord.fromJson({
      'id': 42,
      'created_at': '2026-11-09 08:50:00',
      'risk_percentage': '62.50',
      'risk_level': 'Sedang',
      'bmi': '24.8',
    }, isLatest: true);

    expect(record.id, 42);
    expect(record.percentage, '62.5%');
    expect(record.status, 'Berisiko Sedang');
    expect(record.date, '9 Nov 2026');
    expect(record.bmi, 24.8);
    expect(record.isLatest, isTrue);
  });

  test('rejects invalid risk levels and percentages', () {
    final json = {
      'id': 1,
      'created_at': '2026-11-09 08:50:00',
      'risk_percentage': '120',
      'risk_level': 'Tinggi',
      'bmi': null,
    };

    expect(
      () => HistoryRecord.fromJson(json, isLatest: false),
      throwsFormatException,
    );
    expect(
      () => HistoryRecord.fromJson(
        {...json, 'risk_percentage': '40', 'risk_level': 'Tidak Dikenal'},
        isLatest: false,
      ),
      throwsFormatException,
    );
  });
}
