/**
 * Pubblica skills/ locale su Firestore skills_catalog/current
 * Richiede FIREBASE_SERVICE_ACCOUNT_JSON nel env.
 *
 * Uso: FIREBASE_SERVICE_ACCOUNT_JSON='...' node scripts/publish-skills-firestore.mjs
 */
import admin from 'firebase-admin';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const skillsDir = path.resolve(__dirname, '../../skills');

function stripFrontmatter(raw) {
  const trimmed = raw.trimStart();
  if (!trimmed.startsWith('---')) return raw.trim();
  const end = trimmed.indexOf('---', 3);
  if (end === -1) return raw.trim();
  return trimmed.slice(end + 3).trim();
}

const rawCreds = process.env.FIREBASE_SERVICE_ACCOUNT_JSON?.trim();
if (!rawCreds) {
  console.error('Imposta FIREBASE_SERVICE_ACCOUNT_JSON');
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(JSON.parse(rawCreds)),
});

const manifest = JSON.parse(
  fs.readFileSync(path.join(skillsDir, 'manifest.json'), 'utf8'),
);
const bodies = {};
for (const entry of manifest.skills) {
  if (!entry.file || entry.id === 'none') continue;
  const filePath = path.join(skillsDir, entry.file);
  if (fs.existsSync(filePath)) {
    bodies[entry.id] = stripFrontmatter(fs.readFileSync(filePath, 'utf8'));
  }
}

const catalog = {
  catalogVersion: manifest.version ?? 1,
  updatedAt: new Date().toISOString(),
  manifest,
  bodies,
};

await admin.firestore().doc('skills_catalog/current').set(catalog);
console.log('Pubblicato skills_catalog/current v', catalog.catalogVersion);
