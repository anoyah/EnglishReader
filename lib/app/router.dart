import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:read_english/features/library/library_page.dart';
import 'package:read_english/features/generate/generate_article_page.dart';
import 'package:read_english/features/reader/reader_page.dart';
import 'package:read_english/features/vocabulary/vocabulary_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        pageBuilder: (context, state) =>
            CupertinoPage<void>(key: state.pageKey, child: const LibraryPage()),
      ),
      GoRoute(
        path: '/reader/:articleId',
        pageBuilder: (context, state) {
          final articleId = state.pathParameters['articleId'] ?? '';
          return CupertinoPage<void>(
            key: state.pageKey,
            child: ReaderPage(articleId: articleId),
          );
        },
      ),
      GoRoute(
        path: '/vocabulary',
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          child: const VocabularyPage(),
        ),
      ),
      GoRoute(
        path: '/generate',
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          child: const GenerateArticlePage(),
        ),
      ),
    ],
  );
});
