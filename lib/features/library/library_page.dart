import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/models/article.dart';
import '../reader/reader_providers.dart';
import 'library_providers.dart';

class LibraryPage extends ConsumerWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articlesAsync = ref.watch(articlesProvider);
    final progressMap =
        ref.watch(progressControllerProvider).asData?.value ?? const {};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Read English'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Vocabulary Notebook',
            onPressed: () => context.push('/vocabulary'),
            icon: const Icon(Icons.bookmark_outline),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/generate'),
        icon: const Icon(Icons.auto_awesome_outlined),
        label: const Text('Generate'),
      ),
      body: articlesAsync.when(
        data: (articles) {
          if (articles.isEmpty) {
            return const Center(
              child: Text('No articles found. Add content in assets/articles.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: articles.length,
            separatorBuilder: (context, index) =>
                const Divider(height: 1, indent: 16, endIndent: 16),
            itemBuilder: (context, index) {
              final article = articles[index];
              final progress = progressMap[article.id];

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                title: Text(article.title),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _buildSubtitle(article, progress?.updatedAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/reader/${article.id}'),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Failed to load articles: $error'),
          ),
        ),
      ),
    );
  }

  String _buildSubtitle(Article article, DateTime? updatedAt) {
    final lines = <String>[];
    lines.add('Level: ${article.level}');
    if (article.isGenerated) {
      lines.add('Generated');
    }
    if (updatedAt != null) {
      final formatted = DateFormat('yyyy-MM-dd HH:mm').format(updatedAt);
      lines.add('Last read: $formatted');
    }
    return lines.join('\n');
  }
}
