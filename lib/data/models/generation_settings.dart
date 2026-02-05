class GenerationSettings {
  const GenerationSettings({
    required this.baseUrl,
    required this.model,
    required this.apiKey,
  });

  static const GenerationSettings defaults = GenerationSettings(
    baseUrl: 'https://api.deepseek.com/chat/completions',
    model: 'deepseek-chat',
    apiKey: '',
  );

  final String baseUrl;
  final String model;
  final String apiKey;

  GenerationSettings copyWith({
    String? baseUrl,
    String? model,
    String? apiKey,
  }) {
    return GenerationSettings(
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
      apiKey: apiKey ?? this.apiKey,
    );
  }
}
