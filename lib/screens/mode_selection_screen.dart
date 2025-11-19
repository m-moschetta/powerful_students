import 'package:flutter/material.dart';
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
                      const Text('Scegli modalità', style: AppTypography.title),
                      const SizedBox(height: AppSpacing.md),
                      ModeOptionCard(
                        title: 'Solo',
                        subtitle: 'Studia per conto tuo',
                        icon: Icons.person,
                        isSelected: selectedMode == StudyMode.solo,
                        onTap: () => pomodoro.selectMode(StudyMode.solo),
                      ),
                      const SizedBox(height: 12),
                      ModeOptionCard(
                        title: 'Group',
                        subtitle: 'Studia in compagnia',
                        icon: Icons.group,
                        isSelected: selectedMode == StudyMode.group,
                        onTap: () => pomodoro.selectMode(StudyMode.group),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: !hasSelection
                            ? null
                            : () {
                                if (selectedMode == StudyMode.group) {
                                  Navigator.pushNamed(context, '/group-room');
                                } else {
                                  Navigator.pushReplacementNamed(
                                    context,
                                    '/timer',
                                  );
                                }
                              },
                        style: AppButtons.primary(enabled: hasSelection),
                        child: Text(
                          'Inizia',
                          style: AppButtons.textStyle.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: AppDecorations.card(
          isSelected: isSelected,
          selectedColor: AppColors.secondary,
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: AppDecorations.circleContainer(
                color: isSelected ? AppColors.surface : AppColors.background,
              ),
              child: Icon(icon, size: 30, color: AppColors.textPrimary),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.subtitle),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondaryWith(0.8),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                AppIcons.check,
                color: AppColors.textPrimary,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }
}
