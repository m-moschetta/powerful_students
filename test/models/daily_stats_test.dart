import 'package:flutter_test/flutter_test.dart';
import 'package:powerful_students/models/daily_stats.dart';

void main() {
  group('DailyStats', () {
    group('Constructor', () {
      test('creates instance with all required fields', () {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        
        final stats = DailyStats(
          id: 'user123_2024-01-15',
          userId: 'user123',
          date: today,
          completedPomodoros: 5,
          totalMinutes: 125,
          createdAt: now,
          updatedAt: now,
        );

        expect(stats.id, equals('user123_2024-01-15'));
        expect(stats.userId, equals('user123'));
        expect(stats.date, equals(today));
        expect(stats.completedPomodoros, equals(5));
        expect(stats.totalMinutes, equals(125));
        expect(stats.createdAt, equals(now));
        expect(stats.updatedAt, equals(now));
      });
    });

    group('generateId', () {
      test('generates ID in correct format', () {
        final date = DateTime(2024, 1, 15);
        final id = DailyStats.generateId('user123', date);

        expect(id, equals('user123_2024-01-15'));
      });

      test('pads single-digit month with zero', () {
        final date = DateTime(2024, 5, 10);
        final id = DailyStats.generateId('test', date);

        expect(id, equals('test_2024-05-10'));
      });

      test('pads single-digit day with zero', () {
        final date = DateTime(2024, 12, 5);
        final id = DailyStats.generateId('test', date);

        expect(id, equals('test_2024-12-05'));
      });

      test('handles different user IDs', () {
        final date = DateTime(2024, 6, 20);
        
        final id1 = DailyStats.generateId('alice', date);
        final id2 = DailyStats.generateId('bob', date);

        expect(id1, equals('alice_2024-06-20'));
        expect(id2, equals('bob_2024-06-20'));
      });

      test('handles different dates for same user', () {
        final date1 = DateTime(2024, 1, 1);
        final date2 = DateTime(2024, 12, 31);

        final id1 = DailyStats.generateId('user', date1);
        final id2 = DailyStats.generateId('user', date2);

        expect(id1, equals('user_2024-01-01'));
        expect(id2, equals('user_2024-12-31'));
      });
    });

    group('createToday', () {
      test('creates stats with zero values', () {
        final stats = DailyStats.createToday('user123');

        expect(stats.completedPomodoros, equals(0));
        expect(stats.totalMinutes, equals(0));
      });

      test('sets userId correctly', () {
        final stats = DailyStats.createToday('test-user');

        expect(stats.userId, equals('test-user'));
      });

      test('sets date to today (midnight)', () {
        final stats = DailyStats.createToday('user');
        final now = DateTime.now();
        final expectedDate = DateTime(now.year, now.month, now.day);

        expect(stats.date, equals(expectedDate));
      });

      test('generates correct ID for today', () {
        final stats = DailyStats.createToday('user123');
        final now = DateTime.now();
        final expectedId = DailyStats.generateId('user123', now);

        expect(stats.id, equals(expectedId));
      });

      test('sets createdAt and updatedAt to now', () {
        final before = DateTime.now();
        final stats = DailyStats.createToday('user');
        final after = DateTime.now();

        expect(stats.createdAt.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
        expect(stats.createdAt.isBefore(after.add(const Duration(seconds: 1))), isTrue);
        expect(stats.updatedAt.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
        expect(stats.updatedAt.isBefore(after.add(const Duration(seconds: 1))), isTrue);
      });
    });

    group('copyWith', () {
      test('creates copy with modified completedPomodoros', () {
        final original = DailyStats.createToday('user');
        final copy = original.copyWith(completedPomodoros: 10);

        expect(copy.completedPomodoros, equals(10));
        expect(copy.totalMinutes, equals(original.totalMinutes));
        expect(copy.id, equals(original.id));
        expect(copy.userId, equals(original.userId));
      });

      test('creates copy with modified totalMinutes', () {
        final original = DailyStats.createToday('user');
        final copy = original.copyWith(totalMinutes: 250);

        expect(copy.totalMinutes, equals(250));
        expect(copy.completedPomodoros, equals(original.completedPomodoros));
      });

      test('creates copy with modified updatedAt', () {
        final original = DailyStats.createToday('user');
        final newTime = DateTime(2024, 6, 15, 14, 30);
        final copy = original.copyWith(updatedAt: newTime);

        expect(copy.updatedAt, equals(newTime));
        expect(copy.createdAt, equals(original.createdAt));
      });

      test('auto-updates updatedAt when not specified', () {
        final now = DateTime.now();
        final original = DailyStats(
          id: 'test_2024-01-01',
          userId: 'test',
          date: DateTime(2024, 1, 1),
          completedPomodoros: 0,
          totalMinutes: 0,
          createdAt: DateTime(2024, 1, 1, 8, 0),
          updatedAt: DateTime(2024, 1, 1, 8, 0),
        );

        final copy = original.copyWith(completedPomodoros: 5);

        expect(copy.updatedAt.isAfter(now.subtract(const Duration(seconds: 1))), isTrue);
      });

      test('preserves unchanged fields', () {
        final createdAt = DateTime(2024, 1, 1, 8, 0);
        final original = DailyStats(
          id: 'user_2024-01-01',
          userId: 'user',
          date: DateTime(2024, 1, 1),
          completedPomodoros: 5,
          totalMinutes: 125,
          createdAt: createdAt,
          updatedAt: createdAt,
        );

        final copy = original.copyWith();

        expect(copy.id, equals(original.id));
        expect(copy.userId, equals(original.userId));
        expect(copy.date, equals(original.date));
        expect(copy.completedPomodoros, equals(original.completedPomodoros));
        expect(copy.totalMinutes, equals(original.totalMinutes));
        expect(copy.createdAt, equals(original.createdAt));
      });

      test('allows multiple fields to be modified', () {
        final original = DailyStats.createToday('user');
        final copy = original.copyWith(
          completedPomodoros: 8,
          totalMinutes: 200,
        );

        expect(copy.completedPomodoros, equals(8));
        expect(copy.totalMinutes, equals(200));
      });
    });

    group('toFirestore', () {
      test('returns map with all required fields', () {
        final date = DateTime(2024, 1, 15);
        final createdAt = DateTime(2024, 1, 15, 8, 0);
        final updatedAt = DateTime(2024, 1, 15, 10, 30);

        final stats = DailyStats(
          id: 'user_2024-01-15',
          userId: 'user123',
          date: date,
          completedPomodoros: 7,
          totalMinutes: 175,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

        final map = stats.toFirestore();

        expect(map['userId'], equals('user123'));
        expect(map['completedPomodoros'], equals(7));
        expect(map['totalMinutes'], equals(175));
        // Timestamp fields are Firestore Timestamps
        expect(map.containsKey('date'), isTrue);
        expect(map.containsKey('createdAt'), isTrue);
        expect(map.containsKey('updatedAt'), isTrue);
      });

      test('does not include id in map (document ID is separate)', () {
        final stats = DailyStats.createToday('user');
        final map = stats.toFirestore();

        expect(map.containsKey('id'), isFalse);
      });

      test('contains exactly expected keys', () {
        final stats = DailyStats.createToday('user');
        final map = stats.toFirestore();

        expect(map.keys.length, equals(6));
        expect(
          map.keys,
          containsAll([
            'userId',
            'date',
            'completedPomodoros',
            'totalMinutes',
            'createdAt',
            'updatedAt',
          ]),
        );
      });
    });

    group('Edge Cases', () {
      test('handles zero values', () {
        final stats = DailyStats.createToday('user');

        expect(stats.completedPomodoros, equals(0));
        expect(stats.totalMinutes, equals(0));
      });

      test('handles large pomodoro counts', () {
        final stats = DailyStats.createToday('user').copyWith(
          completedPomodoros: 999,
          totalMinutes: 24975, // 999 * 25 minutes
        );

        expect(stats.completedPomodoros, equals(999));
        expect(stats.totalMinutes, equals(24975));
      });

      test('handles empty userId', () {
        final stats = DailyStats.createToday('');

        expect(stats.userId, equals(''));
        expect(stats.id, startsWith('_'));
      });

      test('handles special characters in userId', () {
        final stats = DailyStats.createToday('user@example.com');

        expect(stats.userId, equals('user@example.com'));
        expect(stats.id, startsWith('user@example.com_'));
      });
    });
  });
}
