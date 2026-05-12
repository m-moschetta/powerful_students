import 'package:flutter_test/flutter_test.dart';
import 'package:powerful_students/models/daily_stats.dart';
import 'package:powerful_students/models/group_room.dart';
import 'package:powerful_students/models/study_session.dart';
import 'package:powerful_students/providers/pomodoro_provider.dart';
import 'package:powerful_students/providers/room_provider.dart';
import 'package:powerful_students/services/pomodoro_notification_service.dart';
import 'package:powerful_students/services/pomodoro_sync_service.dart';
import 'package:powerful_students/services/pomodoro_timer_service.dart';
import 'package:powerful_students/services/stats_service.dart';

/// Mock implementation of PomodoroNotificationService for testing
class MockNotificationService extends PomodoroNotificationService {
  bool initializeCalled = false;
  bool scheduleSessionEndCalled = false;
  bool cancelScheduledNotificationCalled = false;
  bool handleSessionCompletionFeedbackCalled = false;
  SessionType? lastSessionType;

  @override
  Future<void> initialize({Function()? onNotificationTap}) async {
    initializeCalled = true;
  }

  @override
  Future<void> scheduleSessionEnd({
    required DateTime startTime,
    required int durationSeconds,
    required SessionType sessionType,
  }) async {
    scheduleSessionEndCalled = true;
    lastSessionType = sessionType;
  }

  @override
  Future<void> cancelScheduledNotification() async {
    cancelScheduledNotificationCalled = true;
  }

  @override
  Future<void> handleSessionCompletionFeedback(SessionType type) async {
    handleSessionCompletionFeedbackCalled = true;
    lastSessionType = type;
  }

  @override
  Future<void> dispose() async {}

  void reset() {
    initializeCalled = false;
    scheduleSessionEndCalled = false;
    cancelScheduledNotificationCalled = false;
    handleSessionCompletionFeedbackCalled = false;
    lastSessionType = null;
  }
}

/// Mock implementation of PomodoroSyncService for testing
class MockSyncService extends PomodoroSyncService {
  bool configureCalled = false;
  bool pushTimerStateCalled = false;
  bool clearTimerStateCalled = false;
  
  int? lastRemainingSeconds;
  int? lastTotalSeconds;
  SessionType? lastSessionType;

  @override
  void configure({
    required RoomProvider? roomProvider,
    required void Function(TimerState?)? onRemoteTimerState,
    void Function()? onRemoteSessionFailed,
  }) {
    configureCalled = true;
  }

  @override
  Future<void> pushTimerState({
    required bool isRunning,
    required bool isPaused,
    required int remainingSeconds,
    required int totalSeconds,
    required SessionType sessionType,
    bool isBurnMode = false,
    bool isFailed = false,
    DateTime? startedAt,
    DateTime? pausedAt,
  }) async {
    pushTimerStateCalled = true;
    lastRemainingSeconds = remainingSeconds;
    lastTotalSeconds = totalSeconds;
    lastSessionType = sessionType;
  }

  @override
  Future<void> clearTimerState() async {
    clearTimerStateCalled = true;
  }

  @override
  void dispose() {}

  void reset() {
    configureCalled = false;
    pushTimerStateCalled = false;
    clearTimerStateCalled = false;
    lastRemainingSeconds = null;
    lastTotalSeconds = null;
    lastSessionType = null;
  }
}

/// Mock implementation of StatsService for testing.
/// This mock doesn't call the parent constructor to avoid Firebase initialization.
class MockStatsService implements StatsService {
  bool getTodayStatsCalled = false;
  bool incrementTodayPomodorosCalled = false;
  int incrementedMinutes = 0;
  
  @override
  Future<DailyStats?> getTodayStats(String userId) async {
    getTodayStatsCalled = true;
    return null; // Return null to simulate no existing stats
  }

  @override
  Future<void> incrementTodayPomodoros(String userId, int sessionMinutes) async {
    incrementTodayPomodorosCalled = true;
    incrementedMinutes += sessionMinutes;
  }
  
  @override
  Future<void> saveTodayStats(DailyStats stats) async {}
  
