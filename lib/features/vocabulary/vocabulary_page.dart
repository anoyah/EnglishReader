import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'vocabulary_providers.dart';

class VocabularyPage extends ConsumerWidget {
  const VocabularyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wordsAsync = ref.watch(vocabularyControllerProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: context.canPop() ? () => context.pop() : null,
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Vocabulary Notebook'),
      ),
      body: wordsAsync.when(
        data: (words) {
          if (words.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No saved words yet. Tap words in the reader to add them.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: words.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final word = words[index];
              final time = DateFormat('yyyy-MM-dd HH:mm').format(word.addedAt);

              return Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  title: Text(word.word),
                  subtitle: Text(
                    '${word.meaning}\nSaved: $time',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    tooltip: 'Remove',
                    onPressed: () {
                      ref
                          .read(vocabularyControllerProvider.notifier)
                          .removeWord(word.word);
                    },
                    icon: const Icon(Icons.delete_outline),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Failed to load vocabulary: $error'),
          ),
        ),
      ),
    );
  }
}
