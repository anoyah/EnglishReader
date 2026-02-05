class CloudTtsSettings {
  const CloudTtsSettings({
    required this.baseUrl,
    required this.model,
    required this.apiKey,
    required this.voice,
  });

  static const CloudTtsSettings defaults = CloudTtsSettings(
    baseUrl: 'https://api.openai.com/v1/audio/speech',
    model: 'gpt-4o-mini-tts',
    apiKey: '',
    voice: 'alloy',
  );

  final String baseUrl;
  final String model;
  final String apiKey;
  final String voice;

  CloudTtsSettings copyWith({
    String? baseUrl,
    String? model,
    String? apiKey,
    String? voice,
  }) {
    return CloudTtsSettings(
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
      apiKey: apiKey ?? this.apiKey,
      voice: voice ?? this.voice,
    );
  }
}
