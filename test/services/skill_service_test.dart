import 'package:flutter_test/flutter_test.dart';
import 'package:powerful_students/services/skill_service.dart';

void main() {
  group('SkillService.stripFrontmatter', () {
    test('rimuove il frontmatter YAML', () {
      const input = '''---
name: test
description: demo
---

# Corpo skill
<rule>Regola</rule>
''';
      expect(
        SkillService.stripFrontmatter(input),
        '# Corpo skill\n<rule>Regola</rule>',
      );
    });

    test('restituisce il testo se manca frontmatter', () {
      const input = '# Solo corpo';
      expect(SkillService.stripFrontmatter(input), '# Solo corpo');
    });
  });
}
