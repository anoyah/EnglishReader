# Read English (Flutter, Android-first)

A lightweight English reading app built with Flutter. It focuses on short articles, word lookup, vocabulary building, and AI-generated readings with Chinese translations.

## Features

- Local article library from JSON assets (with Chinese translations).
- Reader with paragraph-based rendering and reading progress restore.
- Word lookup: tap any word to see Chinese translation + English definition.
- Save/remove words to a vocabulary notebook.
- Article generation via DeepSeek/OpenAI-compatible API.
- Reader settings:
  - Font scale
  - Line height
  - Dark mode
  - Default translation display on open
- Long-press text selection for system actions (copy/share).

## Tech Stack

- Flutter 3.35.3
- State management: `flutter_riverpod`
- Routing: `go_router`
- Local persistence: `hive` + `shared_preferences`
- Secure storage: `flutter_secure_storage` (API key)
- Networking: `dio`

## Project Structure

- `lib/app`: app bootstrap, routing, theme
- `lib/data`: models and repositories
- `lib/features/library`: article list
- `lib/features/reader`: reading page and settings
- `lib/features/vocabulary`: vocabulary notebook
- `lib/shared`: shared utilities
- `assets/articles/articles.json`: local article source
- Generated articles stored locally in Hive (`generated_articles`)

## Quick Start

```bash
flutter pub get
flutter run -d android
```

## Build Android Packages

```bash
flutter build apk --release
flutter build appbundle --release
```

## Configuration

### Article Generation (DeepSeek / OpenAI-compatible)

- Open the Library page and tap the sparkle icon to open **Generate Article**.
- Provide a topic, level, and paragraph count.
- Expand **API Settings** and fill in:
  - Base URL (default: `https://api.deepseek.com/chat/completions`)
  - Model (default: `deepseek-chat`)
  - API key (stored in secure storage)

### Word Lookup / Translation

- Tap any English word in the reader to open the lookup sheet.
- The app uses:
  - Dictionary definitions: `dictionaryapi.dev`
  - Chinese translation: `MyMemory` API
- If offline or API fails, it falls back to the local mock dictionary.

## Data & Storage

- Articles (assets): `assets/articles/articles.json`
- Generated articles: Hive box `generated_articles`
- Reading progress: Hive box `reader_progress`
- Vocabulary list: Hive box `reader_vocabulary`
- Reader settings: `SharedPreferences`
- Generation API key: `flutter_secure_storage`

## Privacy Notes

- Article generation sends your input to a third-party AI service.
- Word lookup may call public dictionary/translation APIs.
- All saved data (articles, vocabulary, progress) stays on device.

## Contributing

Issues and PRs are welcome. Keep changes focused, and run `flutter analyze` before submitting.

## License

See `LICENSE`.
