import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:powerful_students/core/design_system.dart';

class ChatEmptyState extends StatelessWidget {
  const ChatEmptyState({
    super.key,
    required this.onSuggestionTap,
  });

  final void Function(String text) onSuggestionTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Center(
                child: Text('🎓', style: TextStyle(fontSize: 40)),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Ciao! Sono Powerful Buddy',
              style: AppTypography.title,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Chiedimi consigli sullo studio, aiuto con le materie, '
              'o strategie per i tuoi esami.',
              style: AppTypography.caption.copyWith(height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            _SuggestionChips(onTap: onSuggestionTap),
          ],
        ),
      ),
    );
  }
}

class _SuggestionChips extends StatelessWidget {
  const _SuggestionChips({required this.onTap});

  final void Function(String text) onTap;

  static const _suggestions = [
    'Come posso concentrarmi meglio?',
    'Tecnica del Pomodoro: consigli',
    'Aiutami a pianificare lo studio',
    'Strategie per memorizzare',
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      alignment: WrapAlignment.center,
      children: _suggestions.map((text) {
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap(text);
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: AppColors.glassBorder,
                    width: 0.5,
                  ),
                ),
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
