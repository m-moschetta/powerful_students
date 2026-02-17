import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AiChatService {
  static const _baseUrl = 'https://openrouter.ai/api/v1/chat/completions';
  static const _model = 'openrouter/auto';

  static const _systemPrompt = '''
Sei **Powerful Buddy**, un assistente AI dedicato allo studio e all'apprendimento.

Il tuo ruolo:
- Dai consigli pratici e motivazionali per migliorare le sessioni di studio
- Suggerisci tecniche di studio evidence-based (Pomodoro, active recall, spaced repetition, ecc.)
- Aiuti a pianificare le sessioni di studio e a gestire il tempo
- Rispondi a domande su qualsiasi materia scolastica o universitaria
- Motivi lo studente quando è stanco o scoraggiato
- Suggerisci strategie per affrontare esami e verifiche

Regole:
- Rispondi sempre in italiano, a meno che lo studente non chieda diversamente
- Usa il markdown per formattare le risposte in modo chiaro (titoli, elenchi, grassetto, code blocks)
- Sii conciso ma completo
- Mantieni un tono amichevole e incoraggiante, come un compagno di studio esperto
- Usa emoji con moderazione per rendere le risposte più vivaci
''';

  String get _apiKey => dotenv.env['OPENROUTER_API_KEY'] ?? '';

  /// Sends a chat completion request and streams the response token by token.
  ///
  /// [messages] is the conversation history as a list of
  /// `{'role': 'user'|'assistant', 'content': '...'}` maps.
  ///
  /// Returns a [Stream<String>] of incremental content deltas.
  Stream<String> streamChatCompletion(
    List<Map<String, dynamic>> messages,
  ) async* {
    final apiKey = _apiKey;
    if (apiKey.isEmpty) {
      yield 'Errore: API key non configurata. Aggiungi OPENROUTER_API_KEY al file .env';
      return;
    }

    final body = jsonEncode({
      'model': _model,
      'messages': [
        {'role': 'system', 'content': _systemPrompt},
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

    try {
      final response = await http.Client().send(request);

      if (response.statusCode != 200) {
        final errorBody = await response.stream.bytesToString();
        debugPrint('OpenRouter error: $errorBody');
        yield 'Errore nella risposta del server. Riprova tra poco.';
        return;
      }

      // Parse SSE stream
      await for (final chunk in response.stream
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
    }
  }

  /// Non-streaming completion for simpler use cases.
  Future<String> sendMessage(List<Map<String, dynamic>> messages) async {
    final apiKey = _apiKey;
    if (apiKey.isEmpty) {
      return 'Errore: API key non configurata. Aggiungi OPENROUTER_API_KEY al file .env';
    }

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://powerful-students.app',
          'X-Title': 'Powerful Students',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {'role': 'system', 'content': _systemPrompt},
            ...messages,
          ],
        }),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final choices = json['choices'] as List;
        return choices[0]['message']['content'] as String;
      } else {
        debugPrint('OpenRouter error: ${response.body}');
        return 'Errore nella risposta del server. Riprova tra poco.';
      }
    } catch (e) {
      debugPrint('AiChatService error: $e');
      return 'Errore di connessione. Controlla la tua rete e riprova.';
    }
  }
}
