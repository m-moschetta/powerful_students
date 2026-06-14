import { NextResponse } from 'next/server';

import {
  createTimeoutSignal,
  OPENROUTER_CHAT_URL,
  openRouterUpstreamHeaders,
  resolveOpenRouterApiKey,
} from '@/lib/openrouter';
import { chatRequestSchema } from '@/lib/schemas';
import { composeSystemPrompt } from '@/lib/skills';

export const runtime = 'nodejs';
export const maxDuration = 120;

export async function POST(request: Request) {
  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: 'Body JSON non valido' }, { status: 400 });
  }

  const parsed = chatRequestSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json({ error: 'Richiesta non valida' }, { status: 400 });
  }

  const apiKey = resolveOpenRouterApiKey();
  if (!apiKey) {
    return NextResponse.json(
      { error: 'OPENROUTER_API_KEY non configurata sul server.' },
      { status: 401 },
    );
  }

  const { model, messages, skillId, systemPrompt, temperature, stream } =
    parsed.data;

  const lastUser = [...messages].reverse().find((m) => m.role === 'user');
  const system = await composeSystemPrompt(
    skillId,
    systemPrompt,
    lastUser?.content,
  );
  const openRouterMessages = [
    { role: 'system' as const, content: system },
    ...messages,
  ];

  const payload: Record<string, unknown> = {
    model,
    messages: openRouterMessages,
    stream,
  };
  if (temperature !== undefined) {
    payload.temperature = temperature;
  }

  const upstream = await fetch(OPENROUTER_CHAT_URL, {
    method: 'POST',
    headers: openRouterUpstreamHeaders(apiKey),
    body: JSON.stringify(payload),
    signal: createTimeoutSignal(),
  });

  if (!upstream.ok) {
    const text = await upstream.text();
    return NextResponse.json(
      { error: 'OpenRouter ha rifiutato la richiesta', detail: text.slice(0, 2000) },
      { status: 502 },
    );
  }

  if (!stream) {
    return NextResponse.json(await upstream.json());
  }

  if (!upstream.body) {
    return NextResponse.json({ error: 'Stream mancante' }, { status: 502 });
  }

  return new Response(upstream.body, {
    headers: {
      'Content-Type':
        upstream.headers.get('content-type') ?? 'text/event-stream; charset=utf-8',
      'Cache-Control': 'no-cache, no-transform',
    },
  });
}
