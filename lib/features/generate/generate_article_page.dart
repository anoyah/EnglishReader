import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:read_english/data/models/generation_settings.dart';
import 'package:read_english/features/library/library_providers.dart';
import 'generate_providers.dart';

class GenerateArticlePage extends ConsumerStatefulWidget {
  const GenerateArticlePage({super.key});

  @override
  ConsumerState<GenerateArticlePage> createState() =>
      _GenerateArticlePageState();
}

class _GenerateArticlePageState extends ConsumerState<GenerateArticlePage> {
  static const List<String> _levels = <String>['A2', 'B1', 'B2', 'C1'];
  static const String _aiRandomTopicTag = '__AI_RANDOM_TOPIC__';

  final Random _random = Random();
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _baseUrlController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();

  String _level = 'B1';
  int _paragraphCount = 3;
  bool _initialized = false;
  bool _useAiRandomTopic = false;

  @override
  void dispose() {
    _topicController.dispose();
    _titleController.dispose();
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(generationSettingsControllerProvider);
    final generationState = ref.watch(generationControllerProvider);
    final isLoading = generationState.isLoading;

    if (!_initialized && settingsAsync.hasValue) {
      // 首次进入页面时回填已保存的 API 配置，避免用户重复输入。
      final settings = settingsAsync.value ?? GenerationSettings.defaults;
      _baseUrlController.text = settings.baseUrl;
      _modelController.text = settings.model;
      _apiKeyController.text = settings.apiKey;
      _initialized = true;
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: context.canPop() ? () => context.pop() : null,
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Generate Article'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            TextField(
              controller: _topicController,
              textInputAction: TextInputAction.next,
              onChanged: (value) {
                if (value.trim().isNotEmpty && _useAiRandomTopic) {
                  setState(() {
                    _useAiRandomTopic = false;
                  });
                }
              },
              decoration: const InputDecoration(
                labelText: 'Topic',
                hintText: 'e.g. Morning routines, City parks, Work habits',
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: isLoading ? null : _applyRandomPreset,
                icon: const Icon(Icons.casino_outlined),
                label: const Text('AI Random Topic'),
              ),
            ),
            if (_useAiRandomTopic)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Topic will be decided by AI.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Title (optional)',
                hintText: 'Let the model decide if empty',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              key: ValueKey<String>(_level),
              initialValue: _level,
              decoration: const InputDecoration(labelText: 'CEFR Level'),
              items: const <DropdownMenuItem<String>>[
                DropdownMenuItem(value: 'A2', child: Text('A2')),
                DropdownMenuItem(value: 'B1', child: Text('B1')),
                DropdownMenuItem(value: 'B2', child: Text('B2')),
                DropdownMenuItem(value: 'C1', child: Text('C1')),
              ],
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _level = value;
                });
              },
            ),
            const SizedBox(height: 16),
            Text('Paragraphs: $_paragraphCount'),
            Slider(
              value: _paragraphCount.toDouble(),
              min: 3,
              max: 8,
              divisions: 5,
              label: _paragraphCount.toString(),
              onChanged: (value) {
                setState(() {
                  _paragraphCount = value.round();
                });
              },
            ),
            const SizedBox(height: 12),
            ExpansionTile(
              title: const Text('API Settings'),
              childrenPadding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
              children: <Widget>[
                TextField(
                  controller: _baseUrlController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Base URL',
                    hintText: 'https://api.deepseek.com/chat/completions',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _modelController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Model',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _apiKeyController,
                  decoration: const InputDecoration(
                    labelText: 'API Key',
                  ),
                  obscureText: true,
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: isLoading ? null : _handleGenerate,
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(isLoading ? 'Generating...' : 'Generate'),
            ),
            if (generationState.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  'Error: ${generationState.error}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleGenerate() async {
    final topic = _topicController.text.trim();
    if (topic.isEmpty && !_useAiRandomTopic) {
      _showMessage('Please enter a topic.');
      return;
    }

    final settings = GenerationSettings(
      baseUrl: _baseUrlController.text.trim(),
      model: _modelController.text.trim(),
      apiKey: _apiKeyController.text.trim(),
    );

    if (settings.baseUrl.isEmpty || settings.model.isEmpty) {
      _showMessage('Please fill in base URL and model.');
      return;
    }

    if (settings.apiKey.isEmpty) {
      _showMessage('Please enter an API key.');
      return;
    }

    await ref
        .read(generationSettingsControllerProvider.notifier)
        .save(settings);

    try {
      // AI 随机模式下用约定标记，让服务端 prompt 自行选择主题。
      final article =
          await ref.read(generationControllerProvider.notifier).generate(
                settings: settings,
                topic: _useAiRandomTopic ? _aiRandomTopicTag : topic,
                level: _level,
                paragraphCount: _paragraphCount,
                titleHint: _titleController.text.trim(),
              );

      await ref.read(generatedArticleRepositoryProvider).save(article);
      ref.invalidate(generatedArticlesProvider);
      ref.invalidate(articlesProvider);

      if (!mounted) {
        return;
      }

      _showMessage('Article generated.');
      // 使用替换跳转：返回时回到书单页，而不是回到生成页。
      context.pushReplacement('/reader/${article.id}');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage('Generation failed: $error');
    }
  }

  void _applyRandomPreset() {
    // 仅随机等级和段落数；主题由 AI 自行决定。
    final randomLevel = _levels[_random.nextInt(_levels.length)];
    final randomParagraphCount = 3 + _random.nextInt(6);

    setState(() {
      _topicController.clear();
      _titleController.clear();
      _level = randomLevel;
      _paragraphCount = randomParagraphCount;
      _useAiRandomTopic = true;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
