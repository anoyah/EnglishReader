class ReaderSettings {
  const ReaderSettings({
    required this.fontScale,
    required this.lineHeight,
    required this.isDarkMode,
    required this.showTranslationByDefault,
  });

  static const ReaderSettings defaults = ReaderSettings(
    fontScale: 1.0,
    lineHeight: 1.6,
    isDarkMode: false,
    showTranslationByDefault: false,
  );

  final double fontScale;
  final double lineHeight;
  final bool isDarkMode;
  final bool showTranslationByDefault;

  ReaderSettings copyWith({
    double? fontScale,
    double? lineHeight,
    bool? isDarkMode,
    bool? showTranslationByDefault,
  }) {
    return ReaderSettings(
      fontScale: fontScale ?? this.fontScale,
      lineHeight: lineHeight ?? this.lineHeight,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      showTranslationByDefault:
          showTranslationByDefault ?? this.showTranslationByDefault,
    );
  }
}
