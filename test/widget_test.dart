import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:langcurve/core/database/database_helper.dart';
import 'package:langcurve/main.dart';

void main() {
  late Database db;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
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
    await db.insert('user_profile', {'id': 1, 'xp': 0, 'email': 'test@langcurve.local'});
    DatabaseHelper.withDatabase(db);
  });

  tearDownAll(() async {
    await db.close();
  });

  testWidgets('LangCurveApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const LangCurveApp());
    await tester.pump(const Duration(seconds: 15));
    expect(find.text('LangCurve'), findsOneWidget);
  });
}
