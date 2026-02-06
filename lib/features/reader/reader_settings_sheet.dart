import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:read_english/data/models/reader_settings.dart';
import 'reader_providers.dart';

class ReaderSettingsSheet extends ConsumerWidget {
  const ReaderSettingsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings =
        ref.watch(readerSettingsControllerProvider).asData?.value ??
            ReaderSettings.defaults;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('Reader Settings',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            Text('Font scale: ${settings.fontScale.toStringAsFixed(2)}'),
            Slider(
              value: settings.fontScale,
              min: 0.8,
              max: 1.6,
              divisions: 8,
              onChanged: (value) {
                ref
                    .read(readerSettingsControllerProvider.notifier)
                    .setFontScale(value);
              },
            ),
            const SizedBox(height: 8),
            Text('Line height: ${settings.lineHeight.toStringAsFixed(2)}'),
            Slider(
              value: settings.lineHeight,
              min: 1.2,
              max: 2.2,
              divisions: 10,
              onChanged: (value) {
                ref
                    .read(readerSettingsControllerProvider.notifier)
                    .setLineHeight(value);
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: settings.isDarkMode,
              onChanged: (value) {
                ref
                    .read(readerSettingsControllerProvider.notifier)
                    .setDarkMode(value);
              },
              title: const Text('Dark mode'),
            ),
          ],
        ),
      ),
    );
  }
}
