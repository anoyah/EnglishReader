import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:read_english/data/models/privacy_settings.dart';
import 'package:read_english/data/repositories/privacy_settings_repository.dart';

final privacySettingsRepositoryProvider =
    Provider<PrivacySettingsRepository>((ref) {
  return const PrivacySettingsRepository();
});

class PrivacySettingsController extends AsyncNotifier<PrivacySettings> {
  @override
  Future<PrivacySettings> build() {
    return ref.read(privacySettingsRepositoryProvider).load();
  }

  Future<void> setAllowOnlineGeneration(bool value) async {
    await _save(state.asData?.value.copyWith(allowOnlineGeneration: value));
  }

  Future<void> setAllowOnlineTranslation(bool value) async {
    await _save(state.asData?.value.copyWith(allowOnlineTranslation: value));
  }

  Future<void> _save(PrivacySettings? next) async {
    final current = next ?? PrivacySettings.defaults;
    state = AsyncData(current);
    await ref.read(privacySettingsRepositoryProvider).save(current);
  }
}

final privacySettingsControllerProvider =
    AsyncNotifierProvider<PrivacySettingsController, PrivacySettings>(
  PrivacySettingsController.new,
);
