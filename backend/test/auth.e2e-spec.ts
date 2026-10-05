import { CONSENT, Harness, PASSWORD, uuidv7 } from './support/harness';

describe('Authentication (§9)', () => {
  let h: Harness;
  beforeAll(async () => {
    h = await Harness.start();
  });
  afterAll(() => h.stop());
  beforeEach(() => h.reset());

  describe('sign-up and email verification', () => {
    it('registers, emails a link, verifies, and lets the parent sign in', async () => {
      await h.register('parent@example.com');
      expect(h.mailer.sent).toHaveLength(1);
      const token = h.tokenFromEmail('parent@example.com', 'verify-email');

      const verify = await h.call('POST', '/api/v1/auth/verify-email', { body: { token } });
      expect(verify.status).toBe(204);
      const again = await h.call('POST', '/api/v1/auth/verify-email', { body: { token } });
      expect(again.status).toBe(400);
      expect(again.body.code).toBe('invalid_token');

      const session = await h.login('parent@example.com');
      expect(session.refreshToken).toMatch(/^[A-Za-z0-9_-]{43}$/);
      const me = await h.call('GET', '/api/v1/users/me', { token: session.accessToken });
      expect(me.status).toBe(200);
      expect(me.body).toMatchObject({ email: 'parent@example.com', emailVerified: true });
    });

    it('answers the same for an existing email and sends a notice instead of a second account', async () => {
      await h.parent('parent@example.com');
      h.mailer.clear();
      const res = await h.call('POST', '/api/v1/auth/register', {
        body: {
          email: 'PARENT@example.com',
          password: 'another long password',
          consentVersion: CONSENT,
        },
      });
      expect(res.status).toBe(202);
      expect(await h.prisma.user.count()).toBe(1);
      expect(h.mailer.sent).toHaveLength(1);
      expect(h.mailer.sent[0]!.text).toContain('already has one');
    });

    it('rejects short passwords, unknown fields and an outdated consent version', async () => {
      const short = await h.call('POST', '/api/v1/auth/register', {
        body: { email: 'a@example.com', password: 'elevenchars', consentVersion: CONSENT },
      });
      expect(short.status).toBe(400);
      expect(short.body.code).toBe('validation_failed');
      expect(short.body.errors[0].path).toBe('password');

      const extra = await h.call('POST', '/api/v1/auth/register', {
        body: {
          email: 'a@example.com',
          password: PASSWORD,
          consentVersion: CONSENT,
          isAdmin: true,
        },
      });
      expect(extra.status).toBe(400);

      const consent = await h.call('POST', '/api/v1/auth/register', {
        body: { email: 'a@example.com', password: PASSWORD, consentVersion: 'old' },
      });
      expect(consent.status).toBe(422);
      expect(consent.body.code).toBe('consent_outdated');
      expect(await h.prisma.user.count()).toBe(0);
    });

    it('stores the consent version and an Argon2id hash, never the password', async () => {
      await h.register('parent@example.com');
      const user = await h.prisma.user.findFirstOrThrow();
      expect(user.passwordHash).toMatch(/^\$argon2id\$v=19\$m=19456,t=2,p=1\$/);
      expect(user.passwordHash).not.toContain(PASSWORD);
      expect(user.consentVersion).toBe(CONSENT);
      const tokens = await h.prisma.emailToken.findMany();
      const sentToken = h.tokenFromEmail('parent@example.com', 'verify-email');
      expect(Buffer.from(tokens[0]!.tokenHash).toString('base64url')).not.toBe(sentToken);
    });

    it('lets an unverified parent sign in but not sync', async () => {
      await h.register('new@example.com');
      const session = await h.login('new@example.com');
      const pull = await h.call('GET', '/api/v1/sync/pull', { token: session.accessToken });
      expect(pull.status).toBe(403);
      expect(pull.body.code).toBe('email_not_verified');
    });

    it('resends the verification email at most a few times an hour', async () => {
      await h.register('new@example.com');
      for (let i = 0; i < 6; i++) {
        const res = await h.call('POST', '/api/v1/auth/resend-verification', {
          body: { email: 'new@example.com' },
        });
        expect(res.status).toBe(202);
      }
      expect(h.mailer.sent.length).toBe(5);
      const unknown = await h.call('POST', '/api/v1/auth/resend-verification', {
        body: { email: 'nobody@example.com' },
      });
      expect(unknown.status).toBe(202);
    });
  });

  describe('sign-in', () => {
    it('gives the same generic error for a wrong password and an unknown email', async () => {
      await h.parent('parent@example.com');
      const body = (email: string) => ({
        email,
        password: 'wrong password!!',
        deviceId: uuidv7(),
        platform: 'android',
      });
      const wrong = await h.call('POST', '/api/v1/auth/login', {
        body: body('parent@example.com'),
      });
      const unknown = await h.call('POST', '/api/v1/auth/login', {
        body: body('nobody@example.com'),
      });
      expect(wrong.status).toBe(401);
      expect(unknown.status).toBe(401);
      expect(wrong.body.code).toBe('invalid_credentials');
      expect(unknown.body.code).toBe('invalid_credentials');
      expect(wrong.body.detail).toBe(unknown.body.detail);
    });

    it('locks an account and address out after five failures in 15 minutes', async () => {
      await h.parent('parent@example.com');
      const deviceId = uuidv7();
      for (let i = 0; i < 5; i++) {
        await h.call('POST', '/api/v1/auth/login', {
          body: {
            email: 'parent@example.com',
            password: `wrong password ${i}`,
            deviceId,
            platform: 'android',
          },
        });
      }
      const locked = await h.call('POST', '/api/v1/auth/login', {
        body: { email: 'parent@example.com', password: PASSWORD, deviceId, platform: 'android' },
      });
      expect(locked.status).toBe(429);
      expect(Number(locked.headers['retry-after'])).toBeGreaterThan(0);
    }, 60_000);

    it('records the device and never puts personal data in the access token', async () => {
      const p = await h.parent('parent@example.com');
      const payload = JSON.parse(
        Buffer.from(p.token.split('.')[1]!, 'base64url').toString(),
      ) as Record<string, unknown>;
      expect(Object.keys(payload).sort()).toEqual(['aud', 'exp', 'iat', 'iss', 'sid', 'sub']);
      expect((payload.exp as number) - (payload.iat as number)).toBe(900);
      expect(JSON.stringify(payload)).not.toContain('example.com');
      const header = JSON.parse(
        Buffer.from(p.token.split('.')[0]!, 'base64url').toString(),
      ) as Record<string, unknown>;
      expect(header).toMatchObject({ alg: 'EdDSA', kid: 'test-key' });
      expect(await h.prisma.device.count({ where: { id: p.deviceId, userId: p.userId } })).toBe(1);
    });

    it('rejects tampered, missing and wrong-scheme tokens', async () => {
      const p = await h.parent('parent@example.com');
      const [head, body] = p.token.split('.');
      const forged = `${head}.${body}.${'A'.repeat(86)}`;
      for (const header of [`Bearer ${forged}`, 'Bearer nonsense', p.token]) {
        const res = await h.call('GET', '/api/v1/users/me', { headers: { Authorization: header } });
        expect(res.status).toBe(401);
      }
      expect((await h.call('GET', '/api/v1/users/me')).status).toBe(401);
    });
  });

  describe('refresh tokens (rotation and reuse detection)', () => {
    it('rotates on every refresh and only stores hashes', async () => {
      const p = await h.parent('parent@example.com');
      const first = await h.call('POST', '/api/v1/auth/refresh', {
        body: { refreshToken: p.refreshToken },
      });
      expect(first.status).toBe(200);
      expect(first.body.refreshToken).not.toBe(p.refreshToken);
      const rows = await h.prisma.refreshToken.findMany();
      expect(rows).toHaveLength(2);
      for (const row of rows) {
        expect(Buffer.from(row.tokenHash).toString('base64url')).not.toBe(p.refreshToken);
      }
      const me = await h.call('GET', '/api/v1/users/me', { token: first.body.accessToken });
      expect(me.status).toBe(200);
    });

    it('treats an immediate repeat as a race, not theft', async () => {
      const p = await h.parent('parent@example.com');
      await h.call('POST', '/api/v1/auth/refresh', { body: { refreshToken: p.refreshToken } });
      const repeat = await h.call('POST', '/api/v1/auth/refresh', {
        body: { refreshToken: p.refreshToken },
      });
      expect(repeat.status).toBe(409);
      expect(repeat.body.code).toBe('refresh_superseded');
      const me = await h.call('GET', '/api/v1/users/me', { token: p.token });
      expect(me.status).toBe(200);
    });

    it('revokes the whole session and emails the parent when an old token is reused later', async () => {
      const p = await h.parent('parent@example.com');
      const rotated = await h.call('POST', '/api/v1/auth/refresh', {
        body: { refreshToken: p.refreshToken },
      });
      await h.prisma.refreshToken.updateMany({
        where: { replacedAt: { not: null } },
        data: { replacedAt: new Date(Date.now() - 60_000) },
      });
      h.mailer.clear();
      const stolen = await h.call('POST', '/api/v1/auth/refresh', {
        body: { refreshToken: p.refreshToken },
      });
      expect(stolen.status).toBe(401);
      expect(stolen.body.code).toBe('session_revoked');
      // The legitimate holder of the newer token is signed out too.
      const newer = await h.call('POST', '/api/v1/auth/refresh', {
        body: { refreshToken: rotated.body.refreshToken },
      });
      expect(newer.status).toBe(401);
      expect(
        (await h.call('GET', '/api/v1/users/me', { token: rotated.body.accessToken })).status,
      ).toBe(401);
      expect(h.mailer.sent.map((m) => m.subject).join()).toContain('Security alert');
      expect(await h.prisma.auditLog.count({ where: { action: 'refresh_reuse_detected' } })).toBe(
        1,
      );
    });

    it('rejects unknown and expired refresh tokens', async () => {
      const p = await h.parent('parent@example.com');
      const unknown = await h.call('POST', '/api/v1/auth/refresh', {
        body: { refreshToken: 'x'.repeat(43) },
      });
      expect(unknown.status).toBe(401);
      await h.prisma.refreshToken.updateMany({ data: { expiresAt: new Date(Date.now() - 1000) } });
      const expired = await h.call('POST', '/api/v1/auth/refresh', {
        body: { refreshToken: p.refreshToken },
      });
      expect(expired.status).toBe(401);
      expect(expired.body.code).toBe('session_expired');
    });
  });

  describe('web sessions (HttpOnly cookie)', () => {
    it('keeps the refresh token out of the body and requires the CSRF header', async () => {
      await h.parent('parent@example.com');
      const login = await h.login('parent@example.com', PASSWORD, 'web');
      expect(login.refreshToken).toBeUndefined();
      const setCookie = String(login.res.headers['set-cookie']);
      expect(setCookie).toMatch(/sa_refresh=[A-Za-z0-9_-]{43};/);
      expect(setCookie).toContain('HttpOnly');
      expect(setCookie).toContain('SameSite=Strict');
      expect(setCookie).toContain('Path=/api/v1/auth');
      const cookie = setCookie.split(';')[0]!;

      const noHeader = await h.call('POST', '/api/v1/auth/refresh', {
        headers: { Cookie: cookie },
        contract: false,
      });
      expect(noHeader.status).toBe(403);
      const ok = await h.call('POST', '/api/v1/auth/refresh', {
        headers: { Cookie: cookie, 'X-CSRF-Protection': '1' },
      });
      expect(ok.status).toBe(200);
      expect(ok.body.refreshToken).toBeUndefined();
      expect(String(ok.headers['set-cookie'])).toMatch(/sa_refresh=/);
    });
  });

  describe('sign-out and passwords', () => {
    it('signs out at once (no 15-minute window) and can sign out every device', async () => {
      const p = await h.parent('parent@example.com');
      const second = await h.login('parent@example.com');
      expect(
        (await h.call('POST', '/api/v1/auth/logout', { token: p.token, body: {} })).status,
      ).toBe(204);
      expect((await h.call('GET', '/api/v1/users/me', { token: p.token })).status).toBe(401);
      expect((await h.call('GET', '/api/v1/users/me', { token: second.accessToken })).status).toBe(
        200,
      );

      const third = await h.login('parent@example.com');
      await h.call('POST', '/api/v1/auth/logout', {
        token: third.accessToken,
        body: { all: true },
      });
      expect((await h.call('GET', '/api/v1/users/me', { token: second.accessToken })).status).toBe(
        401,
      );
    });

    it('resets a forgotten password once, ends every session and sends a notice', async () => {
      const p = await h.parent('parent@example.com');
      const forgot = await h.call('POST', '/api/v1/auth/forgot-password', {
        body: { email: 'parent@example.com' },
      });
      expect(forgot.status).toBe(202);
      const unknown = await h.call('POST', '/api/v1/auth/forgot-password', {
        body: { email: 'nobody@example.com' },
      });
      expect(unknown.status).toBe(202);
      const token = h.tokenFromEmail('parent@example.com', 'reset-password');
      const reset = await h.call('POST', '/api/v1/auth/reset-password', {
        body: { token, newPassword: 'a brand new long password' },
      });
      expect(reset.status).toBe(204);
      expect(
        (
          await h.call('POST', '/api/v1/auth/reset-password', {
            body: { token, newPassword: 'yet another password' },
          })
        ).status,
      ).toBe(400);
      expect((await h.call('GET', '/api/v1/users/me', { token: p.token })).status).toBe(401);
      await expect(h.login('parent@example.com')).rejects.toThrow('login 401');
      await h.login('parent@example.com', 'a brand new long password');
      expect(h.mailer.sent.at(-1)!.subject).toContain('Password changed');
    });

    it('expires reset links after 30 minutes', async () => {
      await h.parent('parent@example.com');
      await h.call('POST', '/api/v1/auth/forgot-password', {
        body: { email: 'parent@example.com' },
      });
      await h.prisma.emailToken.updateMany({
        where: { purpose: 'reset_password' },
        data: { expiresAt: new Date(Date.now() - 1) },
      });
      const res = await h.call('POST', '/api/v1/auth/reset-password', {
        body: {
          token: h.tokenFromEmail('parent@example.com', 'reset-password'),
          newPassword: 'a brand new long password',
        },
      });
      expect(res.status).toBe(400);
    });

    it('changes the password only with the current one and keeps this session', async () => {
      const p = await h.parent('parent@example.com');
      const other = await h.login('parent@example.com');
      const wrong = await h.call('POST', '/api/v1/auth/change-password', {
        token: p.token,
        body: { currentPassword: 'not it at all', newPassword: 'a brand new long password' },
      });
      expect(wrong.status).toBe(401);
      const ok = await h.call('POST', '/api/v1/auth/change-password', {
        token: p.token,
        body: { currentPassword: PASSWORD, newPassword: 'a brand new long password' },
      });
      expect(ok.status).toBe(204);
      expect((await h.call('GET', '/api/v1/users/me', { token: p.token })).status).toBe(200);
      expect((await h.call('GET', '/api/v1/users/me', { token: other.accessToken })).status).toBe(
        401,
      );
    });
  });
});
