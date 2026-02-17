import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AiChatService {
  static const _baseUrl = 'https://openrouter.ai/api/v1/chat/completions';
  static const _timeout = Duration(seconds: 30);

  // Overridable settings (set from SettingsProvider via ChatProvider)
  String? apiKeyOverride;
  String? modelOverride;
  String? systemPromptOverride;

  String get _apiKey =>
      (apiKeyOverride != null && apiKeyOverride!.isNotEmpty)
          ? apiKeyOverride!
          : (dotenv.env['OPENROUTER_API_KEY'] ?? '');

  String get _model => modelOverride ?? 'openrouter/auto';

  /// Sends a chat completion request and streams the response token by token.
  Stream<String> streamChatCompletion(
    List<Map<String, dynamic>> messages,
  ) async* {
    final apiKey = _apiKey;
    if (apiKey.isEmpty) {
      yield 'Errore: API key non configurata. Vai nelle impostazioni sviluppatore (tocca 5 volte la tab Studio) e inserisci la tua OpenRouter API key.';
      return;
    }

    // System prompt is injected via systemPromptOverride from SettingsProvider
    final systemPrompt = systemPromptOverride ?? '';

    final body = jsonEncode({
      'model': _model,
      'messages': [
        if (systemPrompt.isNotEmpty)
          {'role': 'system', 'content': systemPrompt},
        ...messages,
      ],
      'stream': true,
    });

    final request = http.Request('POST', Uri.parse(_baseUrl))
      ..headers.addAll({
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://powerful-students.app',
        'X-Title': 'Powerful Students',
      })
      ..body = body;

    final client = http.Client();
    try {
      final response = await client.send(request).timeout(_timeout);

      if (response.statusCode != 200) {
        final errorBody = await response.stream.bytesToString();
        debugPrint('OpenRouter error: $errorBody');
        yield 'Errore nella risposta del server. Riprova tra poco.';
        return;
      }

      // Parse SSE stream (with timeout to detect stalled connections)
      await for (final chunk in response.stream
          .timeout(_timeout)
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        if (chunk.startsWith('data: ')) {
          final data = chunk.substring(6).trim();
          if (data == '[DONE]') break;

          try {
            final json = jsonDecode(data) as Map<String, dynamic>;
            final choices = json['choices'] as List?;
            if (choices != null && choices.isNotEmpty) {
              final delta = choices[0]['delta'] as Map<String, dynamic>?;
              final content = delta?['content'] as String?;
              if (content != null && content.isNotEmpty) {
                yield content;
              }
            }
          } catch (e) {
            // Skip malformed chunks
          }
        }
      }
    } catch (e) {
      debugPrint('AiChatService error: $e');
      yield 'Errore di connessione. Controlla la tua rete e riprova.';
    } finally {
      client.close();
    }
  }
}
