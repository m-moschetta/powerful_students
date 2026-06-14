import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:powerful_students/core/design_system.dart';
import 'package:powerful_students/l10n/app_localizations.dart';
import 'package:powerful_students/models/study_skill.dart';
import 'package:powerful_students/providers/settings_provider.dart';
import 'package:provider/provider.dart';

/// Selettore skill: routing automatico (default) o scelta manuale.
class ChatSkillPicker extends StatelessWidget {
  const ChatSkillPicker({super.key});

  Future<void> _openPicker(
    BuildContext context,
    SettingsProvider settings,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final skills = settings.availableSkills;
    if (skills.isEmpty) {
      return;
    }

    HapticFeedback.selectionClick();

    var selectedIndex = skills.indexWhere(
      (s) => s.id == settings.selectedSkillId,
    );
    if (selectedIndex < 0) {
      selectedIndex = 0;
    }

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              height: 320,
              color: CupertinoColors.systemBackground.resolveFrom(ctx),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(l10n.cancelLabel),
                        ),
                        Text(
                          l10n.chatSkillSheetTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () async {
                            if (!settings.autoSkillRouting) {
                              final skill = skills[selectedIndex];
                              await settings.setSelectedSkillIdManual(
                                skill.id,
                              );
                            }
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                            }
                          },
                          child: Text(l10n.chatSkillApply),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.chatSkillAutoRouting,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        CupertinoSwitch(
                          value: settings.autoSkillRouting,
                          onChanged: (value) {
                            setModalState(() {});
                            settings.setAutoSkillRouting(value);
                          },
                        ),
                      ],
                    ),
                  ),
                  if (settings.autoSkillRouting)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        0,
                        AppSpacing.md,
                        AppSpacing.sm,
                      ),
                      child: Text(
                        l10n.chatSkillAutoRoutingHint,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                          initialItem: selectedIndex,
                        ),
                        itemExtent: 44,
                        onSelectedItemChanged: (index) {
                          setModalState(() => selectedIndex = index);
                        },
                        children: skills
                            .map(
                              (StudySkill s) => Center(
                                child: Text(
                                  s.name,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final skill = settings.selectedSkill;
        final skillName = skill?.name ?? l10n.chatSkillDefault;
        final label = settings.autoSkillRouting
            ? '${l10n.chatSkillAuto} · $skillName'
            : skillName;

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            0,
            AppSpacing.sm,
            AppSpacing.xs,
          ),
          child: GestureDetector(
            onTap: () => _openPicker(context, settings),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: AppColors.glass(0.92),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.separator),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    settings.autoSkillRouting
                        ? CupertinoIcons.wand_stars
                        : CupertinoIcons.sparkles,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${l10n.chatSkillLabel}: $label',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    CupertinoIcons.chevron_down,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
