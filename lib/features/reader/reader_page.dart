import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/reader_settings.dart';
import '../../data/models/article.dart';
import '../../shared/utils/word_tokenizer.dart';
import '../library/library_providers.dart';
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
  late final ScrollController _scrollController;
  Timer? _saveDebounce;
  bool _hasRestoredOffset = false;
  bool _showTranslation = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
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
                        isSaved ? Icons.bookmark_remove : Icons.bookmark_add),
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

  @override
  Widget build(BuildContext context) {
    final articleAsync = ref.watch(articleByIdProvider(widget.articleId));
    final articleData = articleAsync.asData?.value;
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

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: context.canPop() ? () => context.pop() : null,
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Reader'),
        actions: <Widget>[
          if (_hasTranslations(articleData))
            IconButton(
              tooltip:
                  _showTranslation ? 'Hide translation' : 'Show translation',
              onPressed: () {
                setState(() {
                  _showTranslation = !_showTranslation;
                });
              },
              icon: Icon(
                _showTranslation ? Icons.translate : Icons.g_translate,
              ),
            ),
          IconButton(
            tooltip: 'Reader settings',
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                showDragHandle: true,
                builder: (context) => const ReaderSettingsSheet(),
              );
            },
            icon: const Icon(Icons.tune),
          ),
          IconButton(
            tooltip: 'Vocabulary',
            onPressed: () => context.push('/vocabulary'),
            icon: const Icon(Icons.bookmarks_outlined),
          ),
        ],
      ),
      body: articleAsync.when(
        data: (article) {
          if (article == null) {
            return const Center(child: Text('Article not found.'));
          }

          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: article.paragraphs.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        article.title,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Level ${article.level}',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                );
              }

              final paragraph = article.paragraphs[index - 1];
              final translation =
                  _showTranslation ? _translationFor(article, index - 1) : null;
              return _ParagraphView(
                text: paragraph,
                translation:
                    translation?.trim().isEmpty == true ? null : translation,
                settings: settings,
                onWordTap: (word) => _showWordSheet(context, word),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Failed to open article: $error'),
          ),
        ),
      ),
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
