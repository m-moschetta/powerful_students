import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:powerful_students/models/group_room.dart';

void main() {
  group('TimerState', () {
    group('Constructor', () {
      test('creates instance with required fields', () {
        final state = TimerState(
          isRunning: true,
          isPaused: false,
          remainingSeconds: 1200,
          totalSeconds: 1500,
          sessionType: 'work',
        );

        expect(state.isRunning, isTrue);
        expect(state.isPaused, isFalse);
        expect(state.remainingSeconds, equals(1200));
        expect(state.totalSeconds, equals(1500));
        expect(state.sessionType, equals('work'));
        expect(state.isBurnMode, isFalse); // default
        expect(state.isFailed, isFalse); // default
        expect(state.startedAt, isNull);
        expect(state.pausedAt, isNull);
      });

      test('creates instance with all optional fields', () {
        final startedAt = DateTime(2024, 1, 15, 10, 0);
        final pausedAt = DateTime(2024, 1, 15, 10, 10);

        final state = TimerState(
          isRunning: false,
          isPaused: true,
          remainingSeconds: 600,
          totalSeconds: 1500,
          sessionType: 'shortBreak',
          isBurnMode: true,
          isFailed: true,
          startedAt: startedAt,
          pausedAt: pausedAt,
        );

        expect(state.isBurnMode, isTrue);
        expect(state.isFailed, isTrue);
        expect(state.startedAt, equals(startedAt));
        expect(state.pausedAt, equals(pausedAt));
      });
    });

    group('fromMap', () {
      test('parses map with all fields', () {
        final startedAt = DateTime(2024, 1, 15, 10, 0);
        final pausedAt = DateTime(2024, 1, 15, 10, 10);

        final map = {
          'isRunning': true,
          'isPaused': false,
          'remainingSeconds': 1200,
          'totalSeconds': 1500,
          'sessionType': 'work',
          'isBurnMode': true,
          'isFailed': false,
          'startedAt': Timestamp.fromDate(startedAt),
          'pausedAt': Timestamp.fromDate(pausedAt),
        };

        final state = TimerState.fromMap(map);

        expect(state.isRunning, isTrue);
        expect(state.isPaused, isFalse);
        expect(state.remainingSeconds, equals(1200));
        expect(state.totalSeconds, equals(1500));
        expect(state.sessionType, equals('work'));
        expect(state.isBurnMode, isTrue);
        expect(state.isFailed, isFalse);
        expect(state.startedAt, equals(startedAt));
        expect(state.pausedAt, equals(pausedAt));
      });

      test('handles missing optional fields with defaults', () {
        final map = <String, dynamic>{};

        final state = TimerState.fromMap(map);

        expect(state.isRunning, isFalse);
        expect(state.isPaused, isFalse);
        expect(state.remainingSeconds, equals(0));
        expect(state.totalSeconds, equals(0));
        expect(state.sessionType, equals('work'));
        expect(state.isBurnMode, isFalse);
        expect(state.isFailed, isFalse);
        expect(state.startedAt, isNull);
        expect(state.pausedAt, isNull);
      });

      test('handles null timestamp fields', () {
        final map = {
          'isRunning': true,
          'isPaused': false,
          'remainingSeconds': 100,
          'totalSeconds': 200,
          'sessionType': 'longBreak',
          'startedAt': null,
          'pausedAt': null,
        };

        final state = TimerState.fromMap(map);

        expect(state.startedAt, isNull);
        expect(state.pausedAt, isNull);
      });

      test('parses different session types', () {
        expect(
          TimerState.fromMap({'sessionType': 'work'}).sessionType,
          equals('work'),
        );
        expect(
          TimerState.fromMap({'sessionType': 'shortBreak'}).sessionType,
          equals('shortBreak'),
        );
        expect(
          TimerState.fromMap({'sessionType': 'longBreak'}).sessionType,
          equals('longBreak'),
        );
      });
    });

    group('toMap', () {
      test('converts to map with all fields', () {
        final startedAt = DateTime(2024, 1, 15, 10, 0);
        final pausedAt = DateTime(2024, 1, 15, 10, 10);

        final state = TimerState(
          isRunning: true,
          isPaused: false,
          remainingSeconds: 1200,
          totalSeconds: 1500,
          sessionType: 'work',
          isBurnMode: true,
          isFailed: false,
          startedAt: startedAt,
          pausedAt: pausedAt,
        );

        final map = state.toMap();

        expect(map['isRunning'], isTrue);
        expect(map['isPaused'], isFalse);
        expect(map['remainingSeconds'], equals(1200));
        expect(map['totalSeconds'], equals(1500));
        expect(map['sessionType'], equals('work'));
        expect(map['isBurnMode'], isTrue);
        expect(map['isFailed'], isFalse);
        expect(map['startedAt'], isA<Timestamp>());
        expect(map['pausedAt'], isA<Timestamp>());
      });

      test('handles null timestamps', () {
        final state = TimerState(
          isRunning: true,
          isPaused: false,
          remainingSeconds: 100,
          totalSeconds: 200,
          sessionType: 'work',
        );

        final map = state.toMap();

        expect(map['startedAt'], isNull);
        expect(map['pausedAt'], isNull);
      });

      test('roundtrips through fromMap and toMap', () {
        final original = TimerState(
          isRunning: true,
          isPaused: false,
          remainingSeconds: 900,
          totalSeconds: 1500,
          sessionType: 'shortBreak',
          isBurnMode: true,
          isFailed: false,
          startedAt: DateTime(2024, 1, 15, 10, 0),
          pausedAt: null,
        );

        final map = original.toMap();
        final restored = TimerState.fromMap(map);

        expect(restored.isRunning, equals(original.isRunning));
        expect(restored.isPaused, equals(original.isPaused));
        expect(restored.remainingSeconds, equals(original.remainingSeconds));
        expect(restored.totalSeconds, equals(original.totalSeconds));
        expect(restored.sessionType, equals(original.sessionType));
        expect(restored.isBurnMode, equals(original.isBurnMode));
        expect(restored.isFailed, equals(original.isFailed));
        expect(restored.startedAt, equals(original.startedAt));
        expect(restored.pausedAt, equals(original.pausedAt));
      });
    });
  });

  group('GroupRoom', () {
    group('Constructor', () {
      test('creates instance with required fields', () {
        final room = GroupRoom(
          code: 'ABC123',
          ownerId: 'user-1',
          memberIds: ['user-1', 'user-2'],
        );

        expect(room.code, equals('ABC123'));
        expect(room.ownerId, equals('user-1'));
        expect(room.memberIds, equals(['user-1', 'user-2']));
        expect(room.createdAt, isNull);
        expect(room.updatedAt, isNull);
        expect(room.timerState, isNull);
      });

      test('creates instance with all optional fields', () {
        final createdAt = DateTime(2024, 1, 15, 10, 0);
        final updatedAt = DateTime(2024, 1, 15, 11, 0);
        final timerState = TimerState(
          isRunning: true,
          isPaused: false,
          remainingSeconds: 1200,
          totalSeconds: 1500,
          sessionType: 'work',
        );

        final room = GroupRoom(
          code: 'XYZ789',
          ownerId: 'owner',
          memberIds: ['owner', 'member'],
          createdAt: createdAt,
          updatedAt: updatedAt,
          timerState: timerState,
        );

        expect(room.createdAt, equals(createdAt));
        expect(room.updatedAt, equals(updatedAt));
        expect(room.timerState, equals(timerState));
      });
    });

    group('memberCount', () {
      test('returns count of members', () {
        final room = GroupRoom(
          code: 'ABC',
          ownerId: 'user-1',
          memberIds: ['user-1', 'user-2', 'user-3'],
        );

        expect(room.memberCount, equals(3));
      });

      test('returns zero for empty members', () {
        final room = GroupRoom(
          code: 'ABC',
          ownerId: 'user-1',
          memberIds: [],
        );

        expect(room.memberCount, equals(0));
      });
    });

    group('isOwner', () {
      test('returns true for owner', () {
        final room = GroupRoom(
          code: 'ABC',
          ownerId: 'owner-id',
          memberIds: ['owner-id', 'member-id'],
        );

        expect(room.isOwner('owner-id'), isTrue);
      });

      test('returns false for non-owner', () {
        final room = GroupRoom(
          code: 'ABC',
          ownerId: 'owner-id',
          memberIds: ['owner-id', 'member-id'],
        );

        expect(room.isOwner('member-id'), isFalse);
      });

      test('returns false for unknown user', () {
        final room = GroupRoom(
          code: 'ABC',
          ownerId: 'owner-id',
          memberIds: ['owner-id'],
        );

        expect(room.isOwner('unknown'), isFalse);
      });
    });

    group('containsMember', () {
      test('returns true for existing member', () {
        final room = GroupRoom(
          code: 'ABC',
          ownerId: 'owner',
          memberIds: ['owner', 'user-1', 'user-2'],
        );

        expect(room.containsMember('user-1'), isTrue);
        expect(room.containsMember('user-2'), isTrue);
        expect(room.containsMember('owner'), isTrue);
      });

      test('returns false for non-member', () {
        final room = GroupRoom(
          code: 'ABC',
          ownerId: 'owner',
          memberIds: ['owner', 'user-1'],
        );

        expect(room.containsMember('user-99'), isFalse);
      });
    });

    group('Edge Cases', () {
      test('handles empty code', () {
        final room = GroupRoom(
          code: '',
          ownerId: 'owner',
          memberIds: [],
        );

        expect(room.code, equals(''));
      });

      test('handles special characters in code', () {
        final room = GroupRoom(
          code: 'ABC-123_XYZ',
          ownerId: 'owner',
          memberIds: [],
        );

        expect(room.code, equals('ABC-123_XYZ'));
      });

      test('owner can be empty string', () {
        final room = GroupRoom(
          code: 'ABC',
          ownerId: '',
          memberIds: [],
        );

        expect(room.isOwner(''), isTrue);
        expect(room.isOwner('anyone'), isFalse);
      });
    });
  });
}
