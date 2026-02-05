# Read English (Flutter, Android-first)

A lightweight English reading app for Android built with Flutter.

## Implemented MVP Scope

- Local article library from JSON assets.
- Reader page with paragraph rendering.
- Reader settings:
  - Font scale
  - Line height
  - Light/Dark mode
- Tap any English word to open a definition sheet (local mock dictionary).
- Save/remove words to a vocabulary notebook.
- Cloud TTS read-aloud for English articles (OpenAI-compatible audio API).
- Persisted local data:
  - Reading progress per article
  - Vocabulary words
  - Reader settings
- Generate articles via API (DeepSeek/OpenAI-compatible) with Chinese translations.

## Tech Stack

- Flutter 3.35.3
- State management: `flutter_riverpod`
- Routing: `go_router`
- Local persistence: `hive` + `shared_preferences`
- Networking (reserved for future dictionary API): `dio`
- Text generation: `dio` + API settings (DeepSeek/OpenAI-compatible)
- Audio playback: `just_audio`

## Project Structure

- `lib/app`: app bootstrap, routing, theme
- `lib/data`: models and repositories
- `lib/features/library`: article list
- `lib/features/reader`: reading page and settings
- `lib/features/vocabulary`: vocabulary notebook
- `lib/shared`: shared utilities
- `assets/articles/articles.json`: local article source
- Generated articles stored locally in Hive (`generated_articles`)

## Run for Android

```bash
flutter pub get
flutter run -d android
```

## Build Android Packages

```bash
flutter build apk --release
flutter build appbundle --release
```

## Android Release Notes

Current release build uses debug signing by default.
Before production release:

1. Create/upload a keystore.
2. Configure `android/key.properties` and Gradle signing config.
3. Replace launcher icons and app metadata.
4. Test release build on physical devices.

## Data Model Notes

- Articles are static assets in `assets/articles/articles.json`.
- Reading progress and vocabulary are stored in Hive boxes:
  - `reader_progress`
  - `reader_vocabulary`
- Generated articles are stored in Hive:
  - `generated_articles`
- Reader visual settings are stored in SharedPreferences.
- API settings for generation are stored in SharedPreferences (base URL, model, key).
- Cloud TTS settings are stored in SharedPreferences (base URL, model, voice, key).

## Article Generation (DeepSeek / OpenAI-compatible)

- Open the Library page and tap the sparkle icon to open **Generate Article**.
- Provide a topic, level, and paragraph count.
- Expand **API Settings** and paste your API key.
- The app will save the generated article locally and open it in the reader.

## Cloud TTS Read-Aloud

- Open any article, tap the speaker icon to play or stop read-aloud.
- Tap the voice settings icon in Reader to configure cloud TTS endpoint/model/voice/key.
- Default endpoint is OpenAI-compatible: `https://api.openai.com/v1/audio/speech`.
