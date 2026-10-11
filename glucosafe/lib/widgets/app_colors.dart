import 'package:flutter/material.dart';

/// Palet warna utama aplikasi GlucoSafe (berdasarkan Figma design system).
class AppColors {
  // Warna Latar & Teks Utama
  static const bg = Color(0xFFF0FDFA);
  static const formBg = Color(0xFFFAF8FF);
  static const ink = Color(0xFF131B2E);
  static const mute = Color(0xFF3D4947);
  static const slate = Color(0xFF475569);
  static const hint = Color(0xFF6D7A77);
  static const border = Color(0xFFE2E8F0);
  static const track = Color(0xFFE2E8F0);
  static const trackLight = Color(0xFFCCFBF1);
  static const disabled = Color(0xFFCBD5E1);

  // Brand / Aksen Teal
  static const brand = Color(0xFF00685F);
  static const brand2 = Color(0xFF0D9488);
  static const brandDark = Color(0xFF00534C);

  // Status & Indikator: Hijau (Aman / Risiko Rendah)
  static const ok = Color(0xFF16A34A);
  static const okBg = Color(0xFFDCFCE7);
  static const okBorder = Color(0xFFCCFBF1);
  static const greenText = Color(0xFF047857);
  static const greenBg = Color(0xFFD1FAE5);
  static const greenCircle = Color(0xFF16A34A);

  // Status & Indikator: Kuning / Oranye (Risiko Sedang / Warning)
  static const mid = Color(0xFFF59E0B);
  static const midText = Color(0xFFD97706);
  static const midBg = Color(0xFFFEF3C7);
  static const midInk = Color(0xFFB45309);
  static const yellowBg = Color(0xFFFEF3C7);
  static const yellowText = Color(0xFF92400E);
  static const warn = Color(0xFFEA580C);
  static const warnBg = Color(0xFFFFEDD5);
  static const warnBorder = Color(0xFFFED7AA);

  // Status & Indikator: Merah (Risiko Tinggi / Error)
  static const hi = Color(0xFFDC2626);
  static const hiBg = Color(0xFFFEE2E2);
  static const redBg = Color(0xFFFEE2E2);
  static const redText = Color(0xFFDC2626);
  static const error = Color(0xFFDC2626);

  // Alert Box (Orange/Peach)
  static const alertBg = Color(0xFFFFF7ED);
  static const alertBorder = Color(0xFFFED7AA);
  static const alertText = Color(0xFFC2410C);

  // Pill, Card, & Elemen Form
  static const cardBg = Colors.white;
  static const pillLav = Color(0xFFEAEDFF);
  static const pillBg = Color(0xFFF1F5F9);
  static const lightPill = Color(0xFFE0F5F2);
  static const infoBg = Color(0xFFF2F3FF);
  static const inactiveBg = Color(0xFFEEF0FA);
  static const progressBg = Color(0xFFE0DDF8);
  static const toggleBg = Color(0xFFEEF0FB);
  static const chevronBg = Color(0xFFEEF2FF);
  static const chevronIcon = Color(0xFF475569);

  // Tips & Rekomendasi
  static const tipBg = Color(0xFFE0F2FE);
  static const tipTitle = Color(0xFF0369A1);
  static const tipDot = Color(0xFF0284C7);
  static const tipBody = Color(0xFF0C4A6E);

  // Kategori Rekomendasi
  static const nutrisiBg = Color(0xFFD1FAE5);
  static const nutrisiIcon = Color(0xFF047857);
  static const fisikBg = Color(0xFFE0F2FE);
  static const fisikIcon = Color(0xFF0284C7);
  static const periksaBg = Color(0xFFF3E8FF);
  static const periksaIcon = Color(0xFF7E22CE);
}

/// Alias kompatibilitas
typedef HistoryColors = AppColors;
typedef ScreeningColors = AppColors;
typedef ResultColors = AppColors;
