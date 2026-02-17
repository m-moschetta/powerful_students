import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:powerful_students/core/design_system.dart';
import 'package:powerful_students/providers/settings_provider.dart';

class DevSettingsScreen extends StatefulWidget {
  const DevSettingsScreen({super.key});

  @override
  State<DevSettingsScreen> createState() => _DevSettingsScreenState();
}

class _DevSettingsScreenState extends State<DevSettingsScreen> {
  final _apiKeyController = TextEditingController();
  final _systemPromptController = TextEditingController();
  final _modelSearchController = TextEditingController();
  bool _obscureApiKey = true;
  String _modelSearchQuery = '';

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _apiKeyController.text = settings.apiKey;
    _systemPromptController.text = settings.systemPrompt;
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _systemPromptController.dispose();
    _modelSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Consumer<SettingsProvider>(
          builder: (context, settings, _) {
            return Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    children: [
                      const SizedBox(height: AppSpacing.sm),
                      _buildSectionHeader('API KEY'),
                      const SizedBox(height: AppSpacing.xs),
                      _buildApiKeyField(settings),
                      const SizedBox(height: AppSpacing.md),
                      _buildSectionHeader('MODELLO / MODEL'),
                      const SizedBox(height: AppSpacing.xs),
                      _buildModelSelector(settings),
                      const SizedBox(height: AppSpacing.md),
                      _buildSectionHeader('SYSTEM PROMPT'),
                      const SizedBox(height: AppSpacing.xs),
                      _buildSystemPromptField(settings),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.pop(context),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(AppIcons.back, size: 28, color: AppColors.textPrimary),
                SizedBox(width: 4),
                Text(
                  'Indietro',
                  style: TextStyle(
                    fontSize: 17,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Expanded(
            child: Text(
              'Dev Settings',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 80),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTypography.label.copyWith(
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildApiKeyField(SettingsProvider settings) {
    return AppDecorations.glassContainer(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'OpenRouter API Key',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ottieni la chiave su openrouter.ai/settings/keys',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _apiKeyController,
                  obscureText: _obscureApiKey,
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Menlo',
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'sk-or-...',
                    hintStyle: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.4),
                      fontSize: 14,
                      fontFamily: 'Menlo',
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      borderSide: const BorderSide(
                        color: AppColors.glassBorder,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      borderSide: const BorderSide(
                        color: AppColors.glassBorder,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    suffixIcon: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        setState(() => _obscureApiKey = !_obscureApiKey);
                      },
                      child: Icon(
                        _obscureApiKey
                            ? CupertinoIcons.eye_slash
                            : CupertinoIcons.eye,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 10),
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              onPressed: () {
                HapticFeedback.mediumImpact();
                settings.setApiKey(_apiKeyController.text);
                FocusScope.of(context).unfocus();
                _showSnackBar('API key salvata');
              },
              child: const Text(
                'Salva',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelSelector(SettingsProvider settings) {
    final hasRemoteModels = settings.availableModels.isNotEmpty;

    // Determine the list to display
    List<_ModelEntry> models;
    if (hasRemoteModels) {
      models = settings.availableModels
          .where((m) =>
              _modelSearchQuery.isEmpty ||
              m.name
                  .toLowerCase()
                  .contains(_modelSearchQuery.toLowerCase()) ||
              m.id.toLowerCase().contains(_modelSearchQuery.toLowerCase()))
          .map((m) => _ModelEntry(id: m.id, name: m.name))
          .toList();
    } else {
      models = SettingsProvider.fallbackModels
          .map((id) => _ModelEntry(id: id, name: _formatModelName(id)))
          .toList();
    }

    return AppDecorations.glassContainer(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Modello AI',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Seleziona il modello per il Buddy',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                color: AppColors.cta,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                onPressed: settings.isFetchingModels
                    ? null
                    : () {
                        HapticFeedback.mediumImpact();
                        settings.fetchAvailableModels();
                      },
                child: settings.isFetchingModels
                    ? const CupertinoActivityIndicator()
                    : const Text(
                        'Fetch',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
              ),
            ],
          ),
          if (settings.modelsError != null) ...[
            const SizedBox(height: 8),
            Text(
              settings.modelsError!,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (hasRemoteModels) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _modelSearchController,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Cerca modello...',
                hintStyle: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.4),
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  CupertinoIcons.search,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  borderSide: const BorderSide(
                    color: AppColors.glassBorder,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  borderSide: const BorderSide(
                    color: AppColors.glassBorder,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              onChanged: (v) => setState(() => _modelSearchQuery = v),
            ),
            const SizedBox(height: 4),
            Text(
              '${settings.availableModels.length} modelli disponibili',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary.withValues(alpha: 0.6),
              ),
            ),
          ],
          const SizedBox(height: 8),
          // Current model display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                color: AppColors.primary,
                width: 1,
              ),
            ),
            child: Text(
              'Attuale: ${settings.model}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Model list (limited height with scroll)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: models.length,
              itemBuilder: (context, index) {
                final m = models[index];
                final isSelected = settings.model == m.id;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    settings.setModel(m.id);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 12,
                    ),
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: isSelected
                          ? Border.all(
                              color: AppColors.textPrimary,
                              width: 1.5,
                            )
                          : null,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                m.id,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            AppIcons.check,
                            size: 20,
                            color: AppColors.primary,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemPromptField(SettingsProvider settings) {
    return AppDecorations.glassContainer(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'System Prompt',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            settings.hasCustomSystemPrompt
                ? 'Prompt personalizzato attivo'
                : 'Usando il prompt predefinito',
            style: TextStyle(
              fontSize: 13,
              color: settings.hasCustomSystemPrompt
                  ? AppColors.primary
                  : AppColors.textSecondary.withValues(alpha: 0.7),
              fontWeight: settings.hasCustomSystemPrompt
                  ? FontWeight.w600
                  : FontWeight.w400,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _systemPromptController,
            maxLines: 8,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
            decoration: InputDecoration(
              hintText: 'Inserisci un system prompt personalizzato...',
              hintStyle: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.4),
                fontSize: 14,
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                borderSide: const BorderSide(
                  color: AppColors.glassBorder,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                borderSide: const BorderSide(
                  color: AppColors.glassBorder,
                ),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  color: AppColors.glass(0.3),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    _systemPromptController.clear();
                    settings.resetSystemPrompt();
                    _showSnackBar('Prompt ripristinato');
                  },
                  child: const Text(
                    'Reset',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    settings.setSystemPrompt(_systemPromptController.text);
                    FocusScope.of(context).unfocus();
                    _showSnackBar('System prompt salvato');
                  },
                  child: const Text(
                    'Salva',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatModelName(String modelId) {
    if (modelId == 'openrouter/auto') return 'Auto (Recommended)';
    final parts = modelId.split('/');
    if (parts.length == 2) {
      final provider = parts[0][0].toUpperCase() + parts[0].substring(1);
      return '$provider — ${parts[1]}';
    }
    return modelId;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _ModelEntry {
  final String id;
  final String name;
  const _ModelEntry({required this.id, required this.name});
}
