import 'package:flutter/material.dart';

/// Model data riwayat pemeriksaan berkala.
class HistoryRecord {
  final String percentage;
  final String status;
  final String date;
  final bool isLatest;
  final Color bgColor;
  final Color textColor;
  final IconData icon;

  const HistoryRecord({
    required this.percentage,
    required this.status,
    required this.date,
    this.isLatest = false,
    required this.bgColor,
    required this.textColor,
    required this.icon,
  });
}
