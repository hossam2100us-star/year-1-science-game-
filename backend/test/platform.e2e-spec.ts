import { execFileSync } from 'node:child_process';
import { join } from 'node:path';
import { Client } from 'pg';
import request from 'supertest';
import { CONSENT, Harness, PASSWORD, uuidv7 } from './support/harness';

describe('Platform: errors, headers, probes', () => {
  let h: Harness;
  beforeAll(async () => {
    h = await Harness.start();
    await h.reset();
  });
  afterAll(() => h.stop());

  it('answers the health probes', async () => {
    expect((await h.call('GET', '/health/live')).body).toEqual({ status: 'ok' });
    expect((await h.call('GET', '/health/ready')).body).toEqual({ status: 'ok' });
  });

  it('answers unknown routes and bad JSON with problem+json, never a stack trace', async () => {
    const missing = await request(h.app.getHttpServer()).get('/api/v1/nothing-here');
    expect(missing.status).toBe(404);
    expect(missing.headers['content-type']).toContain('application/problem+json');
    const badJson = await request(h.app.getHttpServer())
      .post('/api/v1/auth/login')
      .set('Content-Type', 'application/json')
      .send('{"email": ');
    expect(badJson.status).toBe(400);
    expect(badJson.body.code).toBe('invalid_json');
    expect(JSON.stringify(badJson.body)).not.toMatch(/at \w+ \(|node_modules/);
  });

  it('sends security headers and a request id', async () => {
    const res = await request(h.app.getHttpServer())
      .get('/health/live')
      .set('X-Request-Id', 'abcd1234-test');
    expect(res.headers['x-request-id']).toBe('abcd1234-test');
    expect(res.headers['x-content-type-options']).toBe('nosniff');
    expect(res.headers['content-security-policy']).toContain("default-src 'none'");
    expect(res.headers['x-powered-by']).toBeUndefined();
    const generated = await request(h.app.getHttpServer())
      .get('/health/live')
      .set('X-Request-Id', 'bad id with spaces');
    expect(generated.headers['x-request-id']).toMatch(/^[0-9a-f-]{36}$/);
  });

  it('limits ordinary request bodies to 64 KB', async () => {
    const res = await request(h.app.getHttpServer())
      .post('/api/v1/auth/login')
      .send({
        email: 'a@example.com',
        password: 'x'.repeat(70 * 1024),
        deviceId: uuidv7(),
        platform: 'android',
      });
    expect(res.status).toBe(413);
  });
});

describe('Rate limits (on, as in production)', () => {
  let h: Harness;
  beforeAll(async () => {
    h = await Harness.start({ RATE_LIMIT: 'true' });
    await h.reset();
  });
  afterAll(() => h.stop());

  it('limits sign-ups per address of origin', async () => {
    const statuses: number[] = [];
    for (let i = 0; i < 7; i++) {
      const res = await h.call('POST', '/api/v1/auth/register', {
        body: { email: `p${i}@example.com`, password: PASSWORD, consentVersion: CONSENT },
      });
      statuses.push(res.status);
    }
    expect(statuses.slice(0, 5)).toEqual([202, 202, 202, 202, 202]);
    expect(statuses.slice(5)).toEqual([429, 429]);
  });
});

describe('Database safeguards', () => {
  it('refuses to install on a database that cannot store Arabic names', async () => {
    const url = new URL(process.env.TEST_DATABASE_URL!);
    const admin = new Client({ connectionString: url.toString() });
    await admin.connect();
    await admin.query('DROP DATABASE IF EXISTS latin1_check');
    await admin.query(
      "CREATE DATABASE latin1_check ENCODING 'LATIN1' LC_COLLATE 'C' LC_CTYPE 'C' TEMPLATE template0",
    );
    await admin.end();
    url.pathname = '/latin1_check';
    let output = '';
    try {
      execFileSync(
        process.execPath,
        [join('node_modules', 'prisma', 'build', 'index.js'), 'migrate', 'deploy'],
        {
          env: { ...process.env, DATABASE_URL: url.toString() },
          stdio: 'pipe',
        },
      );
    } catch (error) {
      output =
        String((error as { stdout?: Buffer }).stdout ?? '') +
        String((error as { stderr?: Buffer }).stderr ?? '');
    }
    expect(output).toContain('must use UTF8');
  }, 120_000);
});
