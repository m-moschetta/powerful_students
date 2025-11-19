import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:powerful_students/models/study_session.dart';
import 'package:vibration/vibration.dart';
import 'package:timezone/timezone.dart' as tz;

class PomodoroNotificationService {
  PomodoroNotificationService();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  AudioPlayer? _audioPlayer;

  Future<void> initialize({required VoidCallback onNotificationTap}) async {
    try {
      _audioPlayer = AudioPlayer();
    } catch (e, stackTrace) {
      debugPrint('AudioPlayer initialization failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      _audioPlayer = null;
    }

    try {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      final bool? initialized = await _notifications.initialize(
        settings,
        onDidReceiveNotificationResponse: (NotificationResponse response) async {
          if (response.id == 0) {
            Future.microtask(onNotificationTap);
          }
        },
      );

      if (initialized == true) {
        try {
          await _notifications
              .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin>()
              ?.requestPermissions(alert: true, badge: true, sound: true);
        } catch (e, stackTrace) {
          debugPrint('iOS notification permission error: $e');
          debugPrintStack(stackTrace: stackTrace);
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Notification initialization failed: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> scheduleSessionEnd({
    required DateTime startTime,
    required int durationSeconds,
    required SessionType sessionType,
  }) async {
    try {
      final endTime = startTime.add(Duration(seconds: durationSeconds));
      if (endTime.isBefore(DateTime.now())) {
        debugPrint('Notification end time already passed, skip schedule');
        return;
      }

      final scheduledDate = tz.TZDateTime.from(endTime, tz.local);
      final (title, body) = _notificationTextFor(sessionType);

      await _notifications.zonedSchedule(
        0,
        title,
        body,
        scheduledDate,
        _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e, stackTrace) {
      debugPrint('Error scheduling notification: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> cancelScheduledNotification() async {
    try {
      await _notifications.cancel(0);
    } catch (e, stackTrace) {
      debugPrint('Error cancelling notification: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> handleSessionCompletionFeedback(SessionType type) async {
    await _triggerVibration();
    await _playNotificationSound();
    await _showNotification(type);
  }

  Future<void> _triggerVibration() async {
    try {
      final bool? hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        await Vibration.vibrate(duration: 1000);
      }
    } catch (e, stackTrace) {
      debugPrint('Vibration error: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _playNotificationSound() async {
    if (_audioPlayer == null) {
      debugPrint('Audio player unavailable, skip sound');
      return;
    }

    try {
      try {
        await _audioPlayer!.play(AssetSource('sounds/notification.mp3'));
        return;
      } catch (e) {
        debugPrint('notification.mp3 failed: $e');
      }

      try {
        await _audioPlayer!.play(AssetSource('sounds/beep.mp3'));
        return;
      } catch (e) {
        debugPrint('beep.mp3 failed: $e');
      }

      debugPrint('No notification sounds could be played');
    } catch (e, stackTrace) {
      debugPrint('Unexpected audio error: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _showNotification(SessionType type) async {
    try {
      final (title, body) = _notificationTextFor(type);
      await _notifications.show(0, title, body, _notificationDetails());
    } catch (e, stackTrace) {
      debugPrint('Show notification failed: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  (String title, String body) _notificationTextFor(SessionType type) {
    if (type == SessionType.work) {
      return (
        'Tempo di pausa!',
        'Ottimo lavoro! Goditi una pausa di 5 minuti.',
      );
    }
    return (
      'Tempo di studiare!',
      'La pausa è finita. Iniziamo un nuovo pomodoro!',
    );
  }

  NotificationDetails _notificationDetails() {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'pomodoro_channel',
      'Pomodoro Timer',
      channelDescription: 'Notifiche per il timer Pomodoro',
      importance: Importance.high,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return const NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  Future<void> dispose() async {
    try {
      await _audioPlayer?.dispose();
    } catch (_) {
      // ignore
    } finally {
      _audioPlayer = null;
    }
  }
}
