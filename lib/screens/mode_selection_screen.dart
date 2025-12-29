import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:powerful_students/models/study_session.dart';
import 'package:powerful_students/providers/pomodoro_provider.dart';
import 'package:powerful_students/core/design_system.dart';

class ModeSelectionScreen extends StatelessWidget {
  const ModeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pomodoro = context.watch<PomodoroProvider>();
    final selectedMode = pomodoro.selectedMode;
    final hasSelection =
        selectedMode == StudyMode.solo || selectedMode == StudyMode.group;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppSpacing.xl),
                      const Text(
                        'Powerful Students',
                        style: AppTypography.headline,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      const Text(
                        'Scegli modalità',
                        style: AppTypography.caption,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      
                      AppDecorations.glassContainer(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        child: Column(
                          children: [
                            ModeOptionCard(
                              title: 'Solo',
                              subtitle: 'Studia per conto tuo',
                              icon: AppIcons.soloMode,
                              isSelected: selectedMode == StudyMode.solo,
                              onTap: () => pomodoro.selectMode(StudyMode.solo),
                            ),
                            const Divider(height: 1, color: AppColors.glassBorder),
                            ModeOptionCard(
                              title: 'Group',
                              subtitle: 'Studia in compagnia',
                              icon: AppIcons.groupMode,
                              isSelected: selectedMode == StudyMode.group,
                              onTap: () => pomodoro.selectMode(StudyMode.group),
                            ),
                          ],
                        ),
                      ),
                      
                      const Spacer(),
                      
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                        child: CupertinoButton(
                          onPressed: !hasSelection
                              ? null
                              : () {
                                  HapticFeedback.heavyImpact();
                                  if (selectedMode == StudyMode.group) {
                                    Navigator.pushNamed(context, '/group-room');
                                  } else {
                                    Navigator.pushNamed(context, '/timer');
                                  }
                                },
                          color: AppColors.cta, // Rosa per CTA come richiesto
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          child: const Text(
                            'INIZIA ORA',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class ModeOptionCard extends StatelessWidget {
  const ModeOptionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.glass(0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: isSelected ? Border.all(color: AppColors.textPrimary, width: 2) : null,
              ),
              child: Icon(
                icon,
                size: 24,
                color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.subtitle),
                  Text(subtitle, style: AppTypography.caption),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                AppIcons.check,
                color: AppColors.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}

