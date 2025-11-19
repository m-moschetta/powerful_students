import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:powerful_students/services/pomodoro_timer_service.dart';

void main() {
  group('PomodoroTimerService', () {
    test('invokes tick callback on start', () {
      final timerService = PomodoroTimerService();
      var tickCount = 0;

      fakeAsync((async) {
        timerService.start(onTick: () => tickCount++);

        expect(timerService.isRunning, isTrue);
        expect(tickCount, 0);

        async.elapse(const Duration(seconds: 1));
        expect(tickCount, 1);

        async.elapse(const Duration(seconds: 3));
        expect(tickCount, 4);
      });
    });

    test('stop cancels further ticks', () {
      final timerService = PomodoroTimerService();
      var tickCount = 0;

      fakeAsync((async) {
        timerService.start(onTick: () => tickCount++);
        async.elapse(const Duration(seconds: 2));
        expect(tickCount, 2);

        timerService.stop();
        expect(timerService.isRunning, isFalse);

        async.elapse(const Duration(seconds: 5));
        expect(tickCount, 2);
      });
    });

    test('start restarts the timer from zero', () {
      final timerService = PomodoroTimerService();
      var tickCount = 0;

      fakeAsync((async) {
        timerService.start(onTick: () => tickCount++);
        async.elapse(const Duration(seconds: 1));
        expect(tickCount, 1);

        timerService.start(onTick: () => tickCount++);
        async.elapse(const Duration(seconds: 2));
        expect(tickCount, 3);
      });
    });
  });
}
