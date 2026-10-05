import { generateKeyPairSync, type KeyObject, sign } from 'node:crypto';
import { createServer, type Server } from 'node:http';
import { type AddressInfo } from 'node:net';

export const GOOGLE_CLIENT_ID = 'test-client.apps.googleusercontent.com';

const b64 = (value: unknown) => Buffer.from(JSON.stringify(value)).toString('base64url');

/**
 * Stands in for Google in tests: serves a JWKS like
 * https://www.googleapis.com/oauth2/v3/certs and mints RS256 ID tokens.
 */
export class FakeGoogle {
  private readonly key: KeyObject;
  private server!: Server;
  readonly kid = 'test-kid-1';
  url = '';

  constructor() {
    this.key = generateKeyPairSync('rsa', { modulusLength: 2048 }).privateKey;
  }

  async start(): Promise<void> {
    const jwk = { ...this.key.export({ format: 'jwk' }), kid: this.kid, alg: 'RS256', use: 'sig' };
    const publicJwk = {
      kty: jwk.kty,
      n: jwk.n,
      e: jwk.e,
      kid: jwk.kid,
      alg: jwk.alg,
      use: jwk.use,
    };
    this.server = createServer((_req, res) => {
      res.writeHead(200, {
        'Content-Type': 'application/json',
        'Cache-Control': 'public, max-age=3600',
      });
      res.end(JSON.stringify({ keys: [publicJwk] }));
    });
    await new Promise<void>((resolve) => this.server.listen(0, '127.0.0.1', resolve));
    this.url = `http://127.0.0.1:${(this.server.address() as AddressInfo).port}/certs`;
  }

  async stop(): Promise<void> {
    await new Promise<void>((resolve) => this.server.close(() => resolve()));
  }

  /** A Google ID token; override any claim to build a bad one. */
  token(claims: Record<string, unknown> = {}, header: Record<string, unknown> = {}): string {
    const now = Math.floor(Date.now() / 1000);
    const head = b64({ alg: 'RS256', kid: this.kid, typ: 'JWT', ...header });
    const body = b64({
      iss: 'https://accounts.google.com',
      aud: GOOGLE_CLIENT_ID,
      azp: GOOGLE_CLIENT_ID,
      sub: '111111111111111111111',
      email: 'parent@gmail.com',
      email_verified: true,
      iat: now,
      exp: now + 3600,
      ...claims,
    });
    const signature = sign('RSA-SHA256', Buffer.from(`${head}.${body}`), this.key).toString(
      'base64url',
    );
    return `${head}.${body}.${signature}`;
  }
}
