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
        builder: (context, state) => const LibraryPage(),
      ),
      GoRoute(
        path: '/reader/:articleId',
        builder: (context, state) {
          final articleId = state.pathParameters['articleId'] ?? '';
          return ReaderPage(articleId: articleId);
        },
      ),
      GoRoute(
        path: '/vocabulary',
        builder: (context, state) => const VocabularyPage(),
      ),
      GoRoute(
        path: '/generate',
        builder: (context, state) => const GenerateArticlePage(),
      ),
    ],
  );
});
