import 'package:flutter_test/flutter_test.dart';
import 'package:powerful_students/models/study_skill.dart';
import 'package:powerful_students/services/skill_router.dart';

void main() {
  const skills = [
    StudySkill(
      id: 'none',
      name: 'Generale',
      description: 'Default',
    ),
    StudySkill(
      id: 'procrastinazione',
      name: 'Procrastinazione',
      description: 'Rimandi',
      routingKeywords: ['procrastin', 'non ho voglia', 'ultimo momento'],
    ),
    StudySkill(
      id: 'esame-orale',
      name: 'Esame orale',
      description: 'Orale',
      routingKeywords: ['esame orale', 'interrog', 'ansia'],
    ),
  ];

  group('SkillRouter.route', () {
    test('sceglie procrastinazione', () {
      expect(
        SkillRouter.route('Ciao, non ho voglia di studiare', skills),
        'procrastinazione',
      );
    });

    test('sceglie esame orale', () {
      expect(
        SkillRouter.route('Ho paura dell\'esame orale di domani', skills),
        'esame-orale',
      );
    });

    test('fallback generale senza match', () {
      expect(
        SkillRouter.route('Spiegami la fotosintesi', skills),
        SkillRouter.idNone,
      );
    });
  });
}
