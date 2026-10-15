import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

enum ProfileActionButtonType {
  outline,
  destructive,
}

/// Widget tombol aksi pada profil (seperti 'Edit Profil' dan 'Keluar dari Akun').
class ProfileActionButton extends StatelessWidget {
  const ProfileActionButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onPressed,
    this.type = ProfileActionButtonType.outline,
    this.height = 50.0,
    this.borderRadius = 14.0,
  });

  /// Tombol dengan border aksen teal (misal: 'Edit Profil')
  const ProfileActionButton.outline({
    super.key,
    required this.text,
    required this.icon,
    required this.onPressed,
    this.height = 50.0,
    this.borderRadius = 14.0,
  }) : type = ProfileActionButtonType.outline;

  /// Tombol berwarna merah lembut untuk aksi destruktif (misal: 'Keluar dari Akun')
  const ProfileActionButton.destructive({
    super.key,
    required this.text,
    required this.icon,
    required this.onPressed,
    this.height = 50.0,
    this.borderRadius = 14.0,
  }) : type = ProfileActionButtonType.destructive;

  final String text;
  final IconData icon;
  final VoidCallback? onPressed;
  final ProfileActionButtonType type;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDestructive = type == ProfileActionButtonType.destructive;

    final primaryColor = isDestructive
        ? const Color(0xFF991B1B)
        : AppColors.brand2;

    final bgColor = isDestructive
        ? const Color(0xFFFFDED9)
        : Colors.white;

    final border = isDestructive
        ? Border.all(color: Colors.transparent, width: 0)
        : Border.all(color: AppColors.brand2, width: 1.5);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Ink(
          height: height,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: border,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                text,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
