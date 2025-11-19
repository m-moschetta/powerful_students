import 'dart:async';
import 'package:flutter/material.dart';
import 'package:powerful_students/models/study_session.dart';
import 'package:powerful_students/models/group_room.dart';
import 'package:powerful_students/providers/room_provider.dart';
import 'package:powerful_students/services/pomodoro_notification_service.dart';
import 'package:powerful_students/services/pomodoro_sync_service.dart';
import 'package:powerful_students/services/pomodoro_timer_service.dart';

class PomodoroProvider extends ChangeNotifier {
  PomodoroProvider({
    PomodoroNotificationService? notificationService,
    PomodoroSyncService? syncService,
    PomodoroTimerService? timerService,
  })  : _notificationService =
            notificationService ?? PomodoroNotificationService(),
        _syncService = syncService ?? PomodoroSyncService(),
        _timerService = timerService ?? PomodoroTimerService();

  StudySession? _currentSession;
  bool _isRunning = false;
  bool _isDisposed = false; // Flag per prevenire callback dopo dispose
  StudyMode _selectedMode = StudyMode.solo;
  bool _isBurnMode = false;
  int _completedPomodoros = 0;
  int _defaultWorkDuration = StudySession.workDuration; // 25 minuti in secondi
  final PomodoroNotificationService _notificationService;
  final PomodoroSyncService _syncService;
  final PomodoroTimerService _timerService;

  // Getters
  StudySession? get currentSession => _currentSession;
  bool get isRunning => _isRunning;
  StudyMode get selectedMode => _selectedMode;
  bool get isBurnMode => _isBurnMode;
  int get completedPomodoros => _completedPomodoros;
  int get defaultWorkDuration => _defaultWorkDuration;

  // Inizializza le notifiche
  Future<void> initializeNotifications() async {
    await _notificationService.initialize(onNotificationTap: () {
      try {
        if (_currentSession != null && _currentSession!.isCompleted) {
          debugPrint('Notification tapped - handling completion');
          _handleSessionComplete();
        } else {
          debugPrint('Notification tapped - session not completed yet');
          notifyListeners();
        }
      } catch (e, stackTrace) {
        debugPrint('Error handling notification tap: $e');
        debugPrint('Stack trace: $stackTrace');
      }
    });
  }

  // Seleziona modalità di studio
  void selectMode(StudyMode mode) {
    _selectedMode = mode;
    notifyListeners();
  }

  // Attiva/disattiva modalità burn
  void toggleBurnMode() {
    _isBurnMode = !_isBurnMode;
    notifyListeners();
  }

  // Avvia una nuova sessione di lavoro
  void startWorkSession() {
    _currentSession = StudySession.custom(
      mode: _selectedMode,
      type: SessionType.work,
      duration: _defaultWorkDuration,
      isBurnMode: _isBurnMode,
    );
    _startTimer();
    // Sincronizza immediatamente all'avvio
    if (_selectedMode == StudyMode.group) {
      unawaited(_pushTimerState());
    }
    notifyListeners();
  }

  // Avvia una pausa breve
  void startShortBreak() {
    _currentSession = StudySession.shortBreak(
      mode: _selectedMode,
      isBurnMode: _isBurnMode,
    );
    _startTimer();
    // Sincronizza immediatamente all'avvio
    if (_selectedMode == StudyMode.group) {
      unawaited(_pushTimerState());
    }
    notifyListeners();
  }

  // Avvia una pausa lunga
  void startLongBreak() {
    _currentSession = StudySession.longBreak(
      mode: _selectedMode,
      isBurnMode: _isBurnMode,
    );
    _startTimer();
    // Sincronizza immediatamente all'avvio
    if (_selectedMode == StudyMode.group) {
      unawaited(_pushTimerState());
    }
    notifyListeners();
  }

  // Avvia il timer
  void _startTimer() {
    // Non avviare timer se il provider è stato dispose
    if (_isDisposed) {
      debugPrint('Cannot start timer - provider already disposed');
      return;
    }

    _isRunning = true;
    _timerService.stop();

    // Cancella eventuali notifiche programmate precedenti
    _notificationService.cancelScheduledNotification();

    // Programma la notifica per quando il timer scade
    if (_currentSession != null) {
      _notificationService.scheduleSessionEnd(
        startTime: _currentSession!.startTime,
        durationSeconds: _currentSession!.duration,
        sessionType: _currentSession!.type,
      );
    }

    _timerService.start(onTick: _handleTick);
  }

