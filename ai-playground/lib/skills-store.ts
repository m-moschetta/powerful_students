import { getFirestoreAdmin } from './firebase-admin';
import {
  catalogToSkillEntries,
  loadLocalCatalog,
  SKILLS_CATALOG_PATH,
  type SkillsCatalogDoc,
} from './skills-catalog';
import type { SkillEntry } from './skills';

let memoryCache: SkillEntry[] | null = null;
let memoryCatalog: SkillsCatalogDoc | null = null;

export function invalidateSkillsCache() {
  memoryCache = null;
  memoryCatalog = null;
}

export async function fetchCatalog(): Promise<SkillsCatalogDoc> {
  if (memoryCatalog) {
    return memoryCatalog;
  }

  const db = getFirestoreAdmin();
  if (db) {
    try {
      const snap = await db.doc(SKILLS_CATALOG_PATH).get();
      if (snap.exists) {
        const data = snap.data() as SkillsCatalogDoc;
        memoryCatalog = data;
        return data;
      }
    } catch (error) {
      console.error('Firestore skills read failed, fallback locale:', error);
    }
  }

  const local = loadLocalCatalog();
  memoryCatalog = local;
  return local;
}

export async function fetchSkillEntries(): Promise<SkillEntry[]> {
  if (memoryCache) {
    return memoryCache;
  }
  const catalog = await fetchCatalog();
  memoryCache = catalogToSkillEntries(catalog);
  return memoryCache;
}

export async function saveCatalog(
  catalog: SkillsCatalogDoc,
): Promise<SkillsCatalogDoc> {
  const db = getFirestoreAdmin();
  if (!db) {
    throw new Error('FIREBASE_SERVICE_ACCOUNT_JSON non configurato sul server.');
  }

  await db.doc(SKILLS_CATALOG_PATH).set(catalog, { merge: false });
  memoryCatalog = catalog;
  memoryCache = catalogToSkillEntries(catalog);
  return catalog;
}
