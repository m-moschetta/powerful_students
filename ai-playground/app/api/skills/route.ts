import { NextResponse } from 'next/server';

import { isFirebaseAdminConfigured } from '@/lib/firebase-admin';
import {
  buildCatalogFromPayload,
  type SkillsCatalogDoc,
} from '@/lib/skills-catalog';
import { fetchCatalog, invalidateSkillsCache, saveCatalog } from '@/lib/skills-store';
import { skillsCatalogPutSchema } from '@/lib/schemas';

export const runtime = 'nodejs';

function verifyAdmin(request: Request): boolean {
  const secret = process.env.PLAYGROUND_ADMIN_SECRET?.trim();
  if (!secret) {
    return false;
  }
  const auth = request.headers.get('authorization') ?? '';
  const token = auth.startsWith('Bearer ') ? auth.slice(7).trim() : '';
  return token.length > 0 && token === secret;
}

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const full = searchParams.get('full') === '1';

  try {
    const catalog = await fetchCatalog();
    if (full) {
      return NextResponse.json({
        catalog,
        source: isFirebaseAdminConfigured() ? 'firestore-or-local' : 'local',
        remoteWriteEnabled: isFirebaseAdminConfigured(),
      });
    }

    const skills = catalog.manifest.skills.map(({ id, name, description }) => ({
      id,
      name,
      description,
    }));
    return NextResponse.json({
      skills,
      catalogVersion: catalog.catalogVersion,
    });
  } catch (error) {
    return NextResponse.json(
      {
        error: 'Impossibile caricare le skill',
        detail: error instanceof Error ? error.message : String(error),
      },
      { status: 500 },
    );
  }
}

export async function PUT(request: Request) {
  if (!verifyAdmin(request)) {
    return NextResponse.json(
      { error: 'Non autorizzato. Header Authorization: Bearer <PLAYGROUND_ADMIN_SECRET>.' },
      { status: 401 },
    );
  }

  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: 'Body JSON non valido' }, { status: 400 });
  }

  const parsed = skillsCatalogPutSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json({ error: 'Payload skill non valido' }, { status: 400 });
  }

  try {
    const current = await fetchCatalog();
    const catalog: SkillsCatalogDoc = buildCatalogFromPayload({
      manifest: parsed.data.manifest,
      bodies: parsed.data.bodies,
      catalogVersion: current.catalogVersion,
    });

    await saveCatalog(catalog);
    invalidateSkillsCache();

    return NextResponse.json({
      ok: true,
      catalog,
    });
  } catch (error) {
    return NextResponse.json(
      {
        error: 'Pubblicazione skill fallita',
        detail: error instanceof Error ? error.message : String(error),
      },
      { status: 502 },
    );
  }
}