  void _handleTick() {
    if (_isDisposed) {
      _timerService.stop();
      debugPrint('Timer cancelled - provider was disposed');
      return;
    }

    try {
      notifyListeners();

      if (_currentSession?.isCompleted ?? false) {
        _handleSessionComplete();
      }

      if (_selectedMode == StudyMode.group &&
          _currentSession != null &&
          _currentSession!.remainingTime % 5 == 0) {
        unawaited(_pushTimerState());
      }
    } catch (e) {
      _timerService.stop();
      debugPrint('Timer cancelled due to error: $e');
    }
  }

  // Flag per prevenire chiamate multiple a _handleSessionComplete
  bool _isHandlingCompletion = false;

  // Gestisce il completamento di una sessione
  void _handleSessionComplete() {
    // Previene chiamate multiple simultanee
    if (_isHandlingCompletion) {
      debugPrint(
        '_handleSessionComplete già in esecuzione, ignoro la chiamata',
      );
      return;
    }

    _isHandlingCompletion = true;

    try {
      _timerService.stop();
      _isRunning = false;

      final sessionType = _currentSession?.type ?? SessionType.work;
      _notificationService.handleSessionCompletionFeedback(sessionType);

      // Logica Pomodoro: dopo 4 pomodori, pausa lunga
      if (_currentSession?.type == SessionType.work) {
        _completedPomodoros++;
        if (_completedPomodoros % 4 == 0) {
          startLongBreak();
        } else {
          startShortBreak();
        }
      } else {
        // Dopo una pausa, torna al lavoro
        startWorkSession();
      }
    } finally {
      _isHandlingCompletion = false;
    }
  }

  // Pausa il timer
  void pauseTimer() {
    if (_isRunning) {
      _timerService.stop();
      _isRunning = false;
      _notificationService.cancelScheduledNotification();
      if (_selectedMode == StudyMode.group) {
        unawaited(_pushTimerState()); // Sincronizza pausa
      }
      notifyListeners();
    }
  }

  // Riprende il timer
  void resumeTimer() {
    if (!_isRunning && _currentSession != null) {
      final remainingSeconds = _currentSession!.remainingTime;
      if (remainingSeconds > 0) {
        // Crea una nuova sessione con il tempo rimanente come durata totale
        _currentSession = StudySession(
          mode: _currentSession!.mode,
          type: _currentSession!.type,
          duration: remainingSeconds,
          startTime: DateTime.now(),
          isBurnMode: _currentSession!.isBurnMode,
        );

        // Cancella la vecchia notifica e programma una nuova con il timing corretto
        _notificationService.cancelScheduledNotification();
        _notificationService.scheduleSessionEnd(
          startTime: _currentSession!.startTime,
          durationSeconds: _currentSession!.duration,
          sessionType: _currentSession!.type,
        );

        _isRunning = true;
        notifyListeners();

        _timerService.stop();
        _timerService.start(onTick: _handleTick);
      } else {
        // Se il tempo è scaduto, gestisci il completamento
        _handleSessionComplete();
      }
    }
  }

  // Ferma il timer e resetta la sessione
  void stopTimer() {
    _timerService.dispose();
    _isRunning = false;
    _currentSession = null;
    _notificationService.cancelScheduledNotification();
    if (_selectedMode == StudyMode.group) {
      unawaited(_pushTimerState()); // Sincronizza stop
    }
    notifyListeners();
  }

  // Reset del contatore pomodori
  void resetPomodoros() {
    _completedPomodoros = 0;
    notifyListeners();
  }

  // Modifica la durata predefinita del lavoro (solo quando non c'è sessione attiva)
  void adjustDefaultWorkDuration(double deltaY) {
    if (_currentSession != null) {
      return; // Non modificare durante una sessione attiva
    }

    // Ogni 10 pixel di movimento corrispondono a 1 minuto
    int minutesToAdd = (deltaY / -10).round();
    final currentMinutes = _defaultWorkDuration ~/ 60;
    setDefaultWorkDurationMinutes(currentMinutes + minutesToAdd);
  }

