class ReaderSettings {
  const ReaderSettings({
    required this.fontScale,
    required this.lineHeight,
    required this.isDarkMode,
  });

  static const ReaderSettings defaults = ReaderSettings(
    fontScale: 1.0,
    lineHeight: 1.6,
    isDarkMode: false,
  );

  final double fontScale;
  final double lineHeight;
  final bool isDarkMode;

  ReaderSettings copyWith({
    double? fontScale,
    double? lineHeight,
    bool? isDarkMode,
  }) {
    return ReaderSettings(
      fontScale: fontScale ?? this.fontScale,
      lineHeight: lineHeight ?? this.lineHeight,
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }
}
