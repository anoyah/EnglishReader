class PrivacySettings {
  const PrivacySettings({
    required this.allowOnlineGeneration,
    required this.allowOnlineTranslation,
  });

  static const PrivacySettings defaults = PrivacySettings(
    allowOnlineGeneration: false,
    allowOnlineTranslation: false,
  );

  final bool allowOnlineGeneration;
  final bool allowOnlineTranslation;

  PrivacySettings copyWith({
    bool? allowOnlineGeneration,
    bool? allowOnlineTranslation,
  }) {
    return PrivacySettings(
      allowOnlineGeneration:
          allowOnlineGeneration ?? this.allowOnlineGeneration,
      allowOnlineTranslation:
          allowOnlineTranslation ?? this.allowOnlineTranslation,
    );
  }
}
