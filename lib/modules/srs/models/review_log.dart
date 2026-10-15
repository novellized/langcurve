class ReviewLog {
  final int? id;
  final int userId;
  final String word;
  final int quality;
  final double easiness;
  final int interval;
  final DateTime createdAt;

  ReviewLog({
    this.id,
    this.userId = 1,
    required this.word,
    required this.quality,
    required this.easiness,
    required this.interval,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'word': word,
      'quality': quality,
      'easiness': easiness,
      'interval': interval,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ReviewLog.fromMap(Map<String, dynamic> map) {
    return ReviewLog(
      id: map['id'] as int?,
      userId: (map['user_id'] as int?) ?? 1,
      word: map['word'] as String,
      quality: map['quality'] as int,
      easiness: (map['easiness'] as num).toDouble(),
      interval: map['interval'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
