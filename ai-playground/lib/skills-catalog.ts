import fs from 'node:fs';
import path from 'node:path';

import type { SkillEntry } from './skills';
import type { SkillsCatalogDoc, SkillsManifest } from './skills-catalog-types';

export type { ManifestSkill, SkillsCatalogDoc, SkillsManifest } from './skills-catalog-types';
export { SKILLS_CATALOG_PATH } from './skills-catalog-types';

const SKILLS_DIR = path.join(process.cwd(), 'skills-data');

export function stripFrontmatter(raw: string): string {
  const trimmed = raw.trimStart();
  if (!trimmed.startsWith('---')) {
    return raw.trim();
  }
  const end = trimmed.indexOf('---', 3);
  if (end === -1) {
    return raw.trim();
  }
  return trimmed.slice(end + 3).trim();
}

export function catalogToSkillEntries(catalog: SkillsCatalogDoc): SkillEntry[] {
  return catalog.manifest.skills.map((entry) => ({
    ...entry,
    promptBody: catalog.bodies[entry.id]?.trim() ?? '',
  }));
}

export function loadLocalCatalog(): SkillsCatalogDoc {
  const manifestPath = path.join(SKILLS_DIR, 'manifest.json');
  const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8')) as SkillsManifest;
  const bodies: Record<string, string> = {};

  for (const entry of manifest.skills) {
    if (!entry.file || entry.id === 'none') {
      continue;
    }
    const filePath = path.join(SKILLS_DIR, entry.file);
    if (fs.existsSync(filePath)) {
      bodies[entry.id] = stripFrontmatter(fs.readFileSync(filePath, 'utf8'));
    }
  }

  return {
    catalogVersion: manifest.version ?? 1,
    updatedAt: new Date().toISOString(),
    manifest,
    bodies,
  };
}

export function buildCatalogFromPayload(payload: {
  manifest: Omit<SkillsManifest, 'version'> & { version?: number };
  bodies: Record<string, string>;
  catalogVersion?: number;
}): SkillsCatalogDoc {
  const nextVersion =
    payload.catalogVersion != null
      ? payload.catalogVersion + 1
      : (payload.manifest.version ?? 1) + 1;

  return {
    catalogVersion: nextVersion,
    updatedAt: new Date().toISOString(),
    manifest: {
      ...payload.manifest,
      version: nextVersion,
    },
    bodies: payload.bodies,
  };
}
