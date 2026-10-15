/// Model representasi data profil pengguna GlucoSafe.
class UserProfile {
  final String name;
  final String email;
  final String initials;
  final int inspectionCount;
  final String lastInspectionDate;
  final String lastRiskStatus;
  final bool isVerified;
  final String? photoAsset;

  const UserProfile({
    required this.name,
    required this.email,
    required this.initials,
    this.inspectionCount = 5,
    this.lastInspectionDate = '14 Okt 2023',
    this.lastRiskStatus = 'Tidak Berisiko',
    this.isVerified = true,
    this.photoAsset,
  });

  /// Data profil default sesuai desain (Rahmawati)
  static const UserProfile defaultUser = UserProfile(
    name: 'Rahmawati',
    email: 'rahmawati.santoso@email.com',
    initials: 'RW',
    inspectionCount: 5,
    lastInspectionDate: '14 Okt 2023',
    lastRiskStatus: 'Tidak Berisiko',
    isVerified: true,
  );

  /// Helper untuk mengekstrak inisial nama jika tidak ditentukan secara manual
  static String extractInitials(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return 'U';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  UserProfile copyWith({
    String? name,
    String? email,
    String? initials,
    int? inspectionCount,
    String? lastInspectionDate,
    String? lastRiskStatus,
    bool? isVerified,
    String? photoAsset,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      initials: initials ?? this.initials,
      inspectionCount: inspectionCount ?? this.inspectionCount,
      lastInspectionDate: lastInspectionDate ?? this.lastInspectionDate,
      lastRiskStatus: lastRiskStatus ?? this.lastRiskStatus,
      isVerified: isVerified ?? this.isVerified,
      photoAsset: photoAsset ?? this.photoAsset,
    );
  }
}
