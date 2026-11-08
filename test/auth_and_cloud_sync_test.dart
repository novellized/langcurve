import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:langcurve/core/database/database_helper.dart';
import 'package:langcurve/modules/auth/models/user_account.dart';
import 'package:langcurve/modules/auth/services/auth_service.dart';
import 'package:langcurve/modules/backup/services/backup_service.dart';
import 'package:langcurve/modules/backup/services/cloud_sync_service.dart';
import 'package:langcurve/modules/notebook/models/vocabulary.dart';
import 'package:langcurve/modules/notebook/repositories/notebook_repository.dart';

void main() {
  late Database db;
  late DatabaseHelper dbHelper;
  late NotebookRepository notebookRepo;
  late BackupService backupService;
  late AuthService authService;
  late CloudSyncService cloudSyncService;
  late Map<String, Map<String, dynamic>> mockCloudDocs;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);

    await db.execute('''
      CREATE TABLE topics (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL,
        description TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE vocabularies (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        topic_id INTEGER NOT NULL,
        word TEXT NOT NULL,
        definition TEXT DEFAULT '',
        part_of_speech TEXT DEFAULT '',
        phonetic_uk TEXT,
        audio_url_uk TEXT,
        phonetic_us TEXT,
        audio_url_us TEXT,
        user_example TEXT,
        easiness REAL DEFAULT 2.5,
        interval INTEGER DEFAULT 0,
        repetitions INTEGER DEFAULT 0,
        due_date TEXT NOT NULL,
        correct_count INTEGER DEFAULT 0,
        wrong_count INTEGER DEFAULT 0,
        cefr_level TEXT,
        synonyms TEXT,
        antonyms TEXT,
        FOREIGN KEY (topic_id) REFERENCES topics (id) ON DELETE CASCADE,
        UNIQUE(topic_id, word)
      )
    ''');
    await db.execute('''
      CREATE TABLE review_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER DEFAULT 1,
        word TEXT NOT NULL,
        quality INTEGER NOT NULL,
        easiness REAL NOT NULL,
        interval INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE user_profile (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        xp INTEGER DEFAULT 0,
        email TEXT,
        streak_count INTEGER DEFAULT 0,
        last_study_date TEXT,
        daily_goal INTEGER DEFAULT 10,
        firebase_uid TEXT,
        display_name TEXT,
        photo_url TEXT,
        last_synced_at TEXT
      )
    ''');

    await db.insert('user_profile', {
      'id': 1,
      'xp': 50,
      'email': 'guest@langcurve.local',
      'streak_count': 3,
      'daily_goal': 15,
      'firebase_uid': null,
      'display_name': 'Người học LangCurve',
    });

    dbHelper = DatabaseHelper.withDatabase(db);
    notebookRepo = NotebookRepository(dbHelper: dbHelper);
    backupService = BackupService(dbHelper: dbHelper);
    mockCloudDocs = {};

    authService = AuthService(
      notebookRepo: notebookRepo,
      customGoogleSignInHandler: () async => const UserAccount(
        uid: 'google-uid-12345',
        email: 'learner@gmail.com',
        displayName: 'Minh Nguyen',
        photoUrl: 'https://example.com/avatar.png',
      ),
    );

    cloudSyncService = CloudSyncService(
      backupService: backupService,
      notebookRepo: notebookRepo,
      authService: authService,
      mockFirestoreDocs: mockCloudDocs,
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('Offline-first Guest mode transitions to Google Signed-In and back', () async {
    await authService.initialize();
    expect(authService.isSignedIn, isFalse);
    expect(authService.currentUser.isGuest, isTrue);
    expect(authService.currentUser.displayName, equals('Người học LangCurve'));

    // Sign in with Google
    final signedInUser = await authService.signInWithGoogle();
    expect(authService.isSignedIn, isTrue);
    expect(signedInUser.uid, equals('google-uid-12345'));
    expect(signedInUser.email, equals('learner@gmail.com'));
    expect(signedInUser.displayName, equals('Minh Nguyen'));

    // Verify persisted in SQLite user_profile
    final profileMap = await notebookRepo.getUserProfile();
    expect(profileMap['firebase_uid'], equals('google-uid-12345'));
    expect(profileMap['email'], equals('learner@gmail.com'));
    expect(profileMap['display_name'], equals('Minh Nguyen'));
    expect(profileMap['xp'], equals(50)); // Offline XP preserved!

    // Sign out -> returns to guest mode while preserving XP & Streak
    await authService.signOut();
    expect(authService.isSignedIn, isFalse);
    final afterSignOutProfile = await notebookRepo.getUserProfile();
    expect(afterSignOutProfile['firebase_uid'], isNull);
    expect(afterSignOutProfile['xp'], equals(50));
    expect(afterSignOutProfile['streak_count'], equals(3));
  });

  test('CloudSyncService syncs vocabulary and profile to Firestore and restores', () async {
    await authService.initialize();
    await authService.signInWithGoogle();

    final topic = await notebookRepo.createTopic('Cloud Sync Topic', 'Synced topic');
    await notebookRepo.upsertVocabulary(
      Vocabulary(
        topicId: topic.id!,
        word: 'resilient',
        definition: 'able to withstand or recover quickly',
        cefrLevel: 'C1',
      ),
    );

    // 1. Sync to Cloud Firestore
    final syncTime = await cloudSyncService.syncToCloud();
    expect(syncTime, isNotEmpty);
    expect(mockCloudDocs.containsKey('google-uid-12345'), isTrue);
    expect(mockCloudDocs['google-uid-12345']!['email'], equals('learner@gmail.com'));
    expect(mockCloudDocs['google-uid-12345']!['xp'], equals(50));

    // 2. Simulate wiping local data on a new device
    await db.delete('vocabularies');
    await db.delete('topics');
    await db.update('user_profile', {'xp': 0, 'streak_count': 0}, where: 'id = ?', whereArgs: [1]);

    expect((await notebookRepo.getAllVocabularies()).isEmpty, isTrue);
    expect(await notebookRepo.getUserXp(), equals(0));

    // 3. Restore from Cloud Firestore
    await cloudSyncService.restoreFromCloud();

    final restoredVocabs = await notebookRepo.getAllVocabularies();
    expect(restoredVocabs.any((v) => v.word == 'resilient'), isTrue);
    expect(await notebookRepo.getUserXp(), equals(50));
    final restoredProfile = await notebookRepo.getUserProfile();
    expect(restoredProfile['streak_count'], equals(3));
  });
}
