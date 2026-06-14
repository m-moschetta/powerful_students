'use client';

import { useCallback, useEffect, useMemo, useState } from 'react';

import type { SkillsCatalogDoc } from '@/lib/skills-catalog-types';

type EditorSkill = {
  id: string;
  name: string;
  description: string;
  keywordsText: string;
  promptBody: string;
};

const ADMIN_TOKEN_KEY = 'playground_admin_token';

function catalogToEditorSkills(catalog: SkillsCatalogDoc): EditorSkill[] {
  return catalog.manifest.skills
    .filter((s) => s.id !== 'none')
    .map((s) => ({
      id: s.id,
      name: s.name,
      description: s.description,
      keywordsText: (s.keywords ?? []).join('\n'),
      promptBody: catalog.bodies[s.id] ?? '',
    }));
}

function editorSkillsToPayload(
  allManifestSkills: SkillsCatalogDoc['manifest']['skills'],
  editorSkills: EditorSkill[],
): Pick<SkillsCatalogDoc, 'manifest' | 'bodies'> {
  const bodies: Record<string, string> = {};
  const byId = new Map(editorSkills.map((s) => [s.id, s]));

  const skills = allManifestSkills.map((entry) => {
    const edited = byId.get(entry.id);
    if (!edited) {
      return entry;
    }
    const keywords = edited.keywordsText
      .split('\n')
      .map((k) => k.trim())
      .filter(Boolean);
    return {
      ...entry,
      name: edited.name.trim() || entry.name,
      description: edited.description.trim() || entry.description,
      keywords,
    };
  });

  for (const skill of editorSkills) {
    if (skill.promptBody.trim()) {
      bodies[skill.id] = skill.promptBody.trim();
    }
  }

  return {
    manifest: { version: 1, skills },
    bodies,
  };
}

