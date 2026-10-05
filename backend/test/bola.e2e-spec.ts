import { attemptPayload, childBody, Harness, uuidv7 } from './support/harness';

/**
 * Broken object-level authorisation tests (§10): user B's token against
 * every one of user A's resources must answer 404 (never 403, never data),
 * and sync must neither change nor reveal A's records.
 */
describe("BOLA / IDOR: one family can never reach another family's data", () => {
  let h: Harness;
  let a: Awaited<ReturnType<Harness['parent']>>;
  let b: Awaited<ReturnType<Harness['parent']>>;
  const child = childBody();
  const attemptId = uuidv7();

  beforeAll(async () => {
    h = await Harness.start();
    await h.reset();
    a = await h.parent('a@example.com');
    b = await h.parent('b@example.com');
    await h.call('POST', '/api/v1/children', { token: a.token, body: child });
    await h.call('POST', '/api/v1/sync/push', {
      token: a.token,
      body: {
        deviceId: a.deviceId,
        mutations: [
          {
            mutationId: uuidv7(),
            entity: 'attempt',
            op: 'create',
            id: attemptId,
            childId: child.id,
            payload: attemptPayload(),
          },
          {
            mutationId: uuidv7(),
            entity: 'journey',
            op: 'put',
            childId: child.id,
            curriculum: 'y1.science',
            key: 'unit_02',
            baseVersion: 0,
            payload: { state: { stepIndex: 1 } },
          },
          {
            mutationId: uuidv7(),
            entity: 'usage',
            op: 'put',
            childId: child.id,
            day: '2026-10-05',
            payload: { seconds: 90 },
          },
        ],
      },
    });
  });
  afterAll(() => h.stop());

  const snapshot = async () =>
    JSON.stringify(
      await Promise.all([
        h.prisma.childProfile.findMany({ orderBy: { id: 'asc' } }),
        h.prisma.childSettings.findMany(),
        h.prisma.unitAttempt.findMany({ include: { objectives: true } }),
        h.prisma.journey.findMany(),
        h.prisma.usageDaily.findMany(),
      ]),
      (_k, v: unknown) => (typeof v === 'bigint' ? v.toString() : v),
    );

  it.each([
    ['GET', () => `/api/v1/children/${child.id}`, undefined],
    ['PATCH', () => `/api/v1/children/${child.id}`, { displayName: 'Hacked', baseVersion: 1 }],
    ['DELETE', () => `/api/v1/children/${child.id}`, undefined],
    ['GET', () => `/api/v1/children/${child.id}/settings`, undefined],
    [
      'PUT',
      () => `/api/v1/children/${child.id}/settings`,
      {
        arabic: true,
        breakMinutes: 5,
        sound: false,
        music: false,
        narration: false,
        volume: 0,
        boyVoice: null,
        girlVoice: null,
        baseVersion: 1,
      },
    ],
    ['GET', () => `/api/v1/children/${child.id}/attempts`, undefined],
    ['GET', () => `/api/v1/children/${child.id}/reports/summary`, undefined],
  ] as const)(
    '%s %s answers 404 to another family and changes nothing',
    async (method, path, body) => {
      const before = await snapshot();
      const res = await h.call(method, path(), { token: b.token, ...(body ? { body } : {}) });
      expect(res.status).toBe(404);
      expect(res.body.code).toBe('not_found');
      expect(JSON.stringify(res.body)).not.toContain('Nour');
      expect(await snapshot()).toBe(before);
    },
  );

  it("answers a random unknown ID exactly like another family's ID", async () => {
    const theirs = await h.call('GET', `/api/v1/children/${child.id}`, { token: b.token });
    const unknown = await h.call('GET', `/api/v1/children/${uuidv7()}`, { token: b.token });
    const strip = (body: Record<string, unknown>) => ({ ...body, requestId: undefined });
    expect(strip(theirs.body)).toEqual(strip(unknown.body));
  });

  it('rejects every sync mutation that targets the other family, without revealing anything', async () => {
    const before = await snapshot();
    const mutations = [
      {
        mutationId: uuidv7(),
        entity: 'child',
        op: 'patch',
        id: child.id,
        baseVersion: 1,
        payload: { displayName: 'Hacked' },
      },
      { mutationId: uuidv7(), entity: 'child', op: 'delete', id: child.id },
      {
        mutationId: uuidv7(),
        entity: 'settings',
        op: 'patch',
        childId: child.id,
        baseVersion: 1,
        payload: { volume: 0 },
      },
      {
        mutationId: uuidv7(),
        entity: 'attempt',
        op: 'create',
        id: uuidv7(),
        childId: child.id,
        payload: attemptPayload(),
      },
      { mutationId: uuidv7(), entity: 'attempt', op: 'delete', id: attemptId, childId: child.id },
      {
        mutationId: uuidv7(),
        entity: 'journey',
        op: 'put',
        childId: child.id,
        curriculum: 'y1.science',
        key: 'unit_02',
        baseVersion: 1,
        payload: { state: { stepIndex: 9 } },
      },
      {
        mutationId: uuidv7(),
        entity: 'journey',
        op: 'delete',
        childId: child.id,
        curriculum: 'y1.science',
        key: 'unit_02',
      },
      {
        mutationId: uuidv7(),
        entity: 'usage',
        op: 'put',
        childId: child.id,
        day: '2026-10-05',
        payload: { seconds: 86400 },
      },
    ];
    const res = await h.call('POST', '/api/v1/sync/push', {
      token: b.token,
      body: { deviceId: b.deviceId, mutations },
    });
    expect(res.status).toBe(200);
    for (const result of res.body.results) {
      expect(result.status).toBe('rejected');
      expect(result.error.code).toBe('child_not_found');
      expect(result.server).toBeUndefined();
    }
    expect(await snapshot()).toBe(before);
  });

  it('cannot take over IDs the other family already uses', async () => {
    const before = await snapshot();
    const res = await h.call('POST', '/api/v1/sync/push', {
      token: b.token,
      body: {
        deviceId: b.deviceId,
        mutations: [
          {
            mutationId: uuidv7(),
            entity: 'child',
            op: 'create',
            id: child.id,
            payload: { displayName: 'Nour', gender: 'girl', avatar: 1, palette: 'ocean' },
          },
        ],
      },
    });
    expect(res.body.results[0]).toMatchObject({
      status: 'rejected',
      error: { code: 'id_unavailable' },
    });
    const rest = await h.call('POST', '/api/v1/children', { token: b.token, body: { ...child } });
    expect(rest.status).toBe(409);
    // B's own child may not reuse A's attempt ID either.
    const own = childBody();
    await h.call('POST', '/api/v1/children', { token: b.token, body: own });
    const attempt = await h.call('POST', '/api/v1/sync/push', {
      token: b.token,
      body: {
        deviceId: b.deviceId,
        mutations: [
          {
            mutationId: uuidv7(),
            entity: 'attempt',
            op: 'create',
            id: attemptId,
            childId: own.id,
            payload: attemptPayload(),
          },
        ],
      },
    });
    expect(attempt.body.results[0]).toMatchObject({
      status: 'rejected',
      error: { code: 'id_unavailable' },
    });
    await h.call('DELETE', `/api/v1/children/${own.id}`, { token: b.token });
    expect(await snapshot()).not.toBe(before); // only B's own (now deleted) child changed
    expect(
      await h.prisma.childProfile.findUniqueOrThrow({ where: { id: child.id } }),
    ).toMatchObject({ displayName: 'Nour' });
  });

  it("never returns the other family's rows from pull, the child list or the export", async () => {
    const pull = await h.call('GET', '/api/v1/sync/pull?since=0', { token: b.token });
    expect(JSON.stringify(pull.body)).not.toContain(child.id);
    const list = await h.call('GET', '/api/v1/children', { token: b.token });
    expect(JSON.stringify(list.body)).not.toContain(child.id);
    const exported = await h.call('GET', '/api/v1/users/me/export', { token: b.token });
    expect(exported.status).toBe(200);
    expect(JSON.stringify(exported.body)).not.toContain(child.id);
    expect(JSON.stringify(exported.body)).not.toContain('a@example.com');
  });

  it("enforces the owner in the database too (a row cannot point at another family's child)", async () => {
    await expect(
      h.prisma.usageDaily.create({
        data: {
          childId: child.id,
          userId: b.userId,
          deviceId: b.deviceId,
          day: '2026-10-06',
          seconds: 1,
        },
      }),
    ).rejects.toThrow();
  });
});
