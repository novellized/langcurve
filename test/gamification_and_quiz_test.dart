import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:langcurve/core/database/database_helper.dart';
import 'package:langcurve/modules/notebook/repositories/notebook_repository.dart';
import 'package:langcurve/core/services/audio_service.dart';

void main() {
  late Database db;
  late NotebookRepository repo;

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
        daily_goal INTEGER DEFAULT 10
      )
    ''');

    await db.insert('user_profile', {
      'id': 1,
      'xp': 100,
      'email': 'test@langcurve.local',
      'streak_count': 0,
      'last_study_date': null,
      'daily_goal': 10,
    });

    final helper = DatabaseHelper.withDatabase(db);
    repo = NotebookRepository(dbHelper: helper);
  });

  tearDown(() async {
    await db.close();
  });

  group('Gamification & Streak Tests', () {
    test('getUserProfile returns default profile stats', () async {
      final profile = await repo.getUserProfile();
      expect(profile['xp'], equals(100));
      expect(profile['streak_count'], equals(0));
      expect(profile['daily_goal'], equals(10));
    });

    test('recordStudySession increments streak correctly', () async {
      final initialStreak = await repo.recordStudySession();
      expect(initialStreak, equals(1));

      // Second call on the same day maintains streak
      final sameDayStreak = await repo.recordStudySession();
      expect(sameDayStreak, equals(1));
    });

    test('updateDailyGoal updates user goal', () async {
      await repo.updateDailyGoal(20);
      final profile = await repo.getUserProfile();
      expect(profile['daily_goal'], equals(20));
    });
  });

  group('AudioService Speed Tests', () {
    test('getFallbackTtsUrl returns valid URL for UK and US', () {
      final ukUrl = AudioService.getFallbackTtsUrl('apple', isUk: true);
      final usUrl = AudioService.getFallbackTtsUrl('apple', isUk: false);

      expect(ukUrl, contains('_gb_1.mp3'));
      expect(usUrl, contains('_us_1.mp3'));
    });
  });
}
