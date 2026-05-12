import 'package:flutter_test/flutter_test.dart';
import 'package:powerful_students/models/study_session.dart';

void main() {
  group('StudyMode', () {
    test('has solo, group, and buddy values', () {
      expect(StudyMode.values, contains(StudyMode.solo));
      expect(StudyMode.values, contains(StudyMode.group));
      expect(StudyMode.values, contains(StudyMode.buddy));
    });
  });

  group('SessionType', () {
    test('has work, shortBreak, and longBreak values', () {
      expect(SessionType.values, contains(SessionType.work));
      expect(SessionType.values, contains(SessionType.shortBreak));
      expect(SessionType.values, contains(SessionType.longBreak));
    });
  });

  group('StudySession', () {
    group('Static Constants', () {
      test('workDuration is 25 minutes in seconds', () {
        expect(StudySession.workDuration, equals(25 * 60));
      });

      test('shortBreakDuration is 5 minutes in seconds', () {
        expect(StudySession.shortBreakDuration, equals(5 * 60));
      });

      test('longBreakDuration is 15 minutes in seconds', () {
        expect(StudySession.longBreakDuration, equals(15 * 60));
      });
    });

    group('Factory Constructors', () {
      test('work() creates a work session with correct duration', () {
        final session = StudySession.work(
          mode: StudyMode.solo,
          isBurnMode: false,
        );

        expect(session.type, equals(SessionType.work));
        expect(session.duration, equals(StudySession.workDuration));
        expect(session.mode, equals(StudyMode.solo));
        expect(session.isBurnMode, isFalse);
      });

      test('shortBreak() creates a short break with correct duration', () {
        final session = StudySession.shortBreak(
          mode: StudyMode.group,
          isBurnMode: true,
        );

        expect(session.type, equals(SessionType.shortBreak));
        expect(session.duration, equals(StudySession.shortBreakDuration));
        expect(session.mode, equals(StudyMode.group));
        expect(session.isBurnMode, isTrue);
      });

      test('longBreak() creates a long break with correct duration', () {
        final session = StudySession.longBreak(
          mode: StudyMode.solo,
          isBurnMode: false,
        );

        expect(session.type, equals(SessionType.longBreak));
        expect(session.duration, equals(StudySession.longBreakDuration));
      });

      test('custom() creates session with custom duration', () {
        final session = StudySession.custom(
          mode: StudyMode.solo,
          type: SessionType.work,
          duration: 30 * 60, // 30 minutes
          isBurnMode: false,
        );

        expect(session.duration, equals(30 * 60));
        expect(session.type, equals(SessionType.work));
      });

      test('factories set startTime to now', () {
        final before = DateTime.now();
        final session = StudySession.work(
          mode: StudyMode.solo,
          isBurnMode: false,
        );
        final after = DateTime.now();

        expect(session.startTime.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
        expect(session.startTime.isBefore(after.add(const Duration(seconds: 1))), isTrue);
      });
    });

    group('copyWith', () {
      test('creates copy with modified mode', () {
        final original = StudySession.work(
          mode: StudyMode.solo,
          isBurnMode: false,
        );

        final copy = original.copyWith(mode: StudyMode.group);

        expect(copy.mode, equals(StudyMode.group));
        expect(copy.type, equals(original.type));
        expect(copy.duration, equals(original.duration));
        expect(copy.isBurnMode, equals(original.isBurnMode));
      });

      test('creates copy with modified type', () {
        final original = StudySession.work(
          mode: StudyMode.solo,
          isBurnMode: false,
        );

        final copy = original.copyWith(type: SessionType.shortBreak);

        expect(copy.type, equals(SessionType.shortBreak));
      });

      test('creates copy with modified duration', () {
        final original = StudySession.work(
          mode: StudyMode.solo,
          isBurnMode: false,
        );

        final copy = original.copyWith(duration: 1800);

        expect(copy.duration, equals(1800));
      });

      test('creates copy with modified startTime', () {
        final original = StudySession.work(
          mode: StudyMode.solo,
          isBurnMode: false,
        );
        final newTime = DateTime(2024, 1, 1, 10, 0);

        final copy = original.copyWith(startTime: newTime);

        expect(copy.startTime, equals(newTime));
      });

      test('creates copy with modified isBurnMode', () {
        final original = StudySession.work(
          mode: StudyMode.solo,
          isBurnMode: false,
        );

        final copy = original.copyWith(isBurnMode: true);

        expect(copy.isBurnMode, isTrue);
      });

      test('preserves unchanged fields', () {
        final original = StudySession(
          mode: StudyMode.group,
          type: SessionType.longBreak,
          duration: 900,
          startTime: DateTime(2024, 1, 1),
          isBurnMode: true,
        );

        final copy = original.copyWith();

        expect(copy.mode, equals(original.mode));
        expect(copy.type, equals(original.type));
        expect(copy.duration, equals(original.duration));
        expect(copy.startTime, equals(original.startTime));
        expect(copy.isBurnMode, equals(original.isBurnMode));
      });
    });

    group('remainingTime', () {
      test('returns full duration at start', () {
        final session = StudySession(
          mode: StudyMode.solo,
          type: SessionType.work,
          duration: 60,
          startTime: DateTime.now(),
          isBurnMode: false,
        );

        // Should be close to 60 (may be 59 due to test execution time)
        expect(session.remainingTime, greaterThanOrEqualTo(59));
        expect(session.remainingTime, lessThanOrEqualTo(60));
      });

      test('decreases over time', () {
        final session = StudySession(
          mode: StudyMode.solo,
          type: SessionType.work,
          duration: 60,
          startTime: DateTime.now().subtract(const Duration(seconds: 10)),
          isBurnMode: false,
        );

        expect(session.remainingTime, lessThanOrEqualTo(50));
      });

      test('is clamped to 0 after duration elapsed', () {
        final session = StudySession(
          mode: StudyMode.solo,
          type: SessionType.work,
          duration: 60,
          startTime: DateTime.now().subtract(const Duration(seconds: 120)),
          isBurnMode: false,
        );

        expect(session.remainingTime, equals(0));
      });

      test('is clamped to duration maximum', () {
        final session = StudySession(
          mode: StudyMode.solo,
          type: SessionType.work,
          duration: 60,
          startTime: DateTime.now().add(const Duration(seconds: 10)), // Future start time
          isBurnMode: false,
        );

        expect(session.remainingTime, equals(60));
      });
    });

    group('isCompleted', () {
      test('returns false when time remaining', () {
        final session = StudySession(
          mode: StudyMode.solo,
          type: SessionType.work,
          duration: 60,
          startTime: DateTime.now(),
          isBurnMode: false,
        );

        expect(session.isCompleted, isFalse);
      });

      test('returns true when time elapsed', () {
        final session = StudySession(
          mode: StudyMode.solo,
          type: SessionType.work,
          duration: 60,
          startTime: DateTime.now().subtract(const Duration(seconds: 120)),
          isBurnMode: false,
        );

        expect(session.isCompleted, isTrue);
      });
    });

    group('formattedRemainingTime', () {
      test('formats time as MM:SS', () {
        final session = StudySession(
          mode: StudyMode.solo,
          type: SessionType.work,
          duration: 90, // 1:30
          startTime: DateTime.now(),
          isBurnMode: false,
        );

        final formatted = session.formattedRemainingTime;
        
        // Should be "01:30" or "01:29" depending on execution timing
        expect(formatted, matches(RegExp(r'^01:(29|30)$')));
      });

      test('pads single digits with zeros', () {
        final session = StudySession(
          mode: StudyMode.solo,
          type: SessionType.work,
          duration: 65, // 1:05
          startTime: DateTime.now(),
          isBurnMode: false,
        );

        final formatted = session.formattedRemainingTime;
        
        expect(formatted, matches(RegExp(r'^01:0[45]$')));
      });

      test('shows 00:00 when completed', () {
        final session = StudySession(
          mode: StudyMode.solo,
          type: SessionType.work,
          duration: 60,
          startTime: DateTime.now().subtract(const Duration(seconds: 120)),
          isBurnMode: false,
        );

        expect(session.formattedRemainingTime, equals('00:00'));
      });
    });

    group('progress', () {
      test('returns 0.0 at start', () {
        final session = StudySession(
          mode: StudyMode.solo,
          type: SessionType.work,
          duration: 60,
          startTime: DateTime.now(),
          isBurnMode: false,
        );

        expect(session.progress, closeTo(0.0, 0.02));
      });

      test('returns value between 0 and 1 during session', () {
        final session = StudySession(
          mode: StudyMode.solo,
          type: SessionType.work,
          duration: 60,
          startTime: DateTime.now().subtract(const Duration(seconds: 30)),
          isBurnMode: false,
        );

        expect(session.progress, greaterThan(0.4));
        expect(session.progress, lessThan(0.6));
      });

      test('returns 1.0 when completed', () {
        final session = StudySession(
          mode: StudyMode.solo,
          type: SessionType.work,
          duration: 60,
          startTime: DateTime.now().subtract(const Duration(seconds: 120)),
          isBurnMode: false,
        );

        expect(session.progress, equals(1.0));
      });

      test('returns 1.0 for zero duration', () {
        final session = StudySession(
          mode: StudyMode.solo,
          type: SessionType.work,
          duration: 0,
          startTime: DateTime.now(),
          isBurnMode: false,
        );

        expect(session.progress, equals(1.0));
      });
    });

    group('toString', () {
      test('returns descriptive string', () {
        final session = StudySession.work(
          mode: StudyMode.solo,
          isBurnMode: true,
        );

        final str = session.toString();

        expect(str, contains('StudySession'));
        expect(str, contains('mode: StudyMode.solo'));
        expect(str, contains('type: SessionType.work'));
        expect(str, contains('isBurnMode: true'));
      });
    });
  });
}
