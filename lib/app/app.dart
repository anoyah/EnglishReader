import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:read_english/features/reader/reader_providers.dart';
import 'router.dart';
import 'theme.dart';

class ReadEnglishApp extends ConsumerWidget {
  const ReadEnglishApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final settingsAsync = ref.watch(readerSettingsControllerProvider);

    final themeMode = settingsAsync.maybeWhen(
      data: (settings) =>
          settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      orElse: () => ThemeMode.system,
    );

    return MaterialApp.router(
      title: 'English Reader',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
