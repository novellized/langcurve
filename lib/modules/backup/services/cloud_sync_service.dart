import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/services/auth_service.dart';
import '../../notebook/repositories/notebook_repository.dart';
import 'backup_service.dart';

class CloudSyncService {
  final BackupService _backupService;
  final NotebookRepository _notebookRepo;
  final AuthService _authService;

  /// Optional in-memory store for unit testing without live Firestore connection
  final Map<String, Map<String, dynamic>>? mockFirestoreDocs;

  CloudSyncService({
    BackupService? backupService,
    NotebookRepository? notebookRepo,
    AuthService? authService,
    this.mockFirestoreDocs,
  })  : _backupService = backupService ?? BackupService(),
        _notebookRepo = notebookRepo ?? NotebookRepository(),
        _authService = authService ?? AuthService.instance;

  /// Uploads local SQLite data (topics, vocabularies, review_logs, XP, Streak) to Cloud Firestore
  /// under `users/{uid}`.
  Future<String> syncToCloud() async {
    final user = _authService.currentUser;
    if (user.isGuest || user.uid == null) {
      throw Exception('Vui lòng đăng nhập Google trước khi đồng bộ lên Đám mây.');
    }

    final uid = user.uid!;
    final backupJson = await _backupService.exportBackupJson();
    final profile = await _notebookRepo.getUserProfile();
    final nowIso = DateTime.now().toIso8601String();

    final payload = <String, dynamic>{
      'uid': uid,
      'email': user.email,
      'displayName': user.displayName,
      'photoUrl': user.photoUrl,
      'xp': profile['xp'] ?? 0,
      'streakCount': profile['streak_count'] ?? 0,
      'backupJson': backupJson,
      'updatedAtIso': nowIso,
    };

    if (mockFirestoreDocs != null) {
      mockFirestoreDocs![uid] = payload;
    } else {
      if (!_authService.isFirebaseInitialized) {
        throw Exception(
          'Firebase chưa được kết nối. Hãy cấu hình `flutterfire configure` trước.',
        );
      }
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        ...payload,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await _notebookRepo.updateLastSyncedAt(nowIso);
    await _authService.refreshLocalAccount();
    return nowIso;
  }

  /// Downloads the user's backup from Cloud Firestore (`users/{uid}`) and merges it
  /// into the local SQLite database.
  Future<void> restoreFromCloud() async {
    final user = _authService.currentUser;
    if (user.isGuest || user.uid == null) {
      throw Exception('Vui lòng đăng nhập Google trước khi tải dữ liệu từ Đám mây.');
    }

    final uid = user.uid!;
    Map<String, dynamic>? data;

    if (mockFirestoreDocs != null) {
      data = mockFirestoreDocs![uid];
    } else {
      if (!_authService.isFirebaseInitialized) {
        throw Exception(
          'Firebase chưa được kết nối. Hãy cấu hình `flutterfire configure` trước.',
        );
      }
      final docSnap =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      data = docSnap.data();
    }

    if (data == null || data['backupJson'] == null) {
      throw Exception('Chưa có bản sao lưu nào trên Đám mây cho tài khoản này.');
    }

    final backupJson = data['backupJson'] as String;
    await _backupService.importBackupJson(backupJson);

    final nowIso = DateTime.now().toIso8601String();
    await _notebookRepo.updateLastSyncedAt(nowIso);
    await _authService.refreshLocalAccount();
  }
}
