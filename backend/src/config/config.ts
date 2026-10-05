import { readFileSync } from 'node:fs';
import { z } from 'zod';

/**
 * 12-factor configuration, validated once at boot (fail fast). Secrets have
 * no defaults. Any secret may instead be given as a file path in
 * `<NAME>_FILE` (Docker secrets).
 */
const booleanFlag = z.enum(['true', 'false', '1', '0']).transform((v) => v === 'true' || v === '1');

const schema = z
  .object({
    NODE_ENV: z.enum(['production', 'development', 'test']).default('production'),
    PORT: z.coerce.number().int().min(1).max(65535).default(3000),
    LOG_LEVEL: z
      .enum(['fatal', 'error', 'warn', 'info', 'debug', 'trace', 'silent'])
      .default('info'),

    DATABASE_URL: z.string().min(1).startsWith('postgres'),

    JWT_PRIVATE_KEY: z.string().min(1),
    JWT_KEY_ID: z
      .string()
      .min(1)
      .max(64)
      .regex(/^[A-Za-z0-9._-]+$/),
    JWT_PREVIOUS_PUBLIC_KEYS: z.string().optional(),
    JWT_ISSUER: z.string().min(1).default('science-adventure-api'),
    JWT_AUDIENCE: z.string().min(1).default('science-adventure'),

    PUBLIC_WEB_URL: z.url({ protocol: /^https?$/ }),
    CORS_ORIGINS: z.string().optional(),
    TRUST_PROXY: z.string().optional(),
    COOKIE_SECURE: booleanFlag.default(true),

    EMAIL_TRANSPORT: z.enum(['smtp', 'memory']).default('smtp'),
    SMTP_URL: z.string().optional(),
    EMAIL_FROM: z.string().min(3),

    CONSENT_VERSION: z.string().min(1).max(40),
    SIGNUP_ALLOWED_EMAILS: z.string().optional(),
    BREACHED_PASSWORD_CHECK: booleanFlag.default(true),
    REQUIRE_VERIFIED_EMAIL_FOR_SYNC: booleanFlag.default(true),
    ACCOUNT_DELETION_GRACE_DAYS: z.coerce.number().int().min(1).max(90).default(14),
    TOMBSTONE_RETENTION_DAYS: z.coerce.number().int().min(30).max(3650).default(180),
    MAINTENANCE: booleanFlag.default(true),
    RATE_LIMIT: booleanFlag.default(true),
  })
  .superRefine((env, ctx) => {
    if (env.EMAIL_TRANSPORT === 'smtp' && !env.SMTP_URL) {
      ctx.addIssue({
        code: 'custom',
        path: ['SMTP_URL'],
        message: 'required when EMAIL_TRANSPORT=smtp',
      });
    }
    if (env.NODE_ENV === 'production' && !env.RATE_LIMIT) {
      ctx.addIssue({
        code: 'custom',
        path: ['RATE_LIMIT'],
        message: 'rate limits cannot be turned off in production',
      });
    }
    if (env.NODE_ENV === 'production' && env.EMAIL_TRANSPORT === 'memory') {
      ctx.addIssue({
        code: 'custom',
        path: ['EMAIL_TRANSPORT'],
        message: 'memory transport is for tests only',
      });
    }
  });

export interface AppConfig {
  env: 'production' | 'development' | 'test';
  port: number;
  logLevel: string;
  databaseUrl: string;
  jwt: {
    privateKeyPem: string;
    keyId: string;
    previousPublicKeys: { kid: string; pem: string }[];
    issuer: string;
    audience: string;
    accessTtlSeconds: number;
  };
  publicWebUrl: string;
  corsOrigins: string[];
  trustProxy: string | undefined;
  cookieSecure: boolean;
  email: { transport: 'smtp' | 'memory'; smtpUrl: string | undefined; from: string };
  consentVersion: string;
  signupAllowedEmails: Set<string> | null;
  breachedPasswordCheck: boolean;
  requireVerifiedEmailForSync: boolean;
  accountDeletionGraceDays: number;
  tombstoneRetentionDays: number;
  maintenance: boolean;
  rateLimit: boolean;
}

