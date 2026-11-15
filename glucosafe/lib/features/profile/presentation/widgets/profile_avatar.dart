import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/config/api_config.dart'; 

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    this.initials = 'RW',
    this.photoAsset,
    this.photoUrl,
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

  final String initials;
  final String? photoAsset;
  final String? photoUrl; 
  final double size;
  final double? fontSize;
  final Color backgroundColor;
  final Color textColor;
  final bool showVerifiedBadge;
  final bool showCameraBadge;
  final IconData? badgeIcon;
  final Color badgeColor;
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
            child: _buildAvatarContent(effectiveFontSize),
          ),

          // Badge Pojok Kanan Bawah
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
                    badgeIcon ?? (showCameraBadge ? Icons.camera_alt_outlined : Icons.check_rounded),
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

  Widget _buildAvatarContent(double textFontSize) {
    // Prioritas 1: Foto dari internet (server backend)
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      final fullUrl = photoUrl!.startsWith('http') 
          ? photoUrl! 
          : '${ApiConfig.baseUrl}$photoUrl'; // Gabungkan dengan baseUrl jika relatif

      return ClipOval(
        child: Image.network(
          fullUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildInitials(textFontSize),
        ),
      );
    }
    
    // Prioritas 2: Foto dari asset lokal (jika ada)
    if (photoAsset != null && photoAsset!.isNotEmpty) {
      return ClipOval(
        child: Image.asset(
          photoAsset!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildInitials(textFontSize),
        ),
      );
    }

    // Prioritas 3: Inisial (cadangan)
    return _buildInitials(textFontSize);
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