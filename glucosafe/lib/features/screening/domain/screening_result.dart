import 'recommendation_item.dart';

class ScreeningResult {
  final int id;
  final DateTime? createdAt;
  final double riskPercent;
  final String riskLabel;
  final double? bmi;
  final double? heightCm;
  final double? weightKg;
  final List<RecommendationItem> recommendations;

  const ScreeningResult({
    required this.id,
    this.createdAt,
    required this.riskPercent,
    required this.riskLabel,
    this.bmi,
    this.heightCm,
    this.weightKg,
    this.recommendations = const [],
  });

  /// MySQL sering mengirim kolom DECIMAL sebagai teks ("28.00"),
  /// jadi terima angka maupun teks.
  static double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  factory ScreeningResult.fromJson(Map<String, dynamic> json) {
    final rawRecs = json['recommendations'];
    List<RecommendationItem> recList = [];
    if (rawRecs is List) {
      recList = rawRecs
          .map((item) => RecommendationItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return ScreeningResult(
      id: json['id'] is num ? (json['id'] as num).toInt() : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      riskPercent: _toDouble(json['risk_percent']) ?? 0.0,
      riskLabel: json['risk_label'] as String? ?? 'Rendah',
      bmi: _toDouble(json['bmi']),
      heightCm: _toDouble(json['height_cm']),
      weightKg: _toDouble(json['weight_kg']),
      recommendations: recList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt?.toIso8601String(),
      'risk_percent': riskPercent,
      'risk_label': riskLabel,
      'bmi': bmi,
      'recommendations': recommendations.map((r) => r.toJson()).toList(),
    };
  }
}