import { createPrivateKey, createPublicKey, type KeyObject } from 'node:crypto';
import { Inject, Injectable } from '@nestjs/common';
import { Problem } from '../common/problem';
import { APP_CONFIG, type AppConfig } from '../config/config';
import { JwtError, publicKeyOf, signJwt, verifyJwt } from './jwt';

export interface AccessClaims {
  userId: string;
  sessionId: string;
}

/**
 * 15-minute EdDSA (Ed25519) access tokens. Claims: sub, sid, iat, exp, iss,
 * aud — no personal data. `kid` lets old keys keep verifying during a key
 * rotation (JWT_PREVIOUS_PUBLIC_KEYS).
 */
@Injectable()
export class TokenService {
  private readonly privateKey: KeyObject;
  private readonly publicKeys = new Map<string, KeyObject>();

  constructor(@Inject(APP_CONFIG) private readonly config: AppConfig) {
    this.privateKey = createPrivateKey(config.jwt.privateKeyPem);
    if (this.privateKey.asymmetricKeyType !== 'ed25519') {
      throw new Error('JWT_PRIVATE_KEY must be an Ed25519 private key');
    }
    this.publicKeys.set(config.jwt.keyId, publicKeyOf(this.privateKey));
    for (const previous of config.jwt.previousPublicKeys) {
      this.publicKeys.set(previous.kid, createPublicKey(previous.pem));
    }
  }

  get accessTtlSeconds(): number {
    return this.config.jwt.accessTtlSeconds;
  }

  signAccess(claims: AccessClaims, now: number = Date.now()): Promise<string> {
    const iat = Math.floor(now / 1000);
    return Promise.resolve(
      signJwt(
        {
          sub: claims.userId,
          sid: claims.sessionId,
          iss: this.config.jwt.issuer,
          aud: this.config.jwt.audience,
          iat,
          exp: iat + this.config.jwt.accessTtlSeconds,
        },
        this.privateKey,
        this.config.jwt.keyId,
      ),
    );
  }

  verifyAccess(token: string, now: number = Date.now()): Promise<AccessClaims> {
    try {
      const claims = verifyJwt(token, this.publicKeys, {
        iss: this.config.jwt.issuer,
        aud: this.config.jwt.audience,
        nowSeconds: Math.floor(now / 1000),
      });
      return Promise.resolve({ userId: claims.sub, sessionId: claims.sid });
    } catch (error) {
      const expired = error instanceof JwtError && error.reason === 'expired';
      return Promise.reject(Problem.unauthorized(expired ? 'token_expired' : 'invalid_token'));
    }
  }
}
