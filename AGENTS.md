# Repository Guidelines

Use this guide to keep the Powerful Students Flutter app consistent across platforms.

## Project Structure & Module Organization
- `lib/main.dart` wires the app bootstrap and providers; shared utilities live in `lib/core/`.
- Feature UI is in `lib/screens/`, reusable UI in `lib/widgets/`, state in `lib/providers/`, models in `lib/models/`, and integrations in `lib/services/`.
- Firebase configuration is generated in `lib/firebase_options.dart`; regenerate it with FlutterFire when project ids change.
- Assets live in `assets/images/` and `assets/sounds/`; register new files in `pubspec.yaml`.
- Tests live under `test/` (for example `test/services/` and `test/widget_test.dart`); mirror the production module names where possible.

## Build, Test, and Development Commands
- `flutter pub get` refreshes dependencies after `pubspec.yaml` changes.
- `flutter run -d chrome` runs the web target locally; swap `chrome` for `ios` or `android`.
- `flutter analyze` enforces the `analysis_options.yaml` lint set.
- `flutter test` runs unit and widget tests; use `flutter test --coverage` when you need a coverage report.
- `dart format lib test` applies the expected Dart formatting.
- `flutterfire configure` regenerates Firebase options after switching Firebase projects.

## Coding Style & Naming Conventions
Follow `package:flutter_lints`: two-space indentation, trailing commas in multi-line widget trees, `UpperCamelCase` types, `lowerCamelCase` members, and `snake_case` file names. Prefer small widgets and keep provider mutations inside provider methods to maintain testability.

## Testing Guidelines
Add `*_test.dart` files alongside new services, providers, and widgets. Use minimal `pumpWidget` setups, stub timers/audio, and cover focus/break transitions. There is no explicit coverage gate, but new behavior should include tests or a brief justification in the PR.

## Commit & Pull Request Guidelines
Recent history uses Conventional Commits (e.g., `feat:`, `fix:`, `docs:`). Keep subjects imperative and concise. PRs should include a short summary, linked issue (if any), QA steps, and screenshots for UI changes, plus confirmation that `flutter analyze`, `dart format`, and `flutter test` pass.

## Configuration & Security Notes
Firestore is required for group rooms. Follow the Firebase setup in `README.md`, and keep rules scoped to the minimum needed for development.
