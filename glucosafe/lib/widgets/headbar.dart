import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Komponen App Bar / Header atas untuk aplikasi GlucoSafe.
/// Dapat digunakan langsung di dalam Column maupun sebagai `appBar:` pada Scaffold.
class HeadBar extends StatelessWidget implements PreferredSizeWidget {
  const HeadBar({
    super.key,
    this.title = 'Beranda',
    this.subtitle,
    this.showBackButton = false,
    this.onBack,
    this.showLogo = true,
    this.showProfile = true,
    this.onProfile,
    this.titleWidget,
  });

  /// Judul halaman di header (contoh: 'Beranda', 'Riwayat', 'Hasil Skrining')
  final String title;

  /// Subtitle opsional di bawah judul (contoh: 'Skrining Mandiri')
  final String? subtitle;

  /// Tampilkan tombol navigasi kembali di sebelah kiri
  final bool showBackButton;

  /// Aksi ketika tombol kembali ditekan
  final VoidCallback? onBack;

  /// Tampilkan icon logo GlucoSafe
  final bool showLogo;

  /// Tampilkan avatar profile di pojok kanan
  final bool showProfile;

  /// Aksi ketika avatar profil ditekan
  final VoidCallback? onProfile;

  /// Widget kustom pengganti judul jika membutuhkan layout khusus
  final Widget? titleWidget;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  void _defaultProfileTap(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Halaman Profil belum dihubungkan')),
      );
  }

  @override
  Widget build(BuildContext context) {
    final bool canBack = showBackButton || onBack != null;

    return Container(
      height: 64,
      padding: EdgeInsets.symmetric(horizontal: canBack ? 8 : 16),
      decoration: const BoxDecoration(
        color: Color(0xD9FFFFFF),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Tombol Kembali (jika ada)
          if (canBack) ...[
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              onPressed: onBack ?? () => Navigator.maybePop(context),
              icon: const Icon(
                Icons.chevron_left_rounded,
                size: 28,
                color: AppColors.ink,
              ),
              tooltip: 'Kembali',
            ),
          ],

          // Logo GlucoSafe (jika aktif)
          if (showLogo) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/logo.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                cacheWidth: 96,
                errorBuilder: (context, error, stack) => Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF14B8A6), Color(0xFF0F766E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(
                    Icons.water_drop_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],

          // Judul / Subtitle
          Expanded(
            child: titleWidget ??
                (subtitle != null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              height: 1.2,
                              fontWeight: FontWeight.w700,
                              color: AppColors.brand,
                            ),
                          ),
                          Text(
                            subtitle!,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.2,
                              color: AppColors.brand2,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          height: 26 / 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      )),
          ),

          // Tombol Profil Pengguna
          if (showProfile)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Semantics(
                button: true,
                label: 'Buka profil pengguna',
                child: InkWell(
                  onTap: onProfile ?? () => _defaultProfileTap(context),
                  customBorder: const CircleBorder(),
                  child: const SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.brand,
                          shape: BoxShape.circle,
                        ),
                        child: SizedBox(
                          width: 32,
                          height: 32,
                          child: Icon(
                            Icons.person_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Alias class name untuk fleksibilitas penamaan
typedef Headbar = HeadBar;
