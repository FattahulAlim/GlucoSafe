import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Widget Avatar Profil yang reusable.
/// Mendukung inisial teks (seperti 'RW'), background kustom,
/// badge verifikasi di pojok kanan bawah, serta fallback gambar.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    this.initials = 'RW',
    this.photoAsset,
    this.size = 88.0,
    this.fontSize,
    this.backgroundColor = const Color(0xFF7DE6CE),
    this.textColor = const Color(0xFF00534C),
    this.showVerifiedBadge = false,
    this.showCameraBadge = false,
    this.badgeIcon,
    this.badgeColor = AppColors.brand,
    this.onBadgeTap,
  });

  /// Inisial nama pengguna (misal: 'RW')
  final String initials;

  /// Path asset foto pengguna jika tersedia (opsional)
  final String? photoAsset;

  /// Diameter lingkaran avatar
  final double size;

  /// Ukuran font untuk inisial (otomatis disesuaikan jika null)
  final double? fontSize;

  /// Warna latar lingkaran avatar
  final Color backgroundColor;

  /// Warna teks inisial
  final Color textColor;

  /// Apakah menampilkan badge terverifikasi (centang hijau) di pojok bawah
  final bool showVerifiedBadge;

  /// Apakah menampilkan badge kamera di pojok bawah
  final bool showCameraBadge;

  /// Icon badge kustom (opsional)
  final IconData? badgeIcon;

  /// Warna latar badge verifikasi
  final Color badgeColor;

  /// Aksi ketika badge ditekan (opsional)
  final VoidCallback? onBadgeTap;

  @override
  Widget build(BuildContext context) {
    final effectiveFontSize = fontSize ?? (size * 0.34);
    final badgeSize = (size * 0.3).clamp(18.0, 28.0);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Lingkaran Avatar Utama
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: photoAsset != null && photoAsset!.isNotEmpty
                ? ClipOval(
                    child: Image.asset(
                      photoAsset!,
                      width: size,
                      height: size,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildInitials(effectiveFontSize),
                    ),
                  )
                : _buildInitials(effectiveFontSize),
          ),

          // Badge Pojok Kanan Bawah (Verifikasi atau Kamera)
          if (showVerifiedBadge || showCameraBadge || badgeIcon != null)
            Positioned(
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: onBadgeTap,
                child: Container(
                  width: badgeSize,
                  height: badgeSize,
                  decoration: BoxDecoration(
                    color: badgeColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: badgeSize > 22 ? 2.5 : 2.0,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1F000000),
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    badgeIcon ??
                        (showCameraBadge
                            ? Icons.camera_alt_outlined
                            : Icons.check_rounded),
                    size: badgeSize * 0.62,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInitials(double textFontSize) {
    return Text(
      initials,
      style: TextStyle(
        fontSize: textFontSize,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: 0.5,
        height: 1.0,
      ),
    );
  }
}
