import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:powerful_students/core/design_system.dart';
import 'package:powerful_students/providers/pomodoro_provider.dart';
import 'package:powerful_students/providers/room_provider.dart';
import 'package:powerful_students/providers/chat_provider.dart';
import 'package:powerful_students/providers/settings_provider.dart';
import 'package:powerful_students/screens/group_room_screen.dart';
import 'package:powerful_students/screens/main_navigation_screen.dart';
import 'package:powerful_students/screens/timer_screen.dart';
import 'package:powerful_students/screens/settings_screen.dart';
import 'package:powerful_students/l10n/app_localizations.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Carica variabili d'ambiente
      try {
        await dotenv.load(fileName: '.env');
      } catch (e) {
        debugPrint('Errore caricamento .env: $e');
      }

      FlutterError.onError = FlutterError.dumpErrorToConsole;

      WidgetsBinding.instance.platformDispatcher.onError =
          (Object error, StackTrace stackTrace) {
            debugPrint('Errore non gestito: $error');
            return true;
          };

      await _configureTimezone();

      final settingsProvider = SettingsProvider();
      await settingsProvider.initialize();

      runApp(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<RoomProvider>(
              create: (_) => RoomProvider(),
            ),
            ChangeNotifierProvider<SettingsProvider>.value(
              value: settingsProvider,
            ),
            ChangeNotifierProxyProvider<RoomProvider, PomodoroProvider>(
              create: (_) => PomodoroProvider(),
              update: (_, roomProvider, pomodoroProvider) {
                final notifier = pomodoroProvider ?? PomodoroProvider();
                notifier.setRoomProvider(roomProvider);
                return notifier;
              },
            ),
            ChangeNotifierProxyProvider<SettingsProvider, ChatProvider>(
              create: (_) => ChatProvider(),
              update: (_, settings, chatProvider) {
                final provider = chatProvider ?? ChatProvider();
                provider.updateSettings(settings);
                return provider;
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

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<PomodoroProvider>();
      await provider.initializeNotifications();
      await _initializeUserId(provider);
    });
  }

  Future<void> _initializeUserId(PomodoroProvider provider) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('device_user_id');

      if (userId == null) {
        userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
        await prefs.setString('device_user_id', userId);
      }
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
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        platform: TargetPlatform.iOS,
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: AppTypography.fontFamily,
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        Widget page;
        switch (settings.name) {
          case '/':
            page = const MainNavigationScreen();
            break;
          case '/timer':
            page = const TimerScreen();
            break;
          case '/group-room':
            page = const GroupRoomScreen();
            break;
          case '/settings':
            page = const SettingsScreen();
            break;
          default:
            page = const MainNavigationScreen();
        }
        return CupertinoPageRoute(
          builder: (_) => page,
          settings: settings,
        );
      },
    );
  }
}
