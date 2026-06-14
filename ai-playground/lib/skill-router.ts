import type { SkillEntry } from './skills';

function normalize(text: string): string {
  return text.toLowerCase().replace(/\s+/g, ' ').trim();
}

/** Seleziona la skill con punteggio keyword più alto, o `none`. */
export function routeSkill(message: string, skills: SkillEntry[]): string {
  const normalized = normalize(message);
  if (!normalized) {
    return 'none';
  }

  let bestId = 'none';
  let bestScore = 0;

  for (const skill of skills) {
    if (skill.id === 'none' || !skill.keywords?.length) {
      continue;
    }

    let score = 0;
    for (const keyword of skill.keywords) {
      const k = normalize(keyword);
      if (!k) {
        continue;
      }
      if (normalized.includes(k)) {
        score += k.length >= 8 ? 4 : 2;
      }
    }

    if (score > bestScore) {
      bestScore = score;
      bestId = skill.id;
    }
  }

  return bestScore > 0 ? bestId : 'none';
}
