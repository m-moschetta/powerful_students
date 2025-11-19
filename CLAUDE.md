# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Powerful Students** is a Flutter-based Pomodoro timer application designed for students. It provides customizable study sessions, break management, and multi-modal study support (solo or group study). The app includes audio and haptic feedback, local notifications, and a burn mode for intensive study sessions.

## Build Commands

### Building the Project
```bash
# Install dependencies
flutter pub get

# Build for iOS (debug)
flutter build ios --debug

# Build for Android (debug)
flutter build apk --debug

# Build for web
flutter build web

# Run in development mode
flutter run
```

### Testing
```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Analyze code for issues
flutter analyze

# Format code according to style guide
dart format .
```

## Architecture Overview

### Core Components

**PomodoroProvider** (`lib/providers/pomodoro_provider.dart`)
- State management using `ChangeNotifier` pattern from Provider package
- Manages timer lifecycle (start, pause, resume, stop)
- Tracks completed Pomodoros and triggers automatic break/work transitions
- Handles notifications (audio, vibration, local notifications)
- Supports session mode selection (solo/group) and burn mode toggle
- Adjustable default work duration via circular slider interaction

**StudySession Model** (`lib/models/study_session.dart`)
- Data class representing a single study or break session
- Enums: `StudyMode` (solo/group), `SessionType` (work/shortBreak/longBreak)
- Factory methods for standard Pomodoro durations (25min work, 5min break, 15min long break)
- Tracks remaining time, progress percentage, and completion state
- Provides formatted time display (MM:SS)

**UI Screens**
- **ModeSelectionScreen** (`lib/screens/mode_selection_screen.dart`): Entry point for selecting study mode and initiating timer
- **TimerScreen** (`lib/screens/timer_screen.dart`): Main timer interface with circular progress indicator, controls, and stats

**CircularSlider Widget** (`lib/widgets/circular_slider.dart`)
- Custom widget enabling drag-based time adjustment (when no active session)
- Visual feedback with 12-point indicator circle
- Drag sensitivity: 10 pixels of vertical movement = 1 minute

### Key Features

- **Pomodoro Technique**: Automatic 25-min work → 5-min break → repeat after 4 cycles (15-min long break)
- **Multi-modal study**: Solo mode and group study mode selection
- **Burn Mode**: Intensive study mode toggle for enhanced focus sessions
- **Notifications**: Haptic feedback (vibration), audio alerts, and local OS notifications
- **Custom durations**: Adjustable work session length via circular slider (1-60 minutes)
- **Session tracking**: Counter for completed Pomodoros per session

### State Management

Uses Provider package for reactive state management:
- `PomodoroProvider` is initialized in `main()` and injected via `MultiProvider`
- All screens consume provider state through `Consumer<PomodoroProvider>`
- `notifyListeners()` triggers UI rebuilds on state changes

### Key Dart/Flutter Versions

- Dart SDK: ^3.9.2
- Uses Material 3 design system
- Support for async/await and Dart streams
- Null safety enabled

### Assets

- **Sounds**: `assets/sounds/notification.mp3`, `assets/sounds/beep.mp3` (notification audio files)
- **Images**: `assets/images/` (for future graphics/icons)

### UI Design

- **Color scheme**: Gradient background (light gray to pink: #E7E7E7 → #F4C3F1)
- **Typography**: Helvetica font family applied globally
- **Material Icons** for navigation and UI controls
- **Responsive layout** using `SafeArea` and flexible padding

### Linting & Code Quality

- Linting rules defined in `analysis_options.yaml`
- Uses `flutter_lints` package for recommended best practices
- Run `flutter analyze` before commits

## Navigation

The app uses named routes:
- `/` → ModeSelectionScreen (initial route)
- `/timer` → TimerScreen

Navigation is handled via `Navigator.of(context).pushReplacementNamed()` to manage screen transitions.

## Notification System

Local notifications use `flutter_local_notifications` plugin:
- **Android**: Channel ID `pomodoro_channel` with high importance
- **iOS**: Uses DarwinNotificationDetails
- Triggered on session completion with contextual messages (break/work)

## Dependencies

- **provider** (^6.1.1): State management
- **flutter_local_notifications** (^17.0.0): OS-level notifications
- **audioplayers** (^5.2.1): Audio playback for notification sounds
- **vibration** (^1.8.4): Haptic feedback
- **percent_indicator** (^4.2.3): Circular progress widget
- **google_fonts** (^6.1.0): Extended font support
- **cupertino_icons** (^1.0.8): iOS-style icons

## Common Development Tasks

### Adding a New Feature

1. Determine if feature requires state management (add method to `PomodoroProvider` if needed)
2. Create UI screen in `lib/screens/` or widget in `lib/widgets/`
3. Consume provider state using `Consumer<PomodoroProvider>` pattern
4. Register route in `main.dart` if new screen
5. Run `flutter analyze` and `flutter test` to validate

### Debugging Timer Issues

- Timer is managed by `Timer.periodic()` in `PomodoroProvider._startTimer()`
- Session completion is checked every second in the timer callback
- Ensure `_handleSessionComplete()` is properly triggered for state transitions

### Customizing Durations

- Standard durations defined as static constants in `StudySession`
- Default work duration adjustable via `adjustDefaultWorkDuration()` in provider
- Burn mode affects session creation but not standard durations

### Testing Notifications

- Ensure audio files exist in `assets/sounds/` (fallback to beep.mp3 if notification.mp3 missing)
- Local notifications require platform-specific setup in Android/iOS native code
- Test on actual device or simulator with appropriate permissions granted
