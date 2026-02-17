import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AiChatService {
  static const _baseUrl = 'https://openrouter.ai/api/v1/chat/completions';

  // Overridable settings (set from SettingsProvider via ChatProvider)
  String? apiKeyOverride;
  String? modelOverride;
  String? systemPromptOverride;

  String get _apiKey =>
      (apiKeyOverride != null && apiKeyOverride!.isNotEmpty)
          ? apiKeyOverride!
          : (dotenv.env['OPENROUTER_API_KEY'] ?? '');

  String get _model => modelOverride ?? 'openrouter/auto';

  String get _systemPrompt =>
      (systemPromptOverride != null && systemPromptOverride!.isNotEmpty)
          ? systemPromptOverride!
          : _defaultSystemPrompt;

  static const _defaultSystemPrompt = '''
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

  /// Sends a chat completion request and streams the response token by token.
  Stream<String> streamChatCompletion(
    List<Map<String, dynamic>> messages,
  ) async* {
    final apiKey = _apiKey;
    if (apiKey.isEmpty) {
      yield 'Errore: API key non configurata. Apri le impostazioni sviluppatore (tieni premuto il titolo 5 volte nella tab Studio) e inserisci la tua OpenRouter API key.';
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
}
