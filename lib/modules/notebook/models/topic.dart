class Topic {
  final int? id;
  final String name;
  final String? description;
  final int wordCount;

  Topic({
    this.id,
    required this.name,
    this.description,
    this.wordCount = 0,
  });

  Topic copyWith({
    int? id,
    String? name,
    String? description,
    int? wordCount,
  }) {
    return Topic(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      wordCount: wordCount ?? this.wordCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
    };
  }

  factory Topic.fromMap(Map<String, dynamic> map, {int wordCount = 0}) {
    return Topic(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      wordCount: (map['word_count'] as int?) ?? wordCount,
    );
  }
}
