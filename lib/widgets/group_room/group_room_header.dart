import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:powerful_students/core/design_system.dart';
import 'package:powerful_students/providers/pomodoro_provider.dart';
import 'package:powerful_students/providers/room_provider.dart';

class GroupRoomHeader extends StatelessWidget {
  const GroupRoomHeader({
    super.key,
    required this.roomProvider,
    required this.pomodoroProvider,
    required this.isOwner,
    required this.isSessionActive,
    required this.onBack,
  });

  final RoomProvider roomProvider;
  final PomodoroProvider pomodoroProvider;
  final bool isOwner;
  final bool isSessionActive;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: onBack,
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
                  pomodoroProvider.isBurnMode ? AppAssets.brickyLogo : AppAssets.brickyBurn,
                  key: ValueKey<bool>(pomodoroProvider.isBurnMode),
                  width: pomodoroProvider.isBurnMode ? 32 : 24,
                  height: pomodoroProvider.isBurnMode ? 32 : 24,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 6),
              if (isOwner || !roomProvider.hasRoom)
                CupertinoSwitch(
                  value: pomodoroProvider.isBurnMode,
                  onChanged: isSessionActive ? null : (_) {
                    HapticFeedback.mediumImpact();
                    pomodoroProvider.toggleBurnMode();
                  },
                  activeTrackColor: AppColors.primary,
                )
              else
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    pomodoroProvider.isBurnMode ? 'ON' : 'OFF',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: pomodoroProvider.isBurnMode ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
