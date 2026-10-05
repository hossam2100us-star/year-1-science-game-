import { setTimeout as sleep } from 'node:timers/promises';
import { Inject, Injectable } from '@nestjs/common';
import { AuditService } from '../audit/audit.service';
import { uuidv7 } from '../common/ids';
import { Problem } from '../common/problem';
import { randomToken, sha256, sha256Hex } from '../common/secrets';
import { APP_CONFIG, type AppConfig } from '../config/config';
import { EmailService } from '../email/email.service';
import { type User } from '../generated/prisma/client';
import { PrismaService, type Tx } from '../prisma/prisma.service';
import { AttemptLimiter } from './attempt-limiter';
import { PasswordService } from './password.service';
import { TokenService } from './token.service';

const DAY = 24 * 60 * 60 * 1000;
export const REFRESH_TTL_MS = 30 * DAY;
export const SESSION_MAX_MS = 90 * DAY;
/** A refresh token presented again this soon after rotating is a race, not theft. */
export const REFRESH_GRACE_MS = 30 * 1000;
const VERIFY_TTL_MS = DAY;
const RESET_TTL_MS = 30 * 60 * 1000;

export type Platform = 'android' | 'web';

export interface IssuedSession {
  accessToken: string;
  tokenType: 'Bearer';
  expiresIn: number;
  refreshToken: string;
  platform: Platform;
  user: PublicUser;
}

export interface PublicUser {
  id: string;
  email: string;
  emailVerified: boolean;
  createdAt: string;
}

