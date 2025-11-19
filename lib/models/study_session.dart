enum StudyMode {
  solo,
  group,
}

enum SessionType {
  work,
  shortBreak,
  longBreak,
}

class StudySession {
  final StudyMode mode;
  final SessionType type;
  final int duration; // in seconds
  final DateTime startTime;
  final bool isBurnMode;

  StudySession({
    required this.mode,
    required this.type,
    required this.duration,
    required this.startTime,
    required this.isBurnMode,
  });

  // Durate standard Pomodoro
  static const int workDuration = 25 * 60; // 25 minuti
  static const int shortBreakDuration = 5 * 60; // 5 minuti
  static const int longBreakDuration = 15 * 60; // 15 minuti

  // Crea una sessione di lavoro
  factory StudySession.work({
    required StudyMode mode,
    required bool isBurnMode,
  }) {
    return StudySession(
      mode: mode,
      type: SessionType.work,
      duration: workDuration,
      startTime: DateTime.now(),
      isBurnMode: isBurnMode,
    );
  }

  // Crea una pausa breve
  factory StudySession.shortBreak({
    required StudyMode mode,
    required bool isBurnMode,
  }) {
    return StudySession(
      mode: mode,
      type: SessionType.shortBreak,
      duration: shortBreakDuration,
      startTime: DateTime.now(),
      isBurnMode: isBurnMode,
    );
  }

  // Crea una pausa lunga
  factory StudySession.longBreak({
    required StudyMode mode,
    required bool isBurnMode,
  }) {
    return StudySession(
      mode: mode,
      type: SessionType.longBreak,
      duration: longBreakDuration,
      startTime: DateTime.now(),
      isBurnMode: isBurnMode,
    );
  }

  // Crea una sessione personalizzata
  factory StudySession.custom({
    required StudyMode mode,
    required SessionType type,
    required int duration,
    required bool isBurnMode,
  }) {
    return StudySession(
      mode: mode,
      type: type,
      duration: duration,
      startTime: DateTime.now(),
      isBurnMode: isBurnMode,
    );
  }

  // Copia con modifiche
  StudySession copyWith({
    StudyMode? mode,
    SessionType? type,
    int? duration,
    DateTime? startTime,
    bool? isBurnMode,
  }) {
    return StudySession(
      mode: mode ?? this.mode,
      type: type ?? this.type,
      duration: duration ?? this.duration,
      startTime: startTime ?? this.startTime,
      isBurnMode: isBurnMode ?? this.isBurnMode,
    );
  }

  // Calcola il tempo rimanente
  int get remainingTime {
    final elapsed = DateTime.now().difference(startTime).inSeconds;
    return (duration - elapsed).clamp(0, duration);
  }

  // Verifica se la sessione è completata
  bool get isCompleted => remainingTime == 0;

  // Formatta il tempo rimanente come stringa MM:SS
  String get formattedRemainingTime {
    final minutes = (remainingTime ~/ 60).toString().padLeft(2, '0');
    final seconds = (remainingTime % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // Progresso come frazione (0.0 - 1.0)
  double get progress {
    if (duration == 0) return 1.0; // Se duration è 0, il progresso è completo
    return 1.0 - (remainingTime / duration);
  }

  @override
  String toString() {
    return 'StudySession(mode: $mode, type: $type, duration: $duration, isBurnMode: $isBurnMode)';
  }
}



