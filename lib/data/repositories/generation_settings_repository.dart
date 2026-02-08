import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:read_english/data/models/generation_settings.dart';

class GenerationSettingsRepository {
  const GenerationSettingsRepository();

  static const String _baseUrlKey = 'generation_base_url';
  static const String _modelKey = 'generation_model';
  static const String _apiKeyKey = 'generation_api_key';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  Future<GenerationSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final defaults = GenerationSettings.defaults;
    final secureApiKey = await _secureStorage.read(key: _apiKeyKey);
    final legacyApiKey = prefs.getString(_apiKeyKey);
    final apiKey = secureApiKey ??
        legacyApiKey ??
        defaults.apiKey;

    if (secureApiKey == null && legacyApiKey != null) {
      await _secureStorage.write(key: _apiKeyKey, value: legacyApiKey);
      await prefs.remove(_apiKeyKey);
    }

    return GenerationSettings(
      baseUrl: prefs.getString(_baseUrlKey) ?? defaults.baseUrl,
      model: prefs.getString(_modelKey) ?? defaults.model,
      apiKey: apiKey,
    );
  }

  Future<void> save(GenerationSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await _secureStorage.write(key: _apiKeyKey, value: settings.apiKey);
    await Future.wait<bool>([
      prefs.setString(_baseUrlKey, settings.baseUrl),
      prefs.setString(_modelKey, settings.model),
    ]);
  }
}
