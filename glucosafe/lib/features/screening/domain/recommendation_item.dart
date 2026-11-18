import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

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

  factory RecommendationItem.fromJson(Map<String, dynamic> json) {
    final category = json['category'] as String? ?? 'Umum';
    final title = json['title'] as String? ?? '';
    final description = json['description'] as String? ?? '';

    IconData icon;
    Color iconBg;
    Color iconColor;

    switch (category.toLowerCase()) {
      case 'nutrisi':
        icon = Icons.restaurant_rounded;
        iconBg = AppColors.nutrisiBg;
        iconColor = AppColors.nutrisiIcon;
        break;
      case 'aktivitas fisik':
        icon = Icons.fitness_center_rounded;
        iconBg = AppColors.fisikBg;
        iconColor = AppColors.fisikIcon;
        break;
      case 'pemeriksaan':
        icon = Icons.calendar_month_rounded;
        iconBg = AppColors.periksaBg;
        iconColor = AppColors.periksaIcon;
        break;
      case 'gaya hidup':
        icon = Icons.smoke_free_rounded;
        iconBg = AppColors.warnBg;
        iconColor = AppColors.warn;
        break;
      case 'kesehatan':
        icon = Icons.monitor_heart_rounded;
        iconBg = AppColors.lightPill;
        iconColor = AppColors.brand;
        break;
      default:
        icon = Icons.health_and_safety_rounded;
        iconBg = AppColors.infoBg;
        iconColor = AppColors.brand;
    }

    return RecommendationItem(
      title: title,
      category: category,
      description: description,
      icon: icon,
      iconBg: iconBg,
      iconColor: iconColor,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'category': category,
      'description': description,
    };
  }
}
