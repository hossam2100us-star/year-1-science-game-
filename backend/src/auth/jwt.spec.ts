import { createHmac, generateKeyPairSync } from 'node:crypto';
import { JwtError, publicKeyOf, signJwt, verifyJwt, type JwtClaims } from './jwt';

const { privateKey } = generateKeyPairSync('ed25519');
const other = generateKeyPairSync('ed25519').privateKey;
const keys = new Map([['k1', publicKeyOf(privateKey)]]);
const now = 1_790_000_000;
const claims: JwtClaims = {
  sub: 'user',
  sid: 'session',
  iss: 'api',
  aud: 'app',
  iat: now,
  exp: now + 900,
};
const expected = { iss: 'api', aud: 'app', nowSeconds: now + 60 };

function reason(fn: () => unknown): string {
  try {
    fn();
    return 'accepted';
  } catch (error) {
    return error instanceof JwtError ? error.reason : 'other';
  }
}

const b64 = (v: unknown) => Buffer.from(JSON.stringify(v)).toString('base64url');

describe('EdDSA JWT', () => {
  it('round-trips valid claims', () => {
    expect(verifyJwt(signJwt(claims, privateKey, 'k1'), keys, expected)).toEqual(claims);
  });

  it('rejects a token signed by another key, or naming an unknown kid', () => {
    expect(reason(() => verifyJwt(signJwt(claims, other, 'k1'), keys, expected))).toBe('signature');
    expect(reason(() => verifyJwt(signJwt(claims, privateKey, 'k2'), keys, expected))).toBe(
      'signature',
    );
  });

  it('rejects a changed payload', () => {
    const [head, , sig] = signJwt(claims, privateKey, 'k1').split('.');
    const forged = `${head}.${b64({ ...claims, sub: 'someone-else' })}.${sig}`;
    expect(reason(() => verifyJwt(forged, keys, expected))).toBe('signature');
  });

  it('rejects alg=none and HS256 signed with the public key (algorithm confusion)', () => {
    const body = b64(claims);
    const none = `${b64({ alg: 'none', kid: 'k1' })}.${body}.`;
    expect(reason(() => verifyJwt(none, keys, expected))).not.toBe('accepted');
    const hsHead = b64({ alg: 'HS256', kid: 'k1' });
    const pem = publicKeyOf(privateKey).export({ type: 'spki', format: 'pem' });
    const mac = createHmac('sha256', pem).update(`${hsHead}.${body}`).digest('base64url');
    expect(reason(() => verifyJwt(`${hsHead}.${body}.${mac}`, keys, expected))).toBe('signature');
  });

  it('rejects expired tokens, wrong audience or issuer, and tokens from the future', () => {
    const sign = (c: Partial<JwtClaims>) => signJwt({ ...claims, ...c }, privateKey, 'k1');
    expect(reason(() => verifyJwt(sign({ exp: now + 30 }), keys, expected))).toBe('expired');
    expect(reason(() => verifyJwt(sign({ aud: 'other' }), keys, expected))).toBe('claims');
    expect(reason(() => verifyJwt(sign({ iss: 'other' }), keys, expected))).toBe('claims');
    expect(reason(() => verifyJwt(sign({ iat: now + 3600 }), keys, expected))).toBe('claims');
  });

  it('rejects malformed input without throwing anything else', () => {
    for (const token of [
      '',
      'a.b',
      'a.b.c.d',
      '!!.!!.!!',
      `${b64([1])}.${b64(claims)}.x`,
      'x'.repeat(5000),
    ]) {
      expect(['malformed', 'signature']).toContain(reason(() => verifyJwt(token, keys, expected)));
    }
  });
});
