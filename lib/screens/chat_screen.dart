import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:powerful_students/core/design_system.dart';
import 'package:powerful_students/providers/chat_provider.dart';
import 'package:powerful_students/widgets/chat/chat.dart';

class ChatScreen extends StatefulWidget {
  final VoidCallback onBackPressed;
  final VoidCallback onStartSession;

  const ChatScreen({
    super.key,
    required this.onBackPressed,
    required this.onStartSession,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  bool _hasText = false;
  int _lastMessageCount = 0;
  DateTime _lastScrollTime = DateTime(0);

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      final hasText = _textController.text.trim().isNotEmpty;
      if (hasText != _hasText) {
        setState(() => _hasText = hasText);
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _textController.text;
    if (text.trim().isEmpty) return;

    HapticFeedback.lightImpact();
    context.read<ChatProvider>().sendMessage(text);
    _textController.clear();
    _scrollToBottom();
  }

  void _handleSuggestionTap(String text) {
    _textController.text = text;
    _sendMessage();
  }

  void _needMoreHelp() {
    context.read<ChatProvider>().continueConversation();
    _focusNode.requestFocus();
  }

  void _showClearConfirmation() {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Nuova conversazione'),
        content: const Text(
          'Vuoi iniziare una nuova conversazione? La cronologia attuale verrà cancellata.',
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Annulla'),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Cancella'),
            onPressed: () {
              context.read<ChatProvider>().clearChat();
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ChatHeader(
              onBack: widget.onBackPressed,
              onSettings: () => Navigator.pushNamed(context, '/settings'),
              onClear: _showClearConfirmation,
            ),
            const ChatSkillPicker(),
            Expanded(
              child: Consumer<ChatProvider>(
                builder: (context, provider, _) {
                  if (provider.messages.isEmpty) {
                    _lastMessageCount = 0;
                    return ChatEmptyState(
                      onSuggestionTap: _handleSuggestionTap,
                    );
                  }

                  // Auto-scroll on new messages; throttle during streaming
                  final messageCount = provider.messages.length;
                  final isStreaming = provider.messages.last.isStreaming;
                  final now = DateTime.now();

                  if (messageCount != _lastMessageCount) {
                    // New message added - always scroll
                    _lastMessageCount = messageCount;
                    _scrollToBottom();
                    _lastScrollTime = now;
                  } else if (isStreaming &&
                      now.difference(_lastScrollTime).inMilliseconds > 300) {
                    // During streaming, scroll at most every 300ms
                    _scrollToBottom();
                    _lastScrollTime = now;
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    itemCount: provider.messages.length,
                    itemBuilder: (context, index) {
                      return ChatBubble(message: provider.messages[index]);
                    },
                  );
                },
              ),
            ),
            Consumer<ChatProvider>(
              builder: (context, provider, _) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: provider.shouldShowActionPrompt
                          ? ChatActionPrompt(
                              key: const ValueKey('chat-action-prompt'),
                              onStartSession: widget.onStartSession,
                              onNeedMoreHelp: _needMoreHelp,
                            )
                          : const SizedBox.shrink(
                              key: ValueKey('no-chat-action-prompt'),
                            ),
                    ),
                    ChatInputBar(
                      textController: _textController,
                      focusNode: _focusNode,
                      hasText: _hasText,
                      isLoading: provider.isLoading,
                      isSecondary: provider.shouldShowActionPrompt,
                      onSend: _sendMessage,
                      onStop: provider.stopStreaming,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
