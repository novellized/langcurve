class BbcVideoItem {
  final String id;
  final String title;
  final String desc;
  final String? publishedAt;

  BbcVideoItem({
    required this.id,
    required this.title,
    required this.desc,
    this.publishedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'desc': desc,
      'publishedAt': publishedAt,
    };
  }

  factory BbcVideoItem.fromMap(Map<String, dynamic> map) {
    return BbcVideoItem(
      id: map['id'] as String,
      title: map['title'] as String,
      desc: map['desc'] as String,
      publishedAt: map['publishedAt'] as String?,
    );
  }
}
