import '../../../core/database/database_helper.dart';
import '../models/curve_data_point.dart';

class TrackingService {
  final DatabaseHelper _dbHelper;

  TrackingService({DatabaseHelper? dbHelper}) : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  /// Fetches time-series data points for drawing user's LangCurve learning curve
  Future<List<CurveDataPoint>> getLearningCurve({int userId = 1}) async {
    final db = await _dbHelper.database;

    final List<Map<String, dynamic>> rows = await db.rawQuery('''
      SELECT 
        substr(created_at, 1, 10) as date,
        COUNT(*) as word_count,
        ROUND(AVG(easiness), 2) as avg_easiness,
        SUM(CASE WHEN quality >= 3 THEN 1 ELSE 0 END) as correct_count,
        SUM(CASE WHEN quality < 3 THEN 1 ELSE 0 END) as wrong_count
      FROM review_logs
      WHERE user_id = ?
      GROUP BY date
      ORDER BY date ASC
    ''', [userId]);

    return rows.map((r) => CurveDataPoint.fromMap(r)).toList();
  }
}
