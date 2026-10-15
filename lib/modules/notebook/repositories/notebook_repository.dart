import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import '../models/topic.dart';
import '../models/vocabulary.dart';

class NotebookRepository {
  final DatabaseHelper _dbHelper;

  NotebookRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<Database> get _db async => await _dbHelper.database;

  /// Get overall statistics for dashboard
  Future<Map<String, int>> getStats() async {
    final db = await _db;
    final topicsCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM topics'),
        ) ??
        0;

    final distinctWordsCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(DISTINCT word) FROM vocabularies'),
        ) ??
        0;

    final examplesCount = Sqflite.firstIntValue(
          await db.rawQuery(
              "SELECT COUNT(*) FROM vocabularies WHERE user_example IS NOT NULL AND trim(user_example) != ''"),
        ) ??
        0;

    final userRow = await db.query('user_profile', where: 'id = ?', whereArgs: [1]);
    final xp = userRow.isNotEmpty ? (userRow.first['xp'] as int? ?? 0) : 0;

    return {
      'total_topics': topicsCount,
      'total_words': distinctWordsCount,
      'total_examples': examplesCount,
      'xp': xp,
    };
  }

  /// Get all topics with their vocabulary count
  Future<List<Topic>> getTopics() async {
    final db = await _db;
    final topicRows = await db.query('topics', orderBy: 'name ASC');

    final List<Topic> result = [];
    for (final row in topicRows) {
      final topicId = row['id'] as int;
      final count = Sqflite.firstIntValue(
            await db.rawQuery(
              'SELECT COUNT(*) FROM vocabularies WHERE topic_id = ?',
              [topicId],
            ),
          ) ??
          0;
      result.add(Topic.fromMap(row, wordCount: count));
    }
    return result;
  }

  /// Create a new topic
  Future<Topic> createTopic(String name, [String? description]) async {
    final db = await _db;
    final id = await db.insert(
      'topics',
      {
        'name': name.trim(),
        'description': description?.trim(),
      },
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    return Topic(id: id, name: name.trim(), description: description?.trim(), wordCount: 0);
  }

  /// Delete topic and cascade delete vocabularies
  Future<int> deleteTopic(int topicId) async {
    final db = await _db;
    return await db.delete('topics', where: 'id = ?', whereArgs: [topicId]);
  }

  /// Get all vocabularies for a specific topic
  Future<List<Vocabulary>> getVocabularies(int topicId) async {
    final db = await _db;
    final rows = await db.query(
      'vocabularies',
      where: 'topic_id = ?',
      whereArgs: [topicId],
      orderBy: 'word ASC',
    );
    return rows.map((r) => Vocabulary.fromMap(r)).toList();
  }

  /// Get all vocabularies across all topics
  Future<List<Vocabulary>> getAllVocabularies() async {
    final db = await _db;
    final rows = await db.query('vocabularies', orderBy: 'due_date ASC');
    return rows.map((r) => Vocabulary.fromMap(r)).toList();
  }

  /// Upsert vocabulary (insert or update on conflict topic_id + word)
  Future<Vocabulary> upsertVocabulary(Vocabulary vocab) async {
    final db = await _db;
    final existing = await db.query(
      'vocabularies',
      where: 'topic_id = ? AND word = ?',
      whereArgs: [vocab.topicId, vocab.word.toLowerCase().trim()],
    );

    if (existing.isNotEmpty) {
      final id = existing.first['id'] as int;
      final updateMap = vocab.toMap();
      updateMap.remove('id');
      await db.update(
        'vocabularies',
        updateMap,
        where: 'id = ?',
        whereArgs: [id],
      );
      return vocab.copyWith(id: id);
    } else {
      final map = vocab.toMap();
      map['word'] = vocab.word.toLowerCase().trim();
      final id = await db.insert('vocabularies', map);
      return vocab.copyWith(id: id);
    }
  }

  /// Update user example sentence for a vocabulary item
  Future<int> updateExample(int vocabId, String? userExample) async {
    final db = await _db;
    return await db.update(
      'vocabularies',
      {'user_example': userExample?.trim()},
      where: 'id = ?',
      whereArgs: [vocabId],
    );
  }

  /// Delete a vocabulary item
  Future<int> deleteVocabulary(int vocabId) async {
    final db = await _db;
    return await db.delete('vocabularies', where: 'id = ?', whereArgs: [vocabId]);
  }

  /// Get user XP
  Future<int> getUserXp() async {
    final db = await _db;
    final rows = await db.query('user_profile', where: 'id = ?', whereArgs: [1]);
    if (rows.isNotEmpty) {
      return (rows.first['xp'] as int?) ?? 0;
    }
    return 0;
  }

  /// Add XP to user profile
  Future<int> addXp(int amount) async {
    final db = await _db;
    final currentXp = await getUserXp();
    final newXp = currentXp + amount;
    await db.update(
      'user_profile',
      {'xp': newXp},
      where: 'id = ?',
      whereArgs: [1],
    );
    return newXp;
  }
}
