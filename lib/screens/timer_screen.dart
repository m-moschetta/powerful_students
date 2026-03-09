import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:powerful_students/providers/pomodoro_provider.dart';
import 'package:powerful_students/models/study_session.dart';
import 'package:powerful_students/core/design_system.dart';
import 'package:powerful_students/l10n/app_localizations.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> with WidgetsBindingObserver {
  bool _sessionFailed = false;
  bool _sessionCompleted = false;
  int _lastCompletedCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Attiva wakelock per mantenere lo schermo acceso
    WakelockPlus.enable();

    // Inizializza il conteggio per rilevare nuovi completamenti
    final provider = context.read<PomodoroProvider>();
    _lastCompletedCount = provider.completedPomodoros;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Disattiva wakelock quando si esce dalla schermata
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final provider = context.read<PomodoroProvider>();

    // Se l'app va in background con burn mode attivo e sessione in corso, la sessione fallisce
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (provider.isBurnMode &&
          provider.isRunning &&
          provider.currentSession != null) {
        provider.stopTimer();
        setState(() {
          _sessionFailed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Consumer<PomodoroProvider>(
          builder: (context, provider, child) {
            // Rileva completamento sessione
            if (provider.completedPomodoros > _lastCompletedCount) {
              _lastCompletedCount = provider.completedPomodoros;
              _sessionCompleted = true;
            }

            // Mostra schermata di fallimento se la sessione è fallita
            if (_sessionFailed) {
              return _buildFailedScreen(context);
            }

            // Mostra schermata di successo se la sessione è completata
            if (_sessionCompleted) {
              return _buildSuccessScreen(context, provider);
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.sm),
                  _buildHeader(context, provider),
                  const Spacer(),
                  _buildCircularTimer(provider),
                  const Spacer(),
                  _buildPomodoroStats(provider),
                  const SizedBox(height: AppSpacing.xl),
                  _buildActionButtons(context, provider),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFailedScreen(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
            l10n.failedTitle,
            style: AppTypography.headline.copyWith(
              color: Colors.red,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.failedMessageSolo,
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              setState(() {
                _sessionFailed = false;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
              decoration: BoxDecoration(
                color: AppColors.cta,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Text(
                l10n.failedCtaSolo,
                style: const TextStyle(
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

  Widget _buildSuccessScreen(BuildContext context, PomodoroProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          // Titolo
          Text(
            l10n.successTitle,
            style: AppTypography.headline.copyWith(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          // Sottotitolo
          Text(
            l10n.successSubtitleSolo,
            style: AppTypography.body.copyWith(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),

          // GIF animata con cerchio dietro
          Stack(
            alignment: Alignment.center,
            children: [
              // Cerchio grigio chiaro di sfondo
              Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.textSecondary.withValues(alpha: 0.08),
                ),
              ),
              // GIF animata del mattoncino felice
              Image.asset(
                AppAssets.brickyCelebration,
                width: 180,
                height: 180,
                fit: BoxFit.contain,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),
          // Testo motivazionale
          Text(
            l10n.successMotivationSolo,
            style: AppTypography.body.copyWith(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          // Contatore mattoncini
          Text(
            l10n.bricksBuiltCount(provider.completedPomodoros),
            style: AppTypography.subtitle.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(),

          // Bottone CTA
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              HapticFeedback.mediumImpact();
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
                boxShadow: [
                  BoxShadow(
                    color: AppColors.cta.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  l10n.successCta,
                  style: const TextStyle(
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

  Widget _buildHeader(BuildContext context, PomodoroProvider provider) {
    final bool isSessionActive = provider.currentSession != null;
    final l10n = AppLocalizations.of(context)!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            if (provider.isRunning) {
              provider.stopTimer();
            }
            Navigator.of(context).pop();
          },
          child: Row(
            children: [
              const Icon(AppIcons.back, color: AppColors.textPrimary, size: 28),
              Text(
                l10n.backButton,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            // Toggle suono
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size(36, 36),
              onPressed: () {
                HapticFeedback.selectionClick();
                provider.toggleSound();
              },
              child: AppDecorations.glassContainer(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  provider.soundEnabled
                      ? CupertinoIcons.speaker_2_fill
                      : CupertinoIcons.speaker_slash_fill,
                  size: 18,
                  color: provider.soundEnabled
                      ? AppColors.textPrimary
                      : AppColors.textSecondary.withValues(alpha: 0.5),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Toggle Deep Focus (mattoncino)
            AppDecorations.glassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  // Mattoncino Deep Focus - acceso/spento basato su isBurnMode
                  Opacity(
                    opacity: provider.isBurnMode ? 1.0 : 0.4,
                    child: Image.asset(
                      AppAssets.brickyBurnSmall,
                      width: 32,
                      height: 32,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 4),
                  CupertinoSwitch(
                    value: provider.isBurnMode,
                    // Disabilita lo switch durante la sessione attiva
                    onChanged: isSessionActive
                        ? null
                        : (value) {
                            HapticFeedback.mediumImpact();
                            provider.toggleBurnMode();
                          },
                    activeTrackColor: AppColors.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCircularTimer(PomodoroProvider provider) {
    final session = provider.currentSession;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Timer circolare con mattoncino al centro
          Stack(
            alignment: Alignment.center,
            children: [
              // Ghiera di contrasto esterna (Ring)
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
                _buildActiveTimerCircle(session, provider.isBurnMode),
            ],
          ),

          // Timer info SOTTO il cerchio
          if (session != null) ...[
            const SizedBox(height: AppSpacing.md),
            _buildTimerInfo(session),
          ],
        ],
      ),
    );
  }

  Widget _buildSetupTimer(PomodoroProvider provider) {
    final l10n = AppLocalizations.of(context)!;
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
                Text(l10n.setupTimeLabel, style: AppTypography.label),
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

  // Cerchio del timer con solo il mattoncino al centro
  Widget _buildActiveTimerCircle(StudySession session, bool isBurnMode) {
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
              // Liquid Animation in background
              _LiquidBackground(progress: session.progress),

              // MATTONCINO AL CENTRO - fisso e protagonista
              _AnimatedBrickyBuilder(
                progress: session.progress,
                isBurnMode: isBurnMode,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Timer info SOTTO il cerchio
  Widget _buildTimerInfo(StudySession session) {
    return Column(
      children: [
        Text(
          _getSessionText(session.type),
          style: AppTypography.label.copyWith(
            letterSpacing: 3,
            fontWeight: FontWeight.w900,
            fontSize: 12,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          session.formattedRemainingTime,
          style: AppTypography.timerLarge.copyWith(
            fontSize: 52,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${(session.progress * 100).round()}%',
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ],
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

  Widget _buildActionButtons(BuildContext context, PomodoroProvider provider) {
    final session = provider.currentSession;
    final isRunning = provider.isRunning;
    final isSoloMode = provider.selectedMode == StudyMode.solo;
    final l10n = AppLocalizations.of(context)!;

    // Se c'è una sessione attiva, mostra solo STOP (per studio singolo)
    if (session != null && isRunning) {
      // In modalità solo: mostra solo STOP
      // In modalità gruppo: nessun controllo (gestito dall'host nella group_room_screen)
      if (isSoloMode) {
        return CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            HapticFeedback.lightImpact();
            provider.stopTimer();
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: Colors.red, width: 2),
            ),
            child: Center(
              child: Text(
                l10n.stopLabel,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        );
      } else {
        // In modalità gruppo, non mostrare controlli durante la sessione
        return const SizedBox.shrink();
      }
    }

    // Prima di iniziare: mostra START
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () {
        HapticFeedback.heavyImpact();
        provider.startWorkSession();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.cta,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: AppColors.cta.withValues(alpha: 0.4),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Center(
          child: Text(
            l10n.startBuildLabel,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
              fontSize: 18,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPomodoroStats(PomodoroProvider provider) {
    final count = provider.completedPomodoros;
    return AppDecorations.glassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            AppAssets.brickyCounter,
            width: 22,
            height: 22,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 10),
          Text(
            AppLocalizations.of(context)!.bricksCountLabel(count),
            style: AppTypography.subtitle.copyWith(letterSpacing: 1),
          ),
        ],
      ),
    );
  }

  String _getSessionText(SessionType type) {
    final l10n = AppLocalizations.of(context)!;
    switch (type) {
      case SessionType.work:
        return l10n.sessionWorkSoloLabel;
      case SessionType.shortBreak:
        return l10n.sessionShortBreakLabel;
      case SessionType.longBreak:
        return l10n.sessionLongBreakLabel;
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
/// Il mattoncino è il PROTAGONISTA: fisso al centro, appare gradualmente
class _AnimatedBrickyBuilder extends StatefulWidget {
  final double progress;
  final bool isBurnMode;

  const _AnimatedBrickyBuilder({
    required this.progress,
    required this.isBurnMode,
  });

  @override
  State<_AnimatedBrickyBuilder> createState() => _AnimatedBrickyBuilderState();
}

class _AnimatedBrickyBuilderState extends State<_AnimatedBrickyBuilder>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    // Animazione leggera di floating
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate reveal factor: fully visible at 97% progress (29/30 minutes)
    final revealFactor = (widget.progress / 0.97).clamp(0.0, 1.0);

    // Scegli l'immagine in base al burn mode
    final assetPath = widget.isBurnMode
        ? AppAssets.brickyLogo  // normale (burn mode attivo)
        : AppAssets.brickyBurn; // con fuoco (burn mode spento)

    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        // Leggero movimento su e giù (max 8 pixel)
        final floatOffset = _floatController.value * 8.0;

        return Transform.translate(
          offset: Offset(0, -floatOffset),
          child: Opacity(
            opacity: revealFactor,
            child: Transform.scale(
              scale: 0.8 + (revealFactor * 0.2), // Da 80% a 100% di dimensione
              child: Image.asset(
                assetPath,
                width: 170,
                height: 170,
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      },
    );
  }
}
