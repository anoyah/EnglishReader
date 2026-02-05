import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/article.dart';
import '../../data/models/generation_settings.dart';
import '../../data/repositories/article_generation_service.dart';
import '../../data/repositories/generation_settings_repository.dart';

final generationSettingsRepositoryProvider =
    Provider<GenerationSettingsRepository>((ref) {
  return const GenerationSettingsRepository();
});

class GenerationSettingsController extends AsyncNotifier<GenerationSettings> {
  @override
  Future<GenerationSettings> build() {
    return ref.read(generationSettingsRepositoryProvider).load();
  }

  Future<void> save(GenerationSettings settings) async {
    state = AsyncData(settings);
    await ref.read(generationSettingsRepositoryProvider).save(settings);
  }
}

final generationSettingsControllerProvider =
    AsyncNotifierProvider<GenerationSettingsController, GenerationSettings>(
  GenerationSettingsController.new,
);

final dioProvider = Provider<Dio>((ref) {
  return Dio();
});

final articleGenerationServiceProvider =
    Provider<ArticleGenerationService>((ref) {
  final dio = ref.watch(dioProvider);
  return ArticleGenerationService(dio);
});

class GenerationController extends AsyncNotifier<Article?> {
  @override
  Future<Article?> build() async => null;

  Future<Article> generate({
    required GenerationSettings settings,
    required String topic,
    required String level,
    required int paragraphCount,
    String? titleHint,
  }) async {
    state = const AsyncLoading();
    final service = ref.read(articleGenerationServiceProvider);

    try {
      final article = await service.generate(
        settings: settings,
        topic: topic,
        level: level,
        paragraphCount: paragraphCount,
        titleHint: titleHint,
      );
      state = AsyncData(article);
      return article;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}

final generationControllerProvider =
    AsyncNotifierProvider<GenerationController, Article?>(
  GenerationController.new,
);
