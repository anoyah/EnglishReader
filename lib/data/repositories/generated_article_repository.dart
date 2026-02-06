import 'package:hive/hive.dart';

import 'package:read_english/data/models/article.dart';

const String generatedArticlesBoxName = 'generated_articles';

class GeneratedArticleRepository {
  GeneratedArticleRepository(this._box);

  final Box<dynamic> _box;

  List<Article> loadAll() {
    final articles = <Article>[];

    for (final key in _box.keys) {
      final raw = _box.get(key);
      if (raw is Map) {
        articles.add(Article.fromMap(raw));
      }
    }

    articles.sort((a, b) {
      final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });

    return articles;
  }

  Future<void> save(Article article) async {
    await _box.put(article.id, article.toMap());
  }

  Future<void> remove(String articleId) async {
    await _box.delete(articleId);
  }
}
