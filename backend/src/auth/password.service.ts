import { createHash } from 'node:crypto';
import { Inject, Injectable, Logger } from '@nestjs/common';
import { Algorithm, hash, verify } from '@node-rs/argon2';
import { APP_CONFIG, type AppConfig } from '../config/config';

/**
 * Argon2id with the OWASP baseline (m = 19 MiB, t = 2, p = 1). The PHC
 * string stores the parameters, so hashes made with older parameters are
 * upgraded at the next successful sign-in.
 */
export const ARGON2_OPTIONS = {
  algorithm: Algorithm.Argon2id,
  memoryCost: 19456,
  timeCost: 2,
  parallelism: 1,
} as const;

const CURRENT_PARAMS = `m=${ARGON2_OPTIONS.memoryCost},t=${ARGON2_OPTIONS.timeCost},p=${ARGON2_OPTIONS.parallelism}`;

export interface BreachChecker {
  /** True when the password appears in known breaches; null when unknown (service unreachable). */
  isBreached(password: string): Promise<boolean | null>;
}
export const BREACH_CHECKER = Symbol('BREACH_CHECKER');

/**
 * Have I Been Pwned range API (k-anonymity): only the first 5 hex characters
 * of the SHA-1 leave the server, with response padding.
 */
export class PwnedPasswordsChecker implements BreachChecker {
  private readonly log = new Logger('BreachCheck');

  async isBreached(password: string): Promise<boolean | null> {
    const sha1 = createHash('sha1').update(password, 'utf8').digest('hex').toUpperCase();
    const prefix = sha1.slice(0, 5);
    const suffix = sha1.slice(5);
    try {
      const response = await fetch(`https://api.pwnedpasswords.com/range/${prefix}`, {
        headers: { 'Add-Padding': 'true', 'User-Agent': 'science-adventure-api' },
        signal: AbortSignal.timeout(3000),
      });
      if (!response.ok) return null;
      const body = await response.text();
      return body.split('\n').some((line) => {
        const [candidate, count] = line.trim().split(':');
        return candidate === suffix && Number(count) > 0;
      });
    } catch {
      this.log.warn('Breached-password service unreachable; sign-up continues without the check');
      return null;
    }
  }
}

export class NoBreachCheck implements BreachChecker {
  isBreached(): Promise<boolean | null> {
    return Promise.resolve(false);
  }
}

@Injectable()
export class PasswordService {
  /** Used for unknown emails so a failed sign-in takes as long as a real one. */
  private dummyHash: Promise<string> | null = null;

  constructor(
    @Inject(BREACH_CHECKER) private readonly breaches: BreachChecker,
    @Inject(APP_CONFIG) private readonly config: AppConfig,
  ) {}

  hash(password: string): Promise<string> {
    return hash(password, ARGON2_OPTIONS);
  }

  async verify(phc: string, password: string): Promise<boolean> {
    try {
      return await verify(phc, password);
    } catch {
      return false;
    }
  }

  async burnTime(password: string): Promise<void> {
    this.dummyHash ??= this.hash('not-a-real-password-for-timing');
    await this.verify(await this.dummyHash, password);
  }

  needsRehash(phc: string): boolean {
    return !phc.startsWith('$argon2id$') || !phc.includes(`$${CURRENT_PARAMS}$`);
  }

  async isBreached(password: string): Promise<boolean> {
    if (!this.config.breachedPasswordCheck) return false;
    return (await this.breaches.isBreached(password)) === true;
  }
}
