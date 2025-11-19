import 'package:flutter/foundation.dart';
import 'package:powerful_students/models/group_room.dart';
import 'package:powerful_students/models/study_session.dart';
import 'package:powerful_students/providers/room_provider.dart';

typedef RemoteTimerCallback = void Function(TimerState? state);

class PomodoroSyncService {
  PomodoroSyncService();

  RoomProvider? _roomProvider;
  RemoteTimerCallback? _onRemoteTimerState;
  bool _isProcessingRemoteUpdate = false;

  bool get isProcessingRemoteUpdate => _isProcessingRemoteUpdate;

  void configure({
    required RoomProvider? roomProvider,
    required RemoteTimerCallback? onRemoteTimerState,
  }) {
    _roomProvider?.removeListener(_handleRoomChange);
    _roomProvider = roomProvider;
    _onRemoteTimerState = onRemoteTimerState;
    _roomProvider?.addListener(_handleRoomChange);

    // Emmetti subito lo stato corrente per mantenere il timer allineato
    if (_roomProvider?.room != null && _onRemoteTimerState != null) {
      _emitCurrentState();
    }
  }

  Future<void> pushTimerState({
    required bool isRunning,
    required bool isPaused,
    required int remainingSeconds,
    required int totalSeconds,
    required SessionType sessionType,
    DateTime? startedAt,
    DateTime? pausedAt,
  }) async {
    if (_roomProvider == null || _isProcessingRemoteUpdate) return;

    try {
      await _roomProvider!.updateTimerState(
        isRunning: isRunning,
        isPaused: isPaused,
        remainingSeconds: remainingSeconds,
        totalSeconds: totalSeconds,
        sessionType: _sessionTypeToString(sessionType),
        startedAt: startedAt,
        pausedAt: pausedAt,
      );
    } catch (e, stackTrace) {
      debugPrint('Push timer state failed: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> clearTimerState() async {
    if (_roomProvider == null) return;
    try {
      await _roomProvider!.clearTimerState();
    } catch (e, stackTrace) {
      debugPrint('Clear timer state failed: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void dispose() {
    _roomProvider?.removeListener(_handleRoomChange);
    _roomProvider = null;
    _onRemoteTimerState = null;
  }

  void _handleRoomChange() {
    if (_onRemoteTimerState == null) return;
    _emitCurrentState();
  }

  void _emitCurrentState() {
    _isProcessingRemoteUpdate = true;
    try {
      final timerState = _roomProvider?.room?.timerState;
      _onRemoteTimerState?.call(timerState);
    } finally {
      _isProcessingRemoteUpdate = false;
    }
  }

  String _sessionTypeToString(SessionType type) {
    switch (type) {
      case SessionType.work:
        return 'work';
      case SessionType.shortBreak:
        return 'shortBreak';
      case SessionType.longBreak:
        return 'longBreak';
    }
  }
}
