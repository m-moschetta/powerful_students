export type ManifestSkill = {
  id: string;
  name: string;
  description: string;
  file?: string;
  keywords?: string[];
};

export type SkillsManifest = {
  version: number;
  skills: ManifestSkill[];
};

export type SkillsCatalogDoc = {
  catalogVersion: number;
  updatedAt: string;
  manifest: SkillsManifest;
  bodies: Record<string, string>;
};

export const SKILLS_CATALOG_PATH = 'skills_catalog/current';
