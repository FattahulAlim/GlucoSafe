import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Komponen Bottom Navigation Bar untuk aplikasi GlucoSafe.
/// Menampilkan navigasi utama antara 'Beranda' dan 'Riwayat'.
class NavBar extends StatelessWidget {
  const NavBar({
    super.key,
    this.currentIndex = 0,
    this.onTap,
    this.onBeranda,
    this.onHistory,
  });

  /// Indeks tab yang sedang aktif (0: Beranda, 1: Riwayat)
  final int currentIndex;

  /// Callback ketika salah satu tab dipilih dengan parameter index
  final ValueChanged<int>? onTap;

  /// Callback khusus ketika tab Beranda diklik
  final VoidCallback? onBeranda;

  /// Callback khusus ketika tab Riwayat diklik
  final VoidCallback? onHistory;

  Widget _buildItem({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback? onPressed,
  }) {
    final color = active ? AppColors.brand : AppColors.mute;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 64, minHeight: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                height: 16 / 12,
                letterSpacing: .24,
                fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: Color(0xE6FFFFFF),
        boxShadow: [
          BoxShadow(
            color: Color(0x0D0F172A),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        height: 68,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildItem(
              icon: Icons.home_outlined,
              label: 'Beranda',
              active: currentIndex == 0,
              onPressed: currentIndex == 0
                  ? null
                  : () {
                      if (onTap != null) {
                        onTap!(0);
                      } else if (onBeranda != null) {
                        onBeranda!();
                      }
                    },
            ),
            _buildItem(
              icon: Icons.history_rounded,
              label: 'Riwayat',
              active: currentIndex == 1,
              onPressed: currentIndex == 1
                  ? null
                  : () {
                      if (onTap != null) {
                        onTap!(1);
                      } else if (onHistory != null) {
                        onHistory!();
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }
}

/// Alias class name untuk fleksibilitas penamaan
typedef Navbar = NavBar;
typedef BottomNav = NavBar;
