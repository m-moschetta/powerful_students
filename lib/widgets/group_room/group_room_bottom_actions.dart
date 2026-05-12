import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:powerful_students/core/design_system.dart';

class GroupRoomBottomActions extends StatelessWidget {
  const GroupRoomBottomActions({
    super.key,
    required this.hasRoom,
    required this.isOwner,
    required this.isRunning,
    required this.hasSession,
    required this.onStop,
    required this.onStart,
    required this.onLeave,
  });

  final bool hasRoom;
  final bool isOwner;
  final bool isRunning;
  final bool hasSession;
  final VoidCallback onStop;
  final VoidCallback onStart;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    // Session is running
    if (hasSession && isRunning) {
      if (isOwner) {
        return _StopButton(onStop: onStop);
      }
      return const SizedBox.shrink();
    }

    // No session, owner can start
    if (isOwner) {
      return _OwnerActions(onLeave: onLeave, onStart: onStart);
    }

    // Non-owner waiting or leaving
    return _LeaveRoomButton(onLeave: onLeave);
  }
}

class _StopButton extends StatelessWidget {
  const _StopButton({required this.onStop});

  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () {
        HapticFeedback.lightImpact();
        onStop();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: AppColors.danger.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.stop_fill,
                size: 14,
                color: AppColors.danger.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 6),
              const Text(
                'STOP',
                style: TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OwnerActions extends StatelessWidget {
  const _OwnerActions({
    required this.onLeave,
    required this.onStart,
  });

  final VoidCallback onLeave;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              HapticFeedback.lightImpact();
              onLeave();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 17),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.separator),
              ),
              child: const Center(
                child: Text(
                  'ESCI',
                  style: TextStyle(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.heavyImpact();
              onStart();
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
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LeaveRoomButton extends StatelessWidget {
  const _LeaveRoomButton({required this.onLeave});

  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () {
        HapticFeedback.lightImpact();
        onLeave();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 17),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.5)),
        ),
        child: const Center(
          child: Text(
            'ESCI DALLA STANZA',
            style: TextStyle(
              color: AppColors.danger,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
