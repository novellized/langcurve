class Vocabulary {
  final int? id;
  final int topicId;
  final String word;
  final String definition;
  final String partOfSpeech;
  final String? phoneticUk;
  final String? audioUrlUk;
  final String? phoneticUs;
  final String? audioUrlUs;
  final String? userExample;
  final double easiness;
  final int interval;
  final int repetitions;
  final DateTime dueDate;
  final int correctCount;
  final int wrongCount;
  final String? cefrLevel;
  final String? synonyms;
  final String? antonyms;

  Vocabulary({
    this.id,
    required this.topicId,
    required this.word,
    this.definition = '',
    this.partOfSpeech = '',
    this.phoneticUk,
    this.audioUrlUk,
    this.phoneticUs,
    this.audioUrlUs,
    this.userExample,
    this.easiness = 2.5,
    this.interval = 0,
    this.repetitions = 0,
    DateTime? dueDate,
    this.correctCount = 0,
    this.wrongCount = 0,
    this.cefrLevel,
    this.synonyms,
    this.antonyms,
  }) : dueDate = dueDate ?? DateTime.now();

  bool get isDue => dueDate.isBefore(DateTime.now());

  String get countdownText {
    final now = DateTime.now();
    if (dueDate.isBefore(now) || dueDate.isAtSameMomentAs(now)) {
      return 'Due now';
    }
    final diff = dueDate.difference(now);
    final hours = (diff.inMinutes / 60).ceil();
    if (hours <= 24) {
      return 'In $hours hour${hours > 1 ? 's' : ''}';
    }
    final days = (hours / 24).ceil();
    return 'In $days day${days > 1 ? 's' : ''}';
  }

  Vocabulary copyWith({
    int? id,
    int? topicId,
    String? word,
    String? definition,
    String? partOfSpeech,
    String? phoneticUk,
    String? audioUrlUk,
    String? phoneticUs,
    String? audioUrlUs,
    String? userExample,
    double? easiness,
    int? interval,
    int? repetitions,
    DateTime? dueDate,
    int? correctCount,
    int? wrongCount,
    String? cefrLevel,
    String? synonyms,
    String? antonyms,
  }) {
    return Vocabulary(
      id: id ?? this.id,
      topicId: topicId ?? this.topicId,
      word: word ?? this.word,
      definition: definition ?? this.definition,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      phoneticUk: phoneticUk ?? this.phoneticUk,
      audioUrlUk: audioUrlUk ?? this.audioUrlUk,
      phoneticUs: phoneticUs ?? this.phoneticUs,
      audioUrlUs: audioUrlUs ?? this.audioUrlUs,
      userExample: userExample ?? this.userExample,
      easiness: easiness ?? this.easiness,
      interval: interval ?? this.interval,
      repetitions: repetitions ?? this.repetitions,
      dueDate: dueDate ?? this.dueDate,
      correctCount: correctCount ?? this.correctCount,
      wrongCount: wrongCount ?? this.wrongCount,
      cefrLevel: cefrLevel ?? this.cefrLevel,
      synonyms: synonyms ?? this.synonyms,
      antonyms: antonyms ?? this.antonyms,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'topic_id': topicId,
      'word': word,
      'definition': definition,
      'part_of_speech': partOfSpeech,
      'phonetic_uk': phoneticUk,
      'audio_url_uk': audioUrlUk,
      'phonetic_us': phoneticUs,
      'audio_url_us': audioUrlUs,
      'user_example': userExample,
      'easiness': easiness,
      'interval': interval,
      'repetitions': repetitions,
      'due_date': dueDate.toIso8601String(),
      'correct_count': correctCount,
      'wrong_count': wrongCount,
      'cefr_level': cefrLevel,
      'synonyms': synonyms,
      'antonyms': antonyms,
    };
  }

  factory Vocabulary.fromMap(Map<String, dynamic> map) {
    return Vocabulary(
      id: map['id'] as int?,
      topicId: map['topic_id'] as int,
      word: map['word'] as String,
      definition: (map['definition'] as String?) ?? '',
      partOfSpeech: (map['part_of_speech'] as String?) ?? '',
      phoneticUk: map['phonetic_uk'] as String?,
      audioUrlUk: map['audio_url_uk'] as String?,
      phoneticUs: map['phonetic_us'] as String?,
      audioUrlUs: map['audio_url_us'] as String?,
      userExample: map['user_example'] as String?,
      easiness: (map['easiness'] as num?)?.toDouble() ?? 2.5,
      interval: (map['interval'] as int?) ?? 0,
      repetitions: (map['repetitions'] as int?) ?? 0,
      dueDate: map['due_date'] != null ? DateTime.parse(map['due_date'] as String) : DateTime.now(),
      correctCount: (map['correct_count'] as int?) ?? 0,
      wrongCount: (map['wrong_count'] as int?) ?? 0,
      cefrLevel: map['cefr_level'] as String?,
      synonyms: map['synonyms'] as String?,
      antonyms: map['antonyms'] as String?,
    );
  }
}
