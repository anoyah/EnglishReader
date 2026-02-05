import 'package:shared_preferences/shared_preferences.dart';

import '../models/generation_settings.dart';

class GenerationSettingsRepository {
  const GenerationSettingsRepository();

  static const String _baseUrlKey = 'generation_base_url';
  static const String _modelKey = 'generation_model';
  static const String _apiKeyKey = 'generation_api_key';

  Future<GenerationSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final defaults = GenerationSettings.defaults;

    return GenerationSettings(
      baseUrl: prefs.getString(_baseUrlKey) ?? defaults.baseUrl,
      model: prefs.getString(_modelKey) ?? defaults.model,
      apiKey: prefs.getString(_apiKeyKey) ?? defaults.apiKey,
    );
  }

  Future<void> save(GenerationSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait<bool>([
      prefs.setString(_baseUrlKey, settings.baseUrl),
      prefs.setString(_modelKey, settings.model),
      prefs.setString(_apiKeyKey, settings.apiKey),
    ]);
  }
}
