import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const source = path.resolve(__dirname, '../../skills');
const target = path.resolve(__dirname, '../skills-data');

function copyRecursive(src, dest) {
  fs.mkdirSync(dest, { recursive: true });
  for (const entry of fs.readdirSync(src, { withFileTypes: true })) {
    const from = path.join(src, entry.name);
    const to = path.join(dest, entry.name);
    if (entry.isDirectory()) {
      copyRecursive(from, to);
    } else {
      fs.copyFileSync(from, to);
    }
  }
}

const targetManifest = path.join(target, 'manifest.json');

if (!fs.existsSync(source)) {
  if (fs.existsSync(targetManifest)) {
    console.warn(
      'skills/ repo root assente — uso skills-data già presente (deploy Vercel).',
    );
    process.exit(0);
  }
  console.error('Cartella skills/ non trovata e skills-data vuota:', target);
  process.exit(1);
}

fs.rmSync(target, { recursive: true, force: true });
copyRecursive(source, target);
console.log('Skills copiate in ai-playground/skills-data');
