import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:powerful_students/providers/room_provider.dart';
import 'package:powerful_students/providers/pomodoro_provider.dart';
import 'package:powerful_students/core/design_system.dart';
import 'package:powerful_students/widgets/group_room/group_room.dart';

class GroupRoomScreen extends StatefulWidget {
  const GroupRoomScreen({super.key});

  @override
  State<GroupRoomScreen> createState() => _GroupRoomScreenState();
}

class _GroupRoomScreenState extends State<GroupRoomScreen>
    with WidgetsBindingObserver {
  bool _sessionFailed = false;
  bool _sessionCompleted = false;
  int _lastCompletedCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable();

    final provider = context.read<PomodoroProvider>();
    _lastCompletedCount = provider.completedPomodoros;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      provider.setRoomProvider(
        context.read<RoomProvider>(),
        onSessionFailed: () {
          if (mounted) {
            setState(() => _sessionFailed = true);
          }
        },
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final provider = context.read<PomodoroProvider>();
    final roomProvider = context.read<RoomProvider>();

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (provider.isBurnMode &&
          provider.isRunning &&
          provider.currentSession != null) {
        provider.stopTimer();
        roomProvider.setFailedState();
        setState(() => _sessionFailed = true);
      }
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _handleRoomError(Object error) {
    final message = error is RoomException
        ? error.message
        : 'Si è verificato un errore. Riprova.';
    _showSnack(message);
  }

  Future<void> _createRoom(RoomProvider provider) async {
    try {
      await provider.createRoom();
      _showShareMessage(provider.currentRoomCode ?? '');
    } catch (error) {
      _handleRoomError(error);
    }
  }

  Future<void> _leaveRoom(RoomProvider provider) async {
    try {
      await provider.leaveRoom();
    } catch (error) {
      _handleRoomError(error);
    }
  }

  void _showShareMessage(String roomCode) {
    final pomodoroProvider = context.read<PomodoroProvider>();
    final durationMinutes = pomodoroProvider.defaultWorkDuration ~/ 60;
    final message =
        'Unisciti alla mia sessione di studio!\n'
        'Codice: $roomCode\n'
        'Durata: $durationMinutes minuti';

    try {
      final box = context.findRenderObject() as RenderBox?;
      final shareOrigin = box != null
          ? box.localToGlobal(Offset.zero) & box.size
          : const Rect.fromLTWH(0, 0, 1, 1);

      Share.share(
        message,
        subject: 'Codice Stanza Powerful Students',
        sharePositionOrigin: shareOrigin,
      );
    } catch (e) {
      _showSnack('Errore nella condivisione');
    }
  }

  void _copyRoomCode(String roomCode) {
    final pomodoroProvider = context.read<PomodoroProvider>();
    final durationMinutes = pomodoroProvider.defaultWorkDuration ~/ 60;
    final message =
        'Unisciti alla mia sessione di studio!\n'
        'Codice: $roomCode\n'
        'Durata: $durationMinutes minuti';

    try {
      Clipboard.setData(ClipboardData(text: message));
      _showSnack('Messaggio copiato!');
    } catch (e) {
      _showSnack('Errore nella copia');
    }
  }

  void _showJoinRoomDialog() {
    final controller = TextEditingController();
    final roomProvider = Provider.of<RoomProvider>(context, listen: false);

    showCupertinoDialog(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text(
          'Unisciti al mattoncino',
          style: TextStyle(fontSize: 18),
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 20),
          child: CupertinoTextField(
            controller: controller,
            placeholder: 'Codice a 9 cifre',
            maxLength: 9,
            textCapitalization: TextCapitalization.characters,
            textAlign: TextAlign.center,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            style: const TextStyle(
              fontSize: 20,
              letterSpacing: 4,
              fontWeight: FontWeight.w600,
            ),
            placeholderStyle: const TextStyle(
              fontSize: 16,
              letterSpacing: 2,
              color: CupertinoColors.placeholderText,
            ),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annulla'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () async {
              if (controller.text.length == 9) {
                final navigator = Navigator.of(dialogContext);
                try {
                  await roomProvider.joinRoom(controller.text);
                  if (mounted) navigator.pop();
                } catch (e) {
                  _handleRoomError(e);
                }
              }
            },
            child: const Text('Unisciti'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBack(RoomProvider roomProvider) async {
    if (roomProvider.hasRoom) await _leaveRoom(roomProvider);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _handleLeaveAndPop(RoomProvider roomProvider) async {
    await _leaveRoom(roomProvider);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _handleSessionFailed(RoomProvider roomProvider) async {
    await _leaveRoom(roomProvider);
    setState(() => _sessionFailed = false);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _handleSessionCompleted(RoomProvider roomProvider) async {
    await _leaveRoom(roomProvider);
    setState(() => _sessionCompleted = false);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer2<RoomProvider, PomodoroProvider>(
          builder: (context, roomProvider, pomodoroProvider, _) {
            if (pomodoroProvider.completedPomodoros > _lastCompletedCount) {
              _lastCompletedCount = pomodoroProvider.completedPomodoros;
              _sessionCompleted = true;
            }

            if (_sessionFailed) {
              return SessionFailedScreen(
                onDismiss: () => _handleSessionFailed(roomProvider),
              );
            }

            if (_sessionCompleted) {
              return SessionCompletedScreen(
                completedPomodoros: pomodoroProvider.completedPomodoros,
                onContinue: () => _handleSessionCompleted(roomProvider),
              );
            }

            final hasRoom = roomProvider.hasRoom;
            final isOwner = roomProvider.isOwner;
            final session = pomodoroProvider.currentSession;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  GroupRoomHeader(
                    roomProvider: roomProvider,
                    pomodoroProvider: pomodoroProvider,
                    isOwner: isOwner,
                    isSessionActive: session != null,
                    onBack: () => _handleBack(roomProvider),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Un mattoncino alla volta puoi\ncostruire molto più di quanto immagini.',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  if (hasRoom)
                    GroupRoomInfoCard(
                      roomProvider: roomProvider,
                      isOwner: isOwner,
                      onCopyCode: () => _copyRoomCode(roomProvider.currentRoomCode!),
                      onShareCode: () => _showShareMessage(roomProvider.currentRoomCode!),
                    ),
                  const Spacer(),
                  GroupRoomTimer(
                    pomodoroProvider: pomodoroProvider,
                    isOwner: !hasRoom || isOwner,
                  ),
                  const Spacer(),
                  if (!hasRoom)
                    CreateJoinRoomButtons(
                      roomProvider: roomProvider,
                      onCreateRoom: () => _createRoom(roomProvider),
                      onJoinRoom: _showJoinRoomDialog,
                    )
                  else
                    GroupRoomBottomActions(
                      hasRoom: hasRoom,
                      isOwner: isOwner,
                      isRunning: pomodoroProvider.isRunning,
                      hasSession: session != null,
                      onStop: () {
                        pomodoroProvider.stopTimer();
                        roomProvider.clearTimerState();
                      },
                      onStart: pomodoroProvider.startWorkSession,
                      onLeave: () => _handleLeaveAndPop(roomProvider),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
