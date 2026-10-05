import { generateKeyPairSync } from 'node:crypto';
import { mkdtempSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { ConfigError, decodePem, loadConfig } from './config';

const pem = generateKeyPairSync('ed25519')
  .privateKey.export({ type: 'pkcs8', format: 'pem' })
  .toString();
const base = {
  DATABASE_URL: 'postgresql://u:p@db:5432/x',
  JWT_PRIVATE_KEY: Buffer.from(pem).toString('base64'),
  JWT_KEY_ID: 'k1',
  PUBLIC_WEB_URL: 'https://science.example.com/',
  SMTP_URL: 'smtps://user:secret@smtp.example.com:465',
  EMAIL_FROM: 'Science <no-reply@example.com>',
  CONSENT_VERSION: 'v1',
};

describe('configuration (fail fast, no defaults for secrets)', () => {
  it('loads a complete production configuration with safe defaults', () => {
    const config = loadConfig(base);
    expect(config.env).toBe('production');
    expect(config.cookieSecure).toBe(true);
    expect(config.rateLimit).toBe(true);
    expect(config.breachedPasswordCheck).toBe(true);
    expect(config.requireVerifiedEmailForSync).toBe(true);
    expect(config.publicWebUrl).toBe('https://science.example.com');
    expect(config.jwt.privateKeyPem).toBe(pem.trim() + '\n');
    expect(config.signupAllowedEmails).toBeNull();
  });

  it.each([
    'DATABASE_URL',
    'JWT_PRIVATE_KEY',
    'JWT_KEY_ID',
    'PUBLIC_WEB_URL',
    'EMAIL_FROM',
    'CONSENT_VERSION',
    'SMTP_URL',
  ])('refuses to start without %s', (name) => {
    const env: Record<string, string> = { ...base };
    delete env[name];
    expect(() => loadConfig(env)).toThrow(ConfigError);
  });

  it('never echoes secret values in its error message', () => {
    try {
      loadConfig({ ...base, DATABASE_URL: 'mysql://user:topsecret@db/x' });
      throw new Error('should fail');
    } catch (error) {
      expect(String(error)).toContain('DATABASE_URL');
      expect(String(error)).not.toContain('topsecret');
    }
  });

  it('forbids turning rate limits off or using the memory mailer in production', () => {
    expect(() => loadConfig({ ...base, RATE_LIMIT: 'false' })).toThrow(ConfigError);
    expect(() => loadConfig({ ...base, EMAIL_TRANSPORT: 'memory' })).toThrow(ConfigError);
  });

  it('reads secrets from *_FILE (Docker secrets)', () => {
    const dir = mkdtempSync(join(tmpdir(), 'cfg-'));
    writeFileSync(join(dir, 'db'), 'postgresql://u:p@db:5432/from-file\n');
    const config = loadConfig({
      ...base,
      DATABASE_URL: undefined,
      DATABASE_URL_FILE: join(dir, 'db'),
    });
    expect(config.databaseUrl).toBe('postgresql://u:p@db:5432/from-file');
  });

  it('normalises the trial sign-up list', () => {
    const config = loadConfig({
      ...base,
      SIGNUP_ALLOWED_EMAILS: ' A@Example.com, b@example.com ,',
    });
    expect([...config.signupAllowedEmails!]).toEqual(['a@example.com', 'b@example.com']);
  });

  it('accepts a PEM with escaped newlines', () => {
    expect(decodePem(pem.replace(/\n/g, '\\n'))).toBe(pem.trim() + '\n');
  });
});
