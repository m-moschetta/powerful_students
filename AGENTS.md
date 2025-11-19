# Repository Guidelines

Follow this guide before shipping any update so the Pomodoro experience remains consistent across platforms.

## Project Structure & Module Organization
- `lib/main.dart` initializes dependency injection and global providers.
- Feature flows sit under `lib/screens/` (e.g., `timer_screen.dart`), reusable UI lives in `lib/widgets/`, shared state in `lib/providers/`, and domain models in `lib/models/`.
- Audio and imagery assets belong in `assets/sounds/` and `assets/images/`; list new files in `pubspec.yaml`.
- Tests mirror the source layout in `test/`, keeping widget, provider, and model coverage close to their implementations.

## Build, Test, and Development Commands
- `flutter pub get` refreshes dependencies after editing `pubspec.yaml`.
- `flutter run -d chrome` spins up the web target; swap the device flag for `ios` or `android` as needed.
- `flutter analyze` surfaces lint, null-safety, and type issues enforced by `analysis_options.yaml`.
- `flutter test --coverage` runs unit and widget suites while updating coverage locally.
- `dart format lib test` applies the expected code style before committing.

## Coding Style & Naming Conventions
Adhere to the Flutter lints baseline: two-space indentation, trailing commas for multi-line widget trees, `UpperCamelCase` classes, `lowerCamelCase` members, and `snake_case` file names. Keep provider mutations inside methods to simplify mocking and maintain declarative widget hierarchies.

## Testing Guidelines
Create a matching `*_test.dart` for every new screen, widget, or provider. Use `pumpWidget` with the minimal provider setup, stub timers and audio callbacks, and assert break/focus transitions plus notification cues. Document intentional gaps in the test description and link to follow-up tasks when necessary.

## Commit & Pull Request Guidelines
Write commit subjects in the imperative mood (≤50 characters) with optional bodies for context. Each PR should include a concise summary, linked issue or story, reproduction steps for new behavior, screenshots for UI changes, and confirmation that `flutter analyze`, `dart format`, and `flutter test` completed successfully. Tag reviewers familiar with the affected module to speed feedback.
