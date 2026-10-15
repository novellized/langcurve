class CurveDataPoint {
  final String date; // YYYY-MM-DD
  final int wordCount;
  final double avgEasiness;
  final int correctReviews;
  final int wrongReviews;

  CurveDataPoint({
    required this.date,
    required this.wordCount,
    required this.avgEasiness,
    required this.correctReviews,
    required this.wrongReviews,
  });

  factory CurveDataPoint.fromMap(Map<String, dynamic> map) {
    return CurveDataPoint(
      date: map['date'] as String,
      wordCount: (map['word_count'] as int?) ?? 0,
      avgEasiness: (map['avg_easiness'] as num?)?.toDouble() ?? 0.0,
      correctReviews: (map['correct_count'] as int?) ?? 0,
      wrongReviews: (map['wrong_count'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'word_count': wordCount,
      'avg_easiness': avgEasiness,
      'correct_count': correctReviews,
      'wrong_count': wrongReviews,
    };
  }
}
