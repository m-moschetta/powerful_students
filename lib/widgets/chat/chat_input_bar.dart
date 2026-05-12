import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:powerful_students/core/design_system.dart';

class ChatInputBar extends StatelessWidget {
  const ChatInputBar({
    super.key,
    required this.textController,
    required this.focusNode,
    required this.hasText,
    required this.isLoading,
    required this.isSecondary,
    required this.onSend,
    required this.onStop,
  });

  final TextEditingController textController;
  final FocusNode focusNode;
  final bool hasText;
  final bool isLoading;
  final bool isSecondary;
  final VoidCallback onSend;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          padding: const EdgeInsets.only(
            left: AppSpacing.sm,
            right: AppSpacing.xs,
            top: AppSpacing.xs,
            bottom: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: isSecondary ? 0.08 : 0.12),
            border: const Border(
              top: BorderSide(color: AppColors.glassBorder, width: 0.5),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(
                      alpha: isSecondary ? 0.14 : 0.2,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isSecondary
                          ? AppColors.glassBorder.withValues(alpha: 0.6)
                          : AppColors.glassBorder,
                      width: 0.5,
                    ),
                  ),
                  child: TextField(
                    controller: textController,
                    focusNode: focusNode,
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: isSecondary
                          ? 'Scrivi comunque al buddy...'
                          : 'Chiedi al tuo buddy...',
                      hintStyle: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: (_) => onSend(),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: isLoading
                    ? _StopButton(onStop: onStop)
                    : _SendButton(hasText: hasText, onSend: onSend),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StopButton extends StatelessWidget {
  const _StopButton({required this.onStop});

  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.all(8),
      onPressed: () {
        HapticFeedback.mediumImpact();
        onStop();
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.textPrimary,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(
          CupertinoIcons.stop_fill,
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.hasText, required this.onSend});

  final bool hasText;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.all(8),
      onPressed: hasText ? onSend : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: hasText ? 1.0 : 0.4,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.cta,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.textPrimary, width: 1.5),
          ),
          child: const Icon(
            CupertinoIcons.arrow_up,
            color: AppColors.textPrimary,
            size: 20,
          ),
        ),
      ),
    );
  }
}
