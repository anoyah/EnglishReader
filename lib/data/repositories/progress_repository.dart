import 'package:hive/hive.dart';

import 'package:read_english/data/models/reader_progress.dart';

const String progressBoxName = 'reader_progress';

class ProgressRepository {
  ProgressRepository(this._box);

  final Box<dynamic> _box;

  Map<String, ReaderProgress> loadAll() {
    final result = <String, ReaderProgress>{};

    for (final key in _box.keys) {
      final raw = _box.get(key);
      if (raw is Map) {
        result[key as String] = ReaderProgress.fromMap(raw);
      }
    }

    return result;
  }

  Future<void> saveProgress({
    required String articleId,
    required double offset,
  }) async {
    final progress = ReaderProgress(
      articleId: articleId,
      offset: offset,
      updatedAt: DateTime.now(),
    );

    await _box.put(articleId, progress.toMap());
  }
}
