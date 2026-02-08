import 'package:shared_preferences/shared_preferences.dart';

import 'package:read_english/data/models/reader_settings.dart';

class SettingsRepository {
  const SettingsRepository();

  static const String _fontScaleKey = 'reader_font_scale';
  static const String _lineHeightKey = 'reader_line_height';
  static const String _isDarkModeKey = 'reader_is_dark_mode';
  static const String _showTranslationByDefaultKey =
      'reader_show_translation_by_default';

  Future<ReaderSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final defaults = ReaderSettings.defaults;

    return ReaderSettings(
      fontScale: prefs.getDouble(_fontScaleKey) ?? defaults.fontScale,
      lineHeight: prefs.getDouble(_lineHeightKey) ?? defaults.lineHeight,
      isDarkMode: prefs.getBool(_isDarkModeKey) ?? defaults.isDarkMode,
      showTranslationByDefault:
          prefs.getBool(_showTranslationByDefaultKey) ??
              defaults.showTranslationByDefault,
    );
  }

  Future<void> saveSettings(ReaderSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait<bool>([
      prefs.setDouble(_fontScaleKey, settings.fontScale),
      prefs.setDouble(_lineHeightKey, settings.lineHeight),
      prefs.setBool(_isDarkModeKey, settings.isDarkMode),
      prefs.setBool(
        _showTranslationByDefaultKey,
        settings.showTranslationByDefault,
      ),
    ]);
  }
}
