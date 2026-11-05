import 'recommendation_item.dart';

class ScreeningResult {
  final int id;
  final DateTime? createdAt;
  final double riskPercent;
  final String riskLabel;
  final double? bmi;
  final List<RecommendationItem> recommendations;

  const ScreeningResult({
    required this.id,
    this.createdAt,
    required this.riskPercent,
    required this.riskLabel,
    this.bmi,
    this.recommendations = const [],
  });

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
      riskPercent: (json['risk_percent'] as num?)?.toDouble() ?? 0.0,
      riskLabel: json['risk_label'] as String? ?? 'Rendah',
      bmi: (json['bmi'] as num?)?.toDouble(),
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

