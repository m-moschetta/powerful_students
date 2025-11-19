import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:powerful_students/providers/pomodoro_provider.dart';
import 'package:powerful_students/models/study_session.dart';
import 'package:powerful_students/core/design_system.dart';

class TimerScreen extends StatelessWidget {
  const TimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(color: AppColors.background),
        child: SafeArea(
          child: Consumer<PomodoroProvider>(
            builder: (context, provider, child) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Header con modalità e toggle burn
                    _buildHeader(context, provider),

                    const SizedBox(height: AppSpacing.lg),

                    // Timer circolare principale
                    _buildCircularTimer(provider),

                    const Spacer(),

                    // Stats pomodoro
                    _buildPomodoroStats(provider),

                    const Spacer(),

                    // Pulsanti azione (Cancel e Study) - allineati con group
                    _buildActionButtons(context, provider),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, PomodoroProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Pulsante Back (più discreto)
        IconButton(
          onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
          icon: const Icon(
            AppIcons.back,
            color: AppColors.textPrimary,
            size: 24,
          ),
          style: IconButton.styleFrom(
            backgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            padding: const EdgeInsets.all(AppSpacing.xs),
          ),
        ),

        // Modalità attuale
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: AppDecorations.badge(),
          child: Row(
            children: [
              Icon(
                provider.selectedMode == StudyMode.solo
                    ? AppIcons.soloMode
                    : AppIcons.groupMode,
                color: AppColors.textPrimary,
                size: 16,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                provider.selectedMode == StudyMode.solo ? 'Solo' : 'Group',
                style: AppTypography.caption,
              ),
            ],
          ),
        ),

        // Toggle modalità burn
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: AppDecorations.badge(),
          child: Row(
            children: [
              const Text('Si brucia', style: AppTypography.label),
              const SizedBox(width: AppSpacing.xs),
              Switch(
                value: provider.isBurnMode,
                onChanged: (value) => provider.toggleBurnMode(),
                activeThumbColor: AppColors.secondary,
                activeTrackColor: AppColors.secondaryWith(0.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCircularTimer(PomodoroProvider provider) {
    final session = provider.currentSession;

    if (session == null) {
      // Schermata iniziale - nessun timer attivo
      return GestureDetector(
        onTap: () => provider.startWorkSession(),
        child: Container(
          width: 280,
          height: 280,
          decoration: AppDecorations.timerCircle(),
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
                  const SizedBox(height: AppSpacing.xs),
                  const Text('Tocca per iniziare', style: AppTypography.title),
                ],
              ),
              // Pulsantino circolare trascinabile per regolare il tempo del pomodoro
              _DraggableTimerIndicator(
                radius: 140.0,
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

    // Timer attivo
    return CircularPercentIndicator(
      radius: 140.0,
      lineWidth: 12.0,
      animation: true,
      animateFromLastPercent: true,
      percent: session.progress,
      center: Container(
        width: 260,
        height: 260,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          shape: BoxShape.circle,
          boxShadow: AppShadows.lg,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Tipo di sessione
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _getSessionColor(session.type).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _getSessionText(session.type),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _getSessionColor(session.type),
                  fontFamily: 'Helvetica',
                  letterSpacing: 0.5,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Timer principale
            Text(
              session.formattedRemainingTime,
              style: AppTypography.timerLarge,
            ),

            const SizedBox(height: AppSpacing.xs),

            // Progresso
            Text(
              '${(session.progress * 100).round()}%',
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondaryWith(0.8),
              ),
            ),
          ],
        ),
      ),
      progressColor: _getSessionColor(session.type),
      backgroundColor: AppColors.surface,
      circularStrokeCap: CircularStrokeCap.round,
    );
  }

  Widget _buildActionButtons(BuildContext context, PomodoroProvider provider) {
    final session = provider.currentSession;
    final isRunning = provider.isRunning;

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 32.0),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                if (session != null) {
                  provider.stopTimer();
                }
                Navigator.of(context).pushReplacementNamed('/');
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
              onPressed: session != null
                  ? () {
                      if (isRunning) {
                        provider.pauseTimer();
                      } else {
                        provider.resumeTimer();
                      }
                    }
                  : () {
                      // Se non c'è sessione, avvia una nuova
                      provider.startWorkSession();
                    },
              style: AppButtons.primary(),
              child: Text(
                session != null ? (isRunning ? 'Pause' : 'Study') : 'Study',
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

  Widget _buildPomodoroStats(PomodoroProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Contatore pomodori completati
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            boxShadow: AppShadows.md,
          ),
          child: Column(
            children: [
              const Icon(AppIcons.fire, color: AppColors.secondary, size: 24),
              const SizedBox(height: 4),
              Text(
                '${provider.completedPomodoros}',
                style: AppTypography.subtitle,
              ),
              const Text('Pomodori', style: AppTypography.label),
            ],
          ),
        ),

        const SizedBox(width: 20),

        // Modalità burn indicator
        if (provider.isBurnMode)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.secondaryWith(0.2),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Column(
              children: [
                Icon(AppIcons.burn, color: AppColors.secondary, size: 24),
                SizedBox(height: 4),
                Text('BURN', style: AppTypography.body),
              ],
            ),
          ),
      ],
    );
  }

  Color _getSessionColor(SessionType type) {
    switch (type) {
      case SessionType.work:
        return AppColors.secondary;
      case SessionType.shortBreak:
        return AppColors.secondary;
      case SessionType.longBreak:
        return AppColors.secondary;
    }
  }

  String _getSessionText(SessionType type) {
    switch (type) {
      case SessionType.work:
        return 'LAVORO';
      case SessionType.shortBreak:
        return 'PAUSA BREVE';
      case SessionType.longBreak:
        return 'PAUSA LUNGA';
    }
  }

  // Formatta la durata in minuti:secondi
  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

// Widget per il pulsantino circolare trascinabile nella schermata del timer
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

  @override
  void initState() {
    super.initState();
    _currentAngle = _minutesToAngle(widget.initialMinutes);
  }

  @override
  void didUpdateWidget(covariant _DraggableTimerIndicator oldWidget) {
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

  @override
  Widget build(BuildContext context) {
    final center = Offset(widget.radius, widget.radius);
    final buttonX = cos(_currentAngle) * (widget.radius - 12);
    final buttonY = sin(_currentAngle) * (widget.radius - 12);

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
          // Area trasparente per il tracking del dito
          Container(
            width: widget.radius * 2,
            height: widget.radius * 2,
            color: Colors.transparent,
          ),
          // Pulsantino trascinabile - più grande e verde come in group
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
                  border: Border.all(color: AppColors.textPrimary, width: 4),
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
  }
}
