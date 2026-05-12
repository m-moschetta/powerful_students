import 'package:flutter_test/flutter_test.dart';
import 'package:powerful_students/models/chat_message.dart';

void main() {
  group('ChatRole', () {
    test('has user and assistant values', () {
      expect(ChatRole.values, contains(ChatRole.user));
      expect(ChatRole.values, contains(ChatRole.assistant));
    });
  });

  group('ChatMessage', () {
    group('Constructor', () {
      test('creates message with required fields', () {
        final message = ChatMessage(
          id: 'msg-1',
          role: ChatRole.user,
          content: 'Hello',
          timestamp: DateTime(2024, 1, 1, 10, 0),
        );

        expect(message.id, equals('msg-1'));
        expect(message.role, equals(ChatRole.user));
        expect(message.content, equals('Hello'));
        expect(message.timestamp, equals(DateTime(2024, 1, 1, 10, 0)));
        expect(message.isStreaming, isFalse); // default value
      });

      test('creates message with streaming flag', () {
        final message = ChatMessage(
          id: 'msg-1',
          role: ChatRole.assistant,
          content: 'Responding...',
          timestamp: DateTime.now(),
          isStreaming: true,
        );

        expect(message.isStreaming, isTrue);
      });
    });

    group('copyWith', () {
      test('creates copy with modified content', () {
        final original = ChatMessage(
          id: 'msg-1',
          role: ChatRole.assistant,
          content: 'Hello',
          timestamp: DateTime(2024, 1, 1),
          isStreaming: true,
        );

        final copy = original.copyWith(content: 'Hello, world!');

        expect(copy.content, equals('Hello, world!'));
        expect(copy.id, equals(original.id));
        expect(copy.role, equals(original.role));
        expect(copy.timestamp, equals(original.timestamp));
        expect(copy.isStreaming, equals(original.isStreaming));
      });

      test('creates copy with modified isStreaming', () {
        final original = ChatMessage(
          id: 'msg-1',
          role: ChatRole.assistant,
          content: 'Complete response',
          timestamp: DateTime(2024, 1, 1),
          isStreaming: true,
        );

        final copy = original.copyWith(isStreaming: false);

        expect(copy.isStreaming, isFalse);
        expect(copy.content, equals(original.content));
      });

      test('preserves unchanged fields', () {
        final timestamp = DateTime(2024, 1, 1, 10, 30);
        final original = ChatMessage(
          id: 'msg-123',
          role: ChatRole.user,
          content: 'Test message',
          timestamp: timestamp,
          isStreaming: false,
        );

        final copy = original.copyWith();

        expect(copy.id, equals(original.id));
        expect(copy.role, equals(original.role));
        expect(copy.content, equals(original.content));
        expect(copy.timestamp, equals(original.timestamp));
        expect(copy.isStreaming, equals(original.isStreaming));
      });

      test('allows multiple fields to be modified', () {
        final original = ChatMessage(
          id: 'msg-1',
          role: ChatRole.assistant,
          content: 'Partial',
          timestamp: DateTime.now(),
          isStreaming: true,
        );

        final copy = original.copyWith(
          content: 'Complete response',
          isStreaming: false,
        );

        expect(copy.content, equals('Complete response'));
        expect(copy.isStreaming, isFalse);
      });
    });

    group('toApiMessage', () {
      test('converts user message to API format', () {
        final message = ChatMessage(
          id: 'msg-1',
          role: ChatRole.user,
          content: 'What is Flutter?',
          timestamp: DateTime.now(),
        );

        final apiMessage = message.toApiMessage();

        expect(apiMessage, isA<Map<String, dynamic>>());
        expect(apiMessage['role'], equals('user'));
        expect(apiMessage['content'], equals('What is Flutter?'));
      });

      test('converts assistant message to API format', () {
        final message = ChatMessage(
          id: 'msg-2',
          role: ChatRole.assistant,
          content: 'Flutter is a UI framework.',
          timestamp: DateTime.now(),
        );

        final apiMessage = message.toApiMessage();

        expect(apiMessage['role'], equals('assistant'));
        expect(apiMessage['content'], equals('Flutter is a UI framework.'));
      });

      test('excludes id and timestamp from API message', () {
        final message = ChatMessage(
          id: 'msg-1',
          role: ChatRole.user,
          content: 'Hello',
          timestamp: DateTime.now(),
        );

        final apiMessage = message.toApiMessage();

        expect(apiMessage.containsKey('id'), isFalse);
        expect(apiMessage.containsKey('timestamp'), isFalse);
        expect(apiMessage.containsKey('isStreaming'), isFalse);
      });

      test('only contains role and content keys', () {
        final message = ChatMessage(
          id: 'msg-1',
          role: ChatRole.user,
          content: 'Test',
          timestamp: DateTime.now(),
          isStreaming: true,
        );

        final apiMessage = message.toApiMessage();

        expect(apiMessage.keys.length, equals(2));
        expect(apiMessage.keys, containsAll(['role', 'content']));
      });
    });

    group('Edge Cases', () {
      test('handles empty content', () {
        final message = ChatMessage(
          id: 'msg-1',
          role: ChatRole.assistant,
          content: '',
          timestamp: DateTime.now(),
          isStreaming: true,
        );

        expect(message.content, equals(''));
        expect(message.toApiMessage()['content'], equals(''));
      });

      test('handles multi-line content', () {
        final content = '''Line 1
Line 2
Line 3''';
        
        final message = ChatMessage(
          id: 'msg-1',
          role: ChatRole.user,
          content: content,
          timestamp: DateTime.now(),
        );

        expect(message.content, equals(content));
        expect(message.toApiMessage()['content'], equals(content));
      });

      test('handles special characters in content', () {
        final content = 'Hello! How are you? 🎉 <script>alert("xss")</script>';
        
        final message = ChatMessage(
          id: 'msg-1',
          role: ChatRole.user,
          content: content,
          timestamp: DateTime.now(),
        );

        expect(message.content, equals(content));
      });

      test('handles unicode content', () {
        final content = '你好世界 مرحبا العالم שלום עולם';
        
        final message = ChatMessage(
          id: 'msg-1',
          role: ChatRole.user,
          content: content,
          timestamp: DateTime.now(),
        );

        expect(message.content, equals(content));
      });
    });
  });
}
