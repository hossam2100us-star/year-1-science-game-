import { createPublicKey, type KeyObject, sign, verify } from 'node:crypto';

/**
 * Minimal JWS/JWT for exactly one algorithm: EdDSA with Ed25519 (RFC 8037),
 * using only node:crypto. Deliberately narrow: the header must say
 * {"alg":"EdDSA"} with a known `kid`, so algorithm-confusion tricks ("none",
 * HS256 with the public key) cannot apply.
 */
export interface JwtClaims {
  sub: string;
  sid: string;
  iss: string;
  aud: string;
  iat: number;
  exp: number;
}

export class JwtError extends Error {
  constructor(readonly reason: 'malformed' | 'signature' | 'expired' | 'claims') {
    super(reason);
  }
}

const b64 = (value: unknown) => Buffer.from(JSON.stringify(value)).toString('base64url');
const B64URL = /^[A-Za-z0-9_-]+$/;

function decodeJson(part: string): Record<string, unknown> {
  if (!B64URL.test(part)) throw new JwtError('malformed');
  try {
    const value = JSON.parse(Buffer.from(part, 'base64url').toString('utf8')) as unknown;
    if (typeof value !== 'object' || value === null || Array.isArray(value)) {
      throw new JwtError('malformed');
    }
    return value as Record<string, unknown>;
  } catch {
    throw new JwtError('malformed');
  }
}

/** Splits a compact JWS and decodes its JSON parts (no signature check). */
export function splitJwt(token: string) {
  if (token.length > 4096) throw new JwtError('malformed');
  const parts = token.split('.');
  if (parts.length !== 3 || !B64URL.test(parts[2]!)) throw new JwtError('malformed');
  const [head, body, signature] = parts as [string, string, string];
  return {
    header: decodeJson(head),
    payload: decodeJson(body),
    signingInput: Buffer.from(`${head}.${body}`),
    signature: Buffer.from(signature, 'base64url'),
  };
}

export function signJwt(claims: JwtClaims, privateKey: KeyObject, kid: string): string {
  const head = b64({ alg: 'EdDSA', kid, typ: 'JWT' });
  const body = b64(claims);
  const signature = sign(null, Buffer.from(`${head}.${body}`), privateKey).toString('base64url');
  return `${head}.${body}.${signature}`;
}

export function verifyJwt(
  token: string,
  keys: ReadonlyMap<string, KeyObject>,
  expected: { iss: string; aud: string; nowSeconds: number; leewaySeconds?: number },
): JwtClaims {
  if (token.length > 4096) throw new JwtError('malformed');
  const parts = token.split('.');
  if (parts.length !== 3 || !B64URL.test(parts[2]!)) throw new JwtError('malformed');
  const [head, body, signature] = parts as [string, string, string];
  const header = decodeJson(head);
  if (header.alg !== 'EdDSA' || typeof header.kid !== 'string') throw new JwtError('signature');
  const key = keys.get(header.kid);
  if (!key || key.asymmetricKeyType !== 'ed25519') throw new JwtError('signature');
  const valid = verify(
    null,
    Buffer.from(`${head}.${body}`),
    key,
    Buffer.from(signature, 'base64url'),
  );
  if (!valid) throw new JwtError('signature');
  const c = decodeJson(body);
  const leeway = expected.leewaySeconds ?? 5;
  if (
    typeof c.sub !== 'string' ||
    typeof c.sid !== 'string' ||
    typeof c.iat !== 'number' ||
    typeof c.exp !== 'number' ||
    c.iss !== expected.iss ||
    c.aud !== expected.aud ||
    c.iat > expected.nowSeconds + leeway
  ) {
    throw new JwtError('claims');
  }
  if (c.exp <= expected.nowSeconds - leeway) throw new JwtError('expired');
  return c as unknown as JwtClaims;
}

export function publicKeyOf(privateKey: KeyObject): KeyObject {
  return createPublicKey(privateKey);
}
