import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AiChatService {
  static const _defaultBaseUrl = 'https://openrouter.ai/api/v1';
  static const _timeout = Duration(seconds: 30);

  // Overridable settings (set from SettingsProvider via ChatProvider)
  String? apiKeyOverride;
  String? modelOverride;
  String? systemPromptOverride;
  String? baseUrlOverride;

  String get _apiKey =>
      (apiKeyOverride != null && apiKeyOverride!.isNotEmpty)
          ? apiKeyOverride!
          : (dotenv.env['OPENROUTER_API_KEY'] ?? '');

  String get _model => modelOverride ?? 'openrouter/auto';

  String get _baseUrl =>
      (baseUrlOverride != null && baseUrlOverride!.isNotEmpty)
          ? baseUrlOverride!
          : _defaultBaseUrl;

  /// Sends a chat completion request and streams the response token by token.
  Stream<String> streamChatCompletion(
    List<Map<String, dynamic>> messages,
  ) async* {
    final apiKey = _apiKey;
    final url = '$_baseUrl/chat/completions';
    
    if (apiKey.isEmpty && _baseUrl.contains('openrouter.ai')) {
      yield 'Errore: API key non configurata. Vai nelle impostazioni e inserisci la tua OpenRouter API key.';
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

    final request = http.Request('POST', Uri.parse(url))
      ..headers.addAll({
        if (apiKey.isNotEmpty) 'Authorization': 'Bearer $apiKey',
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
