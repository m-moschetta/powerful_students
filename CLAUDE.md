# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Powerful Students** is a Flutter-based collaborative Pomodoro timer application designed for students. It provides customizable study sessions, break management, and **real-time synchronized group study rooms**. The app includes Firebase integration for multi-user support, audio/haptic feedback, local notifications, burn mode for intensive study, and a centralized iOS 18/26-style design system.

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

# Run with specific Firebase project
flutter run --dart-define=FIREBASE_PROJECT_ID=your-project-id
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

### Core Architecture Pattern

**MVVM with Service Layer**
```
View (Screens) → Provider (State) → Services → Firebase/Local
```

### Core Components

#### **State Management Layer**

**PomodoroProvider** (`lib/providers/pomodoro_provider.dart`)
- State management using `ChangeNotifier` pattern from Provider package
- Manages timer lifecycle (start, pause, resume, stop)
- Tracks completed Pomodoros and triggers automatic break/work transitions
- Handles notifications (audio, vibration, local notifications)
- Supports session mode selection (solo/group) and burn mode toggle
- Adjustable default work duration via circular slider interaction
- **Integrates with RoomProvider** for group study synchronization
- Background/foreground state handling with app lifecycle observer

**RoomProvider** (`lib/providers/room_provider.dart`)
- Manages group study rooms via Firebase Firestore
- Room creation with unique 9-character alphanumeric codes
- Join/leave room operations with transaction-based safety
- Real-time room state synchronization via Firestore snapshots
- Member management and ownership tracking
- Timer state sharing across room members
- Error handling with user-friendly messages

#### **Service Layer**

**AuthService** (`lib/services/auth_service.dart`)
- Firebase Authentication wrapper
- Email/password sign-in and registration
- Auth state change stream
- Error handling and logging

**DatabaseService** (`lib/services/database_service.dart`)
- Firestore data operations
- Student collection management
- Stream-based data retrieval

**PomodoroNotificationService** (`lib/services/pomodoro_notification_service.dart`)
- Local notification management using `flutter_local_notifications`
- Scheduled notifications with timezone support
- Platform-specific configuration (Android/iOS)
- Audio playback integration for notification sounds
- Vibration/haptic feedback

**PomodoroTimerService** (`lib/services/pomodoro_timer_service.dart`)
- Core timer logic abstraction
- Tick-based countdown mechanism

**PomodoroSyncService** (`lib/services/pomodoro_sync_service.dart`)
- Real-time timer synchronization for group rooms
- Pushes local timer state to Firestore
- Receives remote timer updates via callback pattern
- Prevents circular update loops with `_isProcessingRemoteUpdate` flag

#### **Models**

**StudySession** (`lib/models/study_session.dart`)
- Data class representing a single study or break session
- Enums: `StudyMode` (solo/group), `SessionType` (work/shortBreak/longBreak)
- Factory methods for standard Pomodoro durations (25min work, 5min break, 15min long break)
- Tracks remaining time, progress percentage, and completion state
- Provides formatted time display (MM:SS)

**GroupRoom** (`lib/models/group_room.dart`)
- Firebase-backed model for group study rooms
- Fields: code, ownerId, memberIds, createdAt, updatedAt, timerState
- Factory constructor from Firestore `DocumentSnapshot`
- Ownership and membership validation methods
- Nested `TimerState` model for real-time timer synchronization

#### **UI Components**

**Screens**
- **ModeSelectionScreen** (`lib/screens/mode_selection_screen.dart`): Entry point for selecting study mode (solo/group) and initiating timer
- **TimerScreen** (`lib/screens/timer_screen.dart`): Main timer interface with circular progress indicator, controls, and stats
- **GroupRoomScreen** (`lib/screens/group_room_screen.dart`): Group study room interface with room code display/sharing, member count, and synchronized timer

**Widgets**
- **CircularSlider** (`lib/widgets/circular_slider.dart`): Custom drag-based time adjustment widget (when no active session), visual feedback with 12-point indicator circle, drag sensitivity: 10 pixels vertical = 1 minute

