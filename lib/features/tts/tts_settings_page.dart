import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/cloud_tts_settings.dart';
import 'tts_providers.dart';

class TtsSettingsPage extends ConsumerStatefulWidget {
  const TtsSettingsPage({super.key});

  @override
  ConsumerState<TtsSettingsPage> createState() => _TtsSettingsPageState();
}

class _TtsSettingsPageState extends ConsumerState<TtsSettingsPage> {
  final TextEditingController _baseUrlController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _voiceController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  bool _initialized = false;

  @override
  void dispose() {
    _baseUrlController.dispose();
    _modelController.dispose();
    _voiceController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(cloudTtsSettingsControllerProvider);

    if (!_initialized && settingsAsync.hasValue) {
      final settings = settingsAsync.value ?? CloudTtsSettings.defaults;
      _baseUrlController.text = settings.baseUrl;
      _modelController.text = settings.model;
      _voiceController.text = settings.voice;
      _apiKeyController.text = settings.apiKey;
      _initialized = true;
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: context.canPop() ? () => context.pop() : null,
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Cloud TTS Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          TextField(
            controller: _baseUrlController,
            decoration: const InputDecoration(
              labelText: 'Base URL',
              hintText: 'https://api.openai.com/v1/audio/speech',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _modelController,
            decoration: const InputDecoration(
              labelText: 'Model',
              hintText: 'gpt-4o-mini-tts',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _voiceController,
            decoration: const InputDecoration(
              labelText: 'Voice',
              hintText: 'alloy',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _apiKeyController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'API Key',
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _save,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final settings = CloudTtsSettings(
      baseUrl: _baseUrlController.text.trim(),
      model: _modelController.text.trim(),
      voice: _voiceController.text.trim(),
      apiKey: _apiKeyController.text.trim(),
    );

    await ref.read(cloudTtsSettingsControllerProvider.notifier).save(settings);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cloud TTS settings saved')),
    );
  }
}
