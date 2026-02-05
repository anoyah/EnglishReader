import 'dart:convert';

import 'package:dio/dio.dart';

import '../models/article.dart';
import '../models/generation_settings.dart';

class ArticleGenerationService {
  ArticleGenerationService(this._dio);

  final Dio _dio;

  Future<Article> generate({
    required GenerationSettings settings,
    required String topic,
    required String level,
    required int paragraphCount,
    String? titleHint,
  }) async {
    final systemPrompt = _buildSystemPrompt();
    final userPrompt = _buildUserPrompt(
      topic: topic,
      level: level,
      paragraphCount: paragraphCount,
      titleHint: titleHint,
    );

    final response = await _dio.post<dynamic>(
      settings.baseUrl,
      options: Options(
        headers: <String, dynamic>{
          'Authorization': 'Bearer ${settings.apiKey}',
          'Content-Type': 'application/json',
        },
      ),
      data: <String, dynamic>{
        'model': settings.model,
        'messages': <Map<String, String>>[
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ],
        'temperature': 0.7,
      },
    );

    final content = _extractContent(response.data);
    final payload = _decodeJson(content);

    final title = (payload['title'] as String?)?.trim().isNotEmpty == true
        ? payload['title'] as String
        : (titleHint?.trim().isNotEmpty == true
            ? titleHint!.trim()
            : 'Generated Article');

    final paragraphs = _readStringList(payload['paragraphs']);
    final translations = _readStringList(payload['translations']);

    if (paragraphs.isEmpty) {
      throw const FormatException('Generated response missing paragraphs.');
    }

    final alignedTranslations = translations.isEmpty
        ? null
        : _alignTranslations(paragraphs, translations);

    return Article(
      id: 'gen_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      level: level,
      paragraphs: paragraphs,
      translations: alignedTranslations,
      isGenerated: true,
      createdAt: DateTime.now(),
    );
  }

  String _buildSystemPrompt() {
    return 'You are an assistant that writes short English reading articles '
        'for language learners. Always respond with a pure JSON object. '
        'No markdown, no code fences.';
  }

  String _buildUserPrompt({
    required String topic,
    required String level,
    required int paragraphCount,
    String? titleHint,
  }) {
    final titleLine = titleHint?.trim().isNotEmpty == true
        ? 'Title hint: ${titleHint!.trim()}.'
        : 'Generate a suitable title.';

    return 'Write an English article for learners at CEFR level $level. '
        'Topic: $topic. '
        'Paragraphs: $paragraphCount. '
        '$titleLine '
        'Return JSON with keys: '
        'title (string), paragraphs (array of strings), translations (array of strings). '
        'Each translation must be the Chinese translation of the paragraph with the same index.';
  }

  String _extractContent(dynamic data) {
    if (data is Map<String, dynamic>) {
      final choices = data['choices'];
      if (choices is List && choices.isNotEmpty) {
        final first = choices.first;
        if (first is Map<String, dynamic>) {
          final message = first['message'];
          if (message is Map<String, dynamic>) {
            final content = message['content'];
            if (content is String) {
              return content;
            }
          }
        }
      }
    }
    throw const FormatException('Unexpected API response format.');
  }

  Map<String, dynamic> _decodeJson(String content) {
    final trimmed = content.trim();
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      return jsonDecode(trimmed) as Map<String, dynamic>;
    }

    final start = trimmed.indexOf('{');
    final end = trimmed.lastIndexOf('}');
    if (start >= 0 && end > start) {
      final slice = trimmed.substring(start, end + 1);
      return jsonDecode(slice) as Map<String, dynamic>;
    }

    throw const FormatException('No JSON object found in response.');
  }

  List<String> _readStringList(dynamic value) {
    if (value is List) {
      return value
          .whereType<String>()
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return <String>[];
  }

  List<String> _alignTranslations(
    List<String> paragraphs,
    List<String> translations,
  ) {
    if (translations.length == paragraphs.length) {
      return translations;
    }

    final padded = List<String>.from(translations);
    while (padded.length < paragraphs.length) {
      padded.add('');
    }

    return padded.take(paragraphs.length).toList();
  }
}
