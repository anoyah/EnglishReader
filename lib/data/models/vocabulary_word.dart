class VocabularyWord {
  const VocabularyWord({
    required this.word,
    required this.meaning,
    required this.addedAt,
  });

  final String word;
  final String meaning;
  final DateTime addedAt;

  factory VocabularyWord.fromMap(Map<dynamic, dynamic> map) {
    return VocabularyWord(
      word: map['word'] as String,
      meaning: map['meaning'] as String,
      addedAt: DateTime.fromMillisecondsSinceEpoch(map['addedAt'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'word': word,
      'meaning': meaning,
      'addedAt': addedAt.millisecondsSinceEpoch,
    };
  }
}
