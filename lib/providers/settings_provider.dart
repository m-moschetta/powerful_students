import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AiModel {
  final String id;
  final String name;
  final String? description;
  final int? contextLength;
  final double? promptPricing;

  const AiModel({
    required this.id,
    required this.name,
    this.description,
    this.contextLength,
    this.promptPricing,
  });

  factory AiModel.fromJson(Map<String, dynamic> json) {
    final pricing = json['pricing'] as Map<String, dynamic>?;
    return AiModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? json['id'] as String,
      description: json['description'] as String?,
      contextLength: json['context_length'] as int?,
      promptPricing: pricing != null
          ? double.tryParse(pricing['prompt']?.toString() ?? '')
          : null,
    );
  }
}

class SettingsProvider extends ChangeNotifier {
  static const _keyApiKey = 'openrouter_api_key';
  static const _keySystemPrompt = 'ai_system_prompt';
  static const _keyModel = 'ai_model';

  SharedPreferences? _prefs;

  String _apiKey = '';
  String get apiKey => _apiKey;

  String _systemPrompt = '';
  String get systemPrompt => _systemPrompt;
  bool get hasCustomSystemPrompt => _systemPrompt.isNotEmpty;

  String _model = 'openrouter/auto';
  String get model => _model;

  List<AiModel> _availableModels = [];
  List<AiModel> get availableModels => _availableModels;

  bool _isFetchingModels = false;
  bool get isFetchingModels => _isFetchingModels;

  String? _modelsError;
  String? get modelsError => _modelsError;

  static const fallbackModels = [
    'openrouter/auto',
    'anthropic/claude-sonnet-4',
    'openai/gpt-4o',
    'openai/gpt-4o-mini',
    'google/gemini-2.0-flash-001',
    'meta-llama/llama-3.3-70b-instruct',
  ];

  static final fallbackAiModels = fallbackModels.map((id) {
    return AiModel(
      id: id,
      name: id == 'openrouter/auto' ? 'Auto (OpenRouter)' : id,
      description: id == 'openrouter/auto'
          ? 'Automatically selects the best model for each request'
          : null,
    );
  }).toList();

  static const defaultSystemPrompt = '''
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

  /// The effective system prompt (custom or default).
  String get effectiveSystemPrompt =>
      _systemPrompt.isNotEmpty ? _systemPrompt : defaultSystemPrompt;

  static const _keyBaseUrl = 'ai_base_url';

  String _baseUrl = 'https://openrouter.ai/api/v1';
  String get baseUrl => _baseUrl;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _apiKey = _prefs?.getString(_keyApiKey) ?? '';
    _systemPrompt = _prefs?.getString(_keySystemPrompt) ?? '';
    _model = _prefs?.getString(_keyModel) ?? 'openrouter/auto';
    _baseUrl = _prefs?.getString(_keyBaseUrl) ?? 'https://openrouter.ai/api/v1';
    _availableModels = fallbackAiModels;
    notifyListeners();
  }

  Future<void> setBaseUrl(String url) async {
    _baseUrl = url.trim();
    if (_baseUrl.endsWith('/')) {
      _baseUrl = _baseUrl.substring(0, _baseUrl.length - 1);
    }
    await _prefs?.setString(_keyBaseUrl, _baseUrl);
    notifyListeners();
  }

  Future<void> setApiKey(String key) async {
    _apiKey = key.trim();
    await _prefs?.setString(_keyApiKey, _apiKey);
    notifyListeners();
  }

  Future<void> setSystemPrompt(String prompt) async {
    _systemPrompt = prompt.trim();
    await _prefs?.setString(_keySystemPrompt, _systemPrompt);
    notifyListeners();
  }

  Future<void> resetSystemPrompt() async {
    _systemPrompt = '';
    await _prefs?.remove(_keySystemPrompt);
    notifyListeners();
  }

  Future<void> setModel(String model) async {
    _model = model;
    await _prefs?.setString(_keyModel, _model);
    notifyListeners();
  }

  /// Fetches all available models from the OpenRouter API.
  Future<void> fetchAvailableModels() async {
    if (_isFetchingModels) return;

    _isFetchingModels = true;
    _modelsError = null;
    notifyListeners();

    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/models'),
            headers: {
              if (_apiKey.isNotEmpty) 'Authorization': 'Bearer $_apiKey',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as List;

        _availableModels = [
          const AiModel(
            id: 'openrouter/auto',
            name: 'Auto (OpenRouter)',
            description:
                'Automatically selects the best model for each request',
          ),
          ...data
              .map((m) => AiModel.fromJson(m as Map<String, dynamic>))
              .where((m) => m.id != 'openrouter/auto')
              .toList()
            ..sort((a, b) => a.name.compareTo(b.name)),
        ];
      } else {
        _modelsError = 'Errore ${response.statusCode}';
        debugPrint('Fetch models error: ${response.body}');
      }
    } catch (e) {
      _modelsError = 'Errore di connessione';
      debugPrint('Fetch models error: $e');
    }

    if (_availableModels.isEmpty) {
      _availableModels = fallbackAiModels;
    }

    _isFetchingModels = false;
    notifyListeners();
  }
}
