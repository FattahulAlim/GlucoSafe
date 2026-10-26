import 'package:flutter/material.dart';
import '../../domain/user_profile.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/headbar.dart';
import '../../../../core/widgets/logout_dialog.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/user_service.dart';
import '../widgets/profile_action_button.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/profile_info_tile.dart';
import './edit_profile_page.dart';
import '../../../auth/presentation/pages/login_page.dart';

/// Halaman Profil Pengguna GlucoSafe.
/// Menampilkan informasi akun pengguna, ringkasan pemeriksaan,
/// serta opsi edit profil dan keluar dari akun.
class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    this.profile,
    this.onBack,
  });

  /// Data profil pengguna yang ditampilkan. Jika null, mengambil dari backend/storage.
  final UserProfile? profile;

  /// Callback kustom ketika tombol kembali ditekan
  final VoidCallback? onBack;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final StorageService _storageService = StorageService();
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();

  UserProfile _currentProfile = UserProfile.defaultUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.profile != null) {
      _currentProfile = widget.profile!;
      _isLoading = false;
    } else {
      _loadProfile();
    }
  }

  Future<void> _loadProfile() async {
    // 1. Muat dari local storage dulu agar langsung tampil cepat
    final localUser = await _storageService.getUser();
    if (localUser != null && mounted) {
      setState(() {
        _currentProfile = UserProfile(
          name: localUser.name,
          email: localUser.email,
          initials: UserProfile.extractInitials(localUser.name),
        );
        _isLoading = false;
      });
    }

    // 2. Refresh dari backend API
    try {
      final res = await _userService.getProfile();
      if (res.success && res.data != null && mounted) {
        final u = res.data!;
        setState(() {
          _currentProfile = UserProfile(
            name: u.name,
            email: u.email,
            initials: UserProfile.extractInitials(u.name),
          );
          _isLoading = false;
        });
      }
    } catch (_) {}

    if (mounted && _isLoading) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleEditProfile() async {
    final updatedProfile = await Navigator.push<UserProfile>(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilePage(profile: _currentProfile),
      ),
    );

    if (updatedProfile != null && mounted) {
      setState(() {
        _currentProfile = updatedProfile;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil berhasil diperbarui'),
          backgroundColor: AppColors.brand2,
        ),
      );
    }
  }

  void _handleLogout() {
    LogoutDialog.show(
      context,
      onConfirmLogout: () async {
        await _authService.logout();
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      body: SafeArea(
        child: Column(
          children: [
            // Header Bar
            HeadBar(
              title: 'Profil',
              showBackButton: true,
              onBack: widget.onBack ?? () => Navigator.maybePop(context),
              showLogo: true,
              showProfile: true,
              onProfile: () {}, // Sudah di halaman profil
            ),

            // Konten Profil
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Column(
                  children: [
                    // Kartu 1: Profil Pengguna (Avatar, Nama, Email)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 28,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A0F172A),
                            blurRadius: 16,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ProfileAvatar(
                            initials: _currentProfile.initials,
                            photoAsset: _currentProfile.photoAsset,
                            size: 92,
                            showVerifiedBadge: _currentProfile.isVerified,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _currentProfile.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _currentProfile.email,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Kartu 2: Ringkasan Pemeriksaan
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A0F172A),
                            blurRadius: 16,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Item 1: Jumlah pemeriksaan
                          ProfileInfoTile(
                            icon: Icons.assignment_outlined,
                            title: 'Jumlah pemeriksaan',
                            value: '${_currentProfile.inspectionCount} kali',
                          ),

                          const SizedBox(height: 12),
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: Color(0xFFF1F5F9),
                          ),
                          const SizedBox(height: 12),

                          // Item 2: Pemeriksaan terakhir
                          ProfileInfoTile(
                            icon: Icons.calendar_today_outlined,
                            title: 'Pemeriksaan terakhir',
                            trailing: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _currentProfile.lastInspectionDate,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFCCFBF1),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    _currentProfile.lastRiskStatus,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.brand2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Tombol Aksi: Edit Profil
                    ProfileActionButton.outline(
                      text: 'Edit Profil',
                      icon: Icons.edit_outlined,
                      onPressed: _handleEditProfile,
                    ),

                    const SizedBox(height: 12),

                    // Tombol Aksi: Keluar dari Akun
                    ProfileActionButton.destructive(
                      text: 'Keluar dari Akun',
                      icon: Icons.logout_rounded,
                      onPressed: _handleLogout,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
