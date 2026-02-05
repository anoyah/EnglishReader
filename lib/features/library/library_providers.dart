import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../data/models/article.dart';
import '../../data/repositories/article_repository.dart';
import '../../data/repositories/generated_article_repository.dart';

final articleRepositoryProvider = Provider<ArticleRepository>((ref) {
  return ArticleRepository(rootBundle);
});

final generatedArticleRepositoryProvider =
    Provider<GeneratedArticleRepository>((ref) {
  final box = Hive.box<dynamic>(generatedArticlesBoxName);
  return GeneratedArticleRepository(box);
});

final generatedArticlesProvider = FutureProvider<List<Article>>((ref) async {
  return ref.watch(generatedArticleRepositoryProvider).loadAll();
});

final articlesProvider = FutureProvider<List<Article>>((ref) {
  final repository = ref.watch(articleRepositoryProvider);
  return Future.wait<List<Article>>([
    repository.loadArticles(),
    ref.watch(generatedArticlesProvider.future),
  ]).then((lists) {
    final assets = lists[0];
    final generated = lists[1];
    return [...generated, ...assets];
  });
});

final articleByIdProvider =
    FutureProvider.family<Article?, String>((ref, articleId) async {
  final articles = await ref.watch(articlesProvider.future);
  for (final article in articles) {
    if (article.id == articleId) {
      return article;
    }
  }
  return null;
});
