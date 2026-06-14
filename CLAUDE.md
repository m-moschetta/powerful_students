# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Powerful Students** is a Flutter-based collaborative Pomodoro timer application designed for students. It combines:

- **Customizable Pomodoro sessions** (solo, group, or AI-guided "buddy" mode) with break management and a "burn mode" for intensive focus.
- **Real-time synchronized group study rooms** backed by Cloud Firestore (shareable 9-char room codes).
- **AI Study Buddy chat** ("Powerful Buddy") powered by **OpenRouter** with streaming responses (SSE), markdown rendering, and a configurable system prompt / model / API key.
- **Daily stats tracking** of completed Pomodoros and minutes studied, stored per-user in Firestore.
- **iOS 18/26-style Liquid Glass design system** with localization (Italian + English).

The app targets iOS-first aesthetics but builds for Android and web as well.

## Build Commands

### Building the Project

```bash
# Install dependencies
flutter pub get

# Generate localization files (Italian + English from .arb files)
flutter gen-l10n

# Build for iOS / Android / web
flutter build ios --debug
flutter build apk --debug
flutter build web

# Run in development mode
flutter run
```

`flutter: generate: true` is set in `pubspec.yaml`, so `flutter pub get` and `flutter run` will regenerate localizations automatically from `lib/l10n/app_en.arb` and `lib/l10n/app_it.arb`.

### Testing

```bash
flutter test                # Run all tests
flutter test --coverage     # With coverage
flutter analyze             # Static analysis
dart format .               # Format code
```

## Environment Configuration

The app reads its AI configuration from a `.env` file at the repo root, loaded via `flutter_dotenv` in `main()`:

```env
OPENROUTER_API_KEY=sk-or-v1-...
# AI_BASE_URL=https://openrouter.ai/api/v1   # optional override
```

**Notes:**

- `.env` is declared as a Flutter asset in `pubspec.yaml` (`assets: [.env]`) so it is bundled with the app. Any key shipped this way is effectively shipped to users — prefer the in-app Settings screen for production keys, or proxy through a backend.
- `.env` is currently **not** in `.gitignore`; add it before committing real credentials.
- Users can override `apiKey`, `model`, `systemPrompt`, and `baseUrl` at runtime via `SettingsScreen`; overrides are persisted in `SharedPreferences` and take precedence over `.env`.

## Architecture Overview

### Core Pattern

**MVVM with a service layer**, wired via the `provider` package:

```
Screens / Widgets
   └── Providers (ChangeNotifier)
          └── Services (Firebase, HTTP, OS)
                 └── Firestore / OpenRouter / Local OS APIs
```

`PomodoroProvider` depends on `RoomProvider` via `ChangeNotifierProxyProvider`, and `ChatProvider` depends on `SettingsProvider` the same way (see `main.dart`).

### State Management Layer (4 providers)

**PomodoroProvider** (`lib/providers/pomodoro_provider.dart`)
- Timer lifecycle (start, pause, resume, stop) via `Timer.periodic()`.
- Tracks completed Pomodoros, automatic work → short break → long break transitions.
- Triggers audio, vibration, and scheduled local notifications.
- Holds the selected `StudyMode` (`solo`, `group`, `buddy`) and the burn-mode toggle.
- Adjustable default work duration via the timer screen UI.
- Integrates with `RoomProvider` (via `setRoomProvider()`) so timer state is synced to/from Firestore when in group mode.
- Implements app-lifecycle handlers (`handleAppPaused`, `handleAppResumed`) for background/foreground transitions.
- Holds a device-scoped `userId` initialized from `SharedPreferences` (key `device_user_id`).

**RoomProvider** (`lib/providers/room_provider.dart`)
- Manages group study rooms in Cloud Firestore (`rooms/` collection).
- Creates rooms with unique 9-char alphanumeric codes (uppercase, no ambiguous chars).
- `createRoom()`, `joinRoom(code)`, `leaveRoom()` with transaction-based safety.
- Streams room state via Firestore snapshots; pushes timer state from local provider.
- Exposes `lastError` for UI error display.

