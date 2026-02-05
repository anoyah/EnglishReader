import 'package:shared_preferences/shared_preferences.dart';

import '../models/cloud_tts_settings.dart';

class CloudTtsSettingsRepository {
  const CloudTtsSettingsRepository();

  static const String _baseUrlKey = 'cloud_tts_base_url';
  static const String _modelKey = 'cloud_tts_model';
  static const String _apiKeyKey = 'cloud_tts_api_key';
  static const String _voiceKey = 'cloud_tts_voice';

  Future<CloudTtsSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final defaults = CloudTtsSettings.defaults;

    return CloudTtsSettings(
      baseUrl: prefs.getString(_baseUrlKey) ?? defaults.baseUrl,
      model: prefs.getString(_modelKey) ?? defaults.model,
      apiKey: prefs.getString(_apiKeyKey) ?? defaults.apiKey,
      voice: prefs.getString(_voiceKey) ?? defaults.voice,
    );
  }

  Future<void> save(CloudTtsSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait<bool>([
      prefs.setString(_baseUrlKey, settings.baseUrl),
      prefs.setString(_modelKey, settings.model),
      prefs.setString(_apiKeyKey, settings.apiKey),
      prefs.setString(_voiceKey, settings.voice),
    ]);
  }
}
