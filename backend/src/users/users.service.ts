import { Inject, Injectable } from '@nestjs/common';
import { AuditService } from '../audit/audit.service';
import { AuthService, publicUser } from '../auth/auth.service';
import { childDto, isLive, settingsDto } from '../children/child.repository';
import { attemptDto } from '../children/reports.service';
import { Problem } from '../common/problem';
import { APP_CONFIG, type AppConfig } from '../config/config';
import { EmailService } from '../email/email.service';
import { PrismaService } from '../prisma/prisma.service';

const DAY = 24 * 60 * 60 * 1000;

@Injectable()
export class UsersService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auth: AuthService,
    private readonly audit: AuditService,
    private readonly email: EmailService,
    @Inject(APP_CONFIG) private readonly config: AppConfig,
  ) {}

  async me(userId: string) {
    return publicUser(
      await this.prisma.user.findUniqueOrThrow({
        where: { id: userId },
        include: { identities: { select: { provider: true } } },
      }),
    );
  }

  /**
   * Soft delete with a grace period (§9): sessions end now; the account and
   * every child's data are erased by the maintenance job afterwards.
   * Signing in again before then cancels it.
   */
  async scheduleDeletion(userId: string, proof: { password: string } | { googleIdToken: string }) {
    const user = await this.auth.confirmIdentity(userId, proof);
    const when = new Date(Date.now() + this.config.accountDeletionGraceDays * DAY);
    await this.prisma.$transaction(async (tx) => {
      await tx.user.update({
        where: { id: userId },
        data: { status: 'pending_deletion', deletionScheduledAt: when },
      });
      await this.auth.revokeFamilies({ userId }, tx);
    });
    await this.audit.record('account_deletion_requested', userId);
    this.email.deletionScheduled(user.email, when);
    return { deletionScheduledAt: when.toISOString() };
  }

  /** Everything stored for the account, as JSON (right of access). */
  async export(userId: string) {
    const since = new Date(Date.now() - 60 * 60 * 1000);
    if ((await this.audit.countSince(userId, 'data_export', since)) >= 3) {
      throw Problem.tooMany(15 * 60);
    }
    const user = await this.prisma.user.findUniqueOrThrow({
      where: { id: userId },
      include: {
        devices: true,
        identities: { select: { provider: true, createdAt: true } },
        children: {
          where: { deletedAt: null },
          include: {
            settings: true,
            attempts: {
              where: { deletedAt: null },
              include: { objectives: true },
              orderBy: { completedAt: 'asc' },
            },
            journeys: { where: { deletedAt: null } },
            usage: true,
          },
          orderBy: { createdAt: 'asc' },
        },
      },
    });
    await this.audit.record('data_export', userId);
    return {
      exportedAt: new Date().toISOString(),
      user: {
        ...publicUser(user),
        consentVersion: user.consentVersion,
        consentedAt: user.consentedAt.toISOString(),
      },
      devices: user.devices.map((d) => ({
        id: d.id,
        platform: d.platform,
        lastSeenAt: d.lastSeenAt.toISOString(),
      })),
      children: user.children.filter(isLive).map((child) => ({
        ...childDto(child),
        settings: child.settings ? settingsDto(child.settings) : null,
        attempts: child.attempts.map(attemptDto),
        journeys: child.journeys.map((j) => ({
          curriculum: j.curriculum,
          key: j.journeyKey,
          version: j.version,
          contentVersion: j.contentVersion,
          state: j.state,
        })),
        usage: child.usage.map((u) => ({ deviceId: u.deviceId, day: u.day, seconds: u.seconds })),
      })),
    };
  }
}