**SettingsProvider** (`lib/providers/settings_provider.dart`)
- Persists AI settings in `SharedPreferences`: `openrouter_api_key`, `ai_system_prompt`, `ai_model`, `ai_base_url`.
- Holds the `defaultSystemPrompt` for "Powerful Buddy" (Italian-first study assistant); `effectiveSystemPrompt` returns the user override or the default.
- Fetches the available models list from `<baseUrl>/models` (`fetchAvailableModels()`), with a fallback list (`fallbackAiModels`) when offline or unauthenticated.
- Initialized in `main()` **before** `runApp` so the first frame already has settings.

**ChatProvider** (`lib/providers/chat_provider.dart`)
- Owns the in-memory chat history (`List<ChatMessage>`) and the streaming state.
- Tracks a `ConversationStep` (`diagnosis` → `response` → `action`) used by the UI to show the "start session" action prompt after the assistant finishes responding.
- `sendMessage(text)`: appends user message + a streaming assistant placeholder, then consumes `AiChatService.streamChatCompletion()` and appends deltas to the placeholder.
- `stopStreaming()`, `clearChat()`, `continueConversation()` for UX controls.
- `updateSettings(SettingsProvider)` is called by `ChangeNotifierProxyProvider` to sync `apiKey`, `model`, `systemPrompt`, `baseUrl` into the underlying service whenever settings change.

### Service Layer

**AiChatService** (`lib/services/ai_chat_service.dart`)
- Wraps `POST {baseUrl}/chat/completions` against OpenRouter (or any OpenAI-compatible endpoint).
- Streams Server-Sent Events: splits on lines starting with `data: `, decodes each chunk's `choices[0].delta.content`, yields strings.
- Headers include `Authorization: Bearer <key>`, plus `HTTP-Referer` and `X-Title` for OpenRouter attribution.
- Reads `apiKeyOverride` / `modelOverride` / `systemPromptOverride` / `baseUrlOverride` set by `ChatProvider`; falls back to `dotenv.env['OPENROUTER_API_KEY']`.
- 30-second timeouts on both connect and stream-chunk read to detect stalled connections.
- Emits user-facing Italian error strings on failure (no exceptions cross the boundary).

