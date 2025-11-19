import 'dart:async';

typedef TickCallback = void Function();

class PomodoroTimerService {
  PomodoroTimerService();

  Timer? _timer;

  bool get isRunning => _timer != null;

  void start({
    Duration interval = const Duration(seconds: 1),
    required TickCallback onTick,
  }) {
    stop();
    _timer = Timer.periodic(interval, (_) => onTick());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    stop();
  }
}
