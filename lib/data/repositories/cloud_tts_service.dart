import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../models/cloud_tts_settings.dart';

class CloudTtsService {
  CloudTtsService(this._dio);

  final Dio _dio;

  Future<String> synthesizeToFile({
    required CloudTtsSettings settings,
    required String input,
  }) async {
    if (settings.apiKey.trim().isEmpty) {
      throw const FormatException('Missing cloud TTS API key.');
    }

    final response = await _dio.post<List<int>>(
      settings.baseUrl,
      options: Options(
        responseType: ResponseType.bytes,
        headers: <String, dynamic>{
          'Authorization': 'Bearer ${settings.apiKey}',
          'Content-Type': 'application/json',
        },
      ),
      data: <String, dynamic>{
        'model': settings.model,
        'voice': settings.voice,
        'input': input,
        'format': 'mp3',
        'response_format': 'mp3',
      },
    );

    final bytes = response.data;
    if (bytes == null || bytes.isEmpty) {
      throw const FormatException('Cloud TTS returned empty audio data.');
    }

    final tempDir = await getTemporaryDirectory();
    final file = File(
      '${tempDir.path}/tts_${DateTime.now().millisecondsSinceEpoch}.mp3',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }
}
