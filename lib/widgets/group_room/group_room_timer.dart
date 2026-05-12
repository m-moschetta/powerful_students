import 'package:flutter/cupertino.dart';
import 'package:powerful_students/core/design_system.dart';
import 'package:powerful_students/providers/pomodoro_provider.dart';
import 'package:powerful_students/widgets/modern_timer_circle.dart';

class GroupRoomTimer extends StatelessWidget {
  const GroupRoomTimer({
    super.key,
    required this.pomodoroProvider,
    required this.isOwner,
  });

  final PomodoroProvider pomodoroProvider;
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    final session = pomodoroProvider.currentSession;
    final progress = session?.progress ?? 
        (pomodoroProvider.defaultWorkDuration / 3600.0).clamp(0.0, 1.0);
    final timeText = session?.formattedRemainingTime ?? 
        _formatDuration(pomodoroProvider.defaultWorkDuration);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ModernTimerCircle(
          progress: progress,
          radius: 120,
          trackWidth: 6,
          progressWidth: 12,
          trackColor: AppColors.separator,
          progressColor: AppColors.primary,
          thumbColor: AppColors.primary,
          thumbRadius: 16,
          isDraggable: session == null && isOwner,
          onProgressChanged: (session == null && isOwner) 
              ? (p) {
                  final minutes = (p * 60).round().clamp(1, 60);
                  pomodoroProvider.setDefaultWorkDurationMinutes(minutes);
                } 
              : null,
          center: _BrickyCenter(
            isBurnMode: pomodoroProvider.isBurnMode && session != null,
            sessionProgress: session?.progress,
          ),
        ),
        const SizedBox(height: 16),
        Text(timeText, style: AppTypography.timerLarge),
        if (session == null && !isOwner) ...[
          const SizedBox(height: 8),
          const Text(
            'IN ATTESA',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "L'host avvierà la sessione",
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ],
    );
  }

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _BrickyCenter extends StatelessWidget {
  const _BrickyCenter({
    required this.isBurnMode,
    this.sessionProgress,
  });

  final bool isBurnMode;
  final double? sessionProgress;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      isBurnMode ? AppAssets.brickyLogo : AppAssets.brickyBurn,
      key: ValueKey<bool>(isBurnMode),
      width: 140,
      height: 140,
      fit: BoxFit.contain,
    );

    Widget child = AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
      child: image,
    );

    if (sessionProgress != null) {
      final opacity = 0.2 + (sessionProgress! * 0.8);
      final scale = 0.85 + (sessionProgress! * 0.15);
      child = Opacity(
        opacity: opacity,
        child: Transform.scale(scale: scale, child: child),
      );
    }

    return child;
  }
}
