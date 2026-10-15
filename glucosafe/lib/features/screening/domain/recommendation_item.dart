import 'package:flutter/material.dart';

/// Model data item rekomendasi pada halaman hasil skrining.
class RecommendationItem {
  final String title;
  final String category;
  final String description;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  const RecommendationItem({
    required this.title,
    required this.category,
    required this.description,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });
}
