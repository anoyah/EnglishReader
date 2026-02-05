class ReaderProgress {
  const ReaderProgress({
    required this.articleId,
    required this.offset,
    required this.updatedAt,
  });

  final String articleId;
  final double offset;
  final DateTime updatedAt;

  factory ReaderProgress.fromMap(Map<dynamic, dynamic> map) {
    return ReaderProgress(
      articleId: map['articleId'] as String,
      offset: (map['offset'] as num).toDouble(),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'articleId': articleId,
      'offset': offset,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }
}
