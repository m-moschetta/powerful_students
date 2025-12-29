import 'dart:math';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Consumer<PomodoroProvider>(
          builder: (context, provider, child) {
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

  Widget _buildHeader(BuildContext context, PomodoroProvider provider) {
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
          child: const Row(
            children: [
              Icon(AppIcons.back, color: AppColors.textPrimary, size: 28),
              Text('Back', style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        AppDecorations.glassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              const Icon(AppIcons.burn, size: 16, color: AppColors.textPrimary),
              const SizedBox(width: 4),
              CupertinoSwitch(
                value: provider.isBurnMode,
                onChanged: (value) {
                  HapticFeedback.mediumImpact();
                  provider.toggleBurnMode();
                },
                activeColor: AppColors.primary,
              ),
            ],
          ),
        ),
      ],
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
                    style: AppTypography.caption.copyWith(fontWeight: FontWeight.w900),
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
              color: isMajor ? AppColors.textPrimary : AppColors.textPrimary.withValues(alpha: 0.3),
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

    return Row(
      children: [
        if (session != null)
          Expanded(
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                HapticFeedback.lightImpact();
                provider.stopTimer();
              },
              child: AppDecorations.glassContainer(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: const Center(
                  child: Text('Cancel', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w800, fontSize: 17)),
                ),
              ),
            ),
          ),
        if (session != null) const SizedBox(width: 16),
        Expanded(
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              HapticFeedback.mediumImpact();
              if (session == null) {
                provider.startWorkSession();
              } else if (isRunning) {
                provider.pauseTimer();
              } else {
                provider.resumeTimer();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: AppColors.cta, // Rosa per CTA come richiesto
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.cta.withValues(alpha: 0.4),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Center(
                child: Text(
                  session == null ? 'START STUDY' : (isRunning ? 'PAUSE' : 'RESUME'),
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPomodoroStats(PomodoroProvider provider) {
    return AppDecorations.glassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(AppIcons.fire, color: Colors.orange, size: 22),
          const SizedBox(width: 10),
          Text(
            '${provider.completedPomodoros} POMODORI',
            style: AppTypography.subtitle.copyWith(letterSpacing: 1),
          ),
        ],
      ),
    );
  }

  String _getSessionText(SessionType type) {
    switch (type) {
      case SessionType.work:
        return 'CONCENTRATI';
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

class _LiquidBackgroundState extends State<_LiquidBackground> with SingleTickerProviderStateMixin {
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
      final y = yOffset + sin((x / size.width * 2 * pi) + (animationValue * 2 * pi)) * waveHeight;
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
          Container(width: widget.radius * 2 + 60, height: widget.radius * 2 + 60, color: Colors.transparent),
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
                  )
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

