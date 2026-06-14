'use client';

import { useCallback, useEffect, useMemo, useRef, useState } from 'react';

import { SkillsEditor } from '@/app/components/skills-editor';
import { iterateChatCompletionStream } from '@/lib/sse-client';

type SkillMeta = { id: string; name: string; description: string };
type ChatMessage = { role: 'user' | 'assistant'; content: string };

const DEFAULT_MODEL = 'google/gemini-2.5-flash';

export default function Home() {
  const [tab, setTab] = useState<'chat' | 'skills'>('chat');
  const [skills, setSkills] = useState<SkillMeta[]>([]);
  const [skillId, setSkillId] = useState('auto');
  const [model, setModel] = useState(DEFAULT_MODEL);
  const [systemOverride, setSystemOverride] = useState('');
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [input, setInput] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [streaming, setStreaming] = useState(false);
  const [serverReady, setServerReady] = useState(false);
  const sendLock = useRef(false);

  const reloadSkillPicker = useCallback(() => {
    fetch('/api/skills')
      .then((r) => r.json())
      .then((d: { skills: SkillMeta[] }) => {
        setSkills(d.skills ?? []);
      });
  }, []);

  useEffect(() => {
    fetch('/api/config')
      .then((r) => r.json())
      .then((c: { serverKeyConfigured: boolean }) =>
        setServerReady(c.serverKeyConfigured),
      );
    reloadSkillPicker();
  }, [reloadSkillPicker]);

  const canSend = useMemo(
    () => serverReady && input.trim().length > 0 && !streaming,
    [serverReady, input, streaming],
  );

  const send = useCallback(async () => {
    const text = input.trim();
    if (!text || !canSend || sendLock.current) {
      return;
    }
    sendLock.current = true;
    setStreaming(true);
    setError(null);
    setInput('');

    const nextMessages: ChatMessage[] = [
      ...messages,
      { role: 'user', content: text },
    ];
    setMessages(nextMessages);
    const assistantIndex = nextMessages.length;
    setMessages([...nextMessages, { role: 'assistant', content: '' }]);

    try {
      const res = await fetch('/api/chat', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          model,
          messages: nextMessages,
          skillId,
          systemPrompt: systemOverride.trim() || undefined,
          stream: true,
        }),
      });

      if (!res.ok) {
        const err = (await res.json().catch(() => null)) as {
          detail?: string;
          error?: string;
        } | null;
        throw new Error(err?.detail ?? err?.error ?? `HTTP ${res.status}`);
      }

      if (!res.body) {
        throw new Error('Nessuno stream');
      }

      let acc = '';
      for await (const chunk of iterateChatCompletionStream(res.body)) {
        acc += chunk;
        setMessages((prev) => {
          const copy = [...prev];
          copy[assistantIndex] = { role: 'assistant', content: acc };
          return copy;
        });
      }
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Errore');
      setMessages((prev) => prev.slice(0, assistantIndex));
    } finally {
      setStreaming(false);
      sendLock.current = false;
    }
  }, [canSend, input, messages, model, skillId, systemOverride]);

  return (
    <div style={{ display: 'grid', gridTemplateColumns: '340px 1fr', minHeight: '100vh' }}>
      <aside style={{ borderRight: '1px solid var(--border)', padding: 16, background: 'var(--panel)', overflow: 'auto' }}>
        <h1 style={{ fontSize: 18, margin: '0 0 12px' }}>AI Playground</h1>
        <div style={{ display: 'flex', gap: 8, marginBottom: 12 }}>
          <button type="button" onClick={() => setTab('chat')} disabled={tab === 'chat'}>
            Chat
          </button>
          <button type="button" onClick={() => setTab('skills')} disabled={tab === 'skills'}>
            Skill
          </button>
        </div>

        {tab === 'chat' ? (
          <>
            {!serverReady ? (
              <p style={{ color: 'var(--danger)', fontSize: 13 }}>
                Imposta OPENROUTER_API_KEY su Vercel.
              </p>
            ) : (
              <p style={{ color: 'var(--accent)', fontSize: 13 }}>Chiave server OK</p>
            )}

            <label style={{ display: 'block', fontSize: 12, color: 'var(--muted)', marginTop: 12 }}>
              Skill
              <select
                value={skillId}
                onChange={(e) => setSkillId(e.target.value)}
                style={{ width: '100%', marginTop: 6, padding: 8, borderRadius: 8 }}
              >
                <option value="auto">Auto (routing keyword)</option>
                {skills.map((s) => (
                  <option key={s.id} value={s.id}>
                    {s.name}
                  </option>
                ))}
              </select>
            </label>

            <label style={{ display: 'block', fontSize: 12, color: 'var(--muted)', marginTop: 12 }}>
              Modello
              <input
                value={model}
                onChange={(e) => setModel(e.target.value)}
                style={{ width: '100%', marginTop: 6, padding: 8, borderRadius: 8 }}
              />
            </label>

            <label style={{ display: 'block', fontSize: 12, color: 'var(--muted)', marginTop: 12 }}>
              Override system prompt (opzionale)
              <textarea
                value={systemOverride}
                onChange={(e) => setSystemOverride(e.target.value)}
                rows={6}
                style={{ width: '100%', marginTop: 6, padding: 8, borderRadius: 8 }}
              />
            </label>
          </>
        ) : (
          <SkillsEditor />
        )}
      </aside>

      <main style={{ display: 'flex', flexDirection: 'column' }}>
        {tab === 'chat' ? (
          <>
            <div style={{ flex: 1, padding: 16, overflow: 'auto' }}>
              {error ? (
                <p style={{ color: 'var(--danger)' }}>Errore: {error}</p>
              ) : null}
              {messages.map((m, i) => (
                <div key={i} style={{ marginBottom: 12, whiteSpace: 'pre-wrap' }}>
                  <strong>{m.role === 'user' ? 'Tu' : 'AI'}:</strong> {m.content}
                </div>
              ))}
            </div>
            <footer style={{ padding: 12, borderTop: '1px solid var(--border)', display: 'flex', gap: 8 }}>
              <textarea
                value={input}
                onChange={(e) => setInput(e.target.value)}
                rows={2}
                disabled={streaming || !serverReady}
                placeholder="Scrivi un messaggio…"
                style={{ flex: 1, padding: 10, borderRadius: 8 }}
                onKeyDown={(e) => {
                  if (e.key === 'Enter' && !e.shiftKey) {
                    e.preventDefault();
                    void send();
                  }
                }}
              />
              <button type="button" disabled={!canSend} onClick={() => void send()}>
                Invia
              </button>
            </footer>
          </>
        ) : (
          <div style={{ padding: 16, color: 'var(--muted)', fontSize: 14 }}>
            <p style={{ marginTop: 0 }}>
              Usa la scheda <strong>Skill</strong> a sinistra per modificare manifest, keyword e corpo markdown.
              Dopo &quot;Pubblica su Firestore → App&quot;, l&apos;app Flutter aggiorna le skill in tempo reale (listener Firestore).
            </p>
            <button type="button" onClick={reloadSkillPicker}>
              Aggiorna elenco skill chat
            </button>
          </div>
        )}
      </main>
    </div>
  );
}
