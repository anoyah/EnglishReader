final RegExp _tokenPattern =
    RegExp(r"[A-Za-z']+(?:-[A-Za-z']+)*|[^A-Za-z']+");
final RegExp _wordPattern = RegExp(r"^[A-Za-z']+(?:-[A-Za-z']+)*$");

class WordToken {
  const WordToken({required this.text, required this.isWord});

  final String text;
  final bool isWord;
}

List<WordToken> tokenizeParagraph(String text) {
  return _tokenPattern
      .allMatches(text)
      .map((match) {
        final chunk = match.group(0) ?? '';
        final isWord = _wordPattern.hasMatch(chunk);
        return WordToken(text: chunk, isWord: isWord);
      })
      .where((token) => token.text.isNotEmpty)
      .toList();
}

String normalizeWord(String text) {
  return text.toLowerCase().replaceAll(RegExp(r"[^a-z'-]"), '');
}
