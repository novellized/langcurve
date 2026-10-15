import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:langcurve/core/database/database_helper.dart';
import 'package:langcurve/modules/notebook/repositories/notebook_repository.dart';
import 'package:langcurve/modules/notebook/models/vocabulary.dart';
import 'package:langcurve/modules/srs/repositories/srs_repository.dart';
import 'package:langcurve/modules/analytics/services/tracking_service.dart';
import 'package:langcurve/modules/backup/services/backup_service.dart';

void main() {
  late Database db;
  late NotebookRepository notebookRepo;
  late SrsRepository srsRepo;
  late TrackingService trackingService;
  late BackupService backupService;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // Create isolated in-memory database for testing
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);

    // Run schema creation
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
        email TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE word_cache (
        word TEXT PRIMARY KEY,
        source TEXT,
        raw_payload TEXT,
        updated_at TEXT
      )
    ''');

    // Seed defaults
    await db.insert('topics', {'name': 'Technology', 'description': 'Tech words'});
    await db.insert('topics', {'name': 'Business', 'description': 'Business words'});
    await db.insert('user_profile', {'id': 1, 'xp': 0, 'email': 'test@langcurve.local'});

    final helper = DatabaseHelper.withDatabase(db);
    notebookRepo = NotebookRepository(dbHelper: helper);
    srsRepo = SrsRepository(dbHelper: helper, notebookRepo: notebookRepo);
    trackingService = TrackingService(dbHelper: helper);
    backupService = BackupService(dbHelper: helper);
  });

  tearDown(() async {
    await db.close();
  });

  test('NotebookRepository CRUD and Stats operate correctly', () async {
    final topics = await notebookRepo.getTopics();
    expect(topics.length, equals(2));
    expect(topics.first.name, equals('Business'));

    final newTopic = await notebookRepo.createTopic('Education', 'Study words');
    expect(newTopic.name, equals('Education'));

    final savedVocab = await notebookRepo.upsertVocabulary(
      Vocabulary(
        topicId: newTopic.id!,
        word: 'study',
        definition: 'acquire knowledge',
        userExample: 'I study English every day.',
      ),
    );
    expect(savedVocab.id, isNotNull);

    final stats = await notebookRepo.getStats();
    expect(stats['total_topics'], equals(3));
    expect(stats['total_words'], equals(1));
    expect(stats['total_examples'], equals(1));
  });

  test('SrsRepository records review, advances interval and updates XP', () async {
    final topic = await notebookRepo.createTopic('Test Topic');
    final vocab = await notebookRepo.upsertVocabulary(
      Vocabulary(
        topicId: topic.id!,
        word: 'innovate',
      ),
    );

    // Review with quality 5 (perfect) -> expect +20 XP, interval = 1
    final updated = await srsRepo.recordReview(vocabId: vocab.id!, quality: 5);
    expect(updated.repetitions, equals(1));
    expect(updated.interval, equals(1));
    expect(updated.correctCount, equals(1));

    final xp = await notebookRepo.getUserXp();
    expect(xp, equals(20));

    // Check Curve Analytics data point
    final curvePoints = await trackingService.getLearningCurve();
    expect(curvePoints.length, equals(1));
    expect(curvePoints.first.wordCount, equals(1));
    expect(curvePoints.first.correctReviews, equals(1));
  });

  test('BackupService exports and imports data cleanly', () async {
    final topic = await notebookRepo.createTopic('Backup Topic');
    await notebookRepo.upsertVocabulary(
      Vocabulary(
        topicId: topic.id!,
        word: 'algorithm',
        definition: 'computational step',
      ),
    );

    final jsonStr = await backupService.exportBackupJson();
    expect(jsonStr, contains('algorithm'));
    expect(jsonStr, contains('Backup Topic'));

    // Clear tables
    await db.delete('vocabularies');
    await db.delete('topics');

    // Restore from backup
    await backupService.importBackupJson(jsonStr);

    final restoredTopics = await notebookRepo.getTopics();
    expect(restoredTopics.any((t) => t.name == 'Backup Topic'), isTrue);

    final allVocabs = await notebookRepo.getAllVocabularies();
    expect(allVocabs.any((v) => v.word == 'algorithm'), isTrue);
  });
}
