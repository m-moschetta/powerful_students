import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:powerful_students/models/group_room.dart';
import 'package:powerful_students/l10n/app_localizations.dart';

class RoomException implements Exception {
  RoomException(this.message);

  final String message;

  @override
  String toString() => message;
}

class RoomProvider extends ChangeNotifier {
  RoomProvider({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _memberId = _generateMemberId();

  final FirebaseFirestore _firestore;
  final String _memberId;

  GroupRoom? _room;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _roomSubscription;

  bool _isCreatingRoom = false;
  bool _isJoiningRoom = false;
  String? _lastError;

  GroupRoom? get room => _room;
  String? get currentRoomCode => _room?.code;
  bool get isCreatingRoom => _isCreatingRoom;
  bool get isJoiningRoom => _isJoiningRoom;
  bool get hasRoom => _room != null;
  String? get lastError => _lastError;
  int get memberCount => _room?.memberCount ?? 0;
  bool get isOwner => _room?.isOwner(_memberId) ?? false;
  String get memberId => _memberId;

  CollectionReference<Map<String, dynamic>> get _roomsRef =>
      _firestore.collection('rooms');

  AppLocalizations get _l10n {
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    return lookupAppLocalizations(locale);
  }

  Future<void> createRoom() async {
    if (_isCreatingRoom) return;

    _setError(null);
    _isCreatingRoom = true;
    notifyListeners();

    try {
      final code = await _generateUniqueRoomCode();
      final docRef = _roomsRef.doc(code);

      await docRef.set({
        'code': code,
        'ownerId': _memberId,
        'members': <String>[_memberId],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _subscribeToRoom(code);
    } on FirebaseException catch (e, stackTrace) {
      _setError(_l10n.roomCreateFailed);
      debugPrint('Firebase createRoom error: ${e.message}\n$stackTrace');
      throw RoomException(
        lastError ?? _l10n.roomCreateError,
      );
    } catch (e, stackTrace) {
      _setError(_l10n.roomCreateError);
      debugPrint('createRoom error: $e\n$stackTrace');
      throw RoomException(
        lastError ?? _l10n.roomCreateError,
      );
    } finally {
      _isCreatingRoom = false;
      notifyListeners();
    }
  }

  Future<void> joinRoom(String code) async {
    final normalizedCode = _normalizeCode(code);
    debugPrint('🔵 JOIN: Tentativo join con codice: $normalizedCode');

    if (!isValidRoomCode(normalizedCode)) {
      debugPrint('❌ JOIN: Codice non valido');
      throw RoomException(_l10n.roomJoinInvalidCode);
    }

    if (_isJoiningRoom) {
      debugPrint('⚠️ JOIN: Join già in corso, ignoro');
      return;
    }

    _setError(null);
    _isJoiningRoom = true;
    notifyListeners();

    try {
      final docRef = _roomsRef.doc(normalizedCode);
      debugPrint('🔵 JOIN: Inizio transaction Firestore');

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) {
          debugPrint('❌ JOIN: Stanza non trovata in Firestore');
          throw RoomException(_l10n.roomNotFound);
        }

        debugPrint('✅ JOIN: Stanza trovata, aggiungo membro $_memberId');

        final data = snapshot.data() as Map<String, dynamic>;
        final List<dynamic> rawMembers =
            data['members'] as List<dynamic>? ?? [];
        final members = rawMembers
            .map((dynamic value) => value as String)
            .toList();

        if (!members.contains(_memberId)) {
          members.add(_memberId);
        }

        var ownerId = data['ownerId'] as String? ?? _memberId;
        if (!members.contains(ownerId)) {
          ownerId = members.first;
        }

        transaction.update(docRef, {
          'members': members,
          'ownerId': ownerId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('✅ JOIN: Transaction completata con successo');
      });

      debugPrint('🔵 JOIN: Sottoscrivo alla stanza $normalizedCode');
      await _subscribeToRoom(normalizedCode);
      debugPrint('✅ JOIN: Join completato con successo!');
    } on RoomException catch (e) {
      debugPrint('❌ JOIN: RoomException - ${e.message}');
      rethrow;
    } on FirebaseException catch (e, stackTrace) {
      _setError(_l10n.roomJoinFailed);
      debugPrint('❌ JOIN: Firebase error: ${e.message}\n$stackTrace');
      throw RoomException(lastError ?? _l10n.roomJoinFailed);
    } catch (e, stackTrace) {
      _setError(_l10n.roomJoinError);
      debugPrint('❌ JOIN: Unexpected error: $e\n$stackTrace');
      throw RoomException(lastError ?? _l10n.roomJoinError);
    } finally {
      _isJoiningRoom = false;
      notifyListeners();
      debugPrint('🔵 JOIN: Cleanup completato');
    }
  }

  Future<void> leaveRoom() async {
    final code = currentRoomCode;
    if (code == null) {
      _resetState();
      return;
    }

    try {
      final docRef = _roomsRef.doc(code);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) {
          return;
        }

        final data = snapshot.data() as Map<String, dynamic>;
        final List<dynamic> rawMembers =
            data['members'] as List<dynamic>? ?? [];
        final members = rawMembers
            .map((dynamic value) => value as String)
            .toList();
        members.remove(_memberId);

        if (members.isEmpty) {
          transaction.delete(docRef);
          return;
        }

        var ownerId = data['ownerId'] as String? ?? members.first;
        if (!members.contains(ownerId)) {
          ownerId = members.first;
        }

        transaction.update(docRef, {
          'members': members,
          'ownerId': ownerId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e, stackTrace) {
      debugPrint('leaveRoom error: $e\n$stackTrace');
      throw RoomException(_l10n.roomLeaveFailed);
    } finally {
      _clearSubscription();
      _resetState();
      notifyListeners();
    }
  }

  bool isValidRoomCode(String code) {
    final normalized = _normalizeCode(code);
    return normalized.length == 9 &&
        normalized.replaceAll(RegExp(r'[^A-Z0-9]'), '').length == 9;
  }

  Future<void> _subscribeToRoom(String code) async {
    _clearSubscription();

    _roomSubscription = _roomsRef
        .doc(code)
        .snapshots()
        .listen(
          (snapshot) {
            if (!snapshot.exists) {
              _resetState();
              notifyListeners();
              return;
            }

            _room = GroupRoom.fromSnapshot(snapshot);
            notifyListeners();
          },
          onError: (Object error, StackTrace stackTrace) {
            debugPrint('Room subscription error: $error\n$stackTrace');
            _setError(_l10n.roomFetchError);
          },
        );
  }

  static String _normalizeCode(String value) =>
      value.trim().toUpperCase().replaceAll(' ', '');

  static String _generateMemberId() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    final codeUnits = List<int>.generate(
      12,
      (_) => chars.codeUnitAt(random.nextInt(chars.length)),
    );
    return String.fromCharCodes(codeUnits);
  }

  Future<String> _generateUniqueRoomCode() async {
    String code = _generateRoomCode();
    var attempts = 0;
    while (attempts < 5) {
      final snapshot = await _roomsRef.doc(code).get();
      if (!snapshot.exists) {
        return code;
      }
      code = _generateRoomCode();
      attempts++;
    }
    throw RoomException(_l10n.roomCodeGenerateError);
  }

  static String _generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    final codeUnits = List<int>.generate(
      9,
      (_) => chars.codeUnitAt(random.nextInt(chars.length)),
    );
    return String.fromCharCodes(codeUnits);
  }

  void _clearSubscription() {
    final subscription = _roomSubscription;
    if (subscription != null) {
      unawaited(subscription.cancel());
    }
    _roomSubscription = null;
  }

  void _resetState() {
    _room = null;
    _lastError = null;
    _isCreatingRoom = false;
    _isJoiningRoom = false;
  }

  void _setError(String? message) {
    _lastError = message;
    if (message != null) {
      notifyListeners();
    }
  }

  Future<void> updateTimerState({
    required bool isRunning,
    required bool isPaused,
    required int remainingSeconds,
    required int totalSeconds,
    required String sessionType,
    bool isBurnMode = false,
    bool isFailed = false,
    DateTime? startedAt,
    DateTime? pausedAt,
  }) async {
    final code = currentRoomCode;
    if (code == null) return;

    try {
      final timerState = TimerState(
        isRunning: isRunning,
        isPaused: isPaused,
        remainingSeconds: remainingSeconds,
        totalSeconds: totalSeconds,
        sessionType: sessionType,
        isBurnMode: isBurnMode,
        isFailed: isFailed,
        startedAt: startedAt,
        pausedAt: pausedAt,
      );

      await _roomsRef.doc(code).update({
        'timerState': timerState.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e, stackTrace) {
      debugPrint('updateTimerState error: $e\n$stackTrace');
    }
  }

  Future<void> setFailedState() async {
    final code = currentRoomCode;
    if (code == null || _room?.timerState == null) return;

    try {
      final currentState = _room!.timerState!;
      final failedState = TimerState(
        isRunning: false,
        isPaused: false,
        remainingSeconds: currentState.remainingSeconds,
        totalSeconds: currentState.totalSeconds,
        sessionType: currentState.sessionType,
        isBurnMode: currentState.isBurnMode,
        isFailed: true,
        startedAt: currentState.startedAt,
      );

      await _roomsRef.doc(code).update({
        'timerState': failedState.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e, stackTrace) {
      debugPrint('setFailedState error: $e\n$stackTrace');
    }
  }

  Future<void> clearTimerState() async {
    final code = currentRoomCode;
    if (code == null) return;

    try {
      await _roomsRef.doc(code).update({
        'timerState': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e, stackTrace) {
      debugPrint('clearTimerState error: $e\n$stackTrace');
    }
  }

  @override
  void dispose() {
    _clearSubscription();
    super.dispose();
  }
}
