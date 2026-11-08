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

    final profile = await getUserProfile();

    return {
      'total_topics': topicsCount,
      'total_words': distinctWordsCount,
      'total_examples': examplesCount,
      'xp': profile['xp'] as int,
      'streak_count': profile['streak_count'] as int,
      'daily_goal': profile['daily_goal'] as int,
      'today_reviewed_count': profile['today_reviewed_count'] as int,
    };
  }

  /// Get user profile (XP, Streak, Daily Goal, Today progress, and Firebase Auth info)
  Future<Map<String, dynamic>> getUserProfile() async {
    final db = await _db;
    final userRow = await db.query('user_profile', where: 'id = ?', whereArgs: [1]);
    if (userRow.isEmpty) {
      return {
        'xp': 0,
        'streak_count': 0,
        'last_study_date': null,
        'daily_goal': 10,
        'today_reviewed_count': 0,
        'email': 'guest@langcurve.local',
        'firebase_uid': null,
        'display_name': 'Người học LangCurve',
        'photo_url': null,
        'last_synced_at': null,
      };
    }

    final row = userRow.first;
    final xp = (row['xp'] as int?) ?? 0;
    var streak = (row['streak_count'] as int?) ?? 0;
    final lastDateStr = row['last_study_date'] as String?;
    final dailyGoal = (row['daily_goal'] as int?) ?? 10;
    final email = (row['email'] as String?) ?? 'guest@langcurve.local';
    final firebaseUid = row['firebase_uid'] as String?;
    final displayName = (row['display_name'] as String?) ?? 'Người học LangCurve';
    final photoUrl = row['photo_url'] as String?;
    final lastSyncedAt = row['last_synced_at'] as String?;

    // Check if streak is broken (more than 1 day missed)
    if (lastDateStr != null && lastDateStr.isNotEmpty) {
      final lastDate = DateTime.tryParse(lastDateStr);
      if (lastDate != null) {
        final diffDays = DateTime.now().difference(DateTime(lastDate.year, lastDate.month, lastDate.day)).inDays;
        if (diffDays > 1) {
          streak = 0; // Streak broken
          await db.update('user_profile', {'streak_count': 0}, where: 'id = ?', whereArgs: [1]);
        }
      }
    }

    final todayReviewedCount = await getTodayReviewedCount();

    return {
      'xp': xp,
      'streak_count': streak,
      'last_study_date': lastDateStr,
      'daily_goal': dailyGoal,
      'today_reviewed_count': todayReviewedCount,
      'email': email,
      'firebase_uid': firebaseUid,
      'display_name': displayName,
      'photo_url': photoUrl,
      'last_synced_at': lastSyncedAt,
    };
  }

  /// Updates the local user profile with Google / Firebase account metadata
  Future<void> updateAuthProfile({
    String? firebaseUid,
    String? email,
    String? displayName,
    String? photoUrl,
  }) async {
    final db = await _db;
    await db.update(
      'user_profile',
      {
        'firebase_uid': firebaseUid,
        'email': email ?? 'guest@langcurve.local',
        'display_name': (displayName != null && displayName.trim().isNotEmpty)
            ? displayName.trim()
            : 'Người học LangCurve',
        'photo_url': photoUrl,
      },
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  /// Updates the last cloud synchronization timestamp
  Future<void> updateLastSyncedAt(String? isoTimestamp) async {
    final db = await _db;
    await db.update(
      'user_profile',
      {'last_synced_at': isoTimestamp},
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  /// Records study activity today and updates daily Streak 🔥
  Future<int> recordStudySession() async {
    final db = await _db;
    final profile = await getUserProfile();
    final todayStr = _formatDate(DateTime.now());
    final lastDateStr = profile['last_study_date'] as String?;
    int streak = profile['streak_count'] as int;

    if (lastDateStr == todayStr) {
      // Already recorded today
      return streak;
    }

    if (lastDateStr != null && lastDateStr.isNotEmpty) {
      final lastDate = DateTime.tryParse(lastDateStr);
      if (lastDate != null) {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final yesterdayStr = _formatDate(yesterday);
        if (lastDateStr == yesterdayStr) {
          streak += 1; // Consecutive day!
        } else {
          streak = 1; // Restart streak
        }
      } else {
        streak = 1;
      }
    } else {
      streak = 1; // First day streak
    }

    await db.update(
      'user_profile',
      {
        'streak_count': streak,
        'last_study_date': todayStr,
      },
      where: 'id = ?',
      whereArgs: [1],
    );

    return streak;
  }

  /// Get count of reviews logged today
  Future<int> getTodayReviewedCount() async {
    final db = await _db;
    final todayStr = _formatDate(DateTime.now());
    final count = Sqflite.firstIntValue(
          await db.rawQuery(
            "SELECT COUNT(*) FROM review_logs WHERE created_at LIKE ?",
            ['$todayStr%'],
          ),
        ) ??
        0;
    return count;
  }

  /// Update daily goal
  Future<void> updateDailyGoal(int newGoal) async {
    final db = await _db;
    await db.update(
      'user_profile',
      {'daily_goal': newGoal},
      where: 'id = ?',
      whereArgs: [1],
    );
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

  String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
