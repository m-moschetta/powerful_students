import 'dart:math';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:powerful_students/models/study_session.dart';
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
      _showSnack('Errore nella condivisione');
    }
  }

  void _copyRoomCode(String roomCode) {
    try {
      Clipboard.setData(ClipboardData(text: roomCode));
      _showSnack('Codice copiato!');
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
        title: const Text('Entra in una stanza'),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: CupertinoTextField(
            controller: controller,
            placeholder: 'Codice a 9 cifre',
            maxLength: 9,
            textCapitalization: TextCapitalization.characters,
            textAlign: TextAlign.center,
            style: const TextStyle(letterSpacing: 2),
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
                try {
                  await roomProvider.joinRoom(controller.text);
                  if (mounted) Navigator.pop(dialogContext);
                } catch (e) {
                  _handleRoomError(e);
                }
              }
            },
            child: const Text('Entra'),
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Consumer<RoomProvider>(
            builder: (context, roomProvider, _) {
              final hasRoom = roomProvider.hasRoom;
              return Column(
                children: [
                  _buildHeader(context),
                  const SizedBox(height: AppSpacing.lg),
                  if (!hasRoom)
                    _buildCreateJoinSection(roomProvider)
                  else ...[
                    _buildRoomInfo(roomProvider),
                    const Spacer(),
                    Consumer<PomodoroProvider>(
                      builder: (context, pomodoroProvider, _) {
                        return _buildCircularTimer(pomodoroProvider);
                      },
                    ),
                    const Spacer(),
                  ],
                  const Spacer(),
                  _buildBottomActions(hasRoom, roomProvider),
                  const SizedBox(height: AppSpacing.lg),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
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
        AppDecorations.glassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              Icon(AppIcons.groupMode, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text('Group', style: AppTypography.label),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCreateJoinSection(RoomProvider provider) {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.xl),
        CupertinoButton(
          onPressed: provider.isCreatingRoom
              ? null
              : () => _createRoom(provider),
          child: AppDecorations.glassContainer(
            padding: const EdgeInsets.all(AppSpacing.xl),
            borderRadius: BorderRadius.circular(100),
            child: provider.isCreatingRoom
                ? const CupertinoActivityIndicator()
                : const Icon(
                    CupertinoIcons.add,
                    size: 48,
                    color: AppColors.textPrimary,
                  ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Crea una stanza', style: AppTypography.subtitle),
        const SizedBox(height: AppSpacing.xl),
        CupertinoButton(
          onPressed: provider.isJoiningRoom ? null : _showJoinRoomDialog,
          child: AppDecorations.glassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: const Text(
              'Entra con codice',
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoomInfo(RoomProvider provider) {
    return AppDecorations.glassContainer(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                provider.currentRoomCode ?? '',
                style: AppTypography.title.copyWith(
                  letterSpacing: 4,
                  fontSize: 24,
                ),
              ),
              const SizedBox(width: 16),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => _copyRoomCode(provider.currentRoomCode!),
                child: const Icon(CupertinoIcons.doc_on_doc, size: 20),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => _shareRoomCode(provider.currentRoomCode!),
                child: const Icon(CupertinoIcons.share, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${provider.memberCount} membri connessi',
            style: AppTypography.caption,
          ),
        ],
      ),
    );
  }

  Widget _buildCircularTimer(PomodoroProvider provider) {
    final session = provider.currentSession;

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ghiera di contrasto esterna (Ring) con più contrasto
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
            _buildSetupTimer(provider)
          else
            _buildActiveTimer(session),
        ],
      ),
    );
  }

  Widget _buildSetupTimer(PomodoroProvider provider) {
    return AppDecorations.glassContainer(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderRadius: BorderRadius.circular(150),
      child: SizedBox(
        width: 280,
        height: 280,
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
              radius: 130.0,
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

  Widget _buildActiveTimer(StudySession session) {
    return CircularPercentIndicator(
      radius: 150.0,
      lineWidth: 12.0,
      animation: true,
      animateFromLastPercent: true,
      percent: session.progress,
      backgroundColor: AppColors.textPrimary.withValues(alpha: 0.05),
      progressColor: AppColors.primary,
      circularStrokeCap: CircularStrokeCap.round,
      center: ClipOval(
        child: SizedBox(
          width: 280,
          height: 280,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Liquid Animation
              _LiquidBackground(progress: session.progress),

              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getSessionText(session.type),
                    style: AppTypography.label.copyWith(
                      letterSpacing: 3,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    session.formattedRemainingTime,
                    style: AppTypography.timerLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(session.progress * 100).round()}%',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
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
          offset: Offset(cos(angle) * 120, sin(angle) * 120),
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

  Widget _buildBottomActions(bool hasRoom, RoomProvider roomProvider) {
    return Row(
      children: [
        Expanded(
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () async {
              HapticFeedback.lightImpact();
              if (hasRoom) await _leaveRoom(roomProvider);
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
        if (hasRoom) ...[
          const SizedBox(width: 16),
          Expanded(
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                HapticFeedback.heavyImpact();
                context.read<PomodoroProvider>().startWorkSession();
                Navigator.pushNamed(context, '/timer');
              },
              color: AppColors.cta, // Rosa per CTA
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: const Text(
                'INIZIA',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ],
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
    int minutes = ((normalizedAngle / (2 * pi)) * 59).toInt() + 1;
    return minutes.clamp(1, 60);
  }

  double _minutesToAngle(int minutes) {
    final clampedMinutes = minutes.clamp(1, 60);
    final normalized = ((clampedMinutes - 1) / 59) * 2 * pi;
    return normalized - pi / 2;
  }

  @override
  Widget build(BuildContext context) {
    final center = Offset(widget.radius, widget.radius);
    final buttonX = cos(_currentAngle) * (widget.radius - 10);
    final buttonY = sin(_currentAngle) * (widget.radius - 10);

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
            width: widget.radius * 2 + 60,
            height: widget.radius * 2 + 60,
            color: Colors.transparent,
          ),
          Positioned(
            left: buttonX + widget.radius - 20,
            top: buttonY + widget.radius - 20,
            child: Container(
              width: 40,
              height: 40,
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
              child: const Icon(AppIcons.drag, size: 20, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}
