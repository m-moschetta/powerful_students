import 'package:powerful_students/models/study_skill.dart';

/// Seleziona la skill più pertinente in base al messaggio utente (keyword scoring).
class SkillRouter {
  SkillRouter._();

  static const idNone = 'none';

  /// Restituisce l'id skill con punteggio più alto, o [idNone] se nessun match.
  static String route(String message, List<StudySkill> skills) {
    final normalized = _normalize(message);
    if (normalized.isEmpty) {
      return idNone;
    }

    var bestId = idNone;
    var bestScore = 0;

    for (final skill in skills) {
      if (skill.id == idNone || skill.routingKeywords.isEmpty) {
        continue;
      }

      var score = 0;
      for (final keyword in skill.routingKeywords) {
        final k = _normalize(keyword);
        if (k.isEmpty) {
          continue;
        }
        if (normalized.contains(k)) {
          // Frasi lunghe pesano di più delle singole parole corte.
          score += k.length >= 8 ? 4 : 2;
        }
      }

      if (score > bestScore) {
        bestScore = score;
        bestId = skill.id;
      }
    }

    return bestScore > 0 ? bestId : idNone;
  }

  static String _normalize(String text) {
    return text.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
