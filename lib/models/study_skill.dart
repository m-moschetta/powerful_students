/// Istruzione modulare iniettata nel system prompt (contenuto di `skills/*/SKILL.md`).
class StudySkill {
  const StudySkill({
    required this.id,
    required this.name,
    required this.description,
    this.promptBody = '',
    this.routingKeywords = const [],
  });

  final String id;
  final String name;
  final String description;

  /// Corpo markdown senza frontmatter YAML.
  final String promptBody;

  /// Parole/frasi per il routing automatico (manifest `keywords`).
  final List<String> routingKeywords;

  bool get hasPromptBody => promptBody.trim().isNotEmpty;
}
