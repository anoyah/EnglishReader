class Article {
  const Article({
    required this.id,
    required this.title,
    required this.level,
    required this.paragraphs,
    this.translations,
    this.isGenerated = false,
    this.createdAt,
  });

  final String id;
  final String title;
  final String level;
  final List<String> paragraphs;
  final List<String>? translations;
  final bool isGenerated;
  final DateTime? createdAt;

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['id'] as String,
      title: json['title'] as String,
      level: json['level'] as String,
      paragraphs: (json['paragraphs'] as List<dynamic>)
          .map((item) => item as String)
          .toList(),
      translations: (json['translations'] as List<dynamic>?)
          ?.map((item) => item as String)
          .toList(),
      isGenerated: json['isGenerated'] as bool? ?? false,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
    );
  }

  factory Article.fromMap(Map<dynamic, dynamic> map) {
    return Article(
      id: map['id'] as String,
      title: map['title'] as String,
      level: map['level'] as String,
      paragraphs: (map['paragraphs'] as List<dynamic>)
          .map((item) => item as String)
          .toList(),
      translations: (map['translations'] as List<dynamic>?)
          ?.map((item) => item as String)
          .toList(),
      isGenerated: map['isGenerated'] as bool? ?? true,
      createdAt: map['createdAt'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'level': level,
      'paragraphs': paragraphs,
      'translations': translations,
      'isGenerated': isGenerated,
      'createdAt': createdAt?.millisecondsSinceEpoch,
    };
  }
}
