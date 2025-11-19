import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:powerful_students/core/design_system.dart';
import 'package:powerful_students/providers/pomodoro_provider.dart';
import 'package:powerful_students/providers/room_provider.dart';
import 'package:powerful_students/screens/group_room_screen.dart';
import 'package:powerful_students/screens/mode_selection_screen.dart';
import 'package:powerful_students/screens/timer_screen.dart';
import 'firebase_options.dart';

void main() {
  BindingBase.debugZoneErrorsAreFatal = true;

  runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      FlutterError.onError = (FlutterErrorDetails details) {
        Zone.current.handleUncaughtError(
          details.exception,
          details.stack ?? StackTrace.empty,
        );
      };

      WidgetsBinding.instance.platformDispatcher.onError =
          (Object error, StackTrace stackTrace) {
            debugPrint('Errore non gestito dal PlatformDispatcher: $error');
            debugPrint('Stack trace: $stackTrace');
            return true;
          };

      await _configureTimezone();

      runApp(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<RoomProvider>(
              create: (_) => RoomProvider(),
            ),
            ChangeNotifierProxyProvider<RoomProvider, PomodoroProvider>(
              create: (_) => PomodoroProvider(),
              update: (_, roomProvider, pomodoroProvider) {
                final notifier = pomodoroProvider ?? PomodoroProvider();
                notifier.setRoomProvider(roomProvider);
                return notifier;
              },
            ),
          ],
          child: const MyApp(),
        ),
      );
    },
    (Object error, StackTrace stackTrace) {
      debugPrint('Errore non gestito nella zona principale: $error');
      debugPrint('Stack trace: $stackTrace');
    },
  );
}

Future<void> _configureTimezone() async {
  tzdata.initializeTimeZones();
  try {
    final dynamic timezoneValue = await FlutterTimezone.getLocalTimezone();
    final timezoneIdentifier = _resolveTimezoneIdentifier(timezoneValue);
    tz.setLocalLocation(tz.getLocation(timezoneIdentifier));
  } catch (e, stackTrace) {
    debugPrint('Impossibile impostare il fuso orario locale: $e');
    debugPrint('Stack trace: $stackTrace');
    tz.setLocalLocation(tz.getLocation('UTC'));
  }
}

String _resolveTimezoneIdentifier(dynamic timezoneValue) {
  if (timezoneValue is String && timezoneValue.isNotEmpty) {
    return timezoneValue;
  }

  try {
    final dynamic identifier =
        (timezoneValue as dynamic).identifier; // ignore: avoid_dynamic_calls
    if (identifier is String && identifier.isNotEmpty) {
      return identifier;
    }
  } catch (_) {
    // Ricadiamo all'analisi generica più sotto
  }

  throw StateError('Timezone non riconosciuto: $timezoneValue');
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool _isObserverAdded = false;
  bool _isObserverRegistrationScheduled = false;
  bool _notificationsInitialized = false;

  @override
  void initState() {
    super.initState();
    // NON aggiungere l'observer qui - verrà aggiunto dopo che il widget è montato
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_notificationsInitialized) {
      _notificationsInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        try {
          await context.read<PomodoroProvider>().initializeNotifications();
        } catch (e, stackTrace) {
          debugPrint(
            'Errore nell\'inizializzazione delle notifiche (non critico): $e',
          );
          debugPrint('Stack trace: $stackTrace');
        }
      });
    }

    if (_isObserverAdded || _isObserverRegistrationScheduled) {
      return;
    }

    _isObserverRegistrationScheduled = true;

    // Registriamo l'observer dopo il primo frame per garantire che il provider sia pronto.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isObserverRegistrationScheduled = false;

      if (!mounted || _isObserverAdded) {
        return;
      }

      try {
        // Verifica che il provider sia disponibile; se non lo è, verrà sollevata un'eccezione.
        context.read<PomodoroProvider>();
        WidgetsBinding.instance.addObserver(this);
        _isObserverAdded = true;
      } catch (e, stackTrace) {
        debugPrint('Impossibile registrare l\'observer del ciclo di vita: $e');
        debugPrint('Stack trace: $stackTrace');
      }
    });
  }

  @override
  void dispose() {
    if (_isObserverAdded) {
      WidgetsBinding.instance.removeObserver(this);
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Verifica che il widget sia ancora montato e il provider disponibile
    if (!mounted) return;

    try {
      final pomodoroProvider = context.read<PomodoroProvider>();

      // A questo punto pomodoroProvider è garantito non essere null
      // (se fosse null, avremmo già fatto return nel blocco catch sopra)
      if (state == AppLifecycleState.paused ||
          state == AppLifecycleState.inactive) {
        // L'app va in background - il timer continuerà tramite notifiche programmate
        pomodoroProvider.handleAppPaused();
      } else if (state == AppLifecycleState.resumed) {
        // L'app torna in foreground - verifica se il timer è scaduto
        pomodoroProvider.handleAppResumed();
      }
    } catch (e, stackTrace) {
      // Se c'è un errore, l'app continua comunque
      debugPrint('Errore nella gestione del ciclo di vita: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Powerful Students',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2A2A2A),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Helvetica',
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontFamily: 'Helvetica'),
          displayMedium: TextStyle(fontFamily: 'Helvetica'),
          displaySmall: TextStyle(fontFamily: 'Helvetica'),
          headlineLarge: TextStyle(fontFamily: 'Helvetica'),
          headlineMedium: TextStyle(fontFamily: 'Helvetica'),
          headlineSmall: TextStyle(fontFamily: 'Helvetica'),
          titleLarge: TextStyle(fontFamily: 'Helvetica'),
          titleMedium: TextStyle(fontFamily: 'Helvetica'),
          titleSmall: TextStyle(fontFamily: 'Helvetica'),
          bodyLarge: TextStyle(fontFamily: 'Helvetica'),
          bodyMedium: TextStyle(fontFamily: 'Helvetica'),
          bodySmall: TextStyle(fontFamily: 'Helvetica'),
          labelLarge: TextStyle(fontFamily: 'Helvetica'),
          labelMedium: TextStyle(fontFamily: 'Helvetica'),
          labelSmall: TextStyle(fontFamily: 'Helvetica'),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const ModeSelectionScreen(),
        '/timer': (context) => const TimerScreen(),
        '/group-room': (context) => const GroupRoomScreen(),
      },
    );
  }
}
