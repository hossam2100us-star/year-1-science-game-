import { Injectable } from '@nestjs/common';
import { AuditService } from '../audit/audit.service';
import { Problem } from '../common/problem';
import { type ChildFields, type Settings } from '../contract/schemas';
import { PrismaService, type Tx } from '../prisma/prisma.service';
import { sameValue } from '../sync/merge';
import {
  childDto,
  childFields,
  ChildRepository,
  type LiveChild,
  MAX_CHILDREN,
  settingsDto,
  settingsFields,
} from './child.repository';

export type CreateOutcome =
  | { kind: 'created'; child: LiveChild }
  | { kind: 'existing'; child: LiveChild }
  | { kind: 'deleted' }
  | { kind: 'different' }
  | { kind: 'unavailable' }
  | { kind: 'limit' };

/** Business rules shared by the REST endpoints and sync push. */
@Injectable()
export class ChildrenService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly repo: ChildRepository,
    private readonly audit: AuditService,
  ) {}

  async list(userId: string) {
    const rows = await this.repo.listLive(this.prisma, userId);
    return { items: rows.map(childDto) };
  }

  async get(userId: string, childId: string) {
    const child = await this.repo.findLive(this.prisma, userId, childId);
    if (!child) throw Problem.notFound();
    return childDto(child);
  }

  /** Idempotent by the client-chosen ID; must run under the account lock. */
  async createInTx(
    tx: Tx,
    userId: string,
    id: string,
    fields: ChildFields,
    settings?: Settings,
  ): Promise<CreateOutcome> {
    const own = await this.repo.findOwned(tx, userId, id);
    if (own) {
      if (own.deletedAt) return { kind: 'deleted' };
      const live = own as LiveChild;
      const same = (Object.keys(fields) as (keyof ChildFields)[]).every((k) =>
        sameValue(childFields(live)[k], fields[k]),
      );
      return same ? { kind: 'existing', child: live } : { kind: 'different' };
    }
    if (await this.repo.idTaken(tx, id)) return { kind: 'unavailable' };
    if ((await this.repo.countLive(tx, userId)) >= MAX_CHILDREN) return { kind: 'limit' };
    const { child } = await this.repo.create(tx, userId, id, fields, settings);
    await this.audit.record('child_created', userId, {}, tx);
    return { kind: 'created', child };
  }

  async create(userId: string, id: string, fields: ChildFields, settings?: Settings) {
    const outcome = await this.prisma.withAccountLock(userId, (tx) =>
      this.createInTx(tx, userId, id, fields, settings),
    );
    switch (outcome.kind) {
      case 'created':
        return { status: 201, body: childDto(outcome.child) };
      case 'existing':
        return { status: 200, body: childDto(outcome.child) };
      case 'limit':
        throw Problem.unprocessable(
          'child_limit',
          `An account can have at most ${MAX_CHILDREN} children.`,
        );
      default:
        // Deleted, different fields, or another family's ID: one generic answer.
        throw Problem.conflict('id_unavailable', 'This child ID cannot be used.');
    }
  }

  async update(userId: string, childId: string, patch: Partial<ChildFields>, baseVersion: number) {
    return this.prisma.withAccountLock(userId, async (tx) => {
      const child = await this.repo.findLive(tx, userId, childId);
      if (!child) throw Problem.notFound();
      if (child.version !== baseVersion) {
        throw Problem.conflict('version_conflict', 'The child was changed on another device.', {
          server: childDto(child),
        });
      }
      return childDto(await this.repo.update(tx, userId, child, patch));
    });
  }

  async delete(userId: string, childId: string): Promise<void> {
    await this.prisma.withAccountLock(userId, async (tx) => {
      const child = await this.repo.findLive(tx, userId, childId);
      if (!child) throw Problem.notFound();
      await this.repo.tombstone(tx, userId, childId);
      await this.audit.record('child_deleted', userId, {}, tx);
    });
  }

  async getSettings(userId: string, childId: string) {
    const child = await this.repo.findLive(this.prisma, userId, childId);
    const row = child ? await this.repo.settings(this.prisma, userId, childId) : null;
    if (!row) throw Problem.notFound();
    return settingsDto(row);
  }

  async putSettings(userId: string, childId: string, settings: Settings, baseVersion: number) {
    return this.prisma.withAccountLock(userId, async (tx) => {
      const child = await this.repo.findLive(tx, userId, childId);
      const row = child ? await this.repo.settings(tx, userId, childId) : null;
      if (!row) throw Problem.notFound();
      if (row.version !== baseVersion) {
        throw Problem.conflict('version_conflict', 'The settings were changed on another device.', {
          server: settingsDto(row),
        });
      }
      const current = settingsFields(row);
      const changed = (Object.keys(settings) as (keyof Settings)[]).some(
        (k) => !sameValue(current[k], settings[k]),
      );
      if (!changed) return settingsDto(row);
      return settingsDto(await this.repo.updateSettings(tx, userId, childId, settings));
    });
  }
}
