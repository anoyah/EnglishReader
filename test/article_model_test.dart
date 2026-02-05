import 'package:flutter_test/flutter_test.dart';

import 'package:read_english/data/models/article.dart';

void main() {
  test('Article.fromJson parses fields correctly', () {
    final article = Article.fromJson(const <String, dynamic>{
      'id': 'sample-id',
      'title': 'Sample Title',
      'level': 'A2',
      'paragraphs': <String>['First paragraph', 'Second paragraph'],
    });

    expect(article.id, 'sample-id');
    expect(article.title, 'Sample Title');
    expect(article.level, 'A2');
    expect(article.paragraphs, hasLength(2));
  });
}
