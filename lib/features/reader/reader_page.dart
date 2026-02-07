import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:read_english/data/models/article.dart';
import 'package:read_english/data/models/reader_settings.dart';
import 'package:read_english/shared/utils/word_tokenizer.dart';
import 'package:read_english/features/library/library_providers.dart';
import 'package:read_english/features/vocabulary/vocabulary_providers.dart';
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
  _HeaderSpec? _cachedHeaderSpec;
  String? _cachedHeaderTitle;
  double? _cachedHeaderWidth;
  double? _cachedHeaderFontSize;
  double? _cachedHeaderLineHeight;

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

        final headerSpec = _resolveHeaderSpec(context, article.title);
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
                    return Consumer(
                      builder: (context, ref, child) {
                        final savedWords = ref.watch(savedWordSetProvider);
                        return RepaintBoundary(
                          child: _ParagraphView(
                            paragraphIndex: index,
                            tokens: tokens,
                            translation: translation?.trim().isEmpty == true
                                ? null
                                : translation,
                            savedWords: savedWords,
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
                          ),
                        );
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

  _HeaderSpec _resolveHeaderSpec(BuildContext context, String title) {
    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          height: 1.2,
          fontWeight: FontWeight.w700,
        );
    final fontSize = titleStyle?.fontSize ?? 22;
    final lineHeight = fontSize * (titleStyle?.height ?? 1.2);
    final width = MediaQuery.of(context).size.width;

    if (_cachedHeaderSpec != null &&
        _cachedHeaderTitle == title &&
        _cachedHeaderWidth == width &&
        _cachedHeaderFontSize == fontSize &&
        _cachedHeaderLineHeight == lineHeight) {
      return _cachedHeaderSpec!;
    }

    final spec = _calculateHeaderSpec(
      context: context,
      title: title,
      titleStyle: titleStyle,
      fontSize: fontSize,
      lineHeight: lineHeight,
      width: width,
    );
    _cachedHeaderSpec = spec;
    _cachedHeaderTitle = title;
    _cachedHeaderWidth = width;
    _cachedHeaderFontSize = fontSize;
    _cachedHeaderLineHeight = lineHeight;
    return spec;
  }

  // 根据标题宽度和字号动态估算展开态头部高度，保证长标题尽量完整可见。
  _HeaderSpec _calculateHeaderSpec({
    required BuildContext context,
    required String title,
    required TextStyle? titleStyle,
    required double fontSize,
    required double lineHeight,
    required double width,
  }) {
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

class _WordHit {
  const _WordHit(this.start, this.end, this.word, this.tokenId);

  final int start;
  final int end;
  final String word;
  final String tokenId;

  bool contains(int index) => index >= start && index < end;
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
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: constraints.maxHeight,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(word, style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 12),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Text(definition),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: onToggleSaved,
                      icon: Icon(
                        isSaved ? Icons.bookmark_remove : Icons.bookmark_add,
                      ),
                      label: Text(
                        isSaved
                            ? 'Remove from vocabulary'
                            : 'Save to vocabulary',
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ParagraphView extends StatefulWidget {
  const _ParagraphView({
    required this.paragraphIndex,
    required this.tokens,
    required this.translation,
    required this.savedWords,
    required this.selectedTokenId,
    required this.settings,
    required this.onWordTap,
  });

  final int paragraphIndex;
  final List<WordToken> tokens;
  final String? translation;
  final Set<String> savedWords;
  final String? selectedTokenId;
  final ReaderSettings settings;
  final void Function(String word, String tokenId) onWordTap;

  @override
  State<_ParagraphView> createState() => _ParagraphViewState();
}

class _ParagraphViewState extends State<_ParagraphView> {
  Offset? _pointerDownPosition;
  DateTime? _pointerDownTime;
  bool _pointerMoved = false;

  @override
  Widget build(BuildContext context) {
    final articleTextColor = Theme.of(context).colorScheme.onSurface;
    final baseStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontSize: 18 * widget.settings.fontScale,
          height: widget.settings.lineHeight,
          color: articleTextColor,
        ) ??
        TextStyle(
          fontSize: 18 * widget.settings.fontScale,
          height: widget.settings.lineHeight,
          color: articleTextColor,
        );
    final wordBaseStyle = baseStyle.copyWith(fontWeight: FontWeight.w500);
    final savedColor = Theme.of(context).colorScheme.primary;
    final selectedColor = const Color(0xFFFDE68A).withValues(alpha: 0.75);

    InlineSpan buildSelectedSpan(String text, BorderRadius borderRadius) {
      return WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: selectedColor,
            borderRadius: borderRadius,
          ),
          child: Text(text, style: wordBaseStyle),
        ),
      );
    }

    final spans = <InlineSpan>[];
    final painterSpans = <TextSpan>[];
    final hits = <_WordHit>[];
    var offset = 0;

    for (final entry in widget.tokens.asMap().entries) {
      final tokenIndex = entry.key;
      final token = entry.value;
      final text = token.text;
      final start = offset;
      final end = start + text.length;

      if (!token.isWord) {
        spans.add(TextSpan(text: text));
        painterSpans.add(TextSpan(text: text));
        offset = end;
        continue;
      }

      final normalized = normalizeWord(text);
      final tokenId = '${widget.paragraphIndex}-$tokenIndex';
      final isSelected =
          normalized.isNotEmpty && tokenId == widget.selectedTokenId;
      final isSaved =
          normalized.isNotEmpty && widget.savedWords.contains(normalized);

      if (isSelected) {
        if (text.contains('-')) {
          final parts = text.split('-');
          var segmentIndex = 0;
          final lastIndex = (parts.length * 2) - 2;
          for (var i = 0; i < parts.length; i++) {
            if (parts[i].isNotEmpty) {
              final radius = segmentIndex == 0
                  ? const BorderRadius.horizontal(left: Radius.circular(5))
                  : segmentIndex == lastIndex
                      ? const BorderRadius.horizontal(
                          right: Radius.circular(5),
                        )
                      : BorderRadius.zero;
              spans.add(buildSelectedSpan(parts[i], radius));
            }
            if (i < parts.length - 1) {
              segmentIndex += 1;
              final radius = segmentIndex == lastIndex
                  ? const BorderRadius.horizontal(right: Radius.circular(5))
                  : BorderRadius.zero;
              spans.add(buildSelectedSpan('-', radius));
            }
            segmentIndex += 1;
          }
        } else {
          spans.add(buildSelectedSpan(text, BorderRadius.circular(5)));
        }
        painterSpans.add(TextSpan(text: text, style: wordBaseStyle));
      } else {
        final style = wordBaseStyle.copyWith(
          decoration: isSaved ? TextDecoration.underline : null,
          decorationColor: isSaved ? savedColor : null,
          decorationThickness: isSaved ? 2 : null,
        );
        spans.add(TextSpan(text: text, style: style));
        painterSpans.add(TextSpan(text: text, style: style));
      }

      if (normalized.isNotEmpty) {
        hits.add(_WordHit(start, end, normalized, tokenId));
      }
      offset = end;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          LayoutBuilder(
            builder: (context, constraints) {
              void handleTap(Offset localPosition) {
                if (hits.isEmpty) {
                  return;
                }
                final painter = TextPainter(
                  text: TextSpan(style: baseStyle, children: painterSpans),
                  textDirection: Directionality.of(context),
                )..layout(maxWidth: constraints.maxWidth);
                final position = painter.getPositionForOffset(localPosition);
                final index = position.offset;
                for (final hit in hits) {
                  if (hit.contains(index)) {
                    widget.onWordTap(hit.word, hit.tokenId);
                    break;
                  }
                }
              }

              return Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (event) {
                  _pointerDownPosition = event.localPosition;
                  _pointerDownTime = DateTime.now();
                  _pointerMoved = false;
                },
                onPointerMove: (event) {
                  final start = _pointerDownPosition;
                  if (start == null) {
                    return;
                  }
                  final delta = (event.localPosition - start).distance;
                  if (delta > 6) {
                    _pointerMoved = true;
                  }
                },
                onPointerUp: (event) {
                  final downTime = _pointerDownTime;
                  final moved = _pointerMoved;
                  _pointerDownPosition = null;
                  _pointerDownTime = null;
                  _pointerMoved = false;
                  if (downTime == null || moved) {
                    return;
                  }
                  final elapsed =
                      DateTime.now().difference(downTime).inMilliseconds;
                  if (elapsed > 220) {
                    return;
                  }
                  handleTap(event.localPosition);
                },
                child: SelectableText.rich(
                  TextSpan(
                    style: baseStyle,
                    children: spans,
                  ),
                ),
              );
            },
          ),
          if (widget.translation != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              widget.translation!,
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
