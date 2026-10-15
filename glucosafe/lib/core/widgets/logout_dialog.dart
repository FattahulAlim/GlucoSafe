import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Dialog konfirmasi keluar dari akun dengan efek blur pada latar belakang.
class LogoutDialog extends StatelessWidget {
  const LogoutDialog({
    super.key,
    this.onConfirmLogout,
  });

  /// Aksi ketika tombol 'Keluar' ditekan
  final VoidCallback? onConfirmLogout;

  /// Helper untuk menampilkan LogoutDialog dengan background blur secara mudah
  static Future<bool?> show(
    BuildContext context, {
    VoidCallback? onConfirmLogout,
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: const Color(0x59000000),
      builder: (dialogContext) => LogoutDialog(
        onConfirmLogout: onConfirmLogout,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
      child: Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Wadah Lingkaran Icon Keluar
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFDED9),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.logout_rounded,
                  size: 32,
                  color: Color(0xFFB91C1C),
                ),
              ),

              const SizedBox(height: 18),

              // Judul Dialog
              const Text(
                'Keluar dari akun?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                  letterSpacing: -0.3,
                ),
              ),

              const SizedBox(height: 8),

              // Penjelasan
              const Text(
                'Anda perlu masuk lagi untuk melihat hasil pemeriksaan Anda.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: AppColors.slate,
                ),
              ),

              const SizedBox(height: 24),

              // Tombol Batal & Keluar
              Row(
                children: [
                  // Tombol Batal
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: const Color(0xFFE2EBFF),
                          foregroundColor: AppColors.ink,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: const Text(
                          'Batal',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Tombol Keluar
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context, true);
                          if (onConfirmLogout != null) {
                            onConfirmLogout!();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: const Color(0xFFB91C1C),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: const Text(
                          'Keluar',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
