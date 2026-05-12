import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:powerful_students/core/design_system.dart';
import 'package:powerful_students/providers/settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  final _baseUrlController = TextEditingController();
  final _systemPromptController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _apiKeyController.text = settings.apiKey;
    _baseUrlController.text = settings.baseUrl;
    _systemPromptController.text = settings.effectiveSystemPrompt;

    // Fetch models if list is empty
    if (settings.availableModels.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        settings.fetchAvailableModels();
      });
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _systemPromptController.dispose();
    super.dispose();
  }

  void _saveSettings() async {
    final settings = context.read<SettingsProvider>();
    await settings.setApiKey(_apiKeyController.text);
    await settings.setBaseUrl(_baseUrlController.text);
    await settings.setSystemPrompt(_systemPromptController.text);

    HapticFeedback.heavyImpact();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Impostazioni salvate')));
      Navigator.pop(context);
    }
  }

  Future<void> _syncConnectionFields(SettingsProvider settings) async {
    if (_apiKeyController.text.trim() != settings.apiKey) {
      await settings.setApiKey(_apiKeyController.text);
    }
    if (_baseUrlController.text.trim() != settings.baseUrl) {
      await settings.setBaseUrl(_baseUrlController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CupertinoNavigationBar(
        middle: const Text('Impostazioni AI'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _saveSettings,
          child: const Text(
            'Salva',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      body: SafeArea(
        child: Consumer<SettingsProvider>(
          builder: (context, settings, _) {
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _buildSectionTitle('OpenRouter API'),
                _buildCard(
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _apiKeyController,
                        label: 'API Key',
                        placeholder: 'sk-or-v1-...',
                        isPassword: true,
                      ),
                      const Divider(height: 1, indent: 16),
                      _buildTextField(
                        controller: _baseUrlController,
                        label: 'Proxy URL',
                        placeholder: 'https://...',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('Modello AI'),
                _buildCard(
                  child: Column(
                    children: [
                      ListTile(
                        title: const Text(
                          'Seleziona Modello',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          settings.model,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        trailing: settings.isFetchingModels
                            ? const CupertinoActivityIndicator()
                            : const Icon(
                                CupertinoIcons.chevron_right,
                                size: 18,
                              ),
                        onTap: () async {
                          await _syncConnectionFields(settings);
                          if (!context.mounted) return;
                          _showModelSelector(context);
                        },
                      ),
                      if (settings.modelsError != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Text(
                            settings.modelsError!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('Personalizzazione'),
                _buildCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'System Prompt',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _systemPromptController,
                          maxLines: 5,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.separator,
                              ),
                            ),
                            filled: true,
                            fillColor: AppColors.background,
                          ),
                        ),
                        const SizedBox(height: 8),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            _systemPromptController.text =
                                SettingsProvider.defaultSystemPrompt;
                          },
                          child: const Text(
                            'Ripristina Default',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.separator),
        boxShadow: AppShadows.sm,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: child,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? placeholder,
    bool isPassword = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: isPassword,
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: placeholder,
                hintStyle: const TextStyle(
                  color: CupertinoColors.placeholderText,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showModelSelector(BuildContext context) {
    final settings = context.read<SettingsProvider>();
    if (!settings.isFetchingModels) {
      settings.fetchAvailableModels();
    }

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Material(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Container(
          height: 400,
          padding: const EdgeInsets.only(top: 6),
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Seleziona Modello',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Chiudi'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Consumer<SettingsProvider>(
                    builder: (context, settings, _) {
                      if (settings.availableModels.isEmpty &&
                          settings.isFetchingModels) {
                        return const Center(
                          child: CupertinoActivityIndicator(),
                        );
                      }

                      return Column(
                        children: [
                          if (settings.modelsError != null)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${settings.modelsError}. Mostro i modelli di base.',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  CupertinoButton(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    onPressed: settings.isFetchingModels
                                        ? null
                                        : settings.fetchAvailableModels,
                                    child: const Text(
                                      'Riprova',
                                      style: TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Expanded(
                            child: ListView.builder(
                              itemCount: settings.availableModels.length,
                              itemBuilder: (context, index) {
                                final model = settings.availableModels[index];
                                final isSelected = settings.model == model.id;
                                return ListTile(
                                  title: Text(
                                    model.name,
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                  subtitle: model.id.contains('/')
                                      ? Text(
                                          model.id,
                                          style: const TextStyle(fontSize: 12),
                                        )
                                      : null,
                                  trailing: isSelected
                                      ? const Icon(
                                          CupertinoIcons.check_mark,
                                          color: AppColors.primary,
                                        )
                                      : null,
                                  onTap: () {
                                    settings.setModel(model.id);
                                    Navigator.pop(context);
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
