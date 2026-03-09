import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:powerful_students/core/design_system.dart';
import 'package:powerful_students/providers/pomodoro_provider.dart';
import 'package:powerful_students/providers/room_provider.dart';
import 'package:powerful_students/screens/group_room_screen.dart';
import 'package:powerful_students/screens/mode_selection_screen.dart';
import 'package:powerful_students/screens/timer_screen.dart';
import 'package:powerful_students/l10n/app_localizations.dart';
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
            debugPrint('Errore non gestito: $error');
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
      debugPrint('Errore fatale: $error');
    },
  );
}

Future<void> _configureTimezone() async {
  tzdata.initializeTimeZones();
  try {
    final timezone = await FlutterTimezone.getLocalTimezone();
    // FlutterTimezone potrebbe restituire un oggetto o una stringa a seconda della versione
    final String identifier = timezone is String ? timezone : (timezone as dynamic).identifier;
    tz.setLocalLocation(tz.getLocation(identifier));
  } catch (e) {
    tz.setLocalLocation(tz.getLocation('UTC'));
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Inizializzazione notifiche e statistiche
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<PomodoroProvider>();
      await provider.initializeNotifications();

      // Genera o recupera userId univoco per questo dispositivo
      await _initializeUserId(provider);
    });
  }

  Future<void> _initializeUserId(PomodoroProvider provider) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('device_user_id');

      if (userId == null) {
        // Genera un nuovo userId univoco per questo dispositivo
        userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
        await prefs.setString('device_user_id', userId);
        debugPrint('🆔 Nuovo userId generato: $userId');
      } else {
        debugPrint('🆔 UserId esistente: $userId');
      }

      // Imposta l'userId nel provider e carica stats
      provider.setUserId(userId);
    } catch (e) {
      debugPrint('❌ Errore inizializzazione userId: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final provider = context.read<PomodoroProvider>();
    if (state == AppLifecycleState.paused) {
      provider.handleAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      provider.handleAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Usiamo MaterialApp con stile iOS per retrocompatibilità e flessibilità
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        platform: TargetPlatform.iOS,
        scaffoldBackgroundColor: Colors.transparent, // Gestito dal gradiente nel body
        fontFamily: AppTypography.fontFamily,
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        Widget page;
        switch (settings.name) {
          case '/':
            page = const ModeSelectionScreen();
            break;
          case '/timer':
            page = const TimerScreen();
            break;
          case '/group-room':
            page = const GroupRoomScreen();
            break;
          default:
            page = const ModeSelectionScreen();
        }
        
        // Usiamo CupertinoPageRoute per transizioni native iOS
        return CupertinoPageRoute(
          builder: (context) => Stack(
            children: [
              // Background globale sfumato stile iOS 18/26
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.bgStart, AppColors.bgEnd],
                  ),
                ),
              ),
              page,
            ],
          ),
          settings: settings,
        );
      },
    );
  }
}

