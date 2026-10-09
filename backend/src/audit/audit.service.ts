import { Injectable } from '@nestjs/common';
import { PrismaService, type Tx } from '../prisma/prisma.service';
import { type Prisma } from '../generated/prisma/client';

/** Account and security events (§17). `meta` must never hold emails, names, tokens or passwords. */
export type AuditAction =
  | 'register'
  | 'register_blocked'
  | 'email_verified'
  | 'google_linked'
  | 'login_success'
  | 'login_failed'
  | 'logout'
  | 'logout_all'
  | 'refresh_reuse_detected'
  | 'password_changed'
  | 'password_reset'
  | 'child_created'
  | 'child_deleted'
  | 'settings_overwritten'
  | 'account_deletion_requested'
  | 'account_deletion_cancelled'
  | 'account_erased'
  | 'data_export';

@Injectable()
export class AuditService {
  constructor(private readonly prisma: PrismaService) {}

  async record(
    action: AuditAction,
    userId: string | null,
    meta: Prisma.InputJsonObject = {},
    tx?: Tx,
  ): Promise<void> {
    await (tx ?? this.prisma).auditLog.create({ data: { action, userId, meta } });
  }

  async countSince(userId: string, action: AuditAction, since: Date): Promise<number> {
    return this.prisma.auditLog.count({ where: { userId, action, createdAt: { gte: since } } });
  }
}
