import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:powerful_students/models/study_session.dart';
import 'package:powerful_students/providers/pomodoro_provider.dart';
import 'package:powerful_students/core/design_system.dart';

class ModeSelectionScreen extends StatelessWidget {
  final VoidCallback onChatPressed;

  const ModeSelectionScreen({super.key, required this.onChatPressed});

  @override
  Widget build(BuildContext context) {
    final pomodoro = context.watch<PomodoroProvider>();
    final selectedMode = pomodoro.selectedMode;
    final hasSelection =
        selectedMode == StudyMode.solo || selectedMode == StudyMode.group;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: AppSpacing.md),
                          const _HomeHero(),
                          const SizedBox(height: AppSpacing.lg),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Come vuoi costruire oggi?',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _ModeCard(
                            selectedMode: selectedMode,
                            onSelectSolo: () =>
                                pomodoro.selectMode(StudyMode.solo),
                            onSelectGroup: () =>
                                pomodoro.selectMode(StudyMode.group),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _BuddyHelpButton(onPressed: onChatPressed),
                          const SizedBox(height: AppSpacing.md),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: GestureDetector(
                onTap: !hasSelection
                    ? null
                    : () {
                        HapticFeedback.heavyImpact();
                        if (selectedMode == StudyMode.group) {
                          Navigator.pushNamed(context, '/group-room');
                        } else {
                          Navigator.pushNamed(context, '/timer');
                        }
                      },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 17),
                  decoration: BoxDecoration(
                    color: hasSelection
                        ? AppColors.cta
                        : AppColors.cta.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    boxShadow: hasSelection ? AppShadows.ctaGlow : [],
                  ),
                  child: const Center(
                    child: Text(
                      'INIZIA A COSTRUIRE',
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
        ),
      ),
    );
  }
}

class _HomeHero extends StatelessWidget {
  const _HomeHero();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.separator.withValues(alpha: 0.65),
              width: 0.5,
            ),
            boxShadow: AppShadows.md,
          ),
          child: Image.asset(AppAssets.brickyLogo, fit: BoxFit.contain),
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'Powerful Buddy',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'Tutto si costruisce\nun mattoncino alla volta.',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary.withValues(alpha: 0.78),
            height: 1.35,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _BuddyHelpButton extends StatelessWidget {
  const _BuddyHelpButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () {
        HapticFeedback.mediumImpact();
        onPressed();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 13,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.58),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: AppColors.separator.withValues(alpha: 0.9),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.45),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.chat_bubble_2_fill,
                color: AppColors.textPrimary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hai un dubbio?',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Chiedilo a Bricky',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              color: AppColors.textSecondary.withValues(alpha: 0.6),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.selectedMode,
    required this.onSelectSolo,
    required this.onSelectGroup,
  });

  final StudyMode? selectedMode;
  final VoidCallback onSelectSolo;
  final VoidCallback onSelectGroup;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.separator, width: 0.5),
        boxShadow: AppShadows.md,
      ),
      child: Column(
        children: [
          _ModeRow(
            title: 'SOLO',
            subtitle: 'Costruisci individualmente',
            imageAsset: AppAssets.brickyLogo,
            isSelected: selectedMode == StudyMode.solo,
            isFirst: true,
            onTap: onSelectSolo,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(height: 0.5, color: AppColors.separator),
          ),
          _ModeRow(
            title: 'GROUP',
            subtitle: 'Costruisci in compagnia',
            imageAsset: AppAssets.brickyGroup,
            isSelected: selectedMode == StudyMode.group,
            isFirst: false,
            isLast: true,
            onTap: onSelectGroup,
          ),
        ],
      ),
    );
  }
}

class _ModeRow extends StatelessWidget {
  const _ModeRow({
    required this.title,
    required this.subtitle,
    required this.imageAsset,
    required this.isSelected,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  final String title;
  final String subtitle;
  final String imageAsset;
  final bool isSelected;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.vertical(
            top: isFirst ? const Radius.circular(AppRadius.lg) : Radius.zero,
            bottom: isLast ? const Radius.circular(AppRadius.lg) : Radius.zero,
          ),
        ),
        child: Row(
          children: [
            // Icon container circolare
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.separator,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Image.asset(imageAsset, fit: BoxFit.contain),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Checkmark animato
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isSelected ? 1.0 : 0.0,
              child: const Icon(
                CupertinoIcons.checkmark_circle_fill,
                color: AppColors.primary,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
