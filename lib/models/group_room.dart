import 'package:cloud_firestore/cloud_firestore.dart';

class GroupRoom {
  GroupRoom({
    required this.code,
    required this.ownerId,
    required this.memberIds,
    this.createdAt,
    this.updatedAt,
    this.timerState,
  });

  final String code;
  final String ownerId;
  final List<String> memberIds;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final TimerState? timerState;

  factory GroupRoom.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};
    final members = (data['members'] as List<dynamic>? ?? [])
        .whereType<String>()
        .toList(growable: false);

    TimerState? timerState;
    if (data['timerState'] != null) {
      final timerData = data['timerState'] as Map<String, dynamic>;
      timerState = TimerState.fromMap(timerData);
    }

    return GroupRoom(
      code: data['code'] as String? ?? snapshot.id,
      ownerId: data['ownerId'] as String? ?? '',
      memberIds: members,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      timerState: timerState,
    );
  }

  int get memberCount => memberIds.length;

  bool isOwner(String memberId) => ownerId == memberId;

  bool containsMember(String memberId) => memberIds.contains(memberId);
}

class TimerState {
  TimerState({
    required this.isRunning,
    required this.isPaused,
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.sessionType,
    this.startedAt,
    this.pausedAt,
  });

  final bool isRunning;
  final bool isPaused;
  final int remainingSeconds;
  final int totalSeconds;
  final String sessionType; // 'work', 'shortBreak', 'longBreak'
  final DateTime? startedAt;
  final DateTime? pausedAt;

  factory TimerState.fromMap(Map<String, dynamic> map) {
    return TimerState(
      isRunning: map['isRunning'] as bool? ?? false,
      isPaused: map['isPaused'] as bool? ?? false,
      remainingSeconds: map['remainingSeconds'] as int? ?? 0,
      totalSeconds: map['totalSeconds'] as int? ?? 0,
      sessionType: map['sessionType'] as String? ?? 'work',
      startedAt: (map['startedAt'] as Timestamp?)?.toDate(),
      pausedAt: (map['pausedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isRunning': isRunning,
      'isPaused': isPaused,
      'remainingSeconds': remainingSeconds,
      'totalSeconds': totalSeconds,
      'sessionType': sessionType,
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'pausedAt': pausedAt != null ? Timestamp.fromDate(pausedAt!) : null,
    };
  }
}
