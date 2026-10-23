import { attemptPayload, childBody, Harness, uuidv7 } from './support/harness';

describe('Children, settings and reports', () => {
  let h: Harness;
  let p: Awaited<ReturnType<Harness['parent']>>;
  beforeAll(async () => {
    h = await Harness.start();
  });
  afterAll(() => h.stop());
  beforeEach(async () => {
    await h.reset();
    p = await h.parent('parent@example.com');
  });

  const push = (mutations: unknown[]) =>
    h.call('POST', '/api/v1/sync/push', {
      token: p.token,
      body: { deviceId: p.deviceId, mutations },
    });

  it('creates a child idempotently by the client UUID', async () => {
    const body = childBody();
    const created = await h.call('POST', '/api/v1/children', { token: p.token, body });
    expect(created.status).toBe(201);
    expect(created.body).toMatchObject({ id: body.id, displayName: 'Nour', version: 1 });
    const repeat = await h.call('POST', '/api/v1/children', { token: p.token, body });
    expect(repeat.status).toBe(200);
    const different = await h.call('POST', '/api/v1/children', {
      token: p.token,
      body: { ...body, avatar: 2 },
    });
    expect(different.status).toBe(409);
    expect(different.body.code).toBe('id_unavailable');
    const list = await h.call('GET', '/api/v1/children', { token: p.token });
    expect(list.body.items).toHaveLength(1);
  });

  it('answers with the school year: Year 1 unless the parent chose another (ADR-0021)', async () => {
    const body = childBody();
    const created = await h.call('POST', '/api/v1/children', { token: p.token, body });
    expect(created.body).toMatchObject({ id: body.id, schoolYear: 'y1' });
    const moved = await h.call('PATCH', `/api/v1/children/${body.id}`, {
      token: p.token,
      body: { schoolYear: 'y2', baseVersion: 1 },
    });
    expect(moved.status).toBe(200);
    expect(moved.body).toMatchObject({ schoolYear: 'y2', displayName: 'Nour', version: 2 });
    const bad = await h.call('PATCH', `/api/v1/children/${body.id}`, {
      token: p.token,
      body: { schoolYear: 'second', baseVersion: 2 },
    });
    expect(bad.status).toBe(400);
    const second = childBody();
    const made = await h.call('POST', '/api/v1/children', {
      token: p.token,
      body: { ...second, schoolYear: 'y3' },
    });
    expect(made.status).toBe(201);
    const list = await h.call('GET', '/api/v1/children', { token: p.token });
    expect(list.body.items.map((c: { schoolYear: string }) => c.schoolYear)).toEqual(['y2', 'y3']);
  });

  it('creates default settings with the child, or the settings given', async () => {
    const a = childBody();
    await h.call('POST', '/api/v1/children', { token: p.token, body: a });
    const defaults = await h.call('GET', `/api/v1/children/${a.id}/settings`, { token: p.token });
    expect(defaults.body).toEqual({
      arabic: true,
      breakMinutes: 12,
      sound: true,
      music: true,
      narration: true,
      volume: 0.85,
      boyVoice: null,
      girlVoice: null,
      version: 1,
    });
    const { version: _version, ...settings } = defaults.body as Record<string, unknown>;
    const b = childBody({ settings: { ...settings, arabic: false, volume: 0.4 } });
    await h.call('POST', '/api/v1/children', { token: p.token, body: b });
    const given = await h.call('GET', `/api/v1/children/${b.id}/settings`, { token: p.token });
    expect(given.body).toMatchObject({ arabic: false, volume: 0.4 });
  });

  it('applies the same name rules as the app (optional, letters, at most 24)', async () => {
    for (const displayName of ['', 'نور', "Anne-Marie O'Neil", 'آدَم']) {
      const res = await h.call('POST', '/api/v1/children', {
        token: p.token,
        body: childBody({ displayName }),
      });
      expect(res.status).toBe(201);
    }
    for (const displayName of ['Nour1', '<b>Nour</b>', 'x'.repeat(25), 'Nour 😀']) {
      const res = await h.call('POST', '/api/v1/children', {
        token: p.token,
        body: childBody({ displayName }),
      });
      expect(res.status).toBe(400);
    }
  });

  it('allows at most 10 children per account', async () => {
    for (let i = 0; i < 10; i++) {
      expect(
        (await h.call('POST', '/api/v1/children', { token: p.token, body: childBody() })).status,
      ).toBe(201);
    }
    const eleventh = await h.call('POST', '/api/v1/children', {
      token: p.token,
      body: childBody(),
    });
    expect(eleventh.status).toBe(422);
    expect(eleventh.body.code).toBe('child_limit');
  });

  it('updates with optimistic concurrency and returns the server copy on a stale version', async () => {
    const body = childBody();
    await h.call('POST', '/api/v1/children', { token: p.token, body });
    const ok = await h.call('PATCH', `/api/v1/children/${body.id}`, {
      token: p.token,
      body: { displayName: 'Nora', baseVersion: 1 },
      headers: { 'If-Match': '"1"' },
    });
    expect(ok.status).toBe(200);
    expect(ok.body).toMatchObject({ displayName: 'Nora', version: 2 });
    const stale = await h.call('PATCH', `/api/v1/children/${body.id}`, {
      token: p.token,
      body: { displayName: 'Nadia', baseVersion: 1 },
    });
    expect(stale.status).toBe(409);
    expect(stale.body.server).toMatchObject({ displayName: 'Nora', version: 2 });
    const mismatch = await h.call('PATCH', `/api/v1/children/${body.id}`, {
      token: p.token,
      body: { avatar: 0, baseVersion: 2 },
      headers: { 'If-Match': '"1"' },
    });
    expect(mismatch.status).toBe(400);
  });

  it('replaces settings with optimistic concurrency', async () => {
    const body = childBody();
    await h.call('POST', '/api/v1/children', { token: p.token, body });
    const current = (
      await h.call('GET', `/api/v1/children/${body.id}/settings`, { token: p.token })
    ).body;
    const { version, ...fields } = current as { version: number } & Record<string, unknown>;
    const put = await h.call('PUT', `/api/v1/children/${body.id}/settings`, {
      token: p.token,
      body: { ...fields, breakMinutes: 20, baseVersion: version },
    });
    expect(put.status).toBe(200);
    expect(put.body).toMatchObject({ breakMinutes: 20, version: 2 });
    const stale = await h.call('PUT', `/api/v1/children/${body.id}/settings`, {
      token: p.token,
      body: { ...fields, breakMinutes: 25, baseVersion: 1 },
    });
    expect(stale.status).toBe(409);
    const outOfRange = await h.call('PUT', `/api/v1/children/${body.id}/settings`, {
      token: p.token,
      body: { ...fields, breakMinutes: 31, baseVersion: 2 },
    });
    expect(outOfRange.status).toBe(400);
  });

  it('lists attempts newest first with a cursor, and summarises latest and best per unit', async () => {
    const child = childBody();
    await h.call('POST', '/api/v1/children', { token: p.token, body: child });
    const attempts = [
      attemptPayload({
        completedAt: '2026-10-01T10:00:00',
        objectives: { a: 'firstTry', b: 'firstTry' },
        effortStars: 2,
      }),
      attemptPayload({
        completedAt: '2026-10-02T10:00:00',
        objectives: { a: 'explained', b: 'afterHint' },
        effortStars: 3,
      }),
      attemptPayload({
        completedAt: '2026-10-03T10:00:00',
        objectives: { a: 'firstTry', b: 'afterHint' },
        effortStars: 1,
      }),
      attemptPayload({ unitId: 'unit_02', completedAt: '2026-10-04T10:00:00' }),
    ];
    const ids = attempts.map(() => uuidv7());
    await push(
      attempts.map((payload, i) => ({
        mutationId: uuidv7(),
        entity: 'attempt',
        op: 'create',
        id: ids[i],
        childId: child.id,
        payload,
      })),
    );
    await push([
      {
        mutationId: uuidv7(),
        entity: 'usage',
        op: 'put',
        childId: child.id,
        day: '2026-10-03',
        payload: { seconds: 600 },
      },
    ]);

    const page1 = await h.call(
      'GET',
      `/api/v1/children/${child.id}/attempts?unitId=unit_01&limit=2`,
      { token: p.token },
    );
    expect(page1.body.items.map((a: { completedAt: string }) => a.completedAt)).toEqual([
      '2026-10-03T10:00:00',
      '2026-10-02T10:00:00',
    ]);
    const page2 = await h.call(
      'GET',
      `/api/v1/children/${child.id}/attempts?unitId=unit_01&limit=2&cursor=${page1.body.nextCursor}`,
      { token: p.token },
    );
    expect(page2.body.items).toHaveLength(1);
    expect(page2.body.nextCursor).toBeNull();
    const bad = await h.call('GET', `/api/v1/children/${child.id}/attempts?cursor=nonsense`, {
      token: p.token,
    });
    expect(bad.status).toBe(400);

    const summary = await h.call('GET', `/api/v1/children/${child.id}/reports/summary`, {
      token: p.token,
    });
    const unit1 = summary.body.units.find((u: { unitId: string }) => u.unitId === 'unit_01');
    expect(unit1.attempts).toBe(3);
    expect(unit1.latest.id).toBe(ids[2]);
    expect(unit1.best.id).toBe(ids[0]);
    expect(unit1.best).toMatchObject({ firstTry: 2, objectives: 2 });
    expect(summary.body.usage).toEqual([{ day: '2026-10-03', seconds: 600 }]);
  });

  it('deletes a child and every record of theirs', async () => {
    const child = childBody();
    await h.call('POST', '/api/v1/children', { token: p.token, body: child });
    await push([
      {
        mutationId: uuidv7(),
        entity: 'attempt',
        op: 'create',
        id: uuidv7(),
        childId: child.id,
        payload: attemptPayload(),
      },
      {
        mutationId: uuidv7(),
        entity: 'usage',
        op: 'put',
        childId: child.id,
        day: '2026-10-05',
        payload: { seconds: 60 },
      },
      {
        mutationId: uuidv7(),
        entity: 'journey',
        op: 'put',
        childId: child.id,
        curriculum: 'y1.science',
        key: 'unit_02',
        baseVersion: 0,
        payload: { state: { stepIndex: 3 } },
      },
    ]);
    const del = await h.call('DELETE', `/api/v1/children/${child.id}`, { token: p.token });
    expect(del.status).toBe(204);
    expect((await h.call('GET', `/api/v1/children/${child.id}`, { token: p.token })).status).toBe(
      404,
    );
    expect(
      (await h.call('DELETE', `/api/v1/children/${child.id}`, { token: p.token })).status,
    ).toBe(404);
    for (const count of [
      h.prisma.unitAttempt.count(),
      h.prisma.attemptObjective.count(),
      h.prisma.journey.count(),
      h.prisma.usageDaily.count(),
      h.prisma.childSettings.count(),
    ]) {
      expect(await count).toBe(0);
    }
    const tomb = await h.prisma.childProfile.findUniqueOrThrow({ where: { id: child.id } });
    expect(tomb).toMatchObject({ displayName: null, gender: null, avatar: null, palette: null });
    expect(tomb.deletedAt).not.toBeNull();
  });

  it('replays a POST with the same Idempotency-Key and refuses the key for another request', async () => {
    const body = childBody();
    const key = 'create-child-0001';
    const first = await h.call('POST', '/api/v1/children', {
      token: p.token,
      body,
      headers: { 'Idempotency-Key': key },
    });
    const again = await h.call('POST', '/api/v1/children', {
      token: p.token,
      body,
      headers: { 'Idempotency-Key': key },
    });
    expect(first.status).toBe(201);
    expect(again.status).toBe(201);
    expect(again.body).toEqual(first.body);
    const reused = await h.call('POST', '/api/v1/children', {
      token: p.token,
      body: childBody(),
      headers: { 'Idempotency-Key': key },
      contract: false,
    });
    expect(reused.status).toBe(422);
    expect(reused.body.code).toBe('idempotency_key_reused');
  });
});
