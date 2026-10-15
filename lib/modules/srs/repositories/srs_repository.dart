import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import '../../notebook/models/vocabulary.dart';
import '../../notebook/repositories/notebook_repository.dart';
import '../models/review_log.dart';
import '../services/srs_engine.dart';

class SrsRepository {
  final DatabaseHelper _dbHelper;
  final NotebookRepository _notebookRepo;

  SrsRepository({DatabaseHelper? dbHelper, NotebookRepository? notebookRepo})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance,
        _notebookRepo = notebookRepo ?? NotebookRepository(dbHelper: dbHelper);

  Future<Database> get _db async => await _dbHelper.database;

  /// Records an SRS review for a vocabulary word
  Future<Vocabulary> recordReview({
    required int vocabId,
    required int quality,
  }) async {
    final db = await _db;

    final rows = await db.query('vocabularies', where: 'id = ?', whereArgs: [vocabId]);
    if (rows.isEmpty) {
      throw Exception('Vocabulary with ID $vocabId not found.');
    }

    final currentVocab = Vocabulary.fromMap(rows.first);

    // Apply SuperMemo-2 calculation
    final sm2 = SrsEngine.calculateSM2(
      quality: quality,
      currentEF: currentVocab.easiness,
      currentRepetitions: currentVocab.repetitions,
      currentInterval: currentVocab.interval,
    );

    final isCorrect = quality >= 3;
    final updatedVocab = currentVocab.copyWith(
      easiness: sm2.easiness,
      repetitions: sm2.repetitions,
      interval: sm2.interval,
      dueDate: sm2.dueDate,
      correctCount: isCorrect ? currentVocab.correctCount + 1 : currentVocab.correctCount,
      wrongCount: !isCorrect ? currentVocab.wrongCount + 1 : currentVocab.wrongCount,
    );

    // Update vocabulary in DB
    await db.update(
      'vocabularies',
      {
        'easiness': updatedVocab.easiness,
        'repetitions': updatedVocab.repetitions,
        'interval': updatedVocab.interval,
        'due_date': updatedVocab.dueDate.toIso8601String(),
        'correct_count': updatedVocab.correctCount,
        'wrong_count': updatedVocab.wrongCount,
      },
      where: 'id = ?',
      whereArgs: [vocabId],
    );

    // Save review log for curve analytics
    final log = ReviewLog(
      userId: 1,
      word: currentVocab.word,
      quality: quality,
      easiness: sm2.easiness,
      interval: sm2.interval,
      createdAt: DateTime.now(),
    );
    await db.insert('review_logs', log.toMap());

    // Award XP
    final xpReward = SrsEngine.calculateXpReward(quality);
    if (xpReward > 0) {
      await _notebookRepo.addXp(xpReward);
    }

    return updatedVocab;
  }

  /// Get all vocabularies for study with countdown info, optionally filtered by topic
  Future<List<Vocabulary>> getVocabulariesForReview({int? topicId}) async {
    final db = await _db;
    final List<Map<String, dynamic>> rows;
    if (topicId != null) {
      rows = await db.query(
        'vocabularies',
        where: 'topic_id = ?',
        whereArgs: [topicId],
        orderBy: 'due_date ASC',
      );
    } else {
      rows = await db.query(
        'vocabularies',
        orderBy: 'due_date ASC',
      );
    }
    return rows.map((r) => Vocabulary.fromMap(r)).toList();
  }

  /// Get only vocabularies that are currently due
  Future<List<Vocabulary>> getDueOnlyVocabularies({int? topicId}) async {
    final all = await getVocabulariesForReview(topicId: topicId);
    return all.where((v) => v.isDue).toList();
  }
}
