import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/cloud_tts_settings.dart';
import '../../data/repositories/cloud_tts_service.dart';
import '../../data/repositories/cloud_tts_settings_repository.dart';

final cloudTtsSettingsRepositoryProvider =
    Provider<CloudTtsSettingsRepository>((ref) {
  return const CloudTtsSettingsRepository();
});

class CloudTtsSettingsController extends AsyncNotifier<CloudTtsSettings> {
  @override
  Future<CloudTtsSettings> build() {
    return ref.read(cloudTtsSettingsRepositoryProvider).load();
  }

  Future<void> save(CloudTtsSettings settings) async {
    state = AsyncData(settings);
    await ref.read(cloudTtsSettingsRepositoryProvider).save(settings);
  }
}

final cloudTtsSettingsControllerProvider =
    AsyncNotifierProvider<CloudTtsSettingsController, CloudTtsSettings>(
  CloudTtsSettingsController.new,
);

final cloudTtsDioProvider = Provider<Dio>((ref) => Dio());

final cloudTtsServiceProvider = Provider<CloudTtsService>((ref) {
  return CloudTtsService(ref.watch(cloudTtsDioProvider));
});
