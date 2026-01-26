import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:powerful_students/models/study_session.dart';
import 'package:powerful_students/providers/room_provider.dart';
import 'package:powerful_students/providers/pomodoro_provider.dart';
import 'package:powerful_students/core/design_system.dart';

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
    
    // Inizializza il conteggio per rilevare nuovi completamenti
    final provider = context.read<PomodoroProvider>();
    _lastCompletedCount = provider.completedPomodoros;

    // Configura il callback per il fallimento remoto
    WidgetsBinding.instance.addPostFrameCallback((_) {
      provider.setRoomProvider(
        context.read<RoomProvider>(),
        onSessionFailed: () {
          if (mounted) {
            setState(() {
              _sessionFailed = true;
            });
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

    // Se l'app va in background con burn mode attivo e sessione in corso, la sessione fallisce per tutti
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (provider.isBurnMode &&
          provider.isRunning &&
          provider.currentSession != null) {
        provider.stopTimer();
        roomProvider.setFailedState();
        setState(() {
          _sessionFailed = true;
        });
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
            placeholderStyle: TextStyle(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Consumer2<RoomProvider, PomodoroProvider>(
          builder: (context, roomProvider, pomodoroProvider, _) {
            // Rileva completamento sessione
            if (pomodoroProvider.completedPomodoros > _lastCompletedCount) {
              _lastCompletedCount = pomodoroProvider.completedPomodoros;
              _sessionCompleted = true;
            }

            // Mostra schermata di fallimento se la sessione è fallita
            if (_sessionFailed) {
              return _buildFailedScreen(context, roomProvider);
            }

            // Mostra schermata di successo se la sessione è conclusa
            if (_sessionCompleted) {
              return _buildCompletedScreen(context, roomProvider, pomodoroProvider);
            }

            final hasRoom = roomProvider.hasRoom;
            final isOwner = roomProvider.isOwner;
            final session = pomodoroProvider.currentSession;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.sm),
                  _buildHeader(
                    context,
                    roomProvider,
                    pomodoroProvider,
                    isOwner,
                    session != null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (!hasRoom)
                    _buildCreateJoinSection(roomProvider, pomodoroProvider)
                  else ...[
                    _buildRoomInfo(roomProvider, pomodoroProvider, isOwner),
                    const Spacer(),
                    _buildCircularTimer(pomodoroProvider, isOwner),
                    const Spacer(),
                  ],
                  const Spacer(),
                  _buildBottomActions(
                    hasRoom,
                    roomProvider,
                    pomodoroProvider,
                    isOwner,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFailedScreen(BuildContext context, RoomProvider roomProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            AppAssets.brickyBroken,
            width: 120,
            height: 120,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'SESSIONE FALLITA',
            style: AppTypography.headline.copyWith(
              color: Colors.red,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Qualcuno ha lasciato l\'app durante una sessione di Deep Building.',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () async {
              final navigator = Navigator.of(context);
              await _leaveRoom(roomProvider);
              setState(() {
                _sessionFailed = false;
              });
              if (mounted) navigator.pop();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
              decoration: BoxDecoration(
                color: AppColors.cta,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: const Text(
                'TORNA INDIETRO',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedScreen(
    BuildContext context,
    RoomProvider roomProvider,
    PomodoroProvider pomodoroProvider,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.sm),
          // Header semplificato senza toggle
          Row(
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () async {
                  await _leaveRoom(roomProvider);
                  setState(() {
                    _sessionCompleted = false;
                  });
                },
                child: const Row(
                  children: [
                    Icon(AppIcons.back, color: AppColors.textPrimary, size: 28),
                    Text(
                      'Back',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // Info stanza con avatar visibili
          _buildRoomInfo(roomProvider, pomodoroProvider, roomProvider.isOwner),
          const Spacer(),
          // Immagine di successo
          Image.asset(
            AppAssets.brickyLogo,
            width: 180,
            height: 180,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'SESSIONE COMPLETATA!',
            style: AppTypography.headline.copyWith(
              color: AppColors.primary,
              letterSpacing: 1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Ottimo lavoro di squadra! Avete costruito un altro mattoncino.',
            style: AppTypography.body,
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () async {
              await _leaveRoom(roomProvider);
              setState(() {
                _sessionCompleted = false;
              });
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: AppColors.cta,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: const Center(
                child: Text(
                  'NUOVA SESSIONE',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    RoomProvider roomProvider,
    PomodoroProvider pomodoroProvider,
    bool isOwner,
    bool isSessionActive,
  ) {
    return Row(
      children: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () async {
            final navigator = Navigator.of(context);
            if (roomProvider.hasRoom) {
              await _leaveRoom(roomProvider);
            }
            if (mounted) navigator.pop();
          },
          child: const Row(
            children: [
              Icon(AppIcons.back, color: AppColors.textPrimary, size: 28),
              Text(
                'Back',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        // Mostra stato Deep Focus per tutti
        AppDecorations.glassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              // Mattoncino Deep Focus - acceso/spento basato su isBurnMode
              Opacity(
                opacity: pomodoroProvider.isBurnMode ? 1.0 : 0.4,
                child: Image.asset(
                  AppAssets.brickyBurnSmall,
                  width: 16,
                  height: 16,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 4),
              // Solo l'owner o chi non è in una stanza può cambiare il burn mode
              if (isOwner || !roomProvider.hasRoom)
                CupertinoSwitch(
                  value: pomodoroProvider.isBurnMode,
                  onChanged: isSessionActive
                      ? null
                      : (value) {
                          HapticFeedback.mediumImpact();
                          pomodoroProvider.toggleBurnMode();
                        },
                  activeTrackColor: AppColors.primary,
                )
              else
                // Badge per i guest che indica lo stato
                Text(
                  pomodoroProvider.isBurnMode ? 'ON' : 'OFF',
                  style: AppTypography.label.copyWith(
                    fontSize: 10,
                    color: pomodoroProvider.isBurnMode
                        ? AppColors.primary
                        : AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCreateJoinSection(
    RoomProvider provider,
    PomodoroProvider pomodoroProvider,
  ) {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.md),
        // Prima: seleziona il tempo
        _buildSetupTimer(pomodoroProvider),
        const SizedBox(height: AppSpacing.xl),
        // Poi: crea la stanza
        CupertinoButton(
          onPressed: provider.isCreatingRoom
              ? null
              : () => _createRoom(provider),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.cta,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: provider.isCreatingRoom
                ? const CupertinoActivityIndicator()
                : const Text(
                    'CREA STANZA',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        CupertinoButton(
          onPressed: provider.isJoiningRoom ? null : _showJoinRoomDialog,
          child: AppDecorations.glassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  AppAssets.brickyGroup,
                  width: 20,
                  height: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Unisciti al mattoncino',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSetupTimer(PomodoroProvider provider) {
    return AppDecorations.glassContainer(
      padding: const EdgeInsets.all(AppSpacing.sm),
      borderRadius: BorderRadius.circular(155),
      child: SizedBox(
        width: 290,
        height: 290,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _formatDuration(provider.defaultWorkDuration),
                  style: AppTypography.timerLarge,
                ),
                const Text('IMPOSTA TEMPO', style: AppTypography.label),
              ],
            ),
            _buildTimerPoints(),
            _DraggableTimerIndicator(
              radius: 125.0,
              initialMinutes: provider.defaultWorkDuration ~/ 60,
              onMinutesChanged: (minutes) {
                provider.setDefaultWorkDurationMinutes(minutes);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomInfo(
    RoomProvider provider,
    PomodoroProvider pomodoroProvider,
    bool isOwner,
  ) {
    final room = provider.room;
    final members = room?.memberIds ?? [];
    // Escludi l'owner dalla lista dei membri visualizzati (solo chi si è unito)
    final joinedMembers = members.where((id) => id != room?.ownerId).toList();

    return AppDecorations.glassContainer(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          // Codice stanza con dimensioni ridotte
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                provider.currentRoomCode ?? '',
                style: AppTypography.title.copyWith(
                  letterSpacing: 2,
                  fontSize: 18,
                ),
              ),
              const SizedBox(width: 12),
              if (isOwner) ...[
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(32, 32),
                  onPressed: () => _copyRoomCode(provider.currentRoomCode!),
                  child: const Icon(CupertinoIcons.doc_on_doc, size: 18),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(32, 32),
                  onPressed: () => _showShareMessage(provider.currentRoomCode!),
                  child: const Icon(CupertinoIcons.share, size: 18),
                ),
              ],
            ],
          ),
          // Mostra avatar dei membri sovrapposti (solo se ce ne sono)
          if (joinedMembers.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 36,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ...joinedMembers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final memberId = entry.value;
                    final initials = memberId.substring(0, 2).toUpperCase();
                    // Calcola offset per sovrapposizione
                    final totalWidth =
                        joinedMembers.length * 24.0 + 12; // 24px overlap + 12 extra
                    final startOffset = -totalWidth / 2;
                    return Positioned(
                      left: MediaQuery.of(context).size.width / 2 -
                          AppSpacing.md -
                          18 +
                          startOffset +
                          (index * 24.0),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            initials,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCircularTimer(PomodoroProvider provider, bool isOwner) {
    final session = provider.currentSession;

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ring esterno
          Container(
            width: 310,
            height: 310,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.textPrimary.withValues(alpha: 0.15),
                width: 15,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),

          if (session == null)
            // Per chi non è owner, mostra solo il timer con la durata impostata dall'host
            _buildWaitingTimer(provider, isOwner)
          else
            _buildActiveTimer(session, provider.isBurnMode),
        ],
      ),
    );
  }

  Widget _buildWaitingTimer(PomodoroProvider provider, bool isOwner) {
    // Chi non è owner non può modificare la durata
    if (!isOwner) {
      return AppDecorations.glassContainer(
        padding: const EdgeInsets.all(AppSpacing.sm),
        borderRadius: BorderRadius.circular(155),
        child: SizedBox(
          width: 290,
          height: 290,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Immagine centrale Bricky in attesa
              Opacity(
                opacity: 0.5,
                child: Image.asset(
                  AppAssets.brickyLogo,
                  width: 140,
                  height: 140,
                  fit: BoxFit.contain,
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),
                  Text(
                    _formatDuration(provider.defaultWorkDuration),
                    style: AppTypography.timerLarge.copyWith(fontSize: 48),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'IN ATTESA',
                    style: AppTypography.label.copyWith(
                      color: AppColors.textSecondary,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "L'host avvierà la sessione",
                    style: AppTypography.caption.copyWith(
                      fontSize: 12,
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                    ),
                  ),
                  const Spacer(flex: 1),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // L'owner può modificare la durata
    return _buildSetupTimer(provider);
  }

  Widget _buildActiveTimer(StudySession session, bool isBurnMode) {
    return CircularPercentIndicator(
      radius: 150.0,
      lineWidth: 12.0,
      animation: true,
      animateFromLastPercent: true,
      percent: session.progress,
      backgroundColor: AppColors.textPrimary.withValues(alpha: 0.05),
      progressColor: AppColors.primary,
      circularStrokeCap: CircularStrokeCap.round,
      center: SizedBox(
        width: 280,
        height: 280,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Liquid Animation in background (molto leggera)
            Positioned.fill(
              child: ClipOval(
                child: _LiquidBackground(progress: session.progress),
              ),
            ),

            // Layout principale: Mattoncino grande + Timer piccolo sotto
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // MATTONCINO PROTAGONISTA - grande e sempre visibile
                _AnimatedBrickyBuilder(
                  progress: session.progress,
                  isBurnMode: isBurnMode,
                ),
                const SizedBox(height: 20),

                // Timer piccolo sotto
                Column(
                  children: [
                    Text(
                      _getSessionText(session.type),
                      style: AppTypography.label.copyWith(
                        letterSpacing: 2,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      session.formattedRemainingTime,
                      style: AppTypography.timerLarge.copyWith(
                        fontSize: 42,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${(session.progress * 100).round()}%',
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerPoints() {
    return Stack(
      children: List.generate(60, (index) {
        final angle = (index * 6) * pi / 180;
        final isMajor = index % 5 == 0;
        return Transform.translate(
          offset: Offset(cos(angle) * 115, sin(angle) * 115),
          child: Container(
            width: isMajor ? 4 : 2,
            height: isMajor ? 4 : 2,
            decoration: BoxDecoration(
              color: isMajor
                  ? AppColors.textPrimary
                  : AppColors.textPrimary.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildBottomActions(
    bool hasRoom,
    RoomProvider roomProvider,
    PomodoroProvider pomodoroProvider,
    bool isOwner,
  ) {
    final session = pomodoroProvider.currentSession;
    final isRunning = pomodoroProvider.isRunning;

    // Se non c'è stanza, non mostrare azioni (gestite nella sezione create/join)
    if (!hasRoom) {
      return const SizedBox.shrink();
    }

    // Se c'è una sessione attiva
    if (session != null && isRunning) {
      // Solo l'owner può stoppare la sessione
      if (isOwner) {
        return CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            HapticFeedback.lightImpact();
            pomodoroProvider.stopTimer();
            roomProvider.clearTimerState();
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: Colors.red, width: 2),
            ),
            child: const Center(
              child: Text(
                'STOP',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        );
      }
      // Chi non è owner non ha controlli durante la sessione
      return const SizedBox.shrink();
    }

    // Prima di iniziare: solo l'owner può avviare
    if (isOwner) {
      return Row(
        children: [
          Expanded(
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () async {
                HapticFeedback.lightImpact();
                await _leaveRoom(roomProvider);
                if (mounted) Navigator.pop(context);
              },
              child: AppDecorations.glassContainer(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: const Center(
                  child: Text(
                    'ESCI',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                HapticFeedback.heavyImpact();
                pomodoroProvider.startWorkSession();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: AppColors.cta,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: const Center(
                  child: Text(
                    'INIZIA',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Chi non è owner può solo uscire
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () async {
        HapticFeedback.lightImpact();
        await _leaveRoom(roomProvider);
        if (mounted) Navigator.pop(context);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: Colors.red, width: 2),
        ),
        child: const Center(
          child: Text(
            'ESCI DALLA STANZA',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  String _getSessionText(SessionType type) {
    switch (type) {
      case SessionType.work:
        return 'STUDIO';
      case SessionType.shortBreak:
        return 'PAUSA';
      case SessionType.longBreak:
        return 'RELAX';
    }
  }

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _LiquidBackground extends StatefulWidget {
  final double progress;
  const _LiquidBackground({required this.progress});

  @override
  State<_LiquidBackground> createState() => _LiquidBackgroundState();
}

class _LiquidBackgroundState extends State<_LiquidBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(300, 300),
          painter: _LiquidPainter(
            animationValue: _controller.value,
            progress: widget.progress,
            color: AppColors.primary.withValues(alpha: 0.4),
          ),
        );
      },
    );
  }
}

class _LiquidPainter extends CustomPainter {
  final double animationValue;
  final double progress;
  final Color color;

  _LiquidPainter({
    required this.animationValue,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();

    final yOffset = size.height * (1 - progress);
    final waveHeight = 15.0;

    path.moveTo(0, size.height);
    path.lineTo(0, yOffset);

    for (double x = 0; x <= size.width; x++) {
      final y =
          yOffset +
          sin((x / size.width * 2 * pi) + (animationValue * 2 * pi)) *
              waveHeight;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LiquidPainter oldDelegate) => true;
}

class _DraggableTimerIndicator extends StatefulWidget {
  final double radius;
  final int initialMinutes;
  final Function(int minutes) onMinutesChanged;

  const _DraggableTimerIndicator({
    required this.radius,
    required this.initialMinutes,
    required this.onMinutesChanged,
  });

  @override
  State<_DraggableTimerIndicator> createState() =>
      _DraggableTimerIndicatorState();
}

class _DraggableTimerIndicatorState extends State<_DraggableTimerIndicator> {
  late double _currentAngle;
  int _lastMinute = 0;

  @override
  void initState() {
    super.initState();
    _currentAngle = _minutesToAngle(widget.initialMinutes);
    _lastMinute = widget.initialMinutes;
  }

  double _calculateAngle(Offset center, Offset point) {
    return atan2(point.dy - center.dy, point.dx - center.dx);
  }

  int _angleToMinutes(double angle) {
    double normalizedAngle = angle + pi / 2;
    if (normalizedAngle < 0) normalizedAngle += 2 * pi;
    int minutes = ((normalizedAngle / (2 * pi)) * 60).round();
    if (minutes == 0) minutes = 60;
    return minutes.clamp(1, 60);
  }

  double _minutesToAngle(int minutes) {
    final clampedMinutes = minutes.clamp(1, 60);
    final effectiveMinutes = clampedMinutes == 60 ? 60 : clampedMinutes;
    final normalized = (effectiveMinutes / 60) * 2 * pi;
    return normalized - pi / 2;
  }

  @override
  Widget build(BuildContext context) {
    // Il centro è a metà del container (145, 145 per un container 290x290)
    const double containerSize = 290;
    final center = const Offset(containerSize / 2, containerSize / 2);
    final buttonX = cos(_currentAngle) * (widget.radius - 15);
    final buttonY = sin(_currentAngle) * (widget.radius - 15);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanUpdate: (details) {
        final angle = _calculateAngle(center, details.localPosition);
        final minutes = _angleToMinutes(angle);

        if (minutes != _lastMinute) {
          HapticFeedback.selectionClick();
          _lastMinute = minutes;
        }

        setState(() => _currentAngle = angle);
        widget.onMinutesChanged(minutes);
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: containerSize,
            height: containerSize,
            color: Colors.transparent,
          ),
          Positioned(
            left: buttonX + (containerSize / 2) - 18,
            top: buttonY + (containerSize / 2) - 18,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.textPrimary, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.5),
                    blurRadius: 15,
                  ),
                ],
              ),
              child: const Icon(AppIcons.drag, size: 18, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated Bricky widget that progressively reveals as session progresses
/// Il mattoncino è il PROTAGONISTA: grande e sempre visibile, mai coperto
class _AnimatedBrickyBuilder extends StatelessWidget {
  final double progress;
  final bool isBurnMode;

  const _AnimatedBrickyBuilder({
    required this.progress,
    required this.isBurnMode,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate reveal factor: fully visible at 97% progress (29/30 minutes)
    // progress ranges from 0.0 (start) to 1.0 (complete)
    final revealFactor = (progress / 0.97).clamp(0.0, 1.0);

    // Scegli l'immagine in base al burn mode
    final assetPath = isBurnMode
        ? AppAssets.brickyBurn  // Image 4 - con fuoco (burn mode attivo)
        : AppAssets.brickyLogo; // Image 3 - normale (burn mode spento)

    return ClipRect(
      child: Align(
        alignment: Alignment.bottomCenter,
        heightFactor: revealFactor,
        child: Image.asset(
          assetPath,
          width: 170,
          height: 170,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
