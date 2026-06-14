export const OPENROUTER_CHAT_URL =
  'https://openrouter.ai/api/v1/chat/completions';

export const OPENROUTER_MODELS_URL = 'https://openrouter.ai/api/v1/models';

export function normalizeApiKey(raw: string): string {
  return raw.replace(/[\u200B-\u200D\uFEFF]/g, '').replace(/\s+/g, '').trim();
}

export function refererUrlFromEnv(): string {
  if (process.env.NEXT_PUBLIC_APP_URL) {
    return process.env.NEXT_PUBLIC_APP_URL;
  }
  if (process.env.VERCEL_URL) {
    return `https://${process.env.VERCEL_URL}`;
  }
  return 'http://localhost:3000';
}

export function openRouterUpstreamHeaders(apiKey: string): Headers {
  const key = normalizeApiKey(apiKey);
  const h = new Headers();
  h.set('Authorization', `Bearer ${key}`);
  h.set('Content-Type', 'application/json');
  h.set('HTTP-Referer', refererUrlFromEnv());
  h.set('X-OpenRouter-Title', 'AI Playground');
  return h;
}

export function resolveOpenRouterApiKey(): string | null {
  const envKey = process.env.OPENROUTER_API_KEY?.trim();
  if (!envKey) {
    return null;
  }
  return normalizeApiKey(envKey);
}

export function createTimeoutSignal(ms = 120_000): AbortSignal {
  const controller = new AbortController();
  setTimeout(() => controller.abort(), ms);
  return controller.signal;
}
