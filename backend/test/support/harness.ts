import { generateKeyPairSync } from 'node:crypto';
import { type INestApplication } from '@nestjs/common';
import request, { type Response } from 'supertest';
import { createApp } from '../../src/app.factory';
import { AttemptLimiter } from '../../src/auth/attempt-limiter';
import { uuidv7 } from '../../src/common/ids';
import { type AppConfig, loadConfig } from '../../src/config/config';
import { MAILER, type MemoryMailer } from '../../src/email/mailer';
import { PrismaService } from '../../src/prisma/prisma.service';
import { expectContract } from './contract';

const TEST_KEY = generateKeyPairSync('ed25519')
  .privateKey.export({ type: 'pkcs8', format: 'pem' })
  .toString();

export const CONSENT = 'test-consent-1';
export const PASSWORD = 'correct horse battery staple';

export function testConfig(overrides: Record<string, string> = {}): AppConfig {
  return loadConfig({
    NODE_ENV: 'test',
    DATABASE_URL: process.env.TEST_DATABASE_URL!,
    JWT_PRIVATE_KEY: TEST_KEY,
    JWT_KEY_ID: 'test-key',
    PUBLIC_WEB_URL: 'https://science.test',
    EMAIL_TRANSPORT: 'memory',
    EMAIL_FROM: 'Science Adventure <test@science.test>',
    CONSENT_VERSION: CONSENT,
    BREACHED_PASSWORD_CHECK: 'false',
    COOKIE_SECURE: 'false',
    MAINTENANCE: 'false',
    RATE_LIMIT: 'false',
    ...overrides,
  });
}

/** A running app plus helpers. Every response goes through the contract check. */
export class Harness {
  private constructor(
    readonly app: INestApplication,
    readonly prisma: PrismaService,
    readonly mailer: MemoryMailer,
  ) {}

  static async start(overrides: Record<string, string> = {}): Promise<Harness> {
    const app = await createApp(testConfig(overrides));
    await app.init();
    return new Harness(app, app.get(PrismaService), app.get<MemoryMailer>(MAILER));
  }

  async stop(): Promise<void> {
    await this.app.close();
  }

  async reset(): Promise<void> {
    await this.prisma.$executeRawUnsafe(
      'TRUNCATE users, audit_log, processed_mutations, idempotency_keys, server_meta RESTART IDENTITY CASCADE',
    );
    this.mailer.clear();
    this.app.get(AttemptLimiter).clear();
  }

  /** Sends a request and checks the response against the contract. */
  async call(
    method: 'GET' | 'POST' | 'PATCH' | 'PUT' | 'DELETE',
    path: string,
    options: {
      token?: string;
      body?: unknown;
      headers?: Record<string, string>;
      contract?: boolean;
    } = {},
  ): Promise<Response> {
    const agent = request(this.app.getHttpServer());
    let req = agent[method.toLowerCase() as 'get'](path);
    if (options.token) req = req.set('Authorization', `Bearer ${options.token}`);
    for (const [k, v] of Object.entries(options.headers ?? {})) req = req.set(k, v);
    const res = options.body === undefined ? await req : await req.send(options.body as object);
    if (options.contract !== false) expectContract(res, method, path);
    return res;
  }

  /** The token from the newest email whose link matches `kind`. */
  tokenFromEmail(to: string, kind: 'verify-email' | 'reset-password'): string {
    const mail = [...this.mailer.sent]
      .reverse()
      .find((m) => m.to === to && m.text.includes(`/account/${kind}#token=`));
    if (!mail) throw new Error(`No ${kind} email for ${to}`);
    return /#token=([A-Za-z0-9_-]+)/.exec(mail.text)![1]!;
  }

  async register(email: string, password = PASSWORD): Promise<void> {
    const res = await this.call('POST', '/api/v1/auth/register', {
      body: { email, password, consentVersion: CONSENT },
    });
    if (res.status !== 202) throw new Error(`register ${res.status} ${JSON.stringify(res.body)}`);
  }

  async login(
    email: string,
    password = PASSWORD,
    platform: 'android' | 'web' = 'android',
    deviceId = uuidv7(),
  ) {
    const res = await this.call('POST', '/api/v1/auth/login', {
      body: { email, password, deviceId, platform },
    });
    if (res.status !== 200) throw new Error(`login ${res.status} ${JSON.stringify(res.body)}`);
    return {
      ...(res.body as { accessToken: string; refreshToken?: string; user: { id: string } }),
      deviceId,
      res,
    };
  }

  /** Registered, verified and signed in on one Android device. */
  async parent(email: string) {
    await this.register(email);
    const verified = await this.call('POST', '/api/v1/auth/verify-email', {
      body: { token: this.tokenFromEmail(email, 'verify-email') },
    });
    if (verified.status !== 204) throw new Error(`verify ${verified.status}`);
    const session = await this.login(email);
    return {
      email,
      token: session.accessToken,
      refreshToken: session.refreshToken!,
      userId: session.user.id,
      deviceId: session.deviceId,
    };
  }
}

export const childBody = (overrides: Record<string, unknown> = {}) => ({
  id: uuidv7(),
  displayName: 'Nour',
  gender: 'girl',
  avatar: 1,
  palette: 'ocean',
  ...overrides,
});

export const attemptPayload = (overrides: Record<string, unknown> = {}) => ({
  curriculum: 'y1.science',
  unitId: 'unit_01',
  contentVersion: 1,
  completed: true,
  effortStars: 3,
  completedAt: '2026-10-05T04:05:12.123456',
  clientAttemptId: 'unit_01-1791162037776000',
  objectives: { 'unit_01.obj.alive': 'firstTry', 'unit_01.obj.grow': 'afterHint' },
  ...overrides,
});

export { uuidv7 };