export const APP_CONFIG = Symbol('APP_CONFIG');

const SECRET_NAMES = ['DATABASE_URL', 'JWT_PRIVATE_KEY', 'SMTP_URL'] as const;

function withFileSecrets(env: NodeJS.ProcessEnv): Record<string, string | undefined> {
  const out: Record<string, string | undefined> = { ...env };
  for (const name of SECRET_NAMES) {
    const file = env[`${name}_FILE`];
    if (!env[name] && file) out[name] = readFileSync(file, 'utf8').trim();
  }
  return out;
}

/** PEM given directly (with real or `\n` newlines) or base64-encoded. */
export function decodePem(value: string): string {
  const text = value.includes('BEGIN') ? value : Buffer.from(value, 'base64').toString('utf8');
  return text.replace(/\\n/g, '\n').trim() + '\n';
}

export class ConfigError extends Error {}

export function loadConfig(env: NodeJS.ProcessEnv = process.env): AppConfig {
  const parsed = schema.safeParse(withFileSecrets(env));
  if (!parsed.success) {
    // Names only: never echo values, some are secrets.
    const problems = parsed.error.issues.map((i) => `${i.path.join('.')}: ${i.message}`);
    throw new ConfigError(`Invalid configuration:\n  ${problems.join('\n  ')}`);
  }
  const e = parsed.data;
  let previous: { kid: string; pem: string }[] = [];
  if (e.JWT_PREVIOUS_PUBLIC_KEYS) {
    const list = z
      .array(z.object({ kid: z.string().min(1), pem: z.string().min(1) }))
      .safeParse(JSON.parse(e.JWT_PREVIOUS_PUBLIC_KEYS));
    if (!list.success) throw new ConfigError('JWT_PREVIOUS_PUBLIC_KEYS must be [{kid, pem}]');
    previous = list.data.map((k) => ({ kid: k.kid, pem: decodePem(k.pem) }));
  }
  const allowed = e.SIGNUP_ALLOWED_EMAILS?.split(',')
    .map((s) => s.trim().toLowerCase())
    .filter(Boolean);
  return {
    env: e.NODE_ENV,
    port: e.PORT,
    logLevel: e.LOG_LEVEL,
    databaseUrl: e.DATABASE_URL,
    jwt: {
      privateKeyPem: decodePem(e.JWT_PRIVATE_KEY),
      keyId: e.JWT_KEY_ID,
      previousPublicKeys: previous,
      issuer: e.JWT_ISSUER,
      audience: e.JWT_AUDIENCE,
      accessTtlSeconds: 15 * 60,
    },
    publicWebUrl: e.PUBLIC_WEB_URL.replace(/\/+$/, ''),
    corsOrigins: (e.CORS_ORIGINS ?? '')
      .split(',')
      .map((s) => s.trim())
      .filter(Boolean),
    trustProxy: e.TRUST_PROXY,
    cookieSecure: e.COOKIE_SECURE,
    email: { transport: e.EMAIL_TRANSPORT, smtpUrl: e.SMTP_URL, from: e.EMAIL_FROM },
    consentVersion: e.CONSENT_VERSION,
    signupAllowedEmails: allowed && allowed.length > 0 ? new Set(allowed) : null,
    breachedPasswordCheck: e.BREACHED_PASSWORD_CHECK,
    requireVerifiedEmailForSync: e.REQUIRE_VERIFIED_EMAIL_FOR_SYNC,
    accountDeletionGraceDays: e.ACCOUNT_DELETION_GRACE_DAYS,
    tombstoneRetentionDays: e.TOMBSTONE_RETENTION_DAYS,
    maintenance: e.MAINTENANCE,
    rateLimit: e.RATE_LIMIT,
  };
}
