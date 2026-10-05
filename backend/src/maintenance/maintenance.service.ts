import { Inject, Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { AuditService } from '../audit/audit.service';
import { APP_CONFIG, type AppConfig } from '../config/config';
import { PrismaService, type Tx } from '../prisma/prisma.service';
import { TOMBSTONE_HORIZON } from '../sync/sync.service';

const DAY = 24 * 60 * 60 * 1000;

/**
 * Hourly housekeeping in one transaction holding a transaction-level lock,
 * so two API containers never run it at once and the lock cannot leak
 * through the connection pool. Every step is idempotent.
 */
@Injectable()
export class MaintenanceService {
  private readonly log = new Logger('Maintenance');

  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
    @Inject(APP_CONFIG) private readonly config: AppConfig,
  ) {}

  @Cron(CronExpression.EVERY_HOUR)
  async scheduled(): Promise<void> {
    if (!this.config.maintenance) return;
    try {
      await this.run();
    } catch (error) {
      this.log.error({ err: error }, 'Maintenance failed');
    }
  }

  async run(now: Date = new Date()): Promise<Record<string, number> | null> {
    return this.prisma.$transaction(
      async (tx) => {
        const locked = await tx.$queryRaw<
          { ok: boolean }[]
        >`SELECT pg_try_advisory_xact_lock(2, 1) AS ok`;
        if (!locked[0]?.ok) return null;
        const ago = (days: number) => new Date(now.getTime() - days * DAY);
        return {
          expiredSessions: (
            await tx.refreshToken.deleteMany({
              where: {
                OR: [
                  { familyExpiresAt: { lt: now } },
                  { expiresAt: { lt: ago(1) } },
                  { revokedAt: { lt: ago(30) } },
                ],
              },
            })
          ).count,
          emailTokens: (
            await tx.emailToken.deleteMany({
              where: { OR: [{ expiresAt: { lt: now } }, { usedAt: { not: null } }] },
            })
          ).count,
          processedMutations: (
            await tx.processedMutation.deleteMany({ where: { createdAt: { lt: ago(30) } } })
          ).count,
          idempotencyKeys: (
            await tx.idempotencyKey.deleteMany({ where: { createdAt: { lt: ago(1) } } })
          ).count,
          erasedAccounts: await this.eraseAccounts(tx, now),
          tombstones: await this.purgeTombstones(tx, ago(this.config.tombstoneRetentionDays)),
          auditRows: (await tx.auditLog.deleteMany({ where: { createdAt: { lt: ago(365) } } }))
            .count,
        };
      },
      { maxWait: 10_000, timeout: 300_000 },
    );
  }

  /** Right to erasure: after the grace period every row of the account goes (FK cascades). */
  private async eraseAccounts(tx: Tx, now: Date): Promise<number> {
    const due = await tx.user.findMany({
      where: { status: 'pending_deletion', deletionScheduledAt: { lte: now } },
      select: { id: true },
    });
    for (const { id } of due) {
      await tx.user.delete({ where: { id } });
      await this.audit.record('account_erased', id, {}, tx);
    }
    return due.length;
  }

  /**
   * Tombstones older than the retention window are removed. Devices whose
   * cursor is older than the newest removed tombstone get 410 and resync.
   */
  private async purgeTombstones(tx: Tx, cutoff: Date): Promise<number> {
    const rows = await tx.$queryRaw<{ n: bigint; max: bigint | null }[]>`
      WITH children AS (DELETE FROM child_profiles WHERE deleted_at < ${cutoff} RETURNING change_seq),
           attempts AS (DELETE FROM unit_attempts WHERE deleted_at < ${cutoff} RETURNING change_seq),
           journeys AS (DELETE FROM journeys WHERE deleted_at < ${cutoff} RETURNING change_seq)
      SELECT count(*) AS n, max(change_seq) AS max FROM (
        SELECT change_seq FROM children
        UNION ALL SELECT change_seq FROM attempts
        UNION ALL SELECT change_seq FROM journeys
      ) gone`;
    const max = rows[0]?.max ?? null;
    if (max !== null) {
      await tx.$executeRaw`
        INSERT INTO server_meta (key, value) VALUES (${TOMBSTONE_HORIZON}, ${String(max)})
        ON CONFLICT (key) DO UPDATE
          SET value = GREATEST(server_meta.value::bigint, EXCLUDED.value::bigint)::text`;
    }
    return Number(rows[0]?.n ?? 0);
  }
}