**StatsService** (`lib/services/stats_service.dart`)
- CRUD over the `daily_stats/` Firestore collection.
- Doc ID format: `{userId}_YYYY-MM-DD` (one doc per user per day).
- `saveTodayStats`, `getTodayStats` (auto-creates today's doc if missing), `incrementTodayPomodoros(userId, sessionMinutes)` using `FieldValue.increment` for atomic updates.
- `getStatsHistory(userId, days)` and `getTotalPomodorosAllTime(userId)` for future charts/badges.
- Supports dependency injection of `FirebaseFirestore` for tests.

**PomodoroNotificationService** (`lib/services/pomodoro_notification_service.dart`)
- Wraps `flutter_local_notifications` + `timezone` for scheduled OS-level notifications.
- Android channel `pomodoro_channel` (high importance); iOS Darwin notification details.
- Triggers contextual messages on session completion (work / break / long break).

**PomodoroTimerService** (`lib/services/pomodoro_timer_service.dart`)
- Tick-based countdown abstraction used by the provider.

**PomodoroSyncService** (`lib/services/pomodoro_sync_service.dart`)
- Bidirectional timer state sync for group rooms.
- Pushes local timer state to Firestore (`rooms/{code}.timerState`).
- Receives remote updates via callback; uses `_isProcessingRemoteUpdate` to prevent circular update loops.

> **Removed in this iteration:** `AuthService`, `DatabaseService`, and the vendored `third_party/wakelock_plus/` plugin. `wakelock_plus` is now consumed from pub (`^1.2.8`). User identity is now device-scoped via `SharedPreferences` (`device_user_id`) — no Firebase Auth sign-in flow.

### Models

**StudySession** (`lib/models/study_session.dart`)
- Enums: `StudyMode { solo, group, buddy }`, `SessionType { work, shortBreak, longBreak }`.
- Standard durations: 25-min work, 5-min short break, 15-min long break.
- Factory constructors: `.work()`, `.shortBreak()`, `.longBreak()`, `.custom()`.
- Computed: `remainingTime`, `progress`, `formattedRemainingTime` (MM:SS), `isCompleted`.

**GroupRoom** (`lib/models/group_room.dart`)
- Firestore-backed: `code`, `ownerId`, `memberIds`, `createdAt`, `updatedAt`, `timerState`.
- Nested `TimerState` for real-time synchronization.

**ChatMessage** (`lib/models/chat_message.dart`)
- `id`, `role` (`ChatRole.user | ChatRole.assistant`), `content`, `timestamp`, `isStreaming`.
- `copyWith` (immutable updates during streaming), `toApiMessage()` for OpenRouter wire format.

**DailyStats** (`lib/models/daily_stats.dart`)
- `id` (`{userId}_YYYY-MM-DD`), `userId`, `date`, `completedPomodoros`, `totalMinutes`, `createdAt`, `updatedAt`.
- `static generateId(userId, date)`, `factory createToday(userId)`, `fromFirestore` / `toFirestore`.

### UI Layer

**Screens** (`lib/screens/`)

| Screen | Purpose |
|---|---|
| `MainNavigationScreen` | Root after splash. **Horizontal `PageView`** with two pages: `ModeSelectionScreen` (page 0) and `ChatScreen` (page 1). Dismisses the keyboard on scroll. Wires the chat → "Start Buddy Session" → `/timer` flow. |
| `ModeSelectionScreen` | Pick `solo` or `group` mode, toggle burn mode, navigate to chat. |
| `TimerScreen` | Main Pomodoro timer with `ModernTimerCircle`, controls, and counters. |
| `GroupRoomScreen` | Group room UI: room code display + share, member list, synchronized timer. Composed of widgets under `lib/widgets/group_room/`. |
| `ChatScreen` | "Powerful Buddy" chat. Renders markdown via `flutter_markdown`, streams assistant replies, shows a contextual "Start a session" action prompt after the assistant finishes (`shouldShowActionPrompt`). |
| `SettingsScreen` | API key, base URL, model picker (with `fetchAvailableModels`), custom system prompt editor. |

**Widget composition**

- `lib/widgets/chat/` — `chat_header`, `chat_empty_state`, `chat_input_bar`, `chat_bubble`, `chat_action_prompt`, plus a `chat.dart` barrel.
- `lib/widgets/group_room/` — `group_room_header`, `group_room_info_card`, `group_room_timer`, `create_join_room_buttons`, `group_room_bottom_actions`, `session_failed_screen`, `session_completed_screen`, plus a `group_room.dart` barrel.
- `lib/widgets/modern_timer_circle.dart` — custom circular timer (replaces the older `percent_indicator`-based widget and the removed `circular_slider.dart`).

**Design System** (`lib/core/design_system.dart`)
- Centralized tokens: `AppColors`, `AppTypography`, spacing, radii, icons.
- Liquid Glass / glassmorphism helpers (backdrop blur, semi-transparent overlays).
- Gradient background (light gray → darker gray: `#D1D1D1` → `#B0B0B0`).
- Brand colors: primary green `#A9FFA6`, pink CTA `#F4C3F1`.
- Typography: SF Pro Text family applied globally via `MaterialApp.theme.fontFamily`.

### Localization

- ARB sources in `lib/l10n/app_en.arb` and `lib/l10n/app_it.arb`.
- Generated Dart files: `lib/l10n/app_localizations.dart` (+ `_en`, `_it`).
- Accessed via `AppLocalizations.of(context)!.<key>`; supported locales and delegates are wired in `MaterialApp` in `main.dart`.
- `MaterialApp.onGenerateTitle` uses `AppLocalizations.of(context)!.appTitle`.

### Routing

`MaterialApp.onGenerateRoute` wraps every route in a `CupertinoPageRoute`:

| Route | Screen |
|---|---|
| `/` (default fallback) | `MainNavigationScreen` |
| `/timer` | `TimerScreen` |
| `/group-room` | `GroupRoomScreen` |
| `/settings` | `SettingsScreen` |

Inside `MainNavigationScreen`, navigation between Mode Selection and Chat is **not** a new route — it's a `PageController.animateToPage`.

### Firebase Integration

**Services in use**
- **Firebase Core**: initialization in `main()` (with `DefaultFirebaseOptions.currentPlatform`).
- **Cloud Firestore**: rooms and daily stats.
- **Firebase Auth**: dependency is still in `pubspec.yaml` (`firebase_auth: ^5.3.1`) but **no active sign-in flow** — `AuthService` was removed and the app uses a device-local `userId` from `SharedPreferences`. If you don't plan to reintroduce auth, the dependency can be dropped.

**Firestore schema**

```
rooms/
  {roomCode}/                       # 9-char alphanumeric, uppercase
    - code: String
    - ownerId: String
    - members: Array<String>        # member IDs
    - createdAt: Timestamp
    - updatedAt: Timestamp
    - timerState: Map
        - isRunning: bool
        - isPaused: bool
        - remainingSeconds: int
        - totalSeconds: int
        - sessionType: String       # 'work' | 'shortBreak' | 'longBreak'
        - startedAt: Timestamp?
        - pausedAt: Timestamp?

daily_stats/
  {userId}_{YYYY-MM-DD}/            # one doc per user per day
    - userId: String
    - date: Timestamp               # midnight of that day
    - completedPomodoros: int
    - totalMinutes: int
    - createdAt: Timestamp
    - updatedAt: Timestamp
```

Configure Firestore security rules in the Firebase Console accordingly.

### State Management Wiring (in `main.dart`)

```
MultiProvider
├── ChangeNotifierProvider<RoomProvider>
├── ChangeNotifierProvider<SettingsProvider>.value     # initialized before runApp
├── ChangeNotifierProxyProvider<RoomProvider, PomodoroProvider>
│      └── calls pomodoro.setRoomProvider(room) on update
└── ChangeNotifierProxyProvider<SettingsProvider, ChatProvider>
       └── calls chat.updateSettings(settings) on update
```

`SettingsProvider.initialize()` is awaited before `runApp` so chat & settings are usable on the first frame. The user ID is read or created (`user_<millis>`) in `_initializeUserId()` and pushed into `PomodoroProvider`.

### Notification System

- `flutter_local_notifications` + `timezone`/`flutter_timezone` (timezone configured in `_configureTimezone()` before `runApp`).
- Android: channel `pomodoro_channel`, high importance.
- iOS: `DarwinNotificationDetails`.
- Triggered on session completion with contextual copy (break / work / long break).
- Audio cues from `assets/sounds/` (placeholder `.gitkeep` only — add `notification.mp3` / `beep.mp3` if you want sound).

### Assets

- `assets/sounds/` — notification audio (currently only `.gitkeep`; placeholder).
- `assets/images/` — Bricky character art: `bricky_logo.png`, `bricky_burn.png`, `bricky_burn_small.png`, `bricky_group.png`, `Bricky rotto.png`, `1 mattoncino_2 mattoncini.png`.
- `.env` — listed as an asset for `flutter_dotenv`.

### Key Versions

- Dart SDK: `^3.9.2`
- Material 3 + `platform: TargetPlatform.iOS` (Cupertino-style behavior on all platforms)
- Null safety, async/await, streams
- Zone-based error handling in `main()` (`runZonedGuarded`)

## Dependencies (pubspec.yaml)

### Production

| Package | Version | Purpose |
|---|---|---|
| `provider` | ^6.1.1 | State management |
| `flutter_local_notifications` | ^17.0.0 | OS notifications |
| `audioplayers` | ^6.5.1 | Audio playback |
| `vibration` | ^3.1.4 | Haptic feedback |
| `percent_indicator` | ^4.2.3 | Circular progress |
| `google_fonts` | ^6.1.0 | Extended fonts |
| `cupertino_icons` | ^1.0.8 | iOS-style icons |
| `share_plus` | ^10.1.0 | Native share sheet (room codes) |
| `timezone` | ^0.9.4 | Timezone-aware scheduling |
| `flutter_timezone` | ^5.0.1 | Device timezone detection |
| `firebase_core` | ^3.6.0 | Firebase init |
| `firebase_auth` | ^5.3.1 | (currently unused — see Firebase Integration note) |
| `cloud_firestore` | ^5.4.4 | Rooms + stats |
| `wakelock_plus` | ^1.2.8 | Keep screen awake during sessions |
| `shared_preferences` | ^2.3.5 | Local persistence (settings, userId) |
| `intl` | ^0.20.2 | Date/number formatting (l10n) |
| `flutter_localizations` | sdk | Localization runtime |
| `flutter_markdown` | ^0.7.7+1 | Rendering chat assistant markdown |
| `http` | ^1.6.0 | OpenRouter API + models list |
| `flutter_dotenv` | ^6.0.1 | `.env` loading |

### Dev

| Package | Version | Purpose |
|---|---|---|
| `flutter_test` | sdk | Test framework |
| `fake_async` | ^1.3.1 | Async test helpers |
| `flutter_lints` | ^5.0.0 | Lint rules |

## Common Development Tasks

### Adding a New Feature

1. Decide which provider owns the state (`PomodoroProvider`, `RoomProvider`, `SettingsProvider`, `ChatProvider`) or add a new one in `lib/providers/` and wire it in `main.dart`'s `MultiProvider`.
2. Add screen(s) under `lib/screens/` and break out reusable pieces into a sub-folder under `lib/widgets/` (with a barrel `<feature>.dart`).
3. Consume state via `Consumer<T>` or `context.read<T>()`/`context.watch<T>()`.
4. Register a new named route in `main.dart`'s `onGenerateRoute` switch if needed; otherwise navigate within `MainNavigationScreen`'s `PageView`.
5. Add user-facing strings to `lib/l10n/app_en.arb` and `lib/l10n/app_it.arb`, then run `flutter gen-l10n` (or just `flutter run`).
6. Run `flutter analyze` and `flutter test` before committing.

### Working with the AI Chat

- The active model, API key, base URL, and system prompt are owned by `SettingsProvider` and pushed into `AiChatService` on every settings change (via `ChatProvider.updateSettings`).
- `streamChatCompletion(messages)` expects OpenAI-style `{role, content}` maps. The system prompt is injected internally — don't include it in the `messages` list.
- The conversation step flips to `ConversationStep.action` after a successful stream so the UI can offer "Start a buddy session" (which sets `StudyMode.buddy` and pushes `/timer`).
- On the OpenRouter side, attribution headers (`HTTP-Referer`, `X-Title`) are sent on every call — update them if you rebrand or fork the app.

### Working with Group Rooms

- Codes are 9-char alphanumeric strings (uppercase, no ambiguous chars).
- Create: `context.read<RoomProvider>().createRoom()`.
- Join: `context.read<RoomProvider>().joinRoom(code)`.
- Leave: `context.read<RoomProvider>().leaveRoom()`.
- Timer sync is automatic once `PomodoroProvider.setRoomProvider()` has been called (wired in `main.dart` via `ChangeNotifierProxyProvider`).
- Listen with `Consumer<RoomProvider>` for `currentRoom`, member changes, and `lastError`.

### Debugging Timer Issues

- Tick loop is in `PomodoroProvider._startTimer()` using `Timer.periodic()`.
- Completion is detected each tick and handed to `_handleSessionComplete()`, which advances state (work → break → work …) and triggers notifications.
- For group desync, instrument `PomodoroSyncService` and verify `_isProcessingRemoteUpdate` to avoid feedback loops.

### Adding/Changing Localized Strings

1. Edit both `lib/l10n/app_en.arb` and `lib/l10n/app_it.arb` (keep keys in sync).
2. Run `flutter gen-l10n` (or rely on `flutter run` with `generate: true`).
3. Access via `AppLocalizations.of(context)!.<key>`.

### Firebase Setup

```bash
flutterfire configure
```

Regenerates `lib/firebase_options.dart` and platform configs (`GoogleService-Info.plist`, `google-services.json`). After changing the project, double-check that Firestore rules cover both `rooms/` and `daily_stats/`.

### Error Handling

- All Firebase ops are wrapped in try/catch with `debugPrint` logging.
- `RoomProvider.lastError` is exposed for UI display.
- `AiChatService` swallows network exceptions and yields a user-facing Italian error string instead of throwing.
- Top level: `runZonedGuarded` in `main()` + `FlutterError.onError = FlutterError.dumpErrorToConsole` + `platformDispatcher.onError`.

## Project File Structure

```
lib/
├── core/
│   └── design_system.dart                    # Tokens, glassmorphism, gradients
├── l10n/
│   ├── app_en.arb, app_it.arb                # Source strings
│   └── app_localizations*.dart               # Generated
├── models/
│   ├── chat_message.dart                     # AI chat message + roles
│   ├── daily_stats.dart                      # Per-day Firestore stats
│   ├── group_room.dart                       # Room + nested TimerState
│   └── study_session.dart                    # StudyMode {solo, group, buddy}, SessionType, durations
├── providers/
│   ├── chat_provider.dart                    # Chat history + streaming + ConversationStep
│   ├── pomodoro_provider.dart                # Timer + Pomodoro lifecycle
│   ├── room_provider.dart                    # Group rooms via Firestore
│   └── settings_provider.dart                # API key, model, system prompt, base URL
├── screens/
│   ├── chat_screen.dart                      # "Powerful Buddy" chat UI
│   ├── group_room_screen.dart                # Group room
│   ├── main_navigation_screen.dart           # PageView: ModeSelection ↔ Chat
│   ├── mode_selection_screen.dart            # Solo/group + open chat
│   ├── settings_screen.dart                  # AI settings UI
│   └── timer_screen.dart                     # Main timer
├── services/
│   ├── ai_chat_service.dart                  # OpenRouter SSE streaming client
│   ├── pomodoro_notification_service.dart    # Local notifications
│   ├── pomodoro_sync_service.dart            # Group room timer sync
│   ├── pomodoro_timer_service.dart           # Tick abstraction
│   └── stats_service.dart                    # daily_stats Firestore CRUD
├── widgets/
│   ├── chat/
│   │   ├── chat.dart                         # barrel
│   │   ├── chat_action_prompt.dart
│   │   ├── chat_bubble.dart
│   │   ├── chat_empty_state.dart
│   │   ├── chat_header.dart
│   │   └── chat_input_bar.dart
│   ├── group_room/
│   │   ├── group_room.dart                   # barrel
│   │   ├── create_join_room_buttons.dart
│   │   ├── group_room_bottom_actions.dart
│   │   ├── group_room_header.dart
│   │   ├── group_room_info_card.dart
│   │   ├── group_room_timer.dart
│   │   ├── session_completed_screen.dart
│   │   └── session_failed_screen.dart
│   └── modern_timer_circle.dart
├── firebase_options.dart                     # auto-generated
└── main.dart                                 # entry: dotenv, Firebase, timezone, providers, routes

assets/
├── images/                                   # Bricky character art
└── sounds/                                   # (placeholder)

.env                                          # OPENROUTER_API_KEY (bundled as asset — handle with care)
```

## Development Notes

- **Provider initialization order** — `SettingsProvider.initialize()` is awaited **before** `runApp` so the first frame has settings. The `ProxyProvider` updates then fan out to `ChatProvider`.
- **Device userId** — generated as `user_<millis>` on first launch, persisted in `SharedPreferences` (`device_user_id`). Used as the partition key for `daily_stats/` and as the room member identifier.
- **`.env` is shipped with the app** — re-evaluate this before public distribution. Treat the runtime Settings screen as the canonical key entry point.
- **Wakelock** — uses the pub package `wakelock_plus`; the old `third_party/wakelock_plus/` vendored copy was removed.
- **Removed services** — `AuthService` and `DatabaseService` no longer exist. Don't reintroduce them implicitly; if you need auth, decide first whether it replaces the device-local userId model.
- **Cupertino-first** — `MaterialApp.theme.platform = TargetPlatform.iOS`; routes wrap in `CupertinoPageRoute`. Use `CupertinoIcons` and SF Pro Text by default.
- **Localization is the source of truth** for user-facing strings — avoid hardcoding Italian/English in widgets, route everything through `AppLocalizations`.
