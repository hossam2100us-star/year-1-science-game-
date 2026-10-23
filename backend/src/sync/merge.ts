/**
 * Field-level three-way merge (Future System Architecture §14). Pure
 * functions: the same rules are unit-tested here and used by the sync
 * service. Device clocks never decide a winner; the order in which the
 * server receives changes does.
 */
export type FieldRule = 'identity' | 'lastReceived';

export interface MergeResult<T> {
  /** Server values after the merge. */
  next: T;
  /** Fields whose value changed on the server. */
  applied: (keyof T & string)[];
  /** Fields both sides changed differently and the server kept (identity fields). */
  conflicts: (keyof T & string)[];
  /** Server values replaced by a later change (low-value fields; recorded in the audit log). */
  overwritten: { field: keyof T & string; previous: unknown }[];
}

export function sameValue(a: unknown, b: unknown): boolean {
  return a === b || (a === null && b === undefined) || (a === undefined && b === null);
}

/**
 * @param current  the server's values now (version `currentVersion`)
 * @param patch    the device's new values for the fields it changed
 * @param base     what the device last saw for those fields (its baseVersion copy)
 * @param baseVersion / currentVersion  equal versions mean nothing changed in between
 */
export function mergeFields<T extends Record<string, unknown>>(
  current: T,
  patch: Partial<T>,
  base: Partial<T> | undefined,
  baseVersion: number,
  currentVersion: number,
  rules: Record<keyof T & string, FieldRule>,
): MergeResult<T> {
  const next = { ...current };
  const applied: (keyof T & string)[] = [];
  const conflicts: (keyof T & string)[] = [];
  const overwritten: { field: keyof T & string; previous: unknown }[] = [];
  const upToDate = baseVersion === currentVersion;

  for (const field of Object.keys(patch) as (keyof T & string)[]) {
    if (!(field in rules)) continue;
    const incoming = patch[field];
    const serverValue = current[field];
    if (sameValue(serverValue, incoming)) continue;
    const serverUnchanged =
      upToDate || (base !== undefined && field in base && sameValue(serverValue, base[field]));
    if (serverUnchanged) {
      next[field] = incoming as T[typeof field];
      applied.push(field);
    } else if (rules[field] === 'identity') {
      conflicts.push(field);
    } else {
      overwritten.push({ field, previous: serverValue });
      next[field] = incoming as T[typeof field];
      applied.push(field);
    }
  }
  return { next, applied, conflicts, overwritten };
}

/**
 * Child profile: name and gender are identity; avatar, colours and the
 * school year (a parent's later choice wins, ADR-0021) are low value.
 */
export const CHILD_RULES = {
  displayName: 'identity',
  gender: 'identity',
  avatar: 'lastReceived',
  palette: 'lastReceived',
  schoolYear: 'lastReceived',
} as const satisfies Record<string, FieldRule>;

/** Settings are all low value: the later change wins and the old value is audited. */
export const SETTINGS_RULES = {
  arabic: 'lastReceived',
  breakMinutes: 'lastReceived',
  sound: 'lastReceived',
  music: 'lastReceived',
  narration: 'lastReceived',
  volume: 'lastReceived',
  boyVoice: 'lastReceived',
  girlVoice: 'lastReceived',
} as const satisfies Record<string, FieldRule>;

/** Per-device play-time counter (G-counter): never decreases. */
export function mergeUsage(existing: number | undefined, incoming: number): number {
  return Math.max(existing ?? 0, incoming);
}

/** Attempts are immutable: a repeat is a duplicate only if every field matches. */
export function sameAttempt(
  a: { objectives: Record<string, string> } & Record<string, unknown>,
  b: { objectives: Record<string, string> } & Record<string, unknown>,
): boolean {
  const scalar = [
    'curriculum',
    'unitId',
    'contentVersion',
    'completed',
    'effortStars',
    'completedAt',
    'clientAttemptId',
  ];
  if (!scalar.every((k) => a[k] === b[k])) return false;
  const ak = Object.keys(a.objectives).sort();
  const bk = Object.keys(b.objectives).sort();
  return (
    ak.length === bk.length &&
    ak.every((k, i) => k === bk[i] && a.objectives[k] === b.objectives[k])
  );
}
