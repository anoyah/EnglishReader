import 'package:flutter/material.dart';
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
            _buildPage(state, const LibraryPage()),
      ),
      GoRoute(
        path: '/reader/:articleId',
        pageBuilder: (context, state) {
          final articleId = state.pathParameters['articleId'] ?? '';
          return _buildPage(state, ReaderPage(articleId: articleId));
        },
      ),
      GoRoute(
        path: '/vocabulary',
        pageBuilder: (context, state) =>
            _buildPage(state, const VocabularyPage()),
      ),
      GoRoute(
        path: '/generate',
        pageBuilder: (context, state) =>
            _buildPage(state, const GenerateArticlePage()),
      ),
    ],
  );
});

Page<void> _buildPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 240),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final inCurve = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      final outCurve = CurvedAnimation(
        parent: secondaryAnimation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      final enter = Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(inCurve);
      final exit = Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(-0.2, 0),
      ).animate(outCurve);

      return SlideTransition(
        position: enter,
        child: SlideTransition(
          position: exit,
          child: child,
        ),
      );
    },
  );
}
