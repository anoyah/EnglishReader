import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/article.dart';
import '../../data/models/reader_settings.dart';
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
  static const double _expandedHeaderMinHeight = 156;
  static const double _expandedHeaderMaxHeight = 300;

  late final ScrollController _scrollController;
  Timer? _saveDebounce;
  bool _hasRestoredOffset = false;
  bool _showTranslation = false;
  bool _showCollapsedTitle = false;
  String? _selectedTokenId;
  double _currentExpandedHeaderHeight = _expandedHeaderMinHeight;
  String? _cachedTokenArticleId;
  final Map<int, List<WordToken>> _tokenCache = <int, List<WordToken>>{};

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
    // 1) 轻量防抖保存阅读进度，避免高频写入本地存储。
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!_scrollController.hasClients) {
        return;
      }
      ref
          .read(progressControllerProvider.notifier)
          .saveProgress(widget.articleId, _scrollController.offset);
    });

    // 2) 仅在“折叠阈值状态切换”时 setState，减少无效重建。
    if (!_scrollController.hasClients) {
      return;
    }
    final shouldShowCollapsedTitle = _scrollController.offset >
        (_currentExpandedHeaderHeight - kToolbarHeight - 8);
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
      useSafeArea: true,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final isSaved = ref.watch(isWordSavedProvider(word));
            return _WordSheetContent(
              word: word,
              definition: definition,
              isSaved: isSaved,
              onToggleSaved: () {
                ref
                    .read(vocabularyControllerProvider.notifier)
                    .toggleWord(word: word, meaning: definition);
                context.pop();
              },
            );
          },
        );
      },
    );
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
        if (_cachedTokenArticleId != article.id) {
          // 切换文章时清空分词缓存，避免跨文章误用。
          _cachedTokenArticleId = article.id;
          _tokenCache.clear();
        }

        final headerSpec = _calculateHeaderSpec(context, article.title);
        _currentExpandedHeaderHeight = headerSpec.height;

        return Scaffold(
          floatingActionButton: _hasTranslations(article)
              ? FloatingActionButton(
                  heroTag: null,
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
                expandedHeight: headerSpec.height,
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
                      if (value == 'reader_settings') {
                        _openReaderSettings();
                      } else if (value == 'vocabulary') {
                        context.push('/vocabulary');
                      }
                    },
                    itemBuilder: (context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'reader_settings',
                        child: Text('Reader settings'),
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
                  background: LayoutBuilder(
                    builder: (context, constraints) {
                      final showMeta = constraints.maxHeight > 128;
                      final topPadding =
                          constraints.maxHeight > 140 ? 52.0 : 16.0;
                      final titleStyle =
                          Theme.of(context).textTheme.titleLarge?.copyWith(
                                height: 1.2,
                                fontWeight: FontWeight.w700,
                              );
                      final fontSize = titleStyle?.fontSize ?? 22;
                      final lineHeight = fontSize * (titleStyle?.height ?? 1.2);
                      final contentHeight =
                          (constraints.maxHeight - topPadding - 16).clamp(
                        lineHeight,
                        double.infinity,
                      );
                      return SafeArea(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(16, topPadding, 72, 16),
                          child: Align(
                            alignment: Alignment.bottomLeft,
                            child: SizedBox(
                              height: contentHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Flexible(
                                    child: Text(
                                      article.title,
                                      maxLines: headerSpec.maxLines,
                                      overflow: TextOverflow.ellipsis,
                                      style: titleStyle,
                                    ),
                                  ),
                                  if (showMeta) ...<Widget>[
                                    const SizedBox(height: 6),
                                    Text(
                                      'English Reading • CEFR ${article.level}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                sliver: SliverList.builder(
                  itemCount: article.paragraphs.length,
                  itemBuilder: (context, index) {
                    final paragraph = article.paragraphs[index];
                    final tokens = _tokensFor(index, paragraph);
                    final translation = _showTranslation
                        ? _translationFor(article, index)
                        : null;
                    return _ParagraphView(
                      paragraphIndex: index,
                      tokens: tokens,
                      translation: translation?.trim().isEmpty == true
                          ? null
                          : translation,
                      selectedTokenId: _selectedTokenId,
                      settings: settings,
                      onWordTap: (word, tokenId) {
                        setState(() {
                          _selectedTokenId = tokenId;
                        });
                        _showWordSheet(context, word).whenComplete(() {
                          if (!mounted) {
                            return;
                          }
                          setState(() {
                            _selectedTokenId = null;
                          });
                        });
                      },
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

  // 根据标题宽度和字号动态估算展开态头部高度，保证长标题尽量完整可见。
  _HeaderSpec _calculateHeaderSpec(BuildContext context, String title) {
    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          height: 1.2,
          fontWeight: FontWeight.w700,
        );
    final fontSize = titleStyle?.fontSize ?? 22;
    final lineHeight = fontSize * (titleStyle?.height ?? 1.2);
    final width = MediaQuery.of(context).size.width;
    final maxTitleWidth = (width - 16 - 72 - 16).clamp(120.0, width);
    final painter = TextPainter(
      text: TextSpan(text: title, style: titleStyle),
      textDirection: Directionality.of(context),
      maxLines: null,
    )..layout(maxWidth: maxTitleWidth);
    final measuredLines = painter.computeLineMetrics().length.clamp(1, 6);
    final maxLines = measuredLines;
    final titleBlockHeight = maxLines * lineHeight;
    const chromeHeight = 56 + 16 + 16 + 24;
    final expandedHeight = (chromeHeight + titleBlockHeight).clamp(
      _expandedHeaderMinHeight,
      _expandedHeaderMaxHeight,
    );
    return _HeaderSpec(
      maxLines: maxLines,
      height: expandedHeight.toDouble(),
    );
  }

  // 对段落分词做缓存：同一文章内同一段落只分词一次，减少构建期开销。
  List<WordToken> _tokensFor(int paragraphIndex, String text) {
    final cached = _tokenCache[paragraphIndex];
    if (cached != null) {
      return cached;
    }
    final created = tokenizeParagraph(text);
    _tokenCache[paragraphIndex] = created;
    return created;
  }
}

class _HeaderSpec {
  const _HeaderSpec({required this.maxLines, required this.height});

  final int maxLines;
  final double height;
}

class _WordSheetContent extends StatelessWidget {
  const _WordSheetContent({
    required this.word,
    required this.definition,
    required this.isSaved,
    required this.onToggleSaved,
  });

  final String word;
  final String definition;
  final bool isSaved;
  final VoidCallback onToggleSaved;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: 1,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(word, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Text(definition),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onToggleSaved,
              icon: Icon(isSaved ? Icons.bookmark_remove : Icons.bookmark_add),
              label: Text(
                isSaved ? 'Remove from vocabulary' : 'Save to vocabulary',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParagraphView extends StatelessWidget {
  const _ParagraphView({
    required this.paragraphIndex,
    required this.tokens,
    required this.translation,
    required this.selectedTokenId,
    required this.settings,
    required this.onWordTap,
  });

  final int paragraphIndex;
  final List<WordToken> tokens;
  final String? translation;
  final String? selectedTokenId;
  final ReaderSettings settings;
  final void Function(String word, String tokenId) onWordTap;

  @override
  Widget build(BuildContext context) {
    final articleTextColor = Theme.of(context).colorScheme.onSurface;
    final baseStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontSize: 18 * settings.fontScale,
          height: settings.lineHeight,
          color: articleTextColor,
        );

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          RichText(
            text: TextSpan(
              style: baseStyle,
              children: tokens.asMap().entries.map((entry) {
                final tokenIndex = entry.key;
                final token = entry.value;
                if (!token.isWord) {
                  return TextSpan(text: token.text);
                }

                final normalized = normalizeWord(token.text);
                final tokenId = '$paragraphIndex-$tokenIndex';
                final isSelected =
                    normalized.isNotEmpty && tokenId == selectedTokenId;

                return WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(4),
                    onTap: normalized.isEmpty
                        ? null
                        : () => onWordTap(normalized, tokenId),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: isSelected
                          ? BoxDecoration(
                              color: const Color(0xFFFDE68A)
                                  .withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(5),
                            )
                          : null,
                      child: Text(
                        token.text,
                        style: baseStyle?.copyWith(
                          color: articleTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
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
