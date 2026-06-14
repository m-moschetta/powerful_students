import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:powerful_students/models/chat_message.dart';
import 'package:powerful_students/providers/settings_provider.dart';
import 'package:powerful_students/services/ai_chat_service.dart';

enum ConversationStep { diagnosis, response, action }

class ChatProvider extends ChangeNotifier {
  ChatProvider({AiChatService? chatService})
    : _chatService = chatService ?? AiChatService();

  final AiChatService _chatService;
  SettingsProvider? _settings;

  /// Syncs chat service settings from the SettingsProvider.
  void updateSettings(SettingsProvider settings) {
    _settings = settings;
    _chatService.apiKeyOverride = settings.apiKey;
    _chatService.modelOverride = settings.model;
    _chatService.systemPromptOverride = settings.effectiveSystemPrompt;
    _chatService.baseUrlOverride = settings.baseUrl;
  }

  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  ConversationStep _conversationStep = ConversationStep.diagnosis;
  ConversationStep get conversationStep => _conversationStep;

  bool get shouldShowActionPrompt {
    if (_isLoading || _conversationStep != ConversationStep.action) {
      return false;
    }

    return _messages.any((message) {
      return message.role == ChatRole.assistant &&
          message.content.trim().isNotEmpty &&
          !message.isStreaming;
    });
  }

  StreamSubscription<String>? _streamSubscription;

  /// Sends a user message and streams the AI response.
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;

    // Add user message
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: ChatRole.user,
      content: text.trim(),
      timestamp: DateTime.now(),
    );
    _messages.add(userMessage);

    final settings = _settings;
    if (settings != null) {
      await settings.routeSkillForMessage(text.trim());
      updateSettings(settings);
    }

    // Create placeholder assistant message for streaming
    final assistantId = (DateTime.now().millisecondsSinceEpoch + 1).toString();
    final assistantMessage = ChatMessage(
      id: assistantId,
      role: ChatRole.assistant,
      content: '',
      timestamp: DateTime.now(),
      isStreaming: true,
    );
    _messages.add(assistantMessage);

    _isLoading = true;
    _conversationStep = ConversationStep.response;
    notifyListeners();

    // Build conversation history for the API
    final apiMessages = _messages
        .where((m) => !m.isStreaming || m.content.isNotEmpty)
        .map((m) => m.toApiMessage())
        .toList();
    // Remove the empty assistant placeholder from API messages
    if (apiMessages.isNotEmpty &&
        apiMessages.last['role'] == 'assistant' &&
        (apiMessages.last['content'] as String).isEmpty) {
      apiMessages.removeLast();
    }

    final buffer = StringBuffer();

    _streamSubscription = _chatService
        .streamChatCompletion(apiMessages)
        .listen(
          (delta) {
            buffer.write(delta);
            final index = _messages.indexWhere((m) => m.id == assistantId);
            if (index != -1) {
              _messages[index] = _messages[index].copyWith(
                content: buffer.toString(),
              );
              notifyListeners();
            }
          },
          onDone: () {
            final index = _messages.indexWhere((m) => m.id == assistantId);
            if (index != -1) {
              _messages[index] = _messages[index].copyWith(isStreaming: false);
            }
            _isLoading = false;
            _conversationStep = ConversationStep.action;
            _streamSubscription = null;
            notifyListeners();
          },
          onError: (error) {
            debugPrint('Stream error: $error');
            final index = _messages.indexWhere((m) => m.id == assistantId);
            if (index != -1) {
              _messages[index] = _messages[index].copyWith(
                content: buffer.isEmpty
                    ? 'Errore di connessione. Riprova.'
                    : buffer.toString(),
                isStreaming: false,
              );
            }
            _isLoading = false;
            _conversationStep = ConversationStep.action;
            _streamSubscription = null;
            notifyListeners();
          },
        );
  }

  void continueConversation() {
    if (_conversationStep == ConversationStep.diagnosis) return;

    _conversationStep = ConversationStep.diagnosis;
    notifyListeners();
  }

  /// Stops the current streaming response.
  void stopStreaming() {
    _streamSubscription?.cancel();
    _streamSubscription = null;

    // Finalize any streaming message
    for (var i = 0; i < _messages.length; i++) {
      if (_messages[i].isStreaming) {
        _messages[i] = _messages[i].copyWith(isStreaming: false);
      }
    }
    _isLoading = false;
    _conversationStep = ConversationStep.action;
    notifyListeners();
  }

  /// Clears the chat history.
  void clearChat() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _messages.clear();
    _isLoading = false;
    _conversationStep = ConversationStep.diagnosis;
    notifyListeners();
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }
}
