class UserAccount {
  final String? uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String? lastSyncedAt;

  const UserAccount({
    this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.lastSyncedAt,
  });

  bool get isGuest => uid == null || uid!.trim().isEmpty;

  factory UserAccount.guest() {
    return const UserAccount(
      uid: null,
      email: 'guest@langcurve.local',
      displayName: 'Người học LangCurve',
      photoUrl: null,
      lastSyncedAt: null,
    );
  }

  factory UserAccount.fromProfileMap(Map<String, dynamic> map) {
    final uid = map['firebase_uid'] as String?;
    final rawName = map['display_name'] as String?;
    final rawEmail = map['email'] as String?;
    return UserAccount(
      uid: (uid != null && uid.trim().isNotEmpty) ? uid.trim() : null,
      email: (rawEmail != null && rawEmail.trim().isNotEmpty)
          ? rawEmail.trim()
          : 'guest@langcurve.local',
      displayName: (rawName != null && rawName.trim().isNotEmpty)
          ? rawName.trim()
          : 'Người học LangCurve',
      photoUrl: map['photo_url'] as String?,
      lastSyncedAt: map['last_synced_at'] as String?,
    );
  }

  UserAccount copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    String? lastSyncedAt,
  }) {
    return UserAccount(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}
