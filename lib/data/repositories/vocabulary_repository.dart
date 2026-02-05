import 'package:hive/hive.dart';

import '../models/vocabulary_word.dart';

const String vocabularyBoxName = 'reader_vocabulary';

class VocabularyRepository {
  VocabularyRepository(this._box);

  final Box<dynamic> _box;

  List<VocabularyWord> loadAll() {
    final words = <VocabularyWord>[];

    for (final key in _box.keys) {
      final raw = _box.get(key);
      if (raw is Map) {
        words.add(VocabularyWord.fromMap(raw));
      }
    }

    words.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return words;
  }

  Future<void> addWord({required String word, required String meaning}) async {
    final normalized = word.toLowerCase();
    final entity = VocabularyWord(
      word: normalized,
      meaning: meaning,
      addedAt: DateTime.now(),
    );

    await _box.put(normalized, entity.toMap());
  }

  Future<void> removeWord(String word) {
    return _box.delete(word.toLowerCase());
  }

  bool exists(String word) {
    return _box.containsKey(word.toLowerCase());
  }
}
