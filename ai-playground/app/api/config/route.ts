import { NextResponse } from 'next/server';

import { isFirebaseAdminConfigured } from '@/lib/firebase-admin';

export const runtime = 'nodejs';

export async function GET() {
  return NextResponse.json({
    serverKeyConfigured: Boolean(process.env.OPENROUTER_API_KEY?.trim()),
    skillsRemoteWriteEnabled: isFirebaseAdminConfigured(),
    skillsAdminConfigured: Boolean(process.env.PLAYGROUND_ADMIN_SECRET?.trim()),
  });
}
