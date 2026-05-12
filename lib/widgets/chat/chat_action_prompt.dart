import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:powerful_students/core/design_system.dart';

class ChatActionPrompt extends StatelessWidget {
  const ChatActionPrompt({
    super.key,
    required this.onStartSession,
    required this.onNeedMoreHelp,
  });

  final VoidCallback onStartSession;
  final VoidCallback onNeedMoreHelp;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
        0,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.glassBorder, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    HapticFeedback.heavyImpact();
                    onStartSession();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cta,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      boxShadow: AppShadows.ctaGlow,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.play_fill,
                          color: AppColors.textPrimary,
                          size: 18,
                        ),
                        SizedBox(width: AppSpacing.xs),
                        Flexible(
                          child: Text(
                            'Inizia sessione',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  minimumSize: Size.zero,
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onNeedMoreHelp();
                  },
                  child: const Text(
                    'Ho ancora bisogno di aiuto',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
