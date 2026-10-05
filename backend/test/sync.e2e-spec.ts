import { attemptPayload, Harness, uuidv7 } from './support/harness';

type Session = Awaited<ReturnType<Harness['parent']>>;
interface Result {
  mutationId: string;
  status: string;
  version?: number;
  changeSeq?: number;
  conflictFields?: string[];
  server?: Record<string, unknown> | null;
  error?: { code: string };
}
interface Change {
  entity: string;
  op: string;
  changeSeq: number;
  [key: string]: unknown;
}

describe('Offline-first sync (§12, §14)', () => {
  let h: Harness;
  let phone: Session;
  let web: { token: string; deviceId: string };

  beforeAll(async () => {
    h = await Harness.start();
  });
  afterAll(() => h.stop());
  beforeEach(async () => {
    await h.reset();
    phone = await h.parent('parent@example.com');
    const second = await h.login('parent@example.com', undefined, 'web');
    web = { token: second.accessToken, deviceId: second.deviceId };
  });

  const push = async (
    who: { token: string; deviceId: string },
    mutations: unknown[],
  ): Promise<Result[]> => {
    const res = await h.call('POST', '/api/v1/sync/push', {
      token: who.token,
      body: { deviceId: who.deviceId, mutations },
    });
    if (res.status !== 200) throw new Error(`push ${res.status} ${JSON.stringify(res.body)}`);
    return res.body.results as Result[];
  };
  const pullAll = async (who: { token: string }, since = 0, limit = 500) => {
    const changes: Change[] = [];
    let cursor = since;
    for (;;) {
      const res = await h.call('GET', `/api/v1/sync/pull?since=${cursor}&limit=${limit}`, {
        token: who.token,
      });
      if (res.status !== 200) throw new Error(`pull ${res.status} ${JSON.stringify(res.body)}`);
      changes.push(...(res.body.changes as Change[]));
      cursor = res.body.cursor as number;
      if (!res.body.hasMore) return { changes, cursor };
    }
  };
  const createChild = (id = uuidv7(), fields: Record<string, unknown> = {}) => ({
    mutationId: uuidv7(),
    entity: 'child',
    op: 'create',
    id,
    payload: { displayName: 'Nour', gender: 'girl', avatar: 1, palette: 'ocean', ...fields },
  });

  it('uploads a whole family offline and another device downloads it in order', async () => {
    const childId = uuidv7();
    const results = await push(phone, [
      createChild(childId),
      {
        mutationId: uuidv7(),
        entity: 'attempt',
        op: 'create',
        id: uuidv7(),
        childId,
        payload: attemptPayload(),
      },
      {
        mutationId: uuidv7(),
        entity: 'journey',
        op: 'put',
        childId,
        curriculum: 'y1.science',
        key: 'unit_01.garden',
        baseVersion: 0,
        payload: { state: { found: ['cat', 'bird', 'car'] }, contentVersion: 1 },
      },
      {
        mutationId: uuidv7(),
        entity: 'usage',
        op: 'put',
        childId,
        day: '2026-10-05',
        payload: { seconds: 300 },
      },
    ]);
    expect(results.map((r) => r.status)).toEqual(['applied', 'applied', 'applied', 'applied']);

    const { changes, cursor } = await pullAll(web);
    expect(changes.map((c) => c.entity)).toEqual([
      'child',
      'settings',
      'attempt',
      'journey',
      'usage',
    ]);
    const seqs = changes.map((c) => c.changeSeq);
    expect([...seqs].sort((a, b) => a - b)).toEqual(seqs);
    expect(cursor).toBe(seqs.at(-1));
    expect(changes[0]).toMatchObject({ op: 'upsert', id: childId, data: { displayName: 'Nour' } });
    expect(changes[2]!.data).toEqual(attemptPayload());
    expect(changes[3]).toMatchObject({
      key: 'unit_01.garden',
      version: 1,
      data: { state: { found: ['cat', 'bird', 'car'] } },
    });
    expect(changes[4]).toMatchObject({ deviceId: phone.deviceId, seconds: 300 });

    const nothingNew = await h.call('GET', `/api/v1/sync/pull?since=${cursor}`, {
      token: web.token,
    });
    expect(nothingNew.body).toEqual({ changes: [], cursor, hasMore: false });
  });

  it('pages with hasMore and never skips or repeats a change', async () => {
    const childId = uuidv7();
    await push(phone, [createChild(childId)]);
    await push(
      phone,
      Array.from({ length: 30 }, (_, i) => ({
        mutationId: uuidv7(),
        entity: 'usage',
        op: 'put',
        childId,
        day: `2026-09-${String(i + 1).padStart(2, '0')}`,
        payload: { seconds: i + 1 },
      })),
    );
    const paged = await pullAll(web, 0, 7);
    const whole = await pullAll(web, 0, 500);
    expect(paged.changes).toEqual(whole.changes);
    expect(new Set(paged.changes.map((c) => c.changeSeq)).size).toBe(32);
  });

  it('is idempotent: replaying a batch returns the stored results and stores nothing twice', async () => {
    const childId = uuidv7();
    const batch = [
      createChild(childId),
      {
        mutationId: uuidv7(),
        entity: 'attempt',
        op: 'create',
        id: uuidv7(),
        childId,
        payload: attemptPayload(),
      },
    ];
    const first = await push(phone, batch);
    const replay = await push(phone, batch);
    expect(replay).toEqual(first);
    expect(await h.prisma.unitAttempt.count()).toBe(1);
    expect(await h.prisma.childProfile.count()).toBe(1);
    // Same records under new mutation IDs (e.g. the outbox was rebuilt): duplicates, not copies.
    const again = await push(
      phone,
      batch.map((m) => ({ ...m, mutationId: uuidv7() })),
    );
    expect(again.map((r) => r.status)).toEqual(['duplicate', 'duplicate']);
  });

  it('keeps attempts immutable', async () => {
    const childId = uuidv7();
    const attemptId = uuidv7();
    await push(phone, [
      createChild(childId),
      {
        mutationId: uuidv7(),
        entity: 'attempt',
        op: 'create',
        id: attemptId,
        childId,
        payload: attemptPayload(),
      },
    ]);
    const [changed] = await push(web, [
      {
        mutationId: uuidv7(),
        entity: 'attempt',
        op: 'create',
        id: attemptId,
        childId,
        payload: attemptPayload({ effortStars: 0 }),
      },
    ]);
    expect(changed).toMatchObject({ status: 'rejected', error: { code: 'immutable' } });
    expect(
      (await h.prisma.unitAttempt.findUniqueOrThrow({ where: { id: attemptId } })).effortStars,
    ).toBe(3);
  });

  it("keeps both devices' attempts (append-only, no conflict possible)", async () => {
    const childId = uuidv7();
    await push(phone, [createChild(childId)]);
    await push(phone, [
      {
        mutationId: uuidv7(),
        entity: 'attempt',
        op: 'create',
        id: uuidv7(),
        childId,
        payload: attemptPayload(),
      },
    ]);
    await push(web, [
      {
        mutationId: uuidv7(),
        entity: 'attempt',
        op: 'create',
        id: uuidv7(),
        childId,
        payload: attemptPayload({ effortStars: 1 }),
      },
    ]);
    expect(await h.prisma.unitAttempt.count({ where: { childId } })).toBe(2);
  });

  describe('child profile and settings merges', () => {
    let childId: string;
    beforeEach(async () => {
      childId = uuidv7();
      await push(phone, [createChild(childId)]);
    });
    const patchChild = (
      payload: Record<string, unknown>,
      base: Record<string, unknown>,
      baseVersion: number,
    ) => ({
      mutationId: uuidv7(),
      entity: 'child',
      op: 'patch',
      id: childId,
      baseVersion,
      payload,
      base,
    });

    it('merges edits to different fields made offline on two devices', async () => {
      const [a] = await push(web, [patchChild({ palette: 'berry' }, { palette: 'ocean' }, 1)]);
      expect(a).toMatchObject({ status: 'applied', version: 2 });
      const [b] = await push(phone, [patchChild({ avatar: 2 }, { avatar: 1 }, 1)]);
      expect(b).toMatchObject({ status: 'applied', version: 3 });
      const row = await h.prisma.childProfile.findUniqueOrThrow({ where: { id: childId } });
      expect(row).toMatchObject({ palette: 'berry', avatar: 2, displayName: 'Nour' });
    });

    it('never silently overwrites a name: the second rename is a conflict with the server copy', async () => {
      await push(web, [patchChild({ displayName: 'Nouran' }, { displayName: 'Nour' }, 1)]);
      const [r] = await push(phone, [
        patchChild({ displayName: 'Noura', avatar: 0 }, { displayName: 'Nour', avatar: 1 }, 1),
      ]);
      expect(r).toMatchObject({ status: 'conflict', conflictFields: ['displayName'] });
      expect(r!.server).toMatchObject({
        kind: 'child',
        displayName: 'Nouran',
        avatar: 0,
        version: 3,
      });
      const row = await h.prisma.childProfile.findUniqueOrThrow({ where: { id: childId } });
      expect(row).toMatchObject({ displayName: 'Nouran', avatar: 0 });
    });

    it('lets the later settings change win and records the overwritten value', async () => {
      const settings = (
        payload: Record<string, unknown>,
        base: Record<string, unknown>,
        baseVersion: number,
      ) => ({
        mutationId: uuidv7(),
        entity: 'settings',
        op: 'patch',
        childId,
        baseVersion,
        payload,
        base,
      });
      await push(web, [settings({ volume: 0.3 }, { volume: 0.85 }, 1)]);
      const [r] = await push(phone, [
        settings({ volume: 0.6, breakMinutes: 20 }, { volume: 0.85, breakMinutes: 12 }, 1),
      ]);
      expect(r).toMatchObject({ status: 'applied', version: 3 });
      const row = await h.prisma.childSettings.findUniqueOrThrow({ where: { childId } });
      expect(row).toMatchObject({ volume: 0.6, breakMinutes: 20 });
      const audit = await h.prisma.auditLog.findFirstOrThrow({
        where: { action: 'settings_overwritten' },
      });
      expect(audit.meta).toEqual({
        entity: 'settings',
        fields: ['volume'],
        previous: { volume: 0.3 },
      });
    });
  });

  describe('journeys (in-progress lessons)', () => {
    const put = (childId: string, baseVersion: number, state: Record<string, unknown>) => ({
      mutationId: uuidv7(),
      entity: 'journey',
      op: 'put',
      childId,
      curriculum: 'y1.science',
      key: 'unit_02',
      baseVersion,
      payload: { state },
    });

    it('returns the server copy on a stale version so the device can merge and retry', async () => {
      const childId = uuidv7();
      await push(phone, [createChild(childId), put(childId, 0, { step: 2 })]);
      const [ahead] = await push(web, [put(childId, 1, { step: 5 })]);
      expect(ahead).toMatchObject({ status: 'applied', version: 2 });
      const [stale] = await push(phone, [put(childId, 1, { step: 3 })]);
      expect(stale).toMatchObject({
        status: 'conflict',
        version: 2,
        server: { kind: 'journey', state: { step: 5 }, version: 2 },
      });
      const [merged] = await push(phone, [put(childId, 2, { step: 5, extra: true })]);
      expect(merged).toMatchObject({ status: 'applied', version: 3 });
    });

    it('lets a deletion (lesson finished or progress reset) win', async () => {
      const childId = uuidv7();
      await push(phone, [createChild(childId), put(childId, 0, { step: 2 })]);
      const [deleted] = await push(web, [
        {
          mutationId: uuidv7(),
          entity: 'journey',
          op: 'delete',
          childId,
          curriculum: 'y1.science',
          key: 'unit_02',
        },
      ]);
      expect(deleted).toMatchObject({ status: 'applied', version: 2 });
      const [late] = await push(phone, [put(childId, 1, { step: 3 })]);
      expect(late).toMatchObject({ status: 'conflict', server: null });
      const { changes } = await pullAll(phone);
      expect(changes.find((c) => c.entity === 'journey')).toMatchObject({
        op: 'delete',
        version: 2,
      });
      expect(changes.find((c) => c.entity === 'journey')!.data).toBeUndefined();
    });

    it('refuses oversized journey state', async () => {
      const childId = uuidv7();
      await push(phone, [createChild(childId)]);
      const [r] = await push(phone, [put(childId, 0, { blob: 'x'.repeat(70 * 1024) })]);
      expect(r).toMatchObject({ status: 'rejected', error: { code: 'validation_failed' } });
    });
  });

  it('counts play time per device and never lets it go backwards (G-counter)', async () => {
    const childId = uuidv7();
    await push(phone, [createChild(childId)]);
    const usage = (seconds: number) => ({
      mutationId: uuidv7(),
      entity: 'usage',
      op: 'put',
      childId,
      day: '2026-10-05',
      payload: { seconds },
    });
    await push(phone, [usage(120)]);
    await push(phone, [usage(60)]); // an older value arriving late
    await push(web, [usage(45)]);
    const rows = await h.prisma.usageDaily.findMany({
      where: { childId },
      orderBy: { seconds: 'desc' },
    });
    expect(rows.map((r) => [r.deviceId, r.seconds])).toEqual([
      [phone.deviceId, 120],
      [web.deviceId, 45],
    ]);
    const summary = await h.call('GET', `/api/v1/children/${childId}/reports/summary`, {
      token: phone.token,
    });
    expect(summary.body.usage).toEqual([{ day: '2026-10-05', seconds: 165 }]);
  });

  it('erases a deleted child everywhere and refuses later changes to them', async () => {
    const childId = uuidv7();
    await push(phone, [
      createChild(childId),
      {
        mutationId: uuidv7(),
        entity: 'attempt',
        op: 'create',
        id: uuidv7(),
        childId,
        payload: attemptPayload(),
      },
    ]);
    const before = await pullAll(web);
    await push(web, [{ mutationId: uuidv7(), entity: 'child', op: 'delete', id: childId }]);
    const after = await pullAll(phone, before.cursor);
    expect(after.changes).toEqual([
      expect.objectContaining({ entity: 'child', op: 'delete', id: childId }),
    ]);
    expect(after.changes[0]!.data).toBeUndefined();

    const [late] = await push(phone, [
      {
        mutationId: uuidv7(),
        entity: 'attempt',
        op: 'create',
        id: uuidv7(),
        childId,
        payload: attemptPayload(),
      },
    ]);
    expect(late).toMatchObject({ status: 'rejected', error: { code: 'child_deleted' } });
    const [recreate] = await push(phone, [createChild(childId)]);
    expect(recreate).toMatchObject({ status: 'rejected', error: { code: 'child_deleted' } });
    const full = await pullAll(phone);
    expect(full.changes.filter((c) => c.entity !== 'child')).toEqual([]);
  });

  it('rejects one bad mutation without failing the rest of the batch', async () => {
    const childId = uuidv7();
    const results = await push(phone, [
      createChild(childId),
      { mutationId: uuidv7(), entity: 'child', op: 'teleport', id: childId },
      createChild(uuidv7(), { displayName: 'Robert); DROP TABLE users;--' }),
      {
        mutationId: uuidv7(),
        entity: 'usage',
        op: 'put',
        childId,
        day: '2026-10-05',
        payload: { seconds: 999999 },
      },
      {
        mutationId: uuidv7(),
        entity: 'usage',
        op: 'put',
        childId,
        day: '2026-10-05',
        payload: { seconds: 10 },
      },
    ]);
    expect(results.map((r) => r.status)).toEqual([
      'applied',
      'rejected',
      'rejected',
      'rejected',
      'applied',
    ]);
    expect(results[1]!.error!.code).toBe('validation_failed');
  });

  it('rejects malformed envelopes, oversized batches and bodies over 1 MB', async () => {
    const noDevice = await h.call('POST', '/api/v1/sync/push', {
      token: phone.token,
      body: { mutations: [createChild()] },
    });
    expect(noDevice.status).toBe(400);
    const tooMany = await h.call('POST', '/api/v1/sync/push', {
      token: phone.token,
      body: {
        deviceId: phone.deviceId,
        mutations: Array.from({ length: 101 }, () => createChild()),
      },
    });
    expect(tooMany.status).toBe(400);
    const huge = await h.call('POST', '/api/v1/sync/push', {
      token: phone.token,
      body: {
        deviceId: phone.deviceId,
        mutations: [createChild()],
        padding: 'x'.repeat(1_100_000),
      },
    });
    expect(huge.status).toBe(413);
    expect(huge.body.code).toBe('too_large');
  });

  it('asks a device with a cursor older than the tombstone window to resync', async () => {
    await push(phone, [createChild()]);
    await h.prisma.serverMeta.create({ data: { key: 'tombstone_horizon', value: '50' } });
    const stale = await h.call('GET', '/api/v1/sync/pull?since=10', { token: phone.token });
    expect(stale.status).toBe(410);
    expect(stale.body.code).toBe('cursor_expired');
    expect((await h.call('GET', '/api/v1/sync/pull?since=0', { token: phone.token })).status).toBe(
      200,
    );
    expect((await h.call('GET', '/api/v1/sync/pull?since=60', { token: phone.token })).status).toBe(
      200,
    );
  });

  it('keeps change numbers in commit order under concurrent pushes', async () => {
    const childId = uuidv7();
    await push(phone, [createChild(childId)]);
    await Promise.all(
      Array.from({ length: 12 }, (_, i) =>
        push(i % 2 ? phone : web, [
          {
            mutationId: uuidv7(),
            entity: 'usage',
            op: 'put',
            childId,
            day: `2026-08-${String(i + 1).padStart(2, '0')}`,
            payload: { seconds: 1 },
          },
          {
            mutationId: uuidv7(),
            entity: 'attempt',
            op: 'create',
            id: uuidv7(),
            childId,
            payload: attemptPayload(),
          },
        ]),
      ),
    );
    const { changes } = await pullAll(web, 0, 5);
    expect(changes.filter((c) => c.entity === 'usage')).toHaveLength(12);
    expect(changes.filter((c) => c.entity === 'attempt')).toHaveLength(12);
    const seqs = changes.map((c) => c.changeSeq);
    expect(new Set(seqs).size).toBe(seqs.length);
  });
});