export function publicUser(
  user: Pick<User, 'id' | 'email' | 'emailVerifiedAt' | 'createdAt'>,
): PublicUser {
  return {
    id: user.id,
    email: user.email,
    emailVerified: user.emailVerifiedAt !== null,
    createdAt: user.createdAt.toISOString(),
  };
}

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly passwords: PasswordService,
    private readonly tokens: TokenService,
    private readonly email: EmailService,
    private readonly audit: AuditService,
    private readonly limiter: AttemptLimiter,
    @Inject(APP_CONFIG) private readonly config: AppConfig,
  ) {}

  // ---- sign-up and verification --------------------------------------------

  async register(email: string, password: string, consentVersion: string): Promise<void> {
    if (consentVersion !== this.config.consentVersion) {
      throw Problem.unprocessable(
        'consent_outdated',
        'Please read and accept the current consent text.',
      );
    }
    if (await this.passwords.isBreached(password)) {
      throw Problem.unprocessable(
        'password_breached',
        'This password appears in known data breaches. Please choose another one.',
      );
    }
    const allowed = this.config.signupAllowedEmails;
    const existing = await this.prisma.user.findUnique({ where: { email } });
    // Hash in every branch so the answer takes the same time either way.
    const passwordHash = await this.passwords.hash(password);
    if (allowed && !allowed.has(email)) {
      await this.audit.record('register_blocked', null);
      return;
    }
    if (existing) {
      if (existing.emailVerifiedAt) this.email.accountExists(email);
      else await this.sendVerification(existing.id, email);
      return;
    }
    const now = new Date();
    try {
      const user = await this.prisma.user.create({
        data: {
          id: uuidv7(),
          email,
          passwordHash,
          consentVersion,
          consentedAt: now,
        },
      });
      await this.audit.record('register', user.id, { consentVersion });
      await this.sendVerification(user.id, email);
    } catch (error) {
      // A concurrent sign-up with the same email: same answer as "exists".
      if ((error as { code?: string }).code !== 'P2002') throw error;
    }
  }

  async resendVerification(email: string): Promise<void> {
    const user = await this.prisma.user.findUnique({ where: { email } });
    if (!user || user.emailVerifiedAt || user.status !== 'active') return;
    const recent = await this.prisma.emailToken.count({
      where: {
        userId: user.id,
        purpose: 'verify_email',
        createdAt: { gt: new Date(Date.now() - 60 * 60 * 1000) },
      },
    });
    if (recent >= 5) return;
    await this.sendVerification(user.id, email);
  }

  async verifyEmail(token: string): Promise<void> {
    const row = await this.consumeEmailToken(token, 'verify_email');
    await this.prisma.user.updateMany({
      where: { id: row.userId, emailVerifiedAt: null },
      data: { emailVerifiedAt: new Date() },
    });
    await this.audit.record('email_verified', row.userId);
  }

  private async sendVerification(userId: string, email: string): Promise<void> {
    const token = randomToken();
    await this.prisma.emailToken.create({
      data: {
        id: uuidv7(),
        userId,
        purpose: 'verify_email',
        tokenHash: sha256(token),
        expiresAt: new Date(Date.now() + VERIFY_TTL_MS),
      },
    });
    this.email.verifyEmail(email, token);
  }

  private async consumeEmailToken(
    token: string,
    purpose: 'verify_email' | 'reset_password',
    tx?: Tx,
  ) {
    const db = tx ?? this.prisma;
    const row = await db.emailToken.findUnique({ where: { tokenHash: sha256(token) } });
    if (!row || row.purpose !== purpose || row.usedAt || row.expiresAt <= new Date()) {
      throw Problem.badRequest(
        'invalid_token',
        'This link is not valid any more. Please ask for a new one.',
      );
    }
    const used = await db.emailToken.updateMany({
      where: { id: row.id, usedAt: null },
      data: { usedAt: new Date() },
    });
    if (used.count !== 1) throw Problem.badRequest('invalid_token');
    return row;
  }

  // ---- sessions ------------------------------------------------------------

  async login(
    email: string,
    password: string,
    deviceId: string,
    platform: Platform,
    ip: string,
  ): Promise<IssuedSession> {
    const accountKey = sha256Hex(email);
    const wait = this.limiter.retryAfter(accountKey, ip);
    if (wait > 0) throw Problem.tooMany(wait);
    const delay = this.limiter.delayFor(accountKey, ip);
    if (delay > 0) await sleep(delay);

    const user = await this.prisma.user.findUnique({ where: { email } });
    const ok = user ? await this.passwords.verify(user.passwordHash, password) : false;
    if (!user) await this.passwords.burnTime(password);
    if (!user || !ok) {
      this.limiter.fail(accountKey, ip);
      if (user) await this.audit.record('login_failed', user.id);
      throw Problem.unauthorized('invalid_credentials', 'The email or password is not correct.');
    }
    this.limiter.succeed(accountKey, ip);

    let current = user;
    if (user.status === 'pending_deletion') {
      current = await this.prisma.user.update({
        where: { id: user.id },
        data: { status: 'active', deletionScheduledAt: null },
      });
      await this.audit.record('account_deletion_cancelled', user.id);
      this.email.deletionCancelled(user.email);
    }
    if (this.passwords.needsRehash(user.passwordHash)) {
      current = await this.prisma.user.update({
        where: { id: user.id },
        data: { passwordHash: await this.passwords.hash(password) },
      });
    }
    const session = await this.prisma.$transaction(async (tx) => {
      await this.touchDevice(tx, user.id, deviceId, platform);
      return this.createFamily(tx, user.id, deviceId, platform);
    });
    await this.audit.record('login_success', user.id, { platform });
    return this.issue(current, session.familyId, session.refreshToken, platform);
  }

  async refresh(refreshToken: string): Promise<IssuedSession> {
    const now = new Date();
    const row = await this.prisma.refreshToken.findUnique({
      where: { tokenHash: sha256(refreshToken) },
      include: { user: true },
    });
    if (!row) throw Problem.unauthorized('invalid_token');
    if (row.revokedAt) throw Problem.unauthorized('session_revoked');
    if (row.replacedAt) {
      if (now.getTime() - row.replacedAt.getTime() < REFRESH_GRACE_MS) {
        throw Problem.conflict(
          'refresh_superseded',
          'This sign-in key was just renewed by another request.',
        );
      }
      await this.revokeFamilies({ familyId: row.familyId });
      await this.audit.record('refresh_reuse_detected', row.userId, { platform: row.platform });
      this.email.securityAlert(row.user.email);
      throw Problem.unauthorized('session_revoked');
    }
    if (row.expiresAt <= now || row.familyExpiresAt <= now || row.user.status !== 'active') {
      throw Problem.unauthorized('session_expired');
    }
    const next = randomToken();
    const nextId = uuidv7();
    await this.prisma.$transaction(async (tx) => {
      const claimed = await tx.refreshToken.updateMany({
        where: { id: row.id, replacedAt: null, revokedAt: null },
        data: { replacedAt: now, replacedById: nextId },
      });
      if (claimed.count !== 1) {
        throw Problem.conflict(
          'refresh_superseded',
          'This sign-in key was just renewed by another request.',
        );
      }
      await tx.refreshToken.create({
        data: {
          id: nextId,
          userId: row.userId,
          familyId: row.familyId,
          tokenHash: sha256(next),
          deviceId: row.deviceId,
          platform: row.platform,
          expiresAt: new Date(
            Math.min(now.getTime() + REFRESH_TTL_MS, row.familyExpiresAt.getTime()),
          ),
          familyExpiresAt: row.familyExpiresAt,
        },
      });
      await this.touchDevice(tx, row.userId, row.deviceId, row.platform as Platform);
    });
    return this.issue(row.user, row.familyId, next, row.platform as Platform);
  }

  async logout(userId: string, sessionId: string, all: boolean): Promise<void> {
    if (all) {
      await this.revokeFamilies({ userId });
      await this.audit.record('logout_all', userId);
    } else {
      await this.revokeFamilies({ familyId: sessionId, userId });
      await this.audit.record('logout', userId);
    }
  }

  // ---- passwords -----------------------------------------------------------

  async forgotPassword(email: string): Promise<void> {
    const user = await this.prisma.user.findUnique({ where: { email } });
    if (!user || user.status !== 'active') return;
    const recent = await this.prisma.emailToken.count({
      where: {
        userId: user.id,
        purpose: 'reset_password',
        createdAt: { gt: new Date(Date.now() - 60 * 60 * 1000) },
      },
    });
    if (recent >= 5) return;
    const token = randomToken();
    await this.prisma.emailToken.create({
      data: {
        id: uuidv7(),
        userId: user.id,
        purpose: 'reset_password',
        tokenHash: sha256(token),
        expiresAt: new Date(Date.now() + RESET_TTL_MS),
      },
    });
    this.email.resetPassword(email, token);
  }

  async resetPassword(token: string, newPassword: string): Promise<void> {
    if (await this.passwords.isBreached(newPassword)) {
      throw Problem.unprocessable(
        'password_breached',
        'This password appears in known data breaches.',
      );
    }
    const passwordHash = await this.passwords.hash(newPassword);
    const user = await this.prisma.$transaction(async (tx) => {
      const row = await this.consumeEmailToken(token, 'reset_password', tx);
      // The emailed link also proves the address belongs to the parent.
      await tx.user.updateMany({
        where: { id: row.userId, emailVerifiedAt: null },
        data: { emailVerifiedAt: new Date() },
      });
      const updated = await tx.user.update({ where: { id: row.userId }, data: { passwordHash } });
      await tx.refreshToken.updateMany({
        where: { userId: row.userId, revokedAt: null },
        data: { revokedAt: new Date() },
      });
      return updated;
    });
    await this.audit.record('password_reset', user.id);
    this.email.passwordChanged(user.email);
  }

  async changePassword(
    userId: string,
    sessionId: string,
    currentPassword: string,
    newPassword: string,
  ): Promise<void> {
    const user = await this.prisma.user.findUniqueOrThrow({ where: { id: userId } });
    if (!(await this.passwords.verify(user.passwordHash, currentPassword))) {
      throw Problem.unauthorized('invalid_credentials', 'The current password is not correct.');
    }
    if (await this.passwords.isBreached(newPassword)) {
      throw Problem.unprocessable(
        'password_breached',
        'This password appears in known data breaches.',
      );
    }
    const passwordHash = await this.passwords.hash(newPassword);
    await this.prisma.$transaction([
      this.prisma.user.update({ where: { id: userId }, data: { passwordHash } }),
      this.prisma.refreshToken.updateMany({
        where: { userId, revokedAt: null, NOT: { familyId: sessionId } },
        data: { revokedAt: new Date() },
      }),
    ]);
    await this.audit.record('password_changed', userId);
    this.email.passwordChanged(user.email);
  }

  /** Confirms the password for sensitive actions (account deletion). */
  async confirmPassword(userId: string, password: string): Promise<User> {
    const user = await this.prisma.user.findUniqueOrThrow({ where: { id: userId } });
    if (!(await this.passwords.verify(user.passwordHash, password))) {
      throw Problem.unauthorized('invalid_credentials', 'The password is not correct.');
    }
    return user;
  }

  async revokeFamilies(where: { familyId?: string; userId?: string }, tx?: Tx): Promise<void> {
    await (tx ?? this.prisma).refreshToken.updateMany({
      where: { ...where, revokedAt: null },
      data: { revokedAt: new Date() },
    });
  }

  // ---- helpers -------------------------------------------------------------

  private async createFamily(tx: Tx, userId: string, deviceId: string, platform: Platform) {
    const now = Date.now();
    const familyId = uuidv7();
    const refreshToken = randomToken();
    await tx.refreshToken.create({
      data: {
        id: uuidv7(),
        userId,
        familyId,
        tokenHash: sha256(refreshToken),
        deviceId,
        platform,
        expiresAt: new Date(now + REFRESH_TTL_MS),
        familyExpiresAt: new Date(now + SESSION_MAX_MS),
      },
    });
    return { familyId, refreshToken };
  }

  async touchDevice(tx: Tx, userId: string, deviceId: string, platform: Platform): Promise<void> {
    await tx.device.upsert({
      where: { userId_id: { userId, id: deviceId } },
      create: { userId, id: deviceId, platform },
      update: { platform, lastSeenAt: new Date() },
    });
  }

  private async issue(
    user: User,
    familyId: string,
    refreshToken: string,
    platform: Platform,
  ): Promise<IssuedSession> {
    return {
      accessToken: await this.tokens.signAccess({ userId: user.id, sessionId: familyId }),
      tokenType: 'Bearer',
      expiresIn: this.tokens.accessTtlSeconds,
      refreshToken,
      platform,
      user: publicUser(user),
    };
  }
}
