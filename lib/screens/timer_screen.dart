import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:powerful_students/widgets/modern_timer_circle.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:powerful_students/providers/pomodoro_provider.dart';
import 'package:powerful_students/core/design_system.dart';

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
    WakelockPlus.enable();

    final provider = context.read<PomodoroProvider>();
    _lastCompletedCount = provider.completedPomodoros;
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

    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (provider.isBurnMode && provider.isRunning && provider.currentSession != null) {
        provider.stopTimer();
        setState(() => _sessionFailed = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<PomodoroProvider>(
          builder: (context, provider, child) {
            if (provider.completedPomodoros > _lastCompletedCount) {
              _lastCompletedCount = provider.completedPomodoros;
              _sessionCompleted = true;
            }

            if (_sessionFailed) return _buildFailedScreen(context);
            if (_sessionCompleted) return _buildSuccessScreen(context, provider);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  _buildHeader(context, provider),
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
                  const Spacer(),
                  _buildCircularTimer(provider),
                  const Spacer(),
                  _buildPomodoroStats(provider),
                  const SizedBox(height: 20),
                  _buildBottomActions(context, provider),
                  const SizedBox(height: 16),
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
      children: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Row(
            children: [
              Icon(CupertinoIcons.chevron_back, color: AppColors.textPrimary, size: 22),
              Text(
                'Back',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.separator),
            boxShadow: AppShadows.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                child: Image.asset(
                  provider.isBurnMode ? AppAssets.brickyLogo : AppAssets.brickyBurn,
                  key: ValueKey<bool>(provider.isBurnMode),
                  width: provider.isBurnMode ? 32 : 24,
                  height: provider.isBurnMode ? 32 : 24,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 6),
              CupertinoSwitch(
                value: provider.isBurnMode,
                onChanged: provider.isRunning ? null : (v) {
                  HapticFeedback.mediumImpact();
                  provider.toggleBurnMode();
                },
                activeTrackColor: AppColors.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCircularTimer(PomodoroProvider provider) {
    final session = provider.currentSession;
    final progress = session?.progress ?? (provider.defaultWorkDuration / 3600.0).clamp(0.0, 1.0);
    final timeText = session?.formattedRemainingTime ?? _formatDuration(provider.defaultWorkDuration);

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
          isDraggable: session == null,
          onProgressChanged: session == null ? (p) {
            final minutes = (p * 60).round().clamp(1, 60);
            provider.setDefaultWorkDurationMinutes(minutes);
          } : null,
          center: _buildBrickyCenter(provider.isBurnMode && session != null, sessionProgress: session?.progress),
        ),
        const SizedBox(height: 16),
        Text(timeText, style: AppTypography.timerLarge),
      ],
    );
  }

  Widget _buildBrickyCenter(bool isBurnMode, {double? sessionProgress}) {
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
      final opacity = 0.2 + (sessionProgress * 0.8);
      final scale = 0.85 + (sessionProgress * 0.15);
      child = Opacity(opacity: opacity, child: Transform.scale(scale: scale, child: child));
    }

    return child;
  }

  Widget _buildBottomActions(BuildContext context, PomodoroProvider provider) {
    final isRunning = provider.isRunning;

    if (isRunning) {
      return CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () {
          HapticFeedback.lightImpact();
          provider.stopTimer();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.danger.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.danger.withValues(alpha: 0.5), width: 1.5),
          ),
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.stop_fill, size: 14, color: AppColors.danger),
                SizedBox(width: 6),
                Text(
                  'STOP',
                  style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w800, fontSize: 17, letterSpacing: 0.8),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.heavyImpact();
        provider.startWorkSession();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 17),
        decoration: BoxDecoration(
          color: AppColors.cta,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.ctaGlow,
        ),
        child: const Center(
          child: Text(
            'INIZIA',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 17, letterSpacing: 0.8),
          ),
        ),
      ),
    );
  }

  Widget _buildFailedScreen(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(AppAssets.brickyBroken, width: 120, height: 120, fit: BoxFit.contain),
          const SizedBox(height: 24),
          const Text('Sessione fallita', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.danger)),
          const SizedBox(height: 8),
          const Text(
            'Hai lasciato l\'app durante una sessione di Deep Building.',
            style: TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          CupertinoButton(
            padding: EdgeInsets.zero,
            color: AppColors.cta,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            onPressed: () => setState(() => _sessionFailed = false),
            child: const SizedBox(width: double.infinity, child: Center(child: Text('RIPROVA', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 17)))),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessScreen(BuildContext context, PomodoroProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Spacer(),
          const Text('Complimenti!', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: AppColors.textPrimary), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          const Text('Hai costruito un nuovo mattoncino', style: TextStyle(fontSize: 16, color: AppColors.textSecondary), textAlign: TextAlign.center),
          const SizedBox(height: 40),
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary.withValues(alpha: 0.1)),
            child: Center(child: Image.asset(AppAssets.brickyCelebration, width: 170, height: 170, fit: BoxFit.contain)),
          ),
          const SizedBox(height: 32),
          Text(
            '${provider.completedPomodoros} ${provider.completedPomodoros == 1 ? 'mattoncino costruito' : 'mattoncini costruiti'}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          CupertinoButton(
            padding: EdgeInsets.zero,
            color: AppColors.cta,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            onPressed: () => setState(() => _sessionCompleted = false),
            child: const SizedBox(width: double.infinity, child: Center(child: Text('Continua a costruire', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 17)))),
          ),
          const SizedBox(height: 24),
        ],
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
            '$count ${count == 1 ? 'MATTONCINO' : 'MATTONCINI'}',
            style: AppTypography.subtitle.copyWith(letterSpacing: 1),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
