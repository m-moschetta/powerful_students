import { routeSkill } from './skill-router';
import { fetchSkillEntries } from './skills-store';

export type SkillEntry = {
  id: string;
  name: string;
  description: string;
  file?: string;
  keywords?: string[];
  promptBody?: string;
};

export const BASE_SYSTEM_PROMPT = `Sei **Powerful Buddy**, un assistente AI dedicato allo studio e all'apprendimento.

Regole:
- Rispondi in italiano, a meno che lo studente non chieda diversamente
- Usa markdown chiaro (titoli, elenchi, grassetto)
- Tono amichevole e incoraggiante, come un compagno di studio esperto
- Sii conciso ma utile`;

export async function loadSkills(): Promise<SkillEntry[]> {
  return fetchSkillEntries();
}

export async function resolveSkillId(
  skillId: string,
  userMessage?: string,
): Promise<string> {
  if (skillId !== 'auto') {
    return skillId;
  }
  if (!userMessage?.trim()) {
    return 'none';
  }
  return routeSkill(userMessage, await loadSkills());
}

export async function composeSystemPrompt(
  skillId: string,
  customPrompt?: string,
  userMessage?: string,
): Promise<string> {
  const custom = customPrompt?.trim();
  if (custom) {
    return custom;
  }
  const resolved = await resolveSkillId(skillId, userMessage);
  const base = BASE_SYSTEM_PROMPT.trim();
  if (resolved === 'none') {
    return base;
  }
  const skill = (await loadSkills()).find((s) => s.id === resolved);
  if (!skill?.promptBody?.trim()) {
    return base;
  }
  return `${base}\n\n---\n\n${skill.promptBody.trim()}`;
}

export { routeSkill };
