import { Writable } from 'node:stream';
import pino from 'pino';
import { REDACT_PATHS, truncateIp } from './logging';

function capture() {
  const lines: string[] = [];
  const stream = new Writable({
    write(chunk: Buffer, _enc, done) {
      lines.push(chunk.toString());
      done();
    },
  });
  const logger = pino({ redact: { paths: REDACT_PATHS, censor: '[redacted]' } }, stream);
  return { logger, lines };
}

describe('log redaction (§17: never log secrets or personal data)', () => {
  it('censors credentials, tokens, emails and child names wherever they appear one level deep', () => {
    const { logger, lines } = capture();
    logger.info(
      {
        req: { headers: { authorization: 'Bearer eyJ.secret', cookie: 'sa_refresh=abc' } },
        res: { headers: { 'set-cookie': 'sa_refresh=def' } },
        body: {
          password: 'hunter2hunter2',
          newPassword: 'n3w-password!!',
          token: 'tok',
          refreshToken: 'rt',
          accessToken: 'at',
          email: 'parent@example.com',
          displayName: 'Nour',
        },
      },
      'request',
    );
    const out = lines.join('');
    for (const secret of [
      'eyJ.secret',
      'sa_refresh=abc',
      'sa_refresh=def',
      'hunter2hunter2',
      'n3w-password!!',
      'parent@example.com',
      'Nour',
    ]) {
      expect(out).not.toContain(secret);
    }
    expect(out).toContain('[redacted]');
  });
});

describe('truncateIp', () => {
  it('keeps only the network part', () => {
    expect(truncateIp('203.0.113.77')).toBe('203.0.113.0');
    expect(truncateIp('::ffff:198.51.100.9')).toBe('198.51.100.0');
    expect(truncateIp('2001:db8:85a3:8d3:1319:8a2e:370:7348')).toBe('2001:db8:85a3::');
    expect(truncateIp(undefined)).toBeUndefined();
  });
});
