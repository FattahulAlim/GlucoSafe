import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/user_profile.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/user_service.dart';
import '../widgets/profile_avatar.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final UserService _userService = UserService();
  final ImagePicker _picker = ImagePicker();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late String _initials;
  String? _photoUrl;
  bool _hasChanges = false;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _emailController = TextEditingController(text: widget.profile.email);
    _initials = widget.profile.initials;
    _photoUrl = widget.profile.photoUrl;

    _nameController.addListener(_onTextChanged);
    _emailController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final currentName = _nameController.text.trim();
    final currentEmail = _emailController.text.trim();
    final changed =
        currentName != widget.profile.name ||
        currentEmail != widget.profile.email ||
        _photoUrl != widget.profile.photoUrl;

    if (changed != _hasChanges) {
      setState(() {
        _hasChanges = changed;
        if (currentName.isNotEmpty) {
          _initials = UserProfile.extractInitials(currentName);
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _changePhoto() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.brand),
                title: const Text('Ambil dari Kamera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: AppColors.brand,
                ),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_photoUrl != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'Hapus Foto Profil',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _deletePhoto();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
        requestFullMetadata: false,
      );
      if (image == null) return;

      setState(() => _isUploadingPhoto = true);

      final res = await _userService.uploadPhoto(File(image.path));

      if (!mounted) return;
      setState(() => _isUploadingPhoto = false);

      if (res.success && res.data != null) {
        setState(() {
          _photoUrl = res.data!.photoUrl;
          _hasChanges = true; // Tandai ada perubahan
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto profil berhasil diunggah'),
            backgroundColor: AppColors.brand2,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      setState(() => _isUploadingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memilih/upload foto: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deletePhoto() async {
    setState(() => _isUploadingPhoto = true);
    final res = await _userService.deletePhoto();
    if (!mounted) return;
    setState(() => _isUploadingPhoto = false);

    if (res.success) {
      setState(() {
        _photoUrl = null;
        _hasChanges = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto profil dihapus'),
          backgroundColor: AppColors.brand2,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _saveChanges() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama lengkap tidak boleh kosong')),
      );
      return;
    }

    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan alamat email yang valid')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final res = await _userService.updateProfile(name: name, email: email);

      if (!mounted) return;
      setState(() => _isSaving = false);

      if (res.success && res.data != null) {
        final updatedProfile = widget.profile.copyWith(
          name: res.data!.name,
          email: res.data!.email,
          initials: UserProfile.extractInitials(res.data!.name),
          photoUrl: _photoUrl, // Simpan URL foto
        );
        Navigator.pop(context, updatedProfile);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui profil: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 58,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: const BoxDecoration(
                color: Colors.white,
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
                  IconButton(
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(
                      Icons.arrow_back,
                      size: 24,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Edit Profil',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                child: Column(
                  children: [
                    Center(
                      child: Column(
                        children: [
                          _isUploadingPhoto
                              ? const SizedBox(
                                  width: 96,
                                  height: 96,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.brand,
                                    ),
                                  ),
                                )
                              : ProfileAvatar(
                                  initials: _initials,
                                  photoUrl: _photoUrl,
                                  size: 96,
                                  showCameraBadge: true,
                                  badgeColor: AppColors.brand,
                                  onBadgeTap: _changePhoto,
                                ),
                          const SizedBox(height: 12),
                          const Text(
                            'Ketuk kamera untuk mengubah foto',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF3D4947),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x060F172A),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nama Lengkap',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: TextField(
                              controller: _nameController,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: AppColors.ink,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x060F172A),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Email',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: AppColors.ink,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.shield_rounded,
                            size: 20,
                            color: AppColors.brand,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Informasi Anda disimpan dengan aman dan hanya digunakan untuk keperluan pengingat dan catatan gula darah GlucoSafe.',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.45,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveChanges,
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: _hasChanges
                              ? AppColors.brand
                              : const Color(
                                  0xFFD6E2FB,
                                ), // Tombol biru jika ada perubahan
                          foregroundColor: _hasChanges
                              ? Colors.white
                              : const Color(0xFF334155),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_rounded, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Simpan Perubahan',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () => Navigator.maybePop(context),
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Text(
                          'Batal',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ),
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
