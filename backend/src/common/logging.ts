import { randomUUID } from 'node:crypto';
import type { IncomingMessage, ServerResponse } from 'node:http';
import type { Params } from 'nestjs-pino';

/**
 * Never logged (Future System Architecture §17): passwords, tokens,
 * Authorization and Cookie headers, emails, child names, photos. Bodies are
 * not logged at all; the paths below are a second line of defence for
 * anything that logs an object by mistake.
 */
export const REDACT_PATHS = [
  'req.headers.authorization',
  'req.headers.cookie',
  'req.headers["x-csrf-protection"]',
  'res.headers["set-cookie"]',
  '*.password',
  '*.newPassword',
  '*.currentPassword',
  '*.token',
  '*.accessToken',
  '*.refreshToken',
  '*.email',
  '*.displayName',
  '*.smtpUrl',
  '*.databaseUrl',
];

const REQUEST_ID = /^[A-Za-z0-9-]{8,64}$/;

/** IPv4 → /24, IPv6 → /48: enough to spot abuse, not to identify a home. */
export function truncateIp(ip: string | undefined): string | undefined {
  if (!ip) return undefined;
  const v4 = ip.replace(/^::ffff:/, '');
  if (/^\d+\.\d+\.\d+\.\d+$/.test(v4)) return v4.replace(/\.\d+$/, '.0');
  const parts = ip.split(':');
  return parts.length > 3 ? `${parts.slice(0, 3).join(':')}::` : ip;
}

export function loggerParams(level: string): Params {
  return {
    pinoHttp: {
      level,
      redact: { paths: REDACT_PATHS, censor: '[redacted]' },
      genReqId: (req: IncomingMessage, res: ServerResponse) => {
        const incoming = req.headers['x-request-id'];
        const id =
          typeof incoming === 'string' && REQUEST_ID.test(incoming) ? incoming : randomUUID();
        res.setHeader('X-Request-Id', id);
        return id;
      },
      serializers: {
        req: (req: { id: string; method: string; url: string; raw?: { ip?: string } }) => ({
          id: req.id,
          method: req.method,
          // Paths and query never carry secrets in this API (tokens travel in bodies).
          url: req.url,
          ip: truncateIp(req.raw?.ip),
        }),
        res: (res: { statusCode: number }) => ({ statusCode: res.statusCode }),
      },
      customLogLevel: (_req, res, err) =>
        err || res.statusCode >= 500 ? 'error' : res.statusCode >= 400 ? 'info' : 'debug',
      autoLogging: { ignore: (req) => (req.url ?? '').startsWith('/health/') },
    },
  };
}
