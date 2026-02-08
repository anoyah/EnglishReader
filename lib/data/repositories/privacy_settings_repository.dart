import 'package:shared_preferences/shared_preferences.dart';

import 'package:read_english/data/models/privacy_settings.dart';

class PrivacySettingsRepository {
  const PrivacySettingsRepository();

  static const String _allowOnlineGenerationKey =
      'privacy_allow_online_generation';
  static const String _allowOnlineTranslationKey =
      'privacy_allow_online_translation';

  Future<PrivacySettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final defaults = PrivacySettings.defaults;
    return PrivacySettings(
      allowOnlineGeneration:
          prefs.getBool(_allowOnlineGenerationKey) ??
              defaults.allowOnlineGeneration,
      allowOnlineTranslation:
          prefs.getBool(_allowOnlineTranslationKey) ??
              defaults.allowOnlineTranslation,
    );
  }

  Future<void> save(PrivacySettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait<bool>([
      prefs.setBool(
        _allowOnlineGenerationKey,
        settings.allowOnlineGeneration,
      ),
      prefs.setBool(
        _allowOnlineTranslationKey,
        settings.allowOnlineTranslation,
      ),
    ]);
  }
}