  void setDefaultWorkDurationMinutes(int minutes) {
    final clampedMinutes = minutes.clamp(1, 60);
    final newDuration = clampedMinutes * 60;

    if (newDuration != _defaultWorkDuration) {
      _defaultWorkDuration = newDuration;
      notifyListeners();
    }
  }

  // Reset durata predefinita
  void resetDefaultWorkDuration() {
    _defaultWorkDuration = StudySession.workDuration;
    notifyListeners();
  }

  // Gestisce quando l'app va in background
  void handleAppPaused() {
    // Il timer continuerà tramite notifiche programmate
    // Non serve fare nulla qui, la notifica è già programmata
  }

  // Gestisce quando l'app torna in foreground
  void handleAppResumed() {
    if (_currentSession != null && _isRunning) {
      // Quando l'app riprende, semplicemente aggiorna l'UI
      // Non auto-avanzare a la sessione successiva - la notifica ha già avvertito l'utente
      // che la sessione è scaduta. Lasciare che loro decidano se continuare.
      debugPrint('App resumed - current session state: ${_currentSession!.isCompleted ? 'completed' : 'active'}');
      notifyListeners();
    }
  }

  // ===== SINCRONIZZAZIONE GRUPPO =====

  /// Associa il RoomProvider per la sincronizzazione
  void setRoomProvider(RoomProvider? provider) {
    _syncService.configure(
      roomProvider: provider,
      onRemoteTimerState: _handleRemoteTimerState,
    );
  }

  Future<void> _pushTimerState() async {
    if (_selectedMode != StudyMode.group || _syncService.isProcessingRemoteUpdate) {
      return;
    }

    if (_currentSession != null && _isRunning) {
      await _syncService.pushTimerState(
        isRunning: true,
        isPaused: false,
        remainingSeconds: _currentSession!.remainingTime,
        totalSeconds: _currentSession!.duration,
        sessionType: _currentSession!.type,
        startedAt: _currentSession!.startTime,
      );
    } else {
      await _syncService.clearTimerState();
    }
  }

  void _handleRemoteTimerState(TimerState? timerState) {
    if (_selectedMode != StudyMode.group) {
      return;
    }

    if (timerState == null) {
      if (_isRunning || _currentSession != null) {
        stopTimer();
      }
      return;
    }

    if (timerState.isRunning && !timerState.isPaused) {
      final sessionType = _stringToSessionType(timerState.sessionType);
      int effectiveRemainingSeconds = timerState.remainingSeconds;
      if (timerState.startedAt != null) {
        final elapsed =
            DateTime.now().difference(timerState.startedAt!).inSeconds;
        effectiveRemainingSeconds = (timerState.totalSeconds - elapsed)
            .clamp(0, timerState.totalSeconds);
      }

      final needsNewSession = _currentSession == null ||
          _currentSession!.type != sessionType ||
          (_currentSession!.remainingTime - effectiveRemainingSeconds).abs() > 2;

      if (needsNewSession) {
        _currentSession = StudySession(
          mode: _selectedMode,
          type: sessionType,
          duration: effectiveRemainingSeconds,
          startTime: DateTime.now(),
          isBurnMode: _isBurnMode,
        );
      }

      if (!_isRunning) {
        _startTimer();
      }
    } else {
      if (_isRunning) {
        _timerService.stop();
        _isRunning = false;
        notifyListeners();
      }
    }
  }

  SessionType _stringToSessionType(String type) {
    switch (type) {
      case 'work':
        return SessionType.work;
      case 'shortBreak':
        return SessionType.shortBreak;
      case 'longBreak':
        return SessionType.longBreak;
      default:
        return SessionType.work;
    }
  }

  @override
  void dispose() {
    // Imposta il flag prima di cancellare le risorse
    // per prevenire che callback asincroni tentino di usare il provider
    _isDisposed = true;

    _timerService.dispose();
    unawaited(_notificationService.dispose());
    _syncService.dispose();
    super.dispose();
  }
}
