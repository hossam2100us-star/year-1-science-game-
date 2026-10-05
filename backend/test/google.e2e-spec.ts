import { createHmac } from 'node:crypto';
import { CONSENT, Harness, PASSWORD, uuidv7 } from './support/harness';
import { FakeGoogle, GOOGLE_CLIENT_ID } from './support/fake-google';

describe('Sign in with Google', () => {
  const google = new FakeGoogle();
  let h: Harness;
  beforeAll(async () => {
    await google.start();
    h = await Harness.start({ GOOGLE_CLIENT_IDS: GOOGLE_CLIENT_ID, GOOGLE_JWKS_URL: google.url });
  });
  afterAll(async () => {
    await h.stop();
    await google.stop();
  });
  beforeEach(() => h.reset());

  const signIn = (idToken: string, extra: Record<string, unknown> = {}) =>
    h.call('POST', '/api/v1/auth/google', {
      body: { idToken, deviceId: uuidv7(), platform: 'android', ...extra },
    });

  it('creates an account only after consent, verified, without a password', async () => {
    const first = await signIn(google.token());
    expect(first.status).toBe(422);
    expect(first.body.code).toBe('consent_required');
    expect(await h.prisma.user.count()).toBe(0);

    const ok = await signIn(google.token(), { consentVersion: CONSENT });
    expect(ok.status).toBe(200);
    expect(ok.body.user).toMatchObject({
      email: 'parent@gmail.com',
      emailVerified: true,
      signInMethods: ['google'],
    });
    const user = await h.prisma.user.findFirstOrThrow({ include: { identities: true } });
    expect(user.passwordHash).toBeNull();
    expect(user.identities).toEqual([
      expect.objectContaining({ provider: 'google', subject: '111111111111111111111' }),
    ]);
    // Only the stable Google ID is stored: no name, picture or Google tokens.
    expect(JSON.stringify(user)).not.toMatch(/picture|given_name|eyJ/);

    const again = await signIn(google.token());
    expect(again.status).toBe(200);
    expect(again.body.user.id).toBe(ok.body.user.id);
    expect(await h.prisma.user.count()).toBe(1);
  });

  it('links Google to an existing verified account and keeps its password', async () => {
    await h.parent('parent@gmail.com');
    const res = await signIn(google.token());
    expect(res.status).toBe(200);
    expect(res.body.user.signInMethods).toEqual(['password', 'google']);
    await h.login('parent@gmail.com'); // the password still works
  });

  it('removes a password set before anyone proved owning the address (pre-hijack)', async () => {
    // Someone registers the parent's Gmail address first and never verifies it.
    await h.register('parent@gmail.com', 'an attacker password');
    const attacker = await h.login('parent@gmail.com', 'an attacker password');
    const res = await signIn(google.token());
    expect(res.status).toBe(200);
    expect(res.body.user.signInMethods).toEqual(['google']);
    await expect(h.login('parent@gmail.com', 'an attacker password')).rejects.toThrow('login 401');
    const me = await h.call('GET', '/api/v1/users/me', { token: attacker.accessToken });
    expect(me.status).toBe(401);
  });

  it('rejects tokens that are forged, for another app, unverified, expired or from another issuer', async () => {
    const [head, body] = google.token().split('.');
    const bad = [
      google.token({ aud: 'someone-elses-app.apps.googleusercontent.com' }),
      google.token({ iss: 'https://evil.example.com' }),
      google.token({ email_verified: false }),
      google.token({ exp: Math.floor(Date.now() / 1000) - 120 }),
      google.token({}, { kid: 'unknown-kid' }),
      `${head}.${body}.${'A'.repeat(342)}`,
      `${Buffer.from(JSON.stringify({ alg: 'none' })).toString('base64url')}.${body}.x`,
      `${Buffer.from(JSON.stringify({ alg: 'HS256', kid: google.kid })).toString('base64url')}.${body}.${createHmac('sha256', 'x').update('y').digest('base64url')}`,
    ];
    for (const token of bad) {
      const res = await signIn(token, { consentVersion: CONSENT });
      expect(res.status).toBe(401);
      expect(res.body.code).toBe('invalid_google_token');
    }
    expect(await h.prisma.user.count()).toBe(0);
  });

  it('handles a Google-only account: no password sign-in, no password change, can add one by email', async () => {
    await signIn(google.token(), { consentVersion: CONSENT });
    const pw = await h.call('POST', '/api/v1/auth/login', {
      body: {
        email: 'parent@gmail.com',
        password: PASSWORD,
        deviceId: uuidv7(),
        platform: 'android',
      },
    });
    expect(pw.status).toBe(401);
    const session = await signIn(google.token());
    const change = await h.call('POST', '/api/v1/auth/change-password', {
      token: session.body.accessToken,
      body: { currentPassword: 'anything at all', newPassword: 'a brand new long password' },
    });
    expect(change.status).toBe(422);
    expect(change.body.code).toBe('no_password');
    await h.call('POST', '/api/v1/auth/forgot-password', { body: { email: 'parent@gmail.com' } });
    const reset = await h.call('POST', '/api/v1/auth/reset-password', {
      body: {
        token: h.tokenFromEmail('parent@gmail.com', 'reset-password'),
        newPassword: 'a brand new long password',
      },
    });
    expect(reset.status).toBe(204);
    const both = await signIn(google.token());
    expect(both.body.user.signInMethods).toEqual(['password', 'google']);
  });

  it('deletes a Google-only account only with a fresh sign-in of the same Google account', async () => {
    const session = await signIn(google.token(), { consentVersion: CONSENT });
    const token = session.body.accessToken as string;
    const other = await h.call('DELETE', '/api/v1/users/me', {
      token,
      body: {
        googleIdToken: google.token({ sub: '222222222222222222222', email: 'other@gmail.com' }),
      },
    });
    expect(other.status).toBe(401);
    const old = await h.call('DELETE', '/api/v1/users/me', {
      token,
      body: { googleIdToken: google.token({ iat: Math.floor(Date.now() / 1000) - 20 * 60 }) },
    });
    expect(old.status).toBe(401);
    const ok = await h.call('DELETE', '/api/v1/users/me', {
      token,
      body: { googleIdToken: google.token() },
    });
    expect(ok.status).toBe(202);
  });

  it('honours the trial sign-up list for new Google accounts', async () => {
    await h.stop();
    h = await Harness.start({
      GOOGLE_CLIENT_IDS: GOOGLE_CLIENT_ID,
      GOOGLE_JWKS_URL: google.url,
      SIGNUP_ALLOWED_EMAILS: 'friend@gmail.com',
    });
    await h.reset();
    const res = await signIn(google.token(), { consentVersion: CONSENT });
    expect(res.status).toBe(403);
    expect(res.body.code).toBe('registration_closed');
  });
});

describe('Sign in with Google switched off', () => {
  let h: Harness;
  beforeAll(async () => {
    h = await Harness.start();
  });
  afterAll(() => h.stop());

  it('answers 404 when no Google client ID is configured', async () => {
    const res = await h.call('POST', '/api/v1/auth/google', {
      body: {
        idToken: 'aaaaaaaaaaaa.bbbbbbbbbbbb.cccccccccccc',
        deviceId: uuidv7(),
        platform: 'web',
      },
    });
    expect(res.status).toBe(404);
    expect(res.body.code).toBe('google_sign_in_disabled');
  });
});
