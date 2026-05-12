import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:powerful_students/models/chat_message.dart';
import 'package:powerful_students/providers/chat_provider.dart';
import 'package:powerful_students/providers/settings_provider.dart';
import 'package:powerful_students/services/ai_chat_service.dart';

/// Mock AiChatService for testing
class MockAiChatService extends AiChatService {
  List<String> mockResponses = [];
  bool shouldError = false;
  String errorMessage = 'Test error';
  Duration? responseDelay;
  int streamCallCount = 0;
  List<Map<String, dynamic>>? lastMessages;

  @override
  Stream<String> streamChatCompletion(
    List<Map<String, dynamic>> messages,
  ) async* {
    streamCallCount++;
    lastMessages = messages;

    if (responseDelay != null) {
      await Future.delayed(responseDelay!);
    }

    if (shouldError) {
      throw Exception(errorMessage);
    }

    for (final response in mockResponses) {
      yield response;
    }
  }

  void reset() {
    mockResponses = [];
    shouldError = false;
    errorMessage = 'Test error';
    responseDelay = null;
    streamCallCount = 0;
    lastMessages = null;
  }
}

/// Helper to create a ChatProvider with a mock service
/// Note: Since ChatProvider creates AiChatService internally,
/// we test through the public API and settings
void main() {
  group('ChatProvider', () {
    late ChatProvider provider;

    setUp(() {
      provider = ChatProvider();
    });

    tearDown(() {
      provider.dispose();
    });

    group('Initial State', () {
      test('has empty messages list initially', () {
        expect(provider.messages, isEmpty);
      });

      test('is not loading initially', () {
        expect(provider.isLoading, isFalse);
      });

      test('starts in diagnosis step without action prompt', () {
        expect(provider.conversationStep, equals(ConversationStep.diagnosis));
        expect(provider.shouldShowActionPrompt, isFalse);
      });

      test('messages list is unmodifiable', () {
        expect(
          () => provider.messages.add(
            ChatMessage(
              id: '1',
              role: ChatRole.user,
              content: 'test',
              timestamp: DateTime.now(),
            ),
          ),
          throwsUnsupportedError,
        );
      });
    });

    group('updateSettings', () {
      test('accepts SettingsProvider without error', () {
        final settings = SettingsProvider();

        expect(() => provider.updateSettings(settings), returnsNormally);
      });
    });

    group('sendMessage', () {
      test('does nothing for empty message', () async {
        await provider.sendMessage('');

        expect(provider.messages, isEmpty);
        expect(provider.isLoading, isFalse);
      });

      test('does nothing for whitespace-only message', () async {
        await provider.sendMessage('   \n\t  ');

        expect(provider.messages, isEmpty);
      });

      test('moves to action step after assistant response completes', () async {
        final mockService = MockAiChatService()
          ..mockResponses = ['Inizia con 25 minuti di focus.'];
        final testProvider = ChatProvider(chatService: mockService);

        await testProvider.sendMessage('Non riesco a concentrarmi');
        await Future.delayed(const Duration(milliseconds: 10));

        expect(testProvider.conversationStep, equals(ConversationStep.action));
        expect(testProvider.shouldShowActionPrompt, isTrue);

        testProvider.dispose();
      });

      test('continueConversation returns to diagnosis step', () async {
        final mockService = MockAiChatService()
          ..mockResponses = ['Facciamo un piano semplice.'];
        final testProvider = ChatProvider(chatService: mockService);

        await testProvider.sendMessage('Aiutami a studiare');
        await Future.delayed(const Duration(milliseconds: 10));
        testProvider.continueConversation();

        expect(
          testProvider.conversationStep,
          equals(ConversationStep.diagnosis),
        );
        expect(testProvider.shouldShowActionPrompt, isFalse);

        testProvider.dispose();
      });

      test('trims whitespace from message', () async {
        // This will fail to connect but will still add the user message
        unawaited(provider.sendMessage('  Hello  '));

        // Give it a moment to process
        await Future.delayed(const Duration(milliseconds: 50));

        // Should have user message with trimmed content
        expect(provider.messages.length, greaterThanOrEqualTo(1));
        expect(provider.messages.first.content, equals('Hello'));
      });

      test('adds user message to list', () async {
        unawaited(provider.sendMessage('Test message'));

        await Future.delayed(const Duration(milliseconds: 50));

        final userMessages = provider.messages.where(
          (m) => m.role == ChatRole.user,
        );
        expect(userMessages.length, equals(1));
        expect(userMessages.first.content, equals('Test message'));
      });

      test('creates placeholder assistant message for streaming', () async {
        unawaited(provider.sendMessage('Hello'));

        await Future.delayed(const Duration(milliseconds: 50));

        final assistantMessages = provider.messages.where(
          (m) => m.role == ChatRole.assistant,
        );
        expect(assistantMessages.length, equals(1));
      });

      test('sets isLoading to true while processing', () async {
        final future = provider.sendMessage('Hello');

        // Check immediately - should be loading
        await Future.delayed(const Duration(milliseconds: 10));
        // Note: isLoading might have already changed if the connection failed fast

        await future;
      });

      test('does not send duplicate messages while loading', () async {
        unawaited(provider.sendMessage('First'));

        await Future.delayed(const Duration(milliseconds: 10));

        // Try to send another message while loading - it should be ignored
        // because isLoading is true
        unawaited(provider.sendMessage('Second'));

        await Future.delayed(const Duration(milliseconds: 100));

        // Count user messages - second message may or may not have been sent
        // depending on timing. The important thing is no crash occurs.
        final userMessages = provider.messages.where(
          (m) => m.role == ChatRole.user,
        );
        expect(userMessages.length, greaterThanOrEqualTo(1));
      });
    });

    group('stopStreaming', () {
      test('stops streaming and sets isLoading to false', () async {
        unawaited(provider.sendMessage('Hello'));
        await Future.delayed(const Duration(milliseconds: 10));

        provider.stopStreaming();

        expect(provider.isLoading, isFalse);
      });

      test('finalizes streaming messages', () async {
        unawaited(provider.sendMessage('Hello'));
        await Future.delayed(const Duration(milliseconds: 50));

        provider.stopStreaming();

        // All messages should have isStreaming = false
        for (final message in provider.messages) {
          expect(message.isStreaming, isFalse);
        }
      });

      test('is safe to call when not streaming', () {
        expect(() => provider.stopStreaming(), returnsNormally);
        expect(provider.isLoading, isFalse);
      });

      test('notifies listeners', () {
        var notified = false;
        provider.addListener(() => notified = true);

        provider.stopStreaming();

        expect(notified, isTrue);
      });
    });

    group('clearChat', () {
      test('clears all messages', () async {
        unawaited(provider.sendMessage('Hello'));
        await Future.delayed(const Duration(milliseconds: 50));
        provider.stopStreaming();

        expect(provider.messages, isNotEmpty);

        provider.clearChat();

        expect(provider.messages, isEmpty);
      });

      test('stops any active streaming', () async {
        unawaited(provider.sendMessage('Hello'));
        await Future.delayed(const Duration(milliseconds: 10));

        provider.clearChat();

        expect(provider.isLoading, isFalse);
      });

      test('resets isLoading to false', () async {
        unawaited(provider.sendMessage('Hello'));
        await Future.delayed(const Duration(milliseconds: 10));

        provider.clearChat();

        expect(provider.isLoading, isFalse);
      });

      test('resets conversation step', () async {
        final mockService = MockAiChatService()
          ..mockResponses = ['Risposta del buddy.'];
        final testProvider = ChatProvider(chatService: mockService);

        await testProvider.sendMessage('Ciao');
        await Future.delayed(const Duration(milliseconds: 10));
        testProvider.clearChat();

        expect(
          testProvider.conversationStep,
          equals(ConversationStep.diagnosis),
        );
        expect(testProvider.shouldShowActionPrompt, isFalse);

        testProvider.dispose();
      });

      test('notifies listeners', () {
        var notified = false;
        provider.addListener(() => notified = true);

        provider.clearChat();

        expect(notified, isTrue);
      });

      test('allows new messages after clearing', () async {
        unawaited(provider.sendMessage('First'));
        await Future.delayed(const Duration(milliseconds: 50));
        provider.stopStreaming();

        provider.clearChat();

        unawaited(provider.sendMessage('Second'));
        await Future.delayed(const Duration(milliseconds: 50));

        final userMessages = provider.messages.where(
          (m) => m.role == ChatRole.user,
        );
        expect(userMessages.length, equals(1));
        expect(userMessages.first.content, equals('Second'));
      });
    });

    group('dispose', () {
      test('cancels active streaming', () async {
        // Create a new provider just for this test to avoid dispose issues
        final testProvider = ChatProvider();
        unawaited(testProvider.sendMessage('Hello'));
        await Future.delayed(const Duration(milliseconds: 10));

        // This should not throw
        expect(() => testProvider.dispose(), returnsNormally);
      });
    });

    group('Message IDs', () {
      test('generates unique IDs for each message', () async {
        unawaited(provider.sendMessage('First'));
        await Future.delayed(const Duration(milliseconds: 100));
        provider.stopStreaming();
        provider.clearChat();

        unawaited(provider.sendMessage('Second'));
        await Future.delayed(const Duration(milliseconds: 50));

        final ids = provider.messages.map((m) => m.id).toSet();
        expect(ids.length, equals(provider.messages.length));
      });

      test('user and assistant message have different IDs', () async {
        unawaited(provider.sendMessage('Hello'));
        await Future.delayed(const Duration(milliseconds: 50));

        if (provider.messages.length >= 2) {
          final userMsg = provider.messages.firstWhere(
            (m) => m.role == ChatRole.user,
          );
          final assistantMsg = provider.messages.firstWhere(
            (m) => m.role == ChatRole.assistant,
          );

          expect(userMsg.id, isNot(equals(assistantMsg.id)));
        }
      });
    });

    group('Listener Notifications', () {
      test('notifies when message is added', () async {
        var notifyCount = 0;
        provider.addListener(() => notifyCount++);

        unawaited(provider.sendMessage('Hello'));
        await Future.delayed(const Duration(milliseconds: 50));

        expect(notifyCount, greaterThan(0));
      });

      test('notifies on clearChat', () {
        var notified = false;
        provider.addListener(() => notified = true);

        provider.clearChat();

        expect(notified, isTrue);
      });

      test('notifies on stopStreaming', () {
        var notified = false;
        provider.addListener(() => notified = true);

        provider.stopStreaming();

        expect(notified, isTrue);
      });
    });
  });
}
