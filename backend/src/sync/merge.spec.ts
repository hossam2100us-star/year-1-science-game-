import { CHILD_RULES, mergeFields, mergeUsage, sameAttempt, SETTINGS_RULES } from './merge';

type Obj = Record<string, unknown>;

const child = { displayName: 'Nour', gender: 'girl', avatar: 1, palette: 'ocean' } as Record<
  string,
  unknown
>;
const settings = {
  arabic: true,
  breakMinutes: 12,
  sound: true,
  music: true,
  narration: true,
  volume: 0.85,
  boyVoice: null,
  girlVoice: null,
} as Record<string, unknown>;

describe('mergeFields (§14 field-level three-way merge)', () => {
  it('applies every field when nothing changed on the server since the base', () => {
    const r = mergeFields(child, { displayName: 'Nora', avatar: 2 }, undefined, 3, 3, CHILD_RULES);
    expect(r.next).toEqual({ ...child, displayName: 'Nora', avatar: 2 });
    expect(r.applied.sort()).toEqual(['avatar', 'displayName']);
    expect(r.conflicts).toEqual([]);
  });

  it('applies disjoint edits from two devices automatically', () => {
    // Server (v4) has the web edit palette=berry; the phone edited avatar from base v3.
    const server: Obj = { ...child, palette: 'berry' };
    const r = mergeFields(server, { avatar: 2 }, { avatar: 1 }, 3, 4, CHILD_RULES);
    expect(r.next).toEqual({ ...server, avatar: 2 });
    expect(r.conflicts).toEqual([]);
    expect(r.overwritten).toEqual([]);
  });

  it('keeps the server name and reports a conflict when both renamed the child', () => {
    const server: Obj = { ...child, displayName: 'Nouran' };
    const r = mergeFields(
      server,
      { displayName: 'Noura' },
      { displayName: 'Nour' },
      3,
      4,
      CHILD_RULES,
    );
    expect(r.next.displayName).toBe('Nouran');
    expect(r.conflicts).toEqual(['displayName']);
    expect(r.applied).toEqual([]);
  });

  it('lets the later change win for a low-value field and records the old value', () => {
    const server: Obj = { ...child, palette: 'berry' };
    const r = mergeFields(server, { palette: 'forest' }, { palette: 'ocean' }, 3, 4, CHILD_RULES);
    expect(r.next.palette).toBe('forest');
    expect(r.overwritten).toEqual([{ field: 'palette', previous: 'berry' }]);
  });

  it('treats a field with no base value as changed on both sides', () => {
    const server: Obj = { ...settings, volume: 0.5 };
    const r = mergeFields(server, { volume: 0.2 }, undefined, 1, 2, SETTINGS_RULES);
    expect(r.next.volume).toBe(0.2);
    expect(r.overwritten).toEqual([{ field: 'volume', previous: 0.5 }]);
  });

  it('does nothing when the device sends the value the server already has', () => {
    const r = mergeFields(
      child,
      { displayName: 'Nour' },
      { displayName: 'Nadia' },
      1,
      5,
      CHILD_RULES,
    );
    expect(r.applied).toEqual([]);
    expect(r.conflicts).toEqual([]);
  });

  it('treats null and missing voices as the same value', () => {
    const r = mergeFields(settings, { boyVoice: null }, undefined, 1, 2, SETTINGS_RULES);
    expect(r.applied).toEqual([]);
  });

  it('ignores fields that are not part of the entity', () => {
    const r = mergeFields(child, { photo: 'x' }, undefined, 1, 1, CHILD_RULES);
    expect(r.next).toEqual(child);
  });

  it('never loses either side: every patched field is applied, kept as a conflict, or already equal', () => {
    const fields = ['displayName', 'gender', 'avatar', 'palette'] as const;
    const values = {
      displayName: ['Nour', 'Nora', 'Nadia'],
      gender: ['boy', 'girl'],
      avatar: [0, 1, 2],
      palette: ['automatic', 'ocean', 'berry'],
    } as Record<string, unknown[]>;
    let seed = 7;
    const pick = (list: unknown[]) =>
      list[(seed = (seed * 1103515245 + 12345) % 2 ** 31) % list.length];
    for (let i = 0; i < 2000; i++) {
      const server: Record<string, unknown> = {};
      const base: Record<string, unknown> = {};
      const patch: Record<string, unknown> = {};
      for (const f of fields) {
        server[f] = pick(values[f]!);
        base[f] = pick(values[f]!);
        if (pick([true, false])) patch[f] = pick(values[f]!);
      }
      const r = mergeFields(server, patch, base, 1, 2, CHILD_RULES);
      for (const f of Object.keys(patch)) {
        const accounted =
          r.applied.includes(f) || r.conflicts.includes(f) || r.next[f] === patch[f];
        expect(accounted).toBe(true);
        if (r.conflicts.includes(f)) expect(r.next[f]).toBe(server[f]);
        if (r.applied.includes(f)) expect(r.next[f]).toBe(patch[f]);
      }
      for (const f of fields) if (!(f in patch)) expect(r.next[f]).toBe(server[f]);
    }
  });
});

describe('mergeUsage (per-device G-counter)', () => {
  it('never goes backwards, so replays and reordering are harmless', () => {
    expect(mergeUsage(undefined, 30)).toBe(30);
    expect(mergeUsage(120, 60)).toBe(120);
    expect(mergeUsage(60, 120)).toBe(120);
  });
});

describe('sameAttempt', () => {
  const a = {
    curriculum: 'y1.science',
    unitId: 'unit_01',
    contentVersion: 1,
    completed: true,
    effortStars: 3,
    completedAt: '2026-10-05T04:05:12.123456',
    clientAttemptId: 'unit_01-1791162037776000',
    objectives: { 'o.1': 'firstTry', 'o.2': 'afterHint' },
  };

  it('matches the same attempt regardless of objective order', () => {
    expect(sameAttempt(a, { ...a, objectives: { 'o.2': 'afterHint', 'o.1': 'firstTry' } })).toBe(
      true,
    );
  });

  it('detects any difference', () => {
    expect(sameAttempt(a, { ...a, effortStars: 2 })).toBe(false);
    expect(sameAttempt(a, { ...a, objectives: { 'o.1': 'firstTry' } })).toBe(false);
    expect(sameAttempt(a, { ...a, objectives: { 'o.1': 'explained', 'o.2': 'afterHint' } })).toBe(
      false,
    );
  });
});
