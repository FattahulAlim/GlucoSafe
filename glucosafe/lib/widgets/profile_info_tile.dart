import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Item baris informasi profil yang reusable.
/// Menampilkan icon dalam kotak soft-rounded, label judul,
/// dan nilai / widget di sisi kanan (seperti jumlah pemeriksaan atau tanggal + badge status).
class ProfileInfoTile extends StatelessWidget {
  const ProfileInfoTile({
    super.key,
    required this.icon,
    required this.title,
    this.value,
    this.trailing,
    this.iconColor = AppColors.brand2,
    this.iconBgColor = const Color(0xFFEEF2FF),
    this.onTap,
  });

  /// Icon yang ditampilkan di sisi kiri
  final IconData icon;

  /// Judul / label item informasi (contoh: 'Jumlah pemeriksaan')
  final String title;

  /// Nilai teks sederhana di sisi kanan (contoh: '5 kali')
  final String? value;

  /// Widget kustom di sisi kanan (contoh: Column tanggal dan pill status)
  final Widget? trailing;

  /// Warna icon
  final Color iconColor;

  /// Warna latar belakang wadah icon
  final Color iconBgColor;

  /// Aksi ketika baris ditekan (opsional)
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      children: [
        // Wadah Icon
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconBgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 22,
            color: iconColor,
          ),
        ),
        const SizedBox(width: 14),

        // Label Judul
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              height: 20 / 14,
              fontWeight: FontWeight.w500,
              color: AppColors.slate,
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Nilai atau Widget Kanan
        trailing ??
            (value != null
                ? Text(
                    value!,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 22 / 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  )
                : const SizedBox.shrink()),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: content,
        ),
      );
    }

    return content;
  }
}
