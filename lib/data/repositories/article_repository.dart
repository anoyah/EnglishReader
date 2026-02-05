import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/article.dart';

class ArticleRepository {
  const ArticleRepository(this._assetBundle);

  final AssetBundle _assetBundle;

  Future<List<Article>> loadArticles() async {
    final jsonString =
        await _assetBundle.loadString('assets/articles/articles.json');
    final decoded = jsonDecode(jsonString) as List<dynamic>;

    return decoded
        .map((item) => Article.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
