import 'package:dio/dio.dart';

enum DictionarySourceType { auto, localOnly, apiOnly }

abstract class DictionarySource {
  Future<String?> lookup(String normalizedWord);
}

abstract class TranslationSource {
  Future<String?> translateToChinese({
    required String normalizedWord,
    String? englishDefinition,
  });
}

class LocalDictionarySource implements DictionarySource {
  const LocalDictionarySource();

  static const Map<String, String> _dictionary = <String, String>{
    'habit': 'A routine behavior that is repeated regularly.',
    'focus': 'To direct attention to one thing and avoid distractions.',
    'improve': 'To become better or make something better.',
    'journey': 'The process of moving from one stage to another over time.',
    'curious': 'Interested in learning or knowing more about something.',
    'practice': 'Repeated action to build a skill.',
    'growth': 'Steady development or progress over time.',
  };

  @override
  Future<String?> lookup(String normalizedWord) async {
    return _dictionary[normalizedWord];
  }
}

class LocalTranslationSource implements TranslationSource {
  const LocalTranslationSource();

  static const Map<String, String> _zh = <String, String>{
    'habit': '习惯；长期形成的行为模式。',
    'focus': '专注；把注意力集中在某件事上。',
    'improve': '改进；变得更好或让某事变得更好。',
    'journey': '旅程；一个逐步发展的过程。',
    'curious': '好奇的；对新事物有探索兴趣。',
    'practice': '练习；通过重复来提升技能。',
    'growth': '成长；持续的发展和进步。',
  };

  @override
  Future<String?> translateToChinese({
    required String normalizedWord,
    String? englishDefinition,
  }) async {
    return _zh[normalizedWord];
  }
}

class DictionaryApiSource implements DictionarySource {
  DictionaryApiSource(this._dio);

  final Dio _dio;

  @override
  Future<String?> lookup(String normalizedWord) async {
    try {
      final response = await _dio.get<dynamic>(
        'https://api.dictionaryapi.dev/api/v2/entries/en/$normalizedWord',
      );
      return _extractDefinition(response.data);
    } on DioException {
      return null;
    } on FormatException {
      return null;
    }
  }

  String? _extractDefinition(dynamic data) {
    if (data is! List || data.isEmpty) {
      throw const FormatException('Unexpected dictionary API response.');
    }
    final firstEntry = data.first;
    if (firstEntry is! Map<String, dynamic>) {
      throw const FormatException('Unexpected dictionary API entry.');
    }
    final meanings = firstEntry['meanings'];
    if (meanings is! List || meanings.isEmpty) {
      return null;
    }
    for (final meaning in meanings) {
      if (meaning is! Map<String, dynamic>) {
        continue;
      }
      final partOfSpeech = (meaning['partOfSpeech'] as String?)?.trim();
      final definitions = meaning['definitions'];
      if (definitions is! List || definitions.isEmpty) {
        continue;
      }
      final firstDefinition = definitions.first;
      if (firstDefinition is! Map<String, dynamic>) {
        continue;
      }
      final definition = (firstDefinition['definition'] as String?)?.trim();
      if (definition == null || definition.isEmpty) {
        continue;
      }
      return partOfSpeech == null || partOfSpeech.isEmpty
          ? definition
          : '$partOfSpeech: $definition';
    }
    return null;
  }
}

class MyMemoryTranslationSource implements TranslationSource {
  MyMemoryTranslationSource(this._dio);

  final Dio _dio;

  @override
  Future<String?> translateToChinese({
    required String normalizedWord,
    String? englishDefinition,
  }) async {
    final query = (englishDefinition ?? normalizedWord).trim();
    if (query.isEmpty) {
      return null;
    }
    try {
      final response = await _dio.get<dynamic>(
        'https://api.mymemory.translated.net/get',
        queryParameters: <String, dynamic>{'q': query, 'langpair': 'en|zh-CN'},
      );
      if (response.data is! Map<String, dynamic>) {
        return null;
      }
      final root = response.data as Map<String, dynamic>;
      final responseData = root['responseData'];
      if (responseData is! Map<String, dynamic>) {
        return null;
      }
      final translated = (responseData['translatedText'] as String?)?.trim();
      if (translated == null || translated.isEmpty) {
        return null;
      }
      return translated;
    } on DioException {
      return null;
    }
  }
}

class DictionaryRepository {
  DictionaryRepository({
    required this.sourceType,
    required DictionarySource localSource,
    required DictionarySource apiSource,
    required TranslationSource localTranslationSource,
    required TranslationSource remoteTranslationSource,
  }) : _localSource = localSource,
       _apiSource = apiSource,
       _localTranslationSource = localTranslationSource,
       _remoteTranslationSource = remoteTranslationSource;

  final DictionarySourceType sourceType;
  final DictionarySource _localSource;
  final DictionarySource _apiSource;
  final TranslationSource _localTranslationSource;
  final TranslationSource _remoteTranslationSource;
  final Map<String, String> _cache = <String, String>{};

  Future<String> lookup(String word) async {
    final normalized = word.toLowerCase().trim();
    if (normalized.isEmpty) {
      return 'No definition available.';
    }
    final cached = _cache[normalized];
    if (cached != null) {
      return cached;
    }

    String? result;
    switch (sourceType) {
      case DictionarySourceType.auto:
        result =
            await _apiSource.lookup(normalized) ??
            await _localSource.lookup(normalized);
        break;
      case DictionarySourceType.localOnly:
        result = await _localSource.lookup(normalized);
        break;
      case DictionarySourceType.apiOnly:
        result = await _apiSource.lookup(normalized);
        break;
    }

    final finalValue = await _formatDefinition(
      normalizedWord: normalized,
      englishDefinition: result,
    );
    _cache[normalized] = finalValue;
    return finalValue;
  }

  Future<String> _formatDefinition({
    required String normalizedWord,
    required String? englishDefinition,
  }) async {
    if (englishDefinition == null || englishDefinition.isEmpty) {
      return '暂无释义\n\nNo definition found for "$normalizedWord".';
    }
    final chinese =
        await _remoteTranslationSource.translateToChinese(
          normalizedWord: normalizedWord,
          englishDefinition: englishDefinition,
        ) ??
        await _localTranslationSource.translateToChinese(
          normalizedWord: normalizedWord,
          englishDefinition: englishDefinition,
        );
    if (chinese == null || chinese.isEmpty) {
      return '暂无释义\n\n$englishDefinition';
    }
    return '$chinese\n\n$englishDefinition';
  }
}