**Design System** (`lib/core/design_system.dart`)
- Centralized design tokens for colors, typography, spacing, radius, icons
- **Glassmorphism** (Liquid Glass) effect utilities
- iOS 18/26 inspired aesthetic with SF Pro Text font
- Color scheme: Green primary (#A9FFA6), Pink CTA (#F4C3F1), gradient backgrounds
- Reusable card and glass container decorators

### Key Features

- **Pomodoro Technique**: Automatic 25-min work → 5-min break → repeat, with 15-min long break after 4 cycles
- **Multi-modal study**: Solo mode and **synchronized group study mode** with shareable room codes
- **Burn Mode**: Intensive study mode toggle for enhanced focus sessions
- **Real-time Sync**: Timer state synchronized across all room members via Firestore
- **Notifications**: Haptic feedback (vibration), audio alerts, and local OS notifications with timezone support
- **Custom durations**: Adjustable work session length via circular slider (1-60 minutes)
- **Session tracking**: Counter for completed Pomodoros per session
- **Screen wakelock**: Keeps screen awake during active study sessions
- **Room code sharing**: Share room codes via native share sheet (`share_plus`)

### Firebase Integration

**Services Used**
- **Firebase Core**: Platform initialization
- **Firebase Auth**: User authentication (email/password)
- **Cloud Firestore**: Real-time database for group rooms and timer state

**Firestore Schema**
```
rooms/
  {roomCode}/
    - code: String (9-char unique)
    - ownerId: String (member ID)
    - members: Array<String> (member IDs)
    - createdAt: Timestamp
    - updatedAt: Timestamp
    - timerState: Map<String, dynamic>
      - isRunning: bool
      - isPaused: bool
      - remainingSeconds: int
      - totalSeconds: int
      - sessionType: String ('work'|'shortBreak'|'longBreak')
      - startedAt: Timestamp?
      - pausedAt: Timestamp?

students/
  {userId}/
    - name: String
    - grade: String
```

### State Management

Uses Provider package for reactive state management:
- `PomodoroProvider` and `RoomProvider` initialized in `main()` and injected via `MultiProvider`
- `ChangeNotifierProxyProvider` connects PomodoroProvider to RoomProvider for sync
- All screens consume provider state through `Consumer<T>` or `context.read<T>()`
- `notifyListeners()` triggers UI rebuilds on state changes
- Firestore snapshots automatically trigger provider updates for group rooms

### Navigation

The app uses named routes with **Cupertino page transitions** for iOS-native feel:
- `/` → ModeSelectionScreen (initial route)
- `/timer` → TimerScreen
- `/group-room` → GroupRoomScreen

Navigation handled via `CupertinoPageRoute` with global gradient background layer.

### Notification System

Local notifications use `flutter_local_notifications` plugin with timezone support:
- **Android**: Channel ID `pomodoro_channel` with high importance
- **iOS**: Uses DarwinNotificationDetails
- Triggered on session completion with contextual messages (break/work)
- **Scheduled notifications** using `timezone` package with `flutter_timezone` for local timezone detection
- Initialization in `main()` with timezone configuration
- Background notification handling when app is paused/resumed

### Key Dart/Flutter Versions

- Dart SDK: ^3.9.2
- Flutter SDK: Latest stable
- Uses Material 3 design system with iOS platform target
- Null safety enabled
- Async/await and Stream support
- Zone-based error handling in `main()`

### Assets

- **Sounds**: `assets/sounds/notification.mp3`, `assets/sounds/beep.mp3` (notification audio files)
- **Images**: `assets/images/` (for future graphics/icons)

### UI Design

- **Color scheme**:
  - Gradient background (light gray to darker gray: #D1D1D1 → #B0B0B0)
  - Primary: Green (#A9FFA6) for branding
  - CTA: Pink (#F4C3F1) for call-to-action buttons
- **Typography**: SF Pro Text (`.SF Pro Text`) font family applied globally
- **Glassmorphism**: Backdrop blur effects with semi-transparent white overlays
- **Icons**: Cupertino (iOS-style) icons from `CupertinoIcons` class
- **Responsive layout**: SafeArea, flexible padding, CupertinoPageRoute transitions

### Linting & Code Quality

- Linting rules defined in `analysis_options.yaml`
- Uses `flutter_lints` package (^5.0.0) for recommended best practices
- Run `flutter analyze` before commits
- Use `dart format .` for consistent code formatting

## Dependencies

### Production Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| **provider** | ^6.1.1 | State management (ChangeNotifier pattern) |
| **flutter_local_notifications** | ^17.0.0 | OS-level notifications |
| **audioplayers** | ^6.5.1 | Audio playback for notification sounds |
| **vibration** | ^3.1.4 | Haptic feedback |
| **percent_indicator** | ^4.2.3 | Circular progress widget |
| **google_fonts** | ^6.1.0 | Extended font support |
| **cupertino_icons** | ^1.0.8 | iOS-style icons |
| **share_plus** | ^10.1.0 | Native share sheet for room codes |
| **timezone** | ^0.9.4 | Timezone-aware scheduled notifications |
| **flutter_timezone** | ^5.0.1 | Device timezone detection |
| **firebase_core** | ^3.6.0 | Firebase initialization |
| **firebase_auth** | ^5.3.1 | User authentication |
| **cloud_firestore** | ^5.4.4 | Real-time database |
| **wakelock_plus** | ^1.2.8 | Keep screen awake during study sessions |

### Dev Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| **flutter_test** | sdk | Testing framework |
| **fake_async** | ^1.3.1 | Testing async code |
| **flutter_lints** | ^5.0.0 | Recommended lints |

## Common Development Tasks

### Adding a New Feature

1. Determine if feature requires state management (add method to `PomodoroProvider` or `RoomProvider` if needed)
2. Create UI screen in `lib/screens/` or widget in `lib/widgets/`
3. Consume provider state using `Consumer<T>` or `context.read<T>()` pattern
4. Register route in `main.dart` if new screen
5. Update `lib/core/design_system.dart` if new design tokens needed
6. Run `flutter analyze` and `flutter test` to validate

### Debugging Timer Issues

- Timer is managed by `Timer.periodic()` in `PomodoroProvider._startTimer()`
- Session completion is checked every second in the timer callback
- Ensure `_handleSessionComplete()` is properly triggered for state transitions
- Check `PomodoroSyncService` for group room sync issues
- Verify `_isProcessingRemoteUpdate` flag to avoid circular updates

### Customizing Durations

- Standard durations defined as static constants in `StudySession`
- Default work duration adjustable via `adjustDefaultWorkDuration()` in provider
- Burn mode affects session creation but not standard durations

### Testing Notifications

- Ensure audio files exist in `assets/sounds/` (fallback to beep.mp3 if notification.mp3 missing)
- Local notifications require platform-specific setup in Android/iOS native code
- Test on actual device or simulator with appropriate permissions granted
- Check timezone configuration in `main.dart` for scheduled notifications

### Working with Group Rooms

- Room codes are 9-character alphanumeric strings (uppercase, no ambiguous chars)
- Creating a room: `context.read<RoomProvider>().createRoom()`
- Joining a room: `context.read<RoomProvider>().joinRoom(code)`
- Leaving a room: `context.read<RoomProvider>().leaveRoom()`
- Listen to room changes: `Consumer<RoomProvider>(builder: (ctx, provider, child) => ...)`
- Timer sync happens automatically when `PomodoroProvider.setRoomProvider()` is called in `main.dart`

### Firebase Setup

1. Ensure `firebase_options.dart` is generated via FlutterFire CLI:
   ```bash
   flutterfire configure
   ```
2. Select your Firebase project or create a new one
3. Platform-specific configuration files are auto-generated (GoogleService-Info.plist for iOS, google-services.json for Android)
4. Firestore security rules should be configured in Firebase Console (current schema: `rooms/`, `students/`)

### Error Handling

- All Firebase operations wrapped in try-catch with `debugPrint` logging
- `RoomProvider` exposes `lastError` property for UI error display
- Zone-based error handling in `main()` catches unhandled exceptions
- FlutterError.onError configured for framework-level errors

## Project File Structure

```
lib/
├── core/
│   └── design_system.dart          # Centralized design tokens & utilities
├── models/
│   ├── group_room.dart             # Group room and timer state models
│   └── study_session.dart          # Study session data model
├── providers/
│   ├── pomodoro_provider.dart      # Main timer state management
│   └── room_provider.dart          # Group room state management
├── screens/
│   ├── mode_selection_screen.dart  # Initial mode selection screen
│   ├── timer_screen.dart           # Main Pomodoro timer screen
│   └── group_room_screen.dart      # Group study room screen
├── services/
│   ├── auth_service.dart           # Firebase Authentication wrapper
│   ├── database_service.dart       # Firestore data operations
│   ├── pomodoro_notification_service.dart  # Notification logic
│   ├── pomodoro_timer_service.dart         # Core timer logic
│   └── pomodoro_sync_service.dart          # Group sync logic
├── widgets/
│   └── circular_slider.dart        # Custom time adjustment widget
├── firebase_options.dart           # Firebase config (auto-generated)
└── main.dart                       # App entry point

assets/
├── sounds/                         # Audio files for notifications
└── images/                         # App images/icons
```

## Development Notes

- **Zone-based error handling**: All errors are caught in `runZonedGuarded` with proper logging
- **App lifecycle observer**: `MyApp` observes app lifecycle to handle background/foreground transitions
- **Provider dependencies**: `PomodoroProvider` depends on `RoomProvider` via `ChangeNotifierProxyProvider`
- **Firebase initialization**: Async initialization in `main()` before `runApp()`
- **Timezone configuration**: Device timezone detected and configured for notification scheduling
- **Platform target**: iOS platform set in theme for Cupertino-style behavior on all platforms
- **Background transparency**: Scaffold background is transparent, gradient applied globally in route builder
