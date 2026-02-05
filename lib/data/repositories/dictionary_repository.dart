class DictionaryRepository {
  const DictionaryRepository();

  static const Map<String, String> _dictionary = <String, String>{
    'habit': 'A routine behavior that is repeated regularly.',
    'focus': 'To direct attention to one thing and avoid distractions.',
    'improve': 'To become better or make something better.',
    'journey': 'The process of moving from one stage to another over time.',
    'curious': 'Interested in learning or knowing more about something.',
    'practice': 'Repeated action to build a skill.',
    'growth': 'Steady development or progress over time.',
  };

  Future<String> lookup(String word) async {
    final normalized = word.toLowerCase();
    return _dictionary[normalized] ??
        'No local definition for "$normalized" yet. You can still save it to your vocabulary list.';
  }
}
