import { MaintenanceService } from '../src/maintenance/maintenance.service';
import { attemptPayload, childBody, Harness, PASSWORD, uuidv7 } from './support/harness';

const DAY = 24 * 60 * 60 * 1000;

describe('Account deletion, export and maintenance', () => {
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

  const fillFamily = async () => {
    const child = childBody();
    await h.call('POST', '/api/v1/children', { token: p.token, body: child });
    await h.call('POST', '/api/v1/sync/push', {
      token: p.token,
      body: {
        deviceId: p.deviceId,
        mutations: [
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
            payload: { seconds: 30 },
          },
        ],
      },
    });
    return child;
  };

  it('schedules deletion with the password, ends sessions, and erases everything after the grace period', async () => {
    await fillFamily();
    const wrong = await h.call('DELETE', '/api/v1/users/me', {
      token: p.token,
      body: { password: 'not my password' },
    });
    expect(wrong.status).toBe(401);
    const res = await h.call('DELETE', '/api/v1/users/me', {
      token: p.token,
      body: { password: PASSWORD },
    });
    expect(res.status).toBe(202);
    const when = new Date(res.body.deletionScheduledAt as string).getTime();
    expect(when - Date.now()).toBeGreaterThan(13.9 * DAY);
    expect((await h.call('GET', '/api/v1/users/me', { token: p.token })).status).toBe(401);
    expect(h.mailer.sent.at(-1)!.subject).toContain('Account deletion');

    const maintenance = h.app.get(MaintenanceService);
    expect((await maintenance.run(new Date(Date.now() + 13 * DAY)))!.erasedAccounts).toBe(0);
    const report = await maintenance.run(new Date(when + 1000));
    expect(report!.erasedAccounts).toBe(1);
    for (const count of [
      h.prisma.user.count(),
      h.prisma.childProfile.count(),
      h.prisma.childSettings.count(),
      h.prisma.unitAttempt.count(),
      h.prisma.attemptObjective.count(),
      h.prisma.usageDaily.count(),
      h.prisma.device.count(),
      h.prisma.refreshToken.count(),
    ]) {
      expect(await count).toBe(0);
    }
    const audit = await h.prisma.auditLog.findMany({ select: { action: true, meta: true } });
    expect(JSON.stringify(audit)).not.toContain('parent@example.com');
    expect(JSON.stringify(audit)).not.toContain('Nour');
  });

  it('cancels a pending deletion when the parent signs in again', async () => {
    await h.call('DELETE', '/api/v1/users/me', { token: p.token, body: { password: PASSWORD } });
    const session = await h.login('parent@example.com');
    expect((await h.call('GET', '/api/v1/users/me', { token: session.accessToken })).status).toBe(
      200,
    );
    expect(await h.prisma.user.findFirstOrThrow()).toMatchObject({
      status: 'active',
      deletionScheduledAt: null,
    });
    expect(h.mailer.sent.at(-1)!.subject).toContain('Deletion cancelled');
  });

  it("exports all of the family's data, at most three times an hour", async () => {
    const child = await fillFamily();
    const res = await h.call('GET', '/api/v1/users/me/export', { token: p.token });
    expect(res.status).toBe(200);
    expect(res.headers['cache-control']).toBe('no-store');
    expect(res.body.user).toMatchObject({
      email: 'parent@example.com',
      consentVersion: 'test-consent-1',
    });
    expect(res.body.children[0]).toMatchObject({ id: child.id, displayName: 'Nour' });
    expect(res.body.children[0].attempts).toHaveLength(1);
    expect(res.body.children[0].usage).toEqual([
      { deviceId: p.deviceId, day: '2026-10-05', seconds: 30 },
    ]);
    expect(JSON.stringify(res.body)).not.toContain('argon2');
    await h.call('GET', '/api/v1/users/me/export', { token: p.token });
    await h.call('GET', '/api/v1/users/me/export', { token: p.token });
    const fourth = await h.call('GET', '/api/v1/users/me/export', { token: p.token });
    expect(fourth.status).toBe(429);
  });

  it('purges old tombstones and moves the sync horizon forward', async () => {
    const child = await fillFamily();
    await h.call('DELETE', `/api/v1/children/${child.id}`, { token: p.token });
    const tomb = await h.prisma.childProfile.findUniqueOrThrow({ where: { id: child.id } });
    const maintenance = h.app.get(MaintenanceService);
    expect((await maintenance.run(new Date(Date.now() + 100 * DAY)))!.tombstones).toBe(0);
    expect((await maintenance.run(new Date(Date.now() + 181 * DAY)))!.tombstones).toBe(1);
    const horizon = await h.prisma.serverMeta.findUniqueOrThrow({
      where: { key: 'tombstone_horizon' },
    });
    expect(horizon.value).toBe(String(tomb.changeSeq));
  });

  it('cleans up expired sessions, used email links and old idempotency keys', async () => {
    await h.prisma.refreshToken.updateMany({
      data: { familyExpiresAt: new Date(Date.now() - 1000) },
    });
    const report = await h.app.get(MaintenanceService).run();
    expect(report!.expiredSessions).toBeGreaterThan(0);
    expect(report!.emailTokens).toBeGreaterThan(0); // the used verification link
    expect(await h.prisma.refreshToken.count()).toBe(0);
  });
});
