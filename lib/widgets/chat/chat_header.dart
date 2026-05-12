import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:powerful_students/core/design_system.dart';

class ChatHeader extends StatelessWidget {
  const ChatHeader({
    super.key,
    required this.onBack,
    required this.onSettings,
    required this.onClear,
  });

  final VoidCallback onBack;
  final VoidCallback onSettings;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              HapticFeedback.lightImpact();
              onBack();
            },
            child: const Icon(
              CupertinoIcons.chevron_left,
              color: AppColors.textPrimary,
              size: 28,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.textPrimary, width: 1.5),
            ),
            child: const Center(
              child: Text('🧠', style: TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Powerful Buddy',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
                Text(
                  'Il tuo compagno di studio AI',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              HapticFeedback.mediumImpact();
              onSettings();
            },
            child: Icon(
              CupertinoIcons.settings,
              color: AppColors.textSecondary.withValues(alpha: 0.6),
              size: 22,
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              HapticFeedback.mediumImpact();
              onClear();
            },
            child: Icon(
              CupertinoIcons.arrow_counterclockwise,
              color: AppColors.textSecondary.withValues(alpha: 0.6),
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}
