import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import 'package:read_english/data/models/reader_progress.dart';
import 'package:read_english/data/models/reader_settings.dart';
import 'package:read_english/data/repositories/progress_repository.dart';
import 'package:read_english/data/repositories/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return const SettingsRepository();
});

final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  final box = Hive.box<dynamic>(progressBoxName);
  return ProgressRepository(box);
});

class ReaderSettingsController extends AsyncNotifier<ReaderSettings> {
  @override
  Future<ReaderSettings> build() {
    return ref.read(settingsRepositoryProvider).loadSettings();
  }

  Future<void> setFontScale(double value) async {
    await _save(state.asData?.value.copyWith(fontScale: value));
  }

  Future<void> setLineHeight(double value) async {
    await _save(state.asData?.value.copyWith(lineHeight: value));
  }

  Future<void> setDarkMode(bool isDark) async {
    await _save(state.asData?.value.copyWith(isDarkMode: isDark));
  }

  Future<void> setShowTranslationByDefault(bool value) async {
    await _save(state.asData?.value.copyWith(showTranslationByDefault: value));
  }

  Future<void> _save(ReaderSettings? next) async {
    final current = next ?? ReaderSettings.defaults;
    state = AsyncData(current);
    await ref.read(settingsRepositoryProvider).saveSettings(current);
  }
}

final readerSettingsControllerProvider =
    AsyncNotifierProvider<ReaderSettingsController, ReaderSettings>(
  ReaderSettingsController.new,
);

class ProgressController extends AsyncNotifier<Map<String, ReaderProgress>> {
  @override
  Future<Map<String, ReaderProgress>> build() async {
    return ref.read(progressRepositoryProvider).loadAll();
  }

  Future<void> saveProgress(String articleId, double offset) async {
    await ref
        .read(progressRepositoryProvider)
        .saveProgress(articleId: articleId, offset: offset);

    final next = Map<String, ReaderProgress>.from(
      state.asData?.value ?? <String, ReaderProgress>{},
    );
    next[articleId] = ReaderProgress(
      articleId: articleId,
      offset: offset,
      updatedAt: DateTime.now(),
    );
    state = AsyncData(next);
  }
}

final progressControllerProvider =
    AsyncNotifierProvider<ProgressController, Map<String, ReaderProgress>>(
  ProgressController.new,
);
