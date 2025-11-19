import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:powerful_students/providers/room_provider.dart';
import 'package:powerful_students/providers/pomodoro_provider.dart';
import 'package:powerful_students/core/design_system.dart';

class GroupRoomScreen extends StatefulWidget {
  const GroupRoomScreen({super.key});

  @override
  State<GroupRoomScreen> createState() => _GroupRoomScreenState();
}

class _GroupRoomScreenState extends State<GroupRoomScreen> {
  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
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

  void _shareRoomCode(String roomCode) {
    try {
      final box = context.findRenderObject() as RenderBox?;
      final shareOrigin = box != null
          ? box.localToGlobal(Offset.zero) & box.size
          : const Rect.fromLTWH(0, 0, 1, 1);

      Share.share(
        'Unisciti alla mia stanza di studio!\nCodice: $roomCode',
        subject: 'Codice Stanza Powerful Students',
        sharePositionOrigin: shareOrigin,
      );
    } catch (e) {
      debugPrint('Errore nella condivisione del codice stanza: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Errore nella condivisione'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _copyRoomCode(String roomCode) {
    try {
      Clipboard.setData(ClipboardData(text: roomCode));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Codice copiato negli appunti!'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint('Errore nella copia del codice: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Errore nella copia del codice'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showJoinRoomDialog() {
    final controller = TextEditingController();
    // Prendi il provider fuori dal dialog per evitare problemi di context
    final roomProvider = Provider.of<RoomProvider>(context, listen: false);

    var isSubmitting = false;
    var dialogClosed = false;

    void safeCloseDialog(BuildContext dialogContext) {
      if (dialogClosed || !dialogContext.mounted) return;
      dialogClosed = true;
      Navigator.of(dialogContext).pop();
    }
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
          shadowColor: Colors.black.withValues(alpha: 0.15),
          title: const Text(
            'Entra in una stanza',
            style: TextStyle(
              color: Color(0xFF2A2A2A),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            controller: controller,
            maxLength: 9,
            textCapitalization: TextCapitalization.characters,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Inserisci il codice',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                borderSide: const BorderSide(
                  color: AppColors.secondary,
                  width: 2,
                ),
              ),
            ),
            onChanged: (value) {
              setDialogState(() {});
            },
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => safeCloseDialog(dialogContext),
              child: const Text(
                'Annulla',
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ),
            ElevatedButton(
              onPressed: controller.text.length == 9 && !isSubmitting
                  ? () async {
                      setDialogState(() {
                        isSubmitting = true;
                      });

                      try {
                        await roomProvider.joinRoom(controller.text);
                        if (mounted) {
                          safeCloseDialog(dialogContext);
                        }
                      } catch (error) {
                        if (mounted) {
                          _handleRoomError(error);
                        }
                      } finally {
                        if (!dialogClosed && dialogContext.mounted) {
                          setDialogState(() {
                            isSubmitting = false;
                          });
                        } else {
                          isSubmitting = false;
                        }
                      }
                    }
                  : null,
              style: AppButtons.primary(
                enabled: controller.text.length == 9 && !isSubmitting,
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Entra', style: AppButtons.textStyle),
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      controller.dispose();
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(color: AppColors.background),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Consumer<RoomProvider>(
              builder: (context, roomProvider, _) {
                final hasRoom = roomProvider.hasRoom;
                return Column(
                  children: [
                    const _GroupHeader(),
                    const SizedBox(height: AppSpacing.lg),
                    if (!hasRoom)
                      _CreateJoinSection(
                        isCreating: roomProvider.isCreatingRoom,
                        isJoining: roomProvider.isJoiningRoom,
                        onCreateRoom: () => _createRoom(roomProvider),
                        onJoinRoom: _showJoinRoomDialog,
                      ),
                    if (hasRoom) ...[
                      const SizedBox(height: 20),
                      _RoomCodeBanner(
                        roomCode: roomProvider.currentRoomCode ?? '',
                        memberCount: roomProvider.memberCount,
                        onCopy: () =>
                            _copyRoomCode(roomProvider.currentRoomCode!),
                        onShare: () =>
                            _shareRoomCode(roomProvider.currentRoomCode!),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const Spacer(),
                      const _GroupTreeVisual(),
                      const Spacer(),
                      const _GroupTimerDisplay(),
                    ] else
                      const Spacer(),
                    const SizedBox(height: 40),
                    _RoomActionButtons(
                      hasRoom: hasRoom,
                      onLeaveRoom: hasRoom
                          ? () => _leaveRoom(roomProvider)
                          : null,
                      onStartStudy: () =>
                          context.read<PomodoroProvider>().startWorkSession(),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              AppIcons.back,
              color: AppColors.textPrimary,
              size: 24,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: AppDecorations.badge(),
            child: const Row(
              children: [
                Icon(
                  AppIcons.groupMode,
                  color: AppColors.textPrimary,
                  size: 16,
                ),
                SizedBox(width: AppSpacing.xs),
                Text('Group', style: AppTypography.caption),
              ],
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class _CreateJoinSection extends StatelessWidget {
  const _CreateJoinSection({
    required this.isCreating,
    required this.isJoining,
    required this.onCreateRoom,
    required this.onJoinRoom,
  });

  final bool isCreating;
  final bool isJoining;
  final VoidCallback onCreateRoom;
  final VoidCallback onJoinRoom;

  @override
  Widget build(BuildContext context) {
    final isBusy = isCreating || isJoining;
    return Column(
      children: [
        GestureDetector(
          onTap: isCreating ? null : onCreateRoom,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.textPrimary, width: 2),
              boxShadow: AppShadows.md,
            ),
            child: isCreating
                ? const SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: AppColors.textPrimary,
                    ),
                  )
                : const Icon(Icons.add, color: AppColors.textPrimary, size: 48),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          isCreating ? 'Creazione stanza...' : 'Crea una nuova stanza',
          style: AppTypography.caption.copyWith(
            color: isBusy
                ? AppColors.textSecondaryWith(0.5)
                : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: isJoining ? null : onJoinRoom,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: AppShadows.sm,
            ),
            child: Text(
              isJoining ? 'Connessione in corso...' : 'Oppure entra in una stanza',
              style: AppTypography.caption.copyWith(
                color: isBusy
                    ? AppColors.textSecondaryWith(0.5)
                    : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RoomCodeBanner extends StatelessWidget {
  const _RoomCodeBanner({
    required this.roomCode,
    required this.memberCount,
    required this.onCopy,
    required this.onShare,
  });

  final String roomCode;
  final int memberCount;
  final VoidCallback onCopy;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.sm,
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Codice: $roomCode',
                style: AppTypography.subtitle.copyWith(
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              GestureDetector(
                onTap: onCopy,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    shape: BoxShape.circle,
                    boxShadow: AppShadows.glow(AppColors.secondary, alpha: 0.3),
                  ),
                  child: const Icon(
                    Icons.copy,
                    color: AppColors.textPrimary,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onShare,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    shape: BoxShape.circle,
                    boxShadow: AppShadows.glow(AppColors.secondary, alpha: 0.3),
                  ),
                  child: const Icon(
                    AppIcons.share,
                    color: AppColors.textPrimary,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          if (memberCount > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.secondary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  memberCount == 1
                      ? '1 membro connesso'
                      : '$memberCount membri connessi',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondaryWith(0.9),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _GroupTreeVisual extends StatelessWidget {
  const _GroupTreeVisual();

  @override
  Widget build(BuildContext context) {
    return Consumer<PomodoroProvider>(
      builder: (context, provider, _) {
        final hasActiveSession = provider.currentSession != null;
        if (hasActiveSession) {
          return Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.secondary, width: 8),
              boxShadow: AppShadows.lg,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 260,
                  height: 260,
                  child: CircularProgressIndicator(
                    value: provider.currentSession!.progress,
                    strokeWidth: 10,
                    backgroundColor: AppColors.surface,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.secondary,
                    ),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Container(
                  width: 200,
                  height: 200,
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 90,
                      height: 70,
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: 12,
                            left: 22,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 22,
                            right: 28,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 18,
                            left: 35,
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 14,
                      height: 35,
                      decoration: const BoxDecoration(
                        color: AppColors.textSecondary,
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    Container(
                      width: 55,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.textSecondary,
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }
        return _GroupCircularSlider(
          radius: 130,
          initialMinutes: provider.defaultWorkDuration ~/ 60,
          onMinutesChanged: provider.setDefaultWorkDurationMinutes,
        );
      },
    );
  }
}

class _GroupTimerDisplay extends StatelessWidget {
  const _GroupTimerDisplay();

  @override
  Widget build(BuildContext context) {
    return Consumer<PomodoroProvider>(
      builder: (context, provider, _) {
        final session = provider.currentSession;
        final timerText = session != null
            ? session.formattedRemainingTime
            : provider.defaultWorkDuration ~/ 60 > 0
                ? '${(provider.defaultWorkDuration ~/ 60).toString().padLeft(2, '0')}:00'
                : '35:00';
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                boxShadow: AppShadows.md,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('Work', style: AppTypography.label),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(timerText, style: AppTypography.timerLarge),
          ],
        );
      },
    );
  }
}

class _RoomActionButtons extends StatelessWidget {
  const _RoomActionButtons({
    required this.hasRoom,
    required this.onLeaveRoom,
    required this.onStartStudy,
  });

  final bool hasRoom;
  final Future<void> Function()? onLeaveRoom;
  final VoidCallback onStartStudy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                if (hasRoom && onLeaveRoom != null) {
                  await onLeaveRoom!();
                }
                if (navigator.mounted) {
                  navigator.pop();
                }
              },
              style: AppButtons.secondary(),
              child: Text(
                'Cancel',
                style: AppButtons.textStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: ElevatedButton(
              onPressed: hasRoom
                  ? () {
                      onStartStudy();
                      Navigator.of(context).pushReplacementNamed('/timer');
                    }
                  : null,
              style: AppButtons.primary(enabled: hasRoom),
              child: Text(
                'Study',
                style: AppButtons.textStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget per lo slider circolare nello stile gruppo
class _GroupCircularSlider extends StatefulWidget {
  final double radius;
  final int initialMinutes;
  final Function(int minutes) onMinutesChanged;

  const _GroupCircularSlider({
    required this.radius,
    required this.initialMinutes,
    required this.onMinutesChanged,
  });

  @override
  State<_GroupCircularSlider> createState() => _GroupCircularSliderState();
}

class _GroupCircularSliderState extends State<_GroupCircularSlider> {
  late double _currentAngle;

  @override
  void initState() {
    super.initState();
    _currentAngle = _minutesToAngle(widget.initialMinutes);
  }

  @override
  void didUpdateWidget(covariant _GroupCircularSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialMinutes != widget.initialMinutes) {
      setState(() {
        _currentAngle = _minutesToAngle(widget.initialMinutes);
      });
    }
  }

  // Calcola l'angolo rispetto al centro del cerchio
  double _calculateAngle(Offset center, Offset point) {
    return atan2(point.dy - center.dy, point.dx - center.dx);
  }

  // Converte angolo (0 a 2π) in minuti (1 a 60)
  int _angleToMinutes(double angle) {
    // Normalizza l'angolo a 0-360 gradi (da -π a π)
    double normalizedAngle = angle + pi / 2; // Inizia da -π/2 (top)
    if (normalizedAngle < 0) normalizedAngle += 2 * pi;

    // Mappa 0-2π a 1-60 minuti
    int minutes = ((normalizedAngle / (2 * pi)) * 59).toInt() + 1;
    return minutes.clamp(1, 60);
  }

  double _minutesToAngle(int minutes) {
    final clampedMinutes = minutes.clamp(1, 60);
    final normalized = ((clampedMinutes - 1) / 59) * 2 * pi;
    return normalized - pi / 2;
  }

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final center = Offset(widget.radius, widget.radius);
    final buttonX = cos(_currentAngle) * (widget.radius - 16);
    final buttonY = sin(_currentAngle) * (widget.radius - 16);
    final currentMinutes = _angleToMinutes(_currentAngle);

    return Consumer<PomodoroProvider>(
      builder: (context, provider, child) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanUpdate: (details) {
            // Calcola l'angolo corrente basato sulla posizione del dito
            final angle = _calculateAngle(center, details.localPosition);

            setState(() {
              _currentAngle = angle;
            });

            // Invia i minuti calcolati
            widget.onMinutesChanged(_angleToMinutes(angle));
          },
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Cerchio esterno con bordo verde per contrasto
              Container(
                width: widget.radius * 2,
                height: widget.radius * 2,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.secondary, width: 8),
                  boxShadow: AppShadows.lg,
                ),
              ),
              // Cerchio interno più chiaro (non interattivo)
              IgnorePointer(
                child: Container(
                  width: (widget.radius - 10) * 2,
                  height: (widget.radius - 10) * 2,
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // Indicatori di posizione attorno al cerchio
              ...List.generate(12, (index) {
                final angle = (index * 30) * (pi / 180); // Ogni 30 gradi
                return Transform.translate(
                  offset: Offset(
                    cos(angle) * (widget.radius - 25),
                    sin(angle) * (widget.radius - 25),
                  ),
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.textPrimary.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }),
              // Timer al centro
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _formatDuration(currentMinutes * 60),
                    style: AppTypography.timerMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'minuti',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondaryWith(0.8),
                    ),
                  ),
                ],
              ),
              // Pulsantino trascinabile - più grande e visibile
              Positioned(
                left: buttonX + widget.radius - 26,
                top: buttonY + widget.radius - 26,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.textPrimary,
                        width: 4,
                      ),
                      boxShadow: AppShadows.glow(AppColors.secondary),
                    ),
                    child: const Icon(
                      AppIcons.drag,
                      color: AppColors.textPrimary,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
