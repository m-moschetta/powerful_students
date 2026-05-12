import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:powerful_students/core/design_system.dart';
import 'package:powerful_students/models/chat_message.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.textPrimary,
                  width: 1,
                ),
              ),
              child: const Center(
                child: Text('🧠', style: TextStyle(fontSize: 14)),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                // Solid semi-transparent background for performance
                // (BackdropFilter on every bubble causes scroll jank)
                color: isUser
                    ? AppColors.cta.withValues(alpha: 0.45)
                    : Colors.white.withValues(alpha: 0.20),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isUser ? AppRadius.lg : 4),
                  topRight: Radius.circular(isUser ? 4 : AppRadius.lg),
                  bottomLeft: const Radius.circular(AppRadius.lg),
                  bottomRight: const Radius.circular(AppRadius.lg),
                ),
                border: Border.all(
                  color: isUser
                      ? AppColors.cta.withValues(alpha: 0.5)
                      : AppColors.glassBorder,
                  width: 0.5,
                ),
              ),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              child: isUser
                  ? Text(
                      message.content,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    )
                  : _AssistantContent(message: message),
            ),
          ),
          if (isUser) const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _AssistantContent extends StatelessWidget {
  const _AssistantContent({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    if (message.content.isEmpty && message.isStreaming) {
      return const TypingIndicator();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MarkdownBody(
          data: message.content,
          selectable: true,
          styleSheet: MarkdownStyleSheet(
            p: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
            h1: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
            h2: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
            h3: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
            strong: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            em: const TextStyle(
              fontStyle: FontStyle.italic,
              color: AppColors.textPrimary,
            ),
            code: TextStyle(
              fontSize: 14,
              fontFamily: 'Menlo',
              color: AppColors.textPrimary,
              backgroundColor: Colors.black.withValues(alpha: 0.08),
            ),
            codeblockDecoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                color: AppColors.glassBorder,
                width: 0.5,
              ),
            ),
            codeblockPadding: const EdgeInsets.all(12),
            blockquoteDecoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.6),
                  width: 3,
                ),
              ),
            ),
            blockquotePadding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
            listBullet: const TextStyle(
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (message.isStreaming) ...[
          const SizedBox(height: 4),
          const CursorBlink(),
        ],
      ],
    );
  }
}

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final offset = index * 0.33;
            final phase = (_controller.value + offset) % 1.0;
            final opacity = 0.3 + 0.7 * math.sin(phase * math.pi);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Opacity(
                opacity: opacity.clamp(0.3, 1.0),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class CursorBlink extends StatefulWidget {
  const CursorBlink({super.key});

  @override
  State<CursorBlink> createState() => _CursorBlinkState();
}

class _CursorBlinkState extends State<CursorBlink>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Opacity(
          opacity: _controller.value,
          child: Container(
            width: 2,
            height: 16,
            color: AppColors.primary,
          ),
        );
      },
    );
  }
}
