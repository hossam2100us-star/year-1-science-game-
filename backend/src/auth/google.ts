import { createPublicKey, type JsonWebKey, type KeyObject, verify } from 'node:crypto';
import { Inject, Injectable, Logger } from '@nestjs/common';
import { Problem } from '../common/problem';
import { APP_CONFIG, type AppConfig } from '../config/config';
import { JwtError, splitJwt } from './jwt';

export const GOOGLE_JWKS_URL = 'https://www.googleapis.com/oauth2/v3/certs';
const GOOGLE_ISSUERS = new Set(['accounts.google.com', 'https://accounts.google.com']);

export interface GoogleIdentity {
  /** Google's stable account ID (`sub`). */
  subject: string;
  /** Lower-cased, verified by Google. */
  email: string;
  /** Seconds since the epoch when Google issued the token. */
  issuedAt: number;
}

/**
 * Verifies Google ID tokens ("Sign in with Google") with node:crypto:
 * RS256 only, a key from Google's published set, our own client ID as the
 * audience, Google as the issuer, not expired, and an email Google has
 * verified. Only the subject ID and email are used; no profile data.
 */
@Injectable()
export class GoogleVerifier {
  private readonly log = new Logger('GoogleSignIn');
  private cache: { keys: Map<string, KeyObject>; expires: number; fetched: number } | null = null;
  private loading: Promise<Map<string, KeyObject>> | null = null;

  constructor(@Inject(APP_CONFIG) private readonly config: AppConfig) {}

  get enabled(): boolean {
    return this.config.google.clientIds.length > 0;
  }

  async verify(idToken: string, now: number = Date.now()): Promise<GoogleIdentity> {
    try {
      const { header, payload, signingInput, signature } = splitJwt(idToken);
      if (header.alg !== 'RS256' || typeof header.kid !== 'string') throw new JwtError('signature');
      let key = (await this.keys(now)).get(header.kid);
      if (!key) key = (await this.keys(now, true)).get(header.kid); // Google rotated its keys.
      if (!key || !verify('RSA-SHA256', signingInput, key, signature)) {
        throw new JwtError('signature');
      }
      const seconds = Math.floor(now / 1000);
      const p = payload;
      const verified = p.email_verified === true || p.email_verified === 'true';
      if (
        typeof p.iss !== 'string' ||
        !GOOGLE_ISSUERS.has(p.iss) ||
        typeof p.aud !== 'string' ||
        !this.config.google.clientIds.includes(p.aud) ||
        typeof p.sub !== 'string' ||
        p.sub.length < 1 ||
        p.sub.length > 255 ||
        typeof p.email !== 'string' ||
        !verified ||
        typeof p.iat !== 'number' ||
        typeof p.exp !== 'number' ||
        p.iat > seconds + 60
      ) {
        throw new JwtError('claims');
      }
      if (p.exp <= seconds - 30) throw new JwtError('expired');
      return { subject: p.sub, email: p.email.trim().toLowerCase(), issuedAt: p.iat };
    } catch (error) {
      if (error instanceof Problem) throw error;
      throw Problem.unauthorized('invalid_google_token', 'Google sign-in could not be confirmed.');
    }
  }

  private async keys(now: number, refresh = false): Promise<Map<string, KeyObject>> {
    if (this.cache && this.cache.expires > now) {
      // An unknown key ID refreshes the set at most once a minute.
      if (!refresh || now - this.cache.fetched < 60_000) return this.cache.keys;
    }
    this.loading ??= this.fetchKeys(now).finally(() => (this.loading = null));
    try {
      return await this.loading;
    } catch {
      if (this.cache) return this.cache.keys; // keep signing in with the last known keys
      throw new Problem(
        503,
        'google_unavailable',
        'Google sign-in is unavailable',
        'Try again later.',
      );
    }
  }

  private async fetchKeys(now: number): Promise<Map<string, KeyObject>> {
    const response = await fetch(this.config.google.jwksUrl, { signal: AbortSignal.timeout(5000) });
    if (!response.ok) {
      this.log.warn({ status: response.status }, 'Could not load Google keys');
      throw new Error('jwks');
    }
    const body = (await response.json()) as { keys?: (JsonWebKey & { kid?: string })[] };
    const keys = new Map<string, KeyObject>();
    for (const jwk of body.keys ?? []) {
      if (jwk.kty === 'RSA' && typeof jwk.kid === 'string') {
        keys.set(jwk.kid, createPublicKey({ key: jwk, format: 'jwk' }));
      }
    }
    const maxAge = /max-age=(\d+)/.exec(response.headers.get('cache-control') ?? '')?.[1];
    const ttl = Math.min(Number(maxAge ?? 3600), 24 * 3600) * 1000;
    this.cache = { keys, expires: now + ttl, fetched: now };
    return keys;
  }
}
