import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import '../../data/models/article.dart';
import '../../data/models/reader_settings.dart';
import '../../shared/utils/word_tokenizer.dart';
import '../library/library_providers.dart';
import '../tts/tts_providers.dart';
import '../vocabulary/vocabulary_providers.dart';
import 'reader_providers.dart';
import 'reader_settings_sheet.dart';

class ReaderPage extends ConsumerStatefulWidget {
  const ReaderPage({super.key, required this.articleId});

  final String articleId;

  @override
  ConsumerState<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends ConsumerState<ReaderPage> {
  static const double _expandedHeaderHeight = 156;

  late final ScrollController _scrollController;
  late final AudioPlayer _audioPlayer;
  Timer? _saveDebounce;
  bool _hasRestoredOffset = false;
  bool _showTranslation = false;
  bool _isSpeaking = false;
  String? _currentAudioPath;
  bool _showCollapsedTitle = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _audioPlayer = AudioPlayer();
    _audioPlayer.playerStateStream.listen((state) {
      if (!mounted) {
        return;
      }
      final isNowSpeaking =
          state.processingState != ProcessingState.completed && state.playing;
      if (_isSpeaking != isNowSpeaking) {
        setState(() {
          _isSpeaking = isNowSpeaking;
        });
      }
    });
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _audioPlayer.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!_scrollController.hasClients) {
        return;
      }
      ref
          .read(progressControllerProvider.notifier)
          .saveProgress(widget.articleId, _scrollController.offset);
    });

    if (!_scrollController.hasClients) {
      return;
    }
    final shouldShowCollapsedTitle =
        _scrollController.offset > (_expandedHeaderHeight - kToolbarHeight - 8);
    if (shouldShowCollapsedTitle != _showCollapsedTitle && mounted) {
      setState(() {
        _showCollapsedTitle = shouldShowCollapsedTitle;
      });
    }
  }

  Future<void> _showWordSheet(BuildContext context, String word) async {
    final definition =
        await ref.read(dictionaryRepositoryProvider).lookup(word);
    if (!context.mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final isSaved = ref.watch(isWordSavedProvider(word));

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    word,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(definition),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () {
                      ref
                          .read(vocabularyControllerProvider.notifier)
                          .toggleWord(word: word, meaning: definition);
                      context.pop();
                    },
                    icon: Icon(
                      isSaved ? Icons.bookmark_remove : Icons.bookmark_add,
                    ),
                    label: Text(
                      isSaved ? 'Remove from vocabulary' : 'Save to vocabulary',
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _toggleSpeak(Article article) async {
    if (_isSpeaking) {
      await _audioPlayer.stop();
      return;
    }

    final settings = ref.read(cloudTtsSettingsControllerProvider).asData?.value;
    if (settings == null || settings.apiKey.trim().isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先配置 Cloud TTS API Key')),
      );
      context.push('/tts-settings');
      return;
    }

    final text = article.paragraphs.join('\n\n').trim();
    if (text.isEmpty) {
      return;
    }

    try {
      final filePath = await ref.read(cloudTtsServiceProvider).synthesizeToFile(
            settings: settings,
            input: text,
          );
      _currentAudioPath = filePath;
      await _audioPlayer.setFilePath(filePath);
      await _audioPlayer.play();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('云端朗读失败: $error')),
      );
    }
  }

  Future<void> _replay() async {
    final path = _currentAudioPath;
    if (path == null) {
      return;
    }
    await _audioPlayer.setFilePath(path);
    await _audioPlayer.play();
  }

  void _openReaderSettings() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => const ReaderSettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final articleAsync = ref.watch(articleByIdProvider(widget.articleId));
    final settings =
        ref.watch(readerSettingsControllerProvider).asData?.value ??
            ReaderSettings.defaults;

    final progress =
        ref.watch(progressControllerProvider).asData?.value[widget.articleId];
    if (!_hasRestoredOffset && progress != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) {
          return;
        }

        final maxOffset = _scrollController.position.maxScrollExtent;
        final target = progress.offset.clamp(0, maxOffset).toDouble();
        _scrollController.jumpTo(target);
      });
      _hasRestoredOffset = true;
    }

    return articleAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(title: const Text('Reader')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Failed to open article: $error'),
          ),
        ),
      ),
      data: (article) {
        if (article == null) {
          return const Scaffold(
            body: Center(child: Text('Article not found.')),
          );
        }

        return Scaffold(
          floatingActionButton: _hasTranslations(article)
              ? FloatingActionButton(
                  tooltip: _showTranslation
                      ? 'Hide translation'
                      : 'Show translation',
                  onPressed: () {
                    setState(() {
                      _showTranslation = !_showTranslation;
                    });
                  },
                  child: Icon(
                    _showTranslation ? Icons.translate : Icons.g_translate,
                  ),
                )
              : null,
          body: CustomScrollView(
            controller: _scrollController,
            slivers: <Widget>[
              SliverAppBar(
                pinned: true,
                expandedHeight: _expandedHeaderHeight,
                toolbarHeight: 56,
                leading: IconButton(
                  tooltip: 'Back',
                  onPressed: context.canPop() ? () => context.pop() : null,
                  icon: const Icon(Icons.arrow_back),
                ),
                title: AnimatedOpacity(
                  opacity: _showCollapsedTitle ? 1 : 0,
                  duration: const Duration(milliseconds: 160),
                  child: Text(
                    article.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                actions: <Widget>[
                  PopupMenuButton<String>(
                    tooltip: 'More actions',
                    onSelected: (value) {
                      if (value == 'toggle_speak') {
                        _toggleSpeak(article);
                      } else if (value == 'replay') {
                        _replay();
                      } else if (value == 'reader_settings') {
                        _openReaderSettings();
                      } else if (value == 'tts_settings') {
                        context.push('/tts-settings');
                      } else if (value == 'vocabulary') {
                        context.push('/vocabulary');
                      }
                    },
                    itemBuilder: (context) => <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        value: 'toggle_speak',
                        child:
                            Text(_isSpeaking ? 'Stop reading' : 'Read aloud'),
                      ),
                      if (_currentAudioPath != null)
                        const PopupMenuItem<String>(
                          value: 'replay',
                          child: Text('Replay'),
                        ),
                      const PopupMenuItem<String>(
                        value: 'reader_settings',
                        child: Text('Reader settings'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'tts_settings',
                        child: Text('Cloud TTS settings'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'vocabulary',
                        child: Text('Vocabulary'),
                      ),
                    ],
                    icon: const Icon(Icons.more_vert),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 52, 72, 16),
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              article.title,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    height: 1.2,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'English Reading • CEFR ${article.level}',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                sliver: SliverList.builder(
                  itemCount: article.paragraphs.length,
                  itemBuilder: (context, index) {
                    final paragraph = article.paragraphs[index];
                    final translation = _showTranslation
                        ? _translationFor(article, index)
                        : null;
                    return _ParagraphView(
                      text: paragraph,
                      translation: translation?.trim().isEmpty == true
                          ? null
                          : translation,
                      settings: settings,
                      onWordTap: (word) => _showWordSheet(context, word),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ParagraphView extends StatelessWidget {
  const _ParagraphView({
    required this.text,
    required this.translation,
    required this.settings,
    required this.onWordTap,
  });

  final String text;
  final String? translation;
  final ReaderSettings settings;
  final ValueChanged<String> onWordTap;

  @override
  Widget build(BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontSize: 18 * settings.fontScale,
          height: settings.lineHeight,
        );

    final tokens = tokenizeParagraph(text);

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            children: tokens.map((token) {
              if (!token.isWord) {
                return Text(token.text, style: baseStyle);
              }

              final normalized = normalizeWord(token.text);
              return InkWell(
                borderRadius: BorderRadius.circular(3),
                onTap: normalized.isEmpty ? null : () => onWordTap(normalized),
                child: Text(
                  token.text,
                  style: baseStyle?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
          if (translation != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              translation!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

bool _hasTranslations(Article? article) {
  if (article == null) {
    return false;
  }
  final translations = article.translations;
  if (translations == null || translations.isEmpty) {
    return false;
  }
  return translations.any((item) => item.trim().isNotEmpty);
}

String? _translationFor(Article article, int index) {
  final translations = article.translations;
  if (translations == null || index < 0 || index >= translations.length) {
    return null;
  }
  return translations[index];
}