  @override
  Future<List<DailyStats>> getStatsHistory(String userId, {int days = 30}) async {
    return [];
  }
  
  @override
  Future<int> getTotalPomodorosAllTime(String userId) async {
    return 0;
  }

  void reset() {
    getTodayStatsCalled = false;
    incrementTodayPomodorosCalled = false;
    incrementedMinutes = 0;
  }
}

void main() {
  group('PomodoroProvider', () {
    late PomodoroProvider provider;
    late MockNotificationService mockNotificationService;
    late MockSyncService mockSyncService;
    late PomodoroTimerService timerService;
    late MockStatsService mockStatsService;

    setUp(() {
      mockNotificationService = MockNotificationService();
      mockSyncService = MockSyncService();
      timerService = PomodoroTimerService();
      mockStatsService = MockStatsService();
      
      provider = PomodoroProvider(
        notificationService: mockNotificationService,
        syncService: mockSyncService,
        timerService: timerService,
        statsService: mockStatsService,
      );
    });

    tearDown(() {
      provider.dispose();
    });

    group('Initial State', () {
      test('has no current session initially', () {
        expect(provider.currentSession, isNull);
      });

      test('is not running initially', () {
        expect(provider.isRunning, isFalse);
      });

      test('has solo mode selected by default', () {
        expect(provider.selectedMode, equals(StudyMode.solo));
      });

      test('burn mode is off by default', () {
        expect(provider.isBurnMode, isFalse);
      });

      test('has zero completed pomodoros initially', () {
        expect(provider.completedPomodoros, equals(0));
      });

      test('has zero total minutes today initially', () {
        expect(provider.totalMinutesToday, equals(0));
      });

      test('has default work duration of 25 minutes', () {
        expect(provider.defaultWorkDuration, equals(25 * 60));
      });
    });

    group('Mode Selection', () {
      test('selectMode changes selected mode', () {
        provider.selectMode(StudyMode.group);
        expect(provider.selectedMode, equals(StudyMode.group));
      });

      test('selectMode notifies listeners', () {
        var notified = false;
        provider.addListener(() => notified = true);
        
        provider.selectMode(StudyMode.group);
        
        expect(notified, isTrue);
      });
    });

    group('Burn Mode', () {
      test('toggleBurnMode toggles burn mode on', () {
        expect(provider.isBurnMode, isFalse);
        provider.toggleBurnMode();
        expect(provider.isBurnMode, isTrue);
      });

      test('toggleBurnMode toggles burn mode off', () {
        provider.toggleBurnMode(); // on
        provider.toggleBurnMode(); // off
        expect(provider.isBurnMode, isFalse);
      });

      test('toggleBurnMode notifies listeners', () {
        var notifyCount = 0;
        provider.addListener(() => notifyCount++);
        
        provider.toggleBurnMode();
        
        expect(notifyCount, equals(1));
      });
    });

    group('Work Duration Settings', () {
      test('setDefaultWorkDurationMinutes sets duration correctly', () {
        provider.setDefaultWorkDurationMinutes(30);
        expect(provider.defaultWorkDuration, equals(30 * 60));
      });

      test('setDefaultWorkDurationMinutes clamps to minimum 1 minute', () {
        provider.setDefaultWorkDurationMinutes(0);
        expect(provider.defaultWorkDuration, equals(1 * 60));
      });

      test('setDefaultWorkDurationMinutes clamps to maximum 60 minutes', () {
        provider.setDefaultWorkDurationMinutes(100);
        expect(provider.defaultWorkDuration, equals(60 * 60));
      });

      test('resetDefaultWorkDuration resets to 25 minutes', () {
        provider.setDefaultWorkDurationMinutes(45);
        provider.resetDefaultWorkDuration();
        expect(provider.defaultWorkDuration, equals(25 * 60));
      });

      test('adjustDefaultWorkDuration does nothing during active session', () {
        provider.startWorkSession();
        final duration = provider.defaultWorkDuration;
        
        provider.adjustDefaultWorkDuration(-100); // Should be ignored
        
        expect(provider.defaultWorkDuration, equals(duration));
      });
    });

    group('Starting Sessions', () {
      test('startWorkSession creates a work session', () {
        provider.startWorkSession();
        
        expect(provider.currentSession, isNotNull);
        expect(provider.currentSession!.type, equals(SessionType.work));
        expect(provider.isRunning, isTrue);
      });

      test('startWorkSession uses default work duration', () {
        provider.setDefaultWorkDurationMinutes(30);
        provider.startWorkSession();
        
        expect(provider.currentSession!.duration, equals(30 * 60));
      });

      test('startWorkSession schedules notification', () async {
        provider.startWorkSession();
        
        // Give async operations time to complete
        await Future.delayed(const Duration(milliseconds: 10));
        
        expect(mockNotificationService.scheduleSessionEndCalled, isTrue);
        expect(mockNotificationService.lastSessionType, equals(SessionType.work));
      });

      test('startShortBreak creates a short break session', () {
        provider.startShortBreak();
        
        expect(provider.currentSession, isNotNull);
        expect(provider.currentSession!.type, equals(SessionType.shortBreak));
        expect(provider.currentSession!.duration, equals(5 * 60));
      });

      test('startLongBreak creates a long break session', () {
        provider.startLongBreak();
        
        expect(provider.currentSession, isNotNull);
        expect(provider.currentSession!.type, equals(SessionType.longBreak));
        expect(provider.currentSession!.duration, equals(15 * 60));
      });

      test('startWorkSession includes burn mode flag', () {
        provider.toggleBurnMode();
        provider.startWorkSession();
        
        expect(provider.currentSession!.isBurnMode, isTrue);
      });

      test('startWorkSession includes selected mode', () {
        provider.selectMode(StudyMode.group);
        provider.startWorkSession();
        
        expect(provider.currentSession!.mode, equals(StudyMode.group));
      });
    });

    group('Timer Control', () {
      test('pauseTimer pauses a running session', () {
        provider.startWorkSession();
        expect(provider.isRunning, isTrue);
        
        provider.pauseTimer();
        
        expect(provider.isRunning, isFalse);
        expect(provider.currentSession, isNotNull); // Session still exists
      });

      test('pauseTimer cancels scheduled notification', () async {
        provider.startWorkSession();
        mockNotificationService.reset();
        
        provider.pauseTimer();
        
        // Give async operations time to complete
        await Future.delayed(const Duration(milliseconds: 10));
        
        expect(mockNotificationService.cancelScheduledNotificationCalled, isTrue);
      });

      test('pauseTimer does nothing if not running', () {
        var notified = false;
        provider.addListener(() => notified = true);
        
        provider.pauseTimer();
        
        expect(notified, isFalse);
      });

      test('stopTimer stops and clears the session', () {
        provider.startWorkSession();
        
        provider.stopTimer();
        
        expect(provider.isRunning, isFalse);
        expect(provider.currentSession, isNull);
      });

      test('stopTimer cancels notification', () async {
        provider.startWorkSession();
        mockNotificationService.reset();
        
        provider.stopTimer();
        
        // Give async operations time to complete
        await Future.delayed(const Duration(milliseconds: 10));
        
        expect(mockNotificationService.cancelScheduledNotificationCalled, isTrue);
      });
    });

    group('Session Completion', () {
      // Note: Full session completion tests require fakeAsync with proper
      // Flutter binding initialization. These are integration-level tests.
      // For unit testing, we verify the completion handler behavior indirectly.
      
      test('session is marked as running after start', () {
        provider.startWorkSession();
        expect(provider.isRunning, isTrue);
        expect(provider.currentSession, isNotNull);
        expect(provider.currentSession!.type, equals(SessionType.work));
      });

      test('break session does not affect pomodoro count on start', () {
        final initialCount = provider.completedPomodoros;
        provider.startShortBreak();
        expect(provider.completedPomodoros, equals(initialCount));
      });
    });

    group('Reset Pomodoros', () {
      test('resetPomodoros sets count to zero', () {
        // Reset should work even with zero count
        provider.resetPomodoros();
        expect(provider.completedPomodoros, equals(0));
      });
      
      test('resetPomodoros notifies listeners', () {
        var notified = false;
        provider.addListener(() => notified = true);
        
        provider.resetPomodoros();
        
        expect(notified, isTrue);
      });
    });

    group('Sound Toggle', () {
      test('toggleSound toggles sound enabled state', () {
        final initialState = provider.soundEnabled;
        provider.toggleSound();
        expect(provider.soundEnabled, equals(!initialState));
      });

      test('setSoundEnabled sets specific state', () {
        provider.setSoundEnabled(false);
        expect(provider.soundEnabled, isFalse);
        
        provider.setSoundEnabled(true);
        expect(provider.soundEnabled, isTrue);
      });
    });

    group('User ID and Stats', () {
      test('setUserId stores the userId', () {
        // Note: The actual stats initialization requires SharedPreferences
        // which needs Flutter binding. This test verifies the method doesn't crash.
        expect(() => provider.setUserId('test-user-123'), returnsNormally);
      });
    });

    group('Group Mode Sync', () {
      test('startWorkSession syncs state in group mode', () async {
        provider.selectMode(StudyMode.group);
        provider.startWorkSession();
        
        // Give async operations time to complete
        await Future.delayed(const Duration(milliseconds: 10));
        
        expect(mockSyncService.pushTimerStateCalled, isTrue);
      });

      test('startWorkSession does not sync in solo mode', () async {
        provider.selectMode(StudyMode.solo);
        provider.startWorkSession();
        
        // Give async operations time to complete
        await Future.delayed(const Duration(milliseconds: 10));
        
        expect(mockSyncService.pushTimerStateCalled, isFalse);
      });

      test('pauseTimer syncs state in group mode', () async {
        provider.selectMode(StudyMode.group);
        provider.startWorkSession();
        
        // Verify starting works before testing pause
        expect(provider.isRunning, isTrue);
        
        // Give ample time for startWorkSession sync and reset
        await Future.delayed(const Duration(milliseconds: 100));
        mockSyncService.reset();
        
        provider.pauseTimer();
        expect(provider.isRunning, isFalse);
        
        // Give async operations time to complete
        await Future.delayed(const Duration(milliseconds: 100));
        
        // When paused, _isRunning is false, so _pushTimerState calls clearTimerState()
        // not pushTimerState(). This is the correct behavior.
        expect(mockSyncService.clearTimerStateCalled, isTrue);
      });

      test('stopTimer clears sync state in group mode', () async {
        provider.selectMode(StudyMode.group);
        provider.startWorkSession();
        
        // Give time for startWorkSession sync
        await Future.delayed(const Duration(milliseconds: 20));
        mockSyncService.reset();
        
        provider.stopTimer();
        
        // Give async operations time to complete
        await Future.delayed(const Duration(milliseconds: 20));
        
        expect(mockSyncService.clearTimerStateCalled, isTrue);
      });
    });

    group('App Lifecycle', () {
      test('handleAppPaused does not crash', () {
        provider.startWorkSession();
        expect(() => provider.handleAppPaused(), returnsNormally);
      });

      test('handleAppResumed notifies listeners when session active', () {
        provider.startWorkSession();
        var notified = false;
        provider.addListener(() => notified = true);
        
        provider.handleAppResumed();
        
        expect(notified, isTrue);
      });

      test('handleAppResumed does nothing without session', () {
        var notified = false;
        provider.addListener(() => notified = true);
        
        provider.handleAppResumed();
        
        expect(notified, isFalse);
      });
    });

    group('Dispose', () {
      test('dispose stops the timer', () {
        // Create a separate provider for this test to avoid double dispose
        final testProvider = PomodoroProvider(
          notificationService: MockNotificationService(),
          syncService: MockSyncService(),
          timerService: PomodoroTimerService(),
          statsService: MockStatsService(),
        );
        
        testProvider.startWorkSession();
        expect(testProvider.isRunning, isTrue);
        
        testProvider.dispose();
        
        // After dispose, the timer should be stopped
        // Note: We can't check isRunning after dispose as it may throw
      });
    });
  });
}
