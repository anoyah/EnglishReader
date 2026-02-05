import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/app.dart';
import 'data/repositories/generated_article_repository.dart';
import 'data/repositories/progress_repository.dart';
import 'data/repositories/vocabulary_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Future.wait<void>([
    Hive.openBox<dynamic>(progressBoxName),
    Hive.openBox<dynamic>(vocabularyBoxName),
    Hive.openBox<dynamic>(generatedArticlesBoxName),
  ]);

  runApp(const ProviderScope(child: ReadEnglishApp()));
}
