import 'package:flutter_test/flutter_test.dart';

import 'package:read_english/shared/utils/word_tokenizer.dart';

void main() {
  test('tokenizeParagraph keeps words and punctuation', () {
    final tokens = tokenizeParagraph("Hello, world! It's me.");

    expect(tokens.length, 8);
    expect(tokens[0].text, 'Hello');
    expect(tokens[0].isWord, isTrue);
    expect(tokens[1].text, ', ');
    expect(tokens[1].isWord, isFalse);
    expect(tokens[4].text, "It's");
    expect(tokens[4].isWord, isTrue);
  });

  test('normalizeWord strips punctuation and lowercases letters', () {
    expect(normalizeWord('Curious!'), 'curious');
    expect(normalizeWord("Can't"), "can't");
    expect(normalizeWord('123Focus?'), 'focus');
  });
}
