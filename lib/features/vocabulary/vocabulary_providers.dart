import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../data/models/vocabulary_word.dart';
import '../../data/repositories/dictionary_repository.dart';
import '../../data/repositories/vocabulary_repository.dart';

final dictionaryDioProvider = Provider<Dio>((ref) => Dio());

final dictionarySourceTypeProvider =
    Provider<DictionarySourceType>((ref) => DictionarySourceType.auto);

final dictionaryRepositoryProvider = Provider<DictionaryRepository>((ref) {
  return DictionaryRepository(
    sourceType: ref.watch(dictionarySourceTypeProvider),
    localSource: const LocalDictionarySource(),
    apiSource: DictionaryApiSource(ref.watch(dictionaryDioProvider)),
    localTranslationSource: const LocalTranslationSource(),
    remoteTranslationSource:
        MyMemoryTranslationSource(ref.watch(dictionaryDioProvider)),
  );
});

final vocabularyRepositoryProvider = Provider<VocabularyRepository>((ref) {
  final box = Hive.box<dynamic>(vocabularyBoxName);
  return VocabularyRepository(box);
});

class VocabularyController extends AsyncNotifier<List<VocabularyWord>> {
  @override
  Future<List<VocabularyWord>> build() async {
    return ref.read(vocabularyRepositoryProvider).loadAll();
  }

  Future<void> toggleWord({
    required String word,
    required String meaning,
  }) async {
    final repository = ref.read(vocabularyRepositoryProvider);
    final normalized = word.toLowerCase();

    if (repository.exists(normalized)) {
      await repository.removeWord(normalized);
    } else {
      await repository.addWord(word: normalized, meaning: meaning);
    }

    state = AsyncData(repository.loadAll());
  }

  Future<void> removeWord(String word) async {
    await ref.read(vocabularyRepositoryProvider).removeWord(word);
    state = AsyncData(ref.read(vocabularyRepositoryProvider).loadAll());
  }
}

final vocabularyControllerProvider =
    AsyncNotifierProvider<VocabularyController, List<VocabularyWord>>(
  VocabularyController.new,
);

final isWordSavedProvider = Provider.family<bool, String>((ref, word) {
  final normalized = word.toLowerCase();
  final words = ref.watch(vocabularyControllerProvider).asData?.value ??
      const <VocabularyWord>[];
  return words.any((item) => item.word == normalized);
});