export function SkillsEditor() {
  const [catalog, setCatalog] = useState<SkillsCatalogDoc | null>(null);
  const [editorSkills, setEditorSkills] = useState<EditorSkill[]>([]);
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [adminToken, setAdminToken] = useState('');
  const [status, setStatus] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [remoteWriteEnabled, setRemoteWriteEnabled] = useState(false);

  const loadCatalog = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await fetch('/api/skills?full=1');
      if (!res.ok) {
        throw new Error(`HTTP ${res.status}`);
      }
      const data = (await res.json()) as {
        catalog: SkillsCatalogDoc;
        remoteWriteEnabled?: boolean;
      };
      setCatalog(data.catalog);
      setRemoteWriteEnabled(Boolean(data.remoteWriteEnabled));
      const editable = catalogToEditorSkills(data.catalog);
      setEditorSkills(editable);
      setSelectedId((prev) => prev ?? editable[0]?.id ?? null);
      setStatus(
        `Catalogo v${data.catalog.catalogVersion} · aggiornato ${new Date(data.catalog.updatedAt).toLocaleString('it-IT')}`,
      );
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Errore caricamento');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    const saved = sessionStorage.getItem(ADMIN_TOKEN_KEY);
    if (saved) {
      setAdminToken(saved);
    }
    void loadCatalog();
  }, [loadCatalog]);

  const selected = useMemo(
    () => editorSkills.find((s) => s.id === selectedId) ?? null,
    [editorSkills, selectedId],
  );

  const updateSelected = (patch: Partial<EditorSkill>) => {
    if (!selectedId) {
      return;
    }
    setEditorSkills((prev) =>
      prev.map((s) => (s.id === selectedId ? { ...s, ...patch } : s)),
    );
  };

  const publish = async () => {
    if (!catalog || !adminToken.trim()) {
      setError('Inserisci il token admin (PLAYGROUND_ADMIN_SECRET).');
      return;
    }
    setSaving(true);
    setError(null);
    sessionStorage.setItem(ADMIN_TOKEN_KEY, adminToken.trim());

    try {
      const payload = editorSkillsToPayload(catalog.manifest.skills, editorSkills);
      const res = await fetch('/api/skills', {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${adminToken.trim()}`,
        },
        body: JSON.stringify(payload),
      });
      const data = (await res.json().catch(() => null)) as {
        error?: string;
        detail?: string;
        catalog?: SkillsCatalogDoc;
      } | null;
      if (!res.ok) {
        throw new Error(data?.detail ?? data?.error ?? `HTTP ${res.status}`);
      }
      if (data?.catalog) {
        setCatalog(data.catalog);
        setEditorSkills(catalogToEditorSkills(data.catalog));
        setStatus(
          `Pubblicato v${data.catalog.catalogVersion} su Firestore · l'app Flutter si aggiorna in tempo reale`,
        );
      }
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Pubblicazione fallita');
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return <p style={{ fontSize: 13, color: 'var(--muted)' }}>Caricamento skill…</p>;
  }

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
      <p style={{ fontSize: 12, color: 'var(--muted)', margin: 0 }}>
        Modifica le skill e pubblica su Firestore. L&apos;app mobile le riceve via sync remoto.
      </p>
      {!remoteWriteEnabled ? (
        <p style={{ fontSize: 12, color: 'var(--danger)', margin: 0 }}>
          FIREBASE_SERVICE_ACCOUNT_JSON non configurato: puoi editare in locale ma non pubblicare.
        </p>
      ) : null}
      {status ? (
        <p style={{ fontSize: 12, color: 'var(--accent)', margin: 0 }}>{status}</p>
      ) : null}
      {error ? (
        <p style={{ fontSize: 12, color: 'var(--danger)', margin: 0 }}>{error}</p>
      ) : null}

      <label style={{ fontSize: 12, color: 'var(--muted)' }}>
        Token admin
        <input
          type="password"
          value={adminToken}
          onChange={(e) => setAdminToken(e.target.value)}
          placeholder="PLAYGROUND_ADMIN_SECRET"
          style={{ width: '100%', marginTop: 4, padding: 8, borderRadius: 8 }}
        />
      </label>

      <label style={{ fontSize: 12, color: 'var(--muted)' }}>
        Skill
        <select
          value={selectedId ?? ''}
          onChange={(e) => setSelectedId(e.target.value)}
          style={{ width: '100%', marginTop: 4, padding: 8, borderRadius: 8 }}
        >
          {editorSkills.map((s) => (
            <option key={s.id} value={s.id}>
              {s.name}
            </option>
          ))}
        </select>
      </label>

      {selected ? (
        <>
          <label style={{ fontSize: 12, color: 'var(--muted)' }}>
            Nome
            <input
              value={selected.name}
              onChange={(e) => updateSelected({ name: e.target.value })}
              style={{ width: '100%', marginTop: 4, padding: 8, borderRadius: 8 }}
            />
          </label>
          <label style={{ fontSize: 12, color: 'var(--muted)' }}>
            Descrizione
            <input
              value={selected.description}
              onChange={(e) => updateSelected({ description: e.target.value })}
              style={{ width: '100%', marginTop: 4, padding: 8, borderRadius: 8 }}
            />
          </label>
          <label style={{ fontSize: 12, color: 'var(--muted)' }}>
            Keyword routing (una per riga)
            <textarea
              value={selected.keywordsText}
              onChange={(e) => updateSelected({ keywordsText: e.target.value })}
              rows={4}
              style={{ width: '100%', marginTop: 4, padding: 8, borderRadius: 8 }}
            />
          </label>
          <label style={{ fontSize: 12, color: 'var(--muted)' }}>
            Corpo skill (markdown)
            <textarea
              value={selected.promptBody}
              onChange={(e) => updateSelected({ promptBody: e.target.value })}
              rows={10}
              style={{ width: '100%', marginTop: 4, padding: 8, borderRadius: 8, fontFamily: 'monospace' }}
            />
          </label>
        </>
      ) : null}

      <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
        <button type="button" onClick={() => void loadCatalog()} disabled={loading}>
          Ricarica
        </button>
        <button
          type="button"
          onClick={() => void publish()}
          disabled={saving || !remoteWriteEnabled}
        >
          {saving ? 'Pubblicazione…' : 'Pubblica su Firestore → App'}
        </button>
      </div>
    </div>
  );
}
