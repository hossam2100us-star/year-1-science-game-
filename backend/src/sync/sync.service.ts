import { Injectable } from '@nestjs/common';
import { AuditService } from '../audit/audit.service';
import { AuthService, type Platform } from '../auth/auth.service';
import { childFields, ChildRepository, settingsFields } from '../children/child.repository';
import { ChildrenService } from '../children/children.service';
import { attemptFields } from '../children/reports.service';
import { issuesToFieldErrors } from '../common/zod.pipe';
import { Problem } from '../common/problem';
import { type ChildFields, Mutation, type Settings } from '../contract/schemas';
import { Prisma } from '../generated/prisma/client';
import { PrismaService, type Tx } from '../prisma/prisma.service';
import { CHILD_RULES, mergeFields, sameAttempt, SETTINGS_RULES } from './merge';

export type MutationStatus = 'applied' | 'duplicate' | 'conflict' | 'rejected';

export interface MutationResult {
  mutationId: string;
  status: MutationStatus;
  version?: number;
  changeSeq?: number;
  conflictFields?: string[];
  server?: Record<string, unknown> | null;
  error?: { code: string; detail?: string };
}

type Outcome = Omit<MutationResult, 'mutationId'>;

export const TOMBSTONE_HORIZON = 'tombstone_horizon';

const seq = (value: bigint) => Number(value);

function rejected(code: string, detail?: string): Outcome {
  return { status: 'rejected', error: detail ? { code, detail } : { code } };
}

function pick<T extends object>(source: T, keys: (keyof T)[]): Partial<T> {
  return Object.fromEntries(keys.map((k) => [k, source[k]])) as Partial<T>;
}

@Injectable()
export class SyncService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly children: ChildrenService,
    private readonly repo: ChildRepository,
    private readonly audit: AuditService,
    private readonly auth: AuthService,
  ) {}

  // ---- push ----------------------------------------------------------------

  async push(
    userId: string,
    deviceId: string,
    platform: Platform | undefined,
    mutations: { mutationId: string }[],
  ): Promise<{ results: MutationResult[] }> {
    await this.prisma.$transaction(async (tx) => {
      const known = await tx.device.findUnique({ where: { userId_id: { userId, id: deviceId } } });
      await this.auth.touchDevice(
        tx,
        userId,
        deviceId,
        platform ?? (known?.platform as Platform) ?? 'android',
      );
    });
    const results: MutationResult[] = [];
    for (const raw of mutations) {
      const parsed = Mutation.safeParse(raw);
      if (!parsed.success) {
        const first = issuesToFieldErrors(parsed.error.issues)[0];
        results.push({
          mutationId: raw.mutationId,
          ...rejected('validation_failed', first ? `${first.path}: ${first.message}` : undefined),
        });
        continue;
      }
      results.push(await this.applyOne(userId, deviceId, parsed.data));
    }
    return { results };
  }

  /** One transaction per mutation, holding the account lock; idempotent by mutationId. */
  private applyOne(userId: string, deviceId: string, m: Mutation): Promise<MutationResult> {
    return this.prisma.withAccountLock(userId, async (tx) => {
      const stored = await tx.processedMutation.findUnique({
        where: { userId_mutationId: { userId, mutationId: m.mutationId } },
      });
      if (stored) return stored.result as unknown as MutationResult;
      const result: MutationResult = {
        mutationId: m.mutationId,
        ...(await this.dispatch(tx, userId, deviceId, m)),
      };
      await tx.processedMutation.create({
        data: {
          userId,
          mutationId: m.mutationId,
          result: result as unknown as Prisma.InputJsonObject,
        },
      });
      return result;
    });
  }

  private dispatch(tx: Tx, userId: string, deviceId: string, m: Mutation): Promise<Outcome> {
    switch (m.entity) {
      case 'child':
        if (m.op === 'create') {
          const { settings, ...fields } = m.payload;
          return this.createChild(tx, userId, m.id, fields, settings);
        }
        if (m.op === 'patch') {
          return this.patchChild(tx, userId, m.id, m.payload, m.base, m.baseVersion);
        }
        return this.deleteChild(tx, userId, m.id);
      case 'settings':
        return this.patchSettings(tx, userId, m.childId, m.payload, m.base, m.baseVersion);
      case 'attempt':
        return m.op === 'create'
          ? this.createAttempt(tx, userId, m.childId, m.id, m.payload)
          : this.deleteAttempt(tx, userId, m.childId, m.id);
      case 'journey':
        return m.op === 'put'
          ? this.putJourney(tx, userId, m.childId, m.curriculum, m.key, m.baseVersion, m.payload)
          : this.deleteJourney(tx, userId, m.childId, m.curriculum, m.key);
      case 'usage':
        return this.putUsage(tx, userId, m.childId, deviceId, m.day, m.payload.seconds);
    }
  }

  /** Live child of this account, or the reason it cannot be used. */
  private async liveChild(tx: Tx, userId: string, childId: string) {
    const row = await this.repo.findOwned(tx, userId, childId);
    if (!row) return { error: rejected('child_not_found') };
    if (row.deletedAt) return { error: rejected('child_deleted'), deleted: true as const };
    return { child: await this.repo.findLive(tx, userId, childId) };
  }

  private async createChild(
    tx: Tx,
    userId: string,
    id: string,
    fields: ChildFields,
    settings?: Settings,
  ) {
    const outcome = await this.children.createInTx(tx, userId, id, fields, settings);
    switch (outcome.kind) {
      case 'created':
        return {
          status: 'applied' as const,
          version: outcome.child.version,
          changeSeq: seq(outcome.child.changeSeq),
        };
      case 'existing':
        return {
          status: 'duplicate' as const,
          version: outcome.child.version,
          changeSeq: seq(outcome.child.changeSeq),
        };
      case 'different': {
        const child = (await this.repo.findLive(tx, userId, id))!;
        return {
          status: 'conflict' as const,
          version: child.version,
          changeSeq: seq(child.changeSeq),
          conflictFields: (Object.keys(fields) as (keyof ChildFields)[]).filter(
            (k) => childFields(child)[k] !== fields[k],
          ),
          server: { kind: 'child', ...childFields(child), version: child.version },
        };
      }
      case 'deleted':
        return rejected('child_deleted');
      case 'limit':
        return rejected('child_limit');
      case 'unavailable':
        return rejected('id_unavailable');
    }
  }

  private async patchChild(
    tx: Tx,
    userId: string,
    id: string,
    patch: Partial<ChildFields>,
    base: Partial<ChildFields> | undefined,
    baseVersion: number,
  ): Promise<Outcome> {
    const found = await this.liveChild(tx, userId, id);
    if (!found.child) return found.error!;
    let child = found.child;
    const merge = mergeFields(
      childFields(child),
      patch,
      base,
      baseVersion,
      child.version,
      CHILD_RULES,
    );
    if (merge.applied.length) {
      child = await this.repo.update(tx, userId, child, pick(merge.next, merge.applied));
    }
    if (merge.overwritten.length) {
      await this.audit.record(
        'settings_overwritten',
        userId,
        overwrittenMeta('child', merge.overwritten),
        tx,
      );
    }
    return {
      status: merge.conflicts.length ? 'conflict' : 'applied',
      version: child.version,
      changeSeq: seq(child.changeSeq),
      ...(merge.conflicts.length
        ? {
            conflictFields: merge.conflicts,
            server: { kind: 'child', ...childFields(child), version: child.version },
          }
        : {}),
    };
  }

  private async deleteChild(tx: Tx, userId: string, id: string): Promise<Outcome> {
    const row = await this.repo.findOwned(tx, userId, id);
    if (!row) return rejected('child_not_found');
    if (row.deletedAt) {
      return { status: 'applied', version: row.version, changeSeq: seq(row.changeSeq) };
    }
    const tomb = await this.repo.tombstone(tx, userId, id);
    await this.audit.record('child_deleted', userId, {}, tx);
    return { status: 'applied', version: tomb.version, changeSeq: seq(tomb.changeSeq) };
  }

  private async patchSettings(
    tx: Tx,
    userId: string,
    childId: string,
    patch: Partial<Settings>,
    base: Partial<Settings> | undefined,
    baseVersion: number,
  ): Promise<Outcome> {
    const found = await this.liveChild(tx, userId, childId);
    if (!found.child) return found.error!;
    let row = await this.repo.settings(tx, userId, childId);
    if (!row) return rejected('child_not_found');
    const merge = mergeFields(
      settingsFields(row),
      patch,
      base,
      baseVersion,
      row.version,
      SETTINGS_RULES,
    );
    if (merge.applied.length) {
      row = await this.repo.updateSettings(tx, userId, childId, pick(merge.next, merge.applied));
    }
    if (merge.overwritten.length) {
      await this.audit.record(
        'settings_overwritten',
        userId,
        overwrittenMeta('settings', merge.overwritten),
        tx,
      );
    }
    return { status: 'applied', version: row.version, changeSeq: seq(row.changeSeq) };
  }

  private async createAttempt(
    tx: Tx,
    userId: string,
    childId: string,
    id: string,
    fields: ReturnType<typeof attemptFields>,
  ): Promise<Outcome> {
    const found = await this.liveChild(tx, userId, childId);
    if (!found.child) return found.error!;
    const existing = await tx.unitAttempt.findUnique({
      where: { id },
      include: { objectives: true },
    });
    if (existing) {
      if (existing.userId !== userId || existing.childId !== childId) {
        return rejected('id_unavailable');
      }
      // Attempts are append-only and immutable (§14); a tombstoned one stays deleted.
      if (existing.deletedAt || sameAttempt(attemptFields(existing), fields)) {
        return { status: 'duplicate', changeSeq: seq(existing.changeSeq) };
      }
      return rejected('immutable', 'An attempt never changes after it is recorded.');
    }
    const { objectives, ...scalars } = fields;
    const created = await tx.unitAttempt.create({
      data: {
        id,
        childId,
        userId,
        ...scalars,
        objectives: {
          create: Object.entries(objectives).map(([objectiveId, outcome]) => ({
            objectiveId,
            outcome,
          })),
        },
      },
    });
    return { status: 'applied', changeSeq: seq(created.changeSeq) };
  }

  private async deleteAttempt(
    tx: Tx,
    userId: string,
    childId: string,
    id: string,
  ): Promise<Outcome> {
    const found = await this.liveChild(tx, userId, childId);
    if (found.deleted) return { status: 'applied' };
    if (!found.child) return found.error!;
    const row = await tx.unitAttempt.findFirst({ where: { id, childId, userId } });
    if (!row || row.deletedAt) {
      return { status: 'applied', ...(row ? { changeSeq: seq(row.changeSeq) } : {}) };
    }
    const tomb = await tx.unitAttempt.update({ where: { id }, data: { deletedAt: new Date() } });
    return { status: 'applied', changeSeq: seq(tomb.changeSeq) };
  }

  private async putJourney(
    tx: Tx,
    userId: string,
    childId: string,
    curriculum: string,
    journeyKey: string,
    baseVersion: number,
    payload: { state: Record<string, unknown>; contentVersion?: number | null | undefined },
  ): Promise<Outcome> {
    const found = await this.liveChild(tx, userId, childId);
    if (!found.child) return found.error!;
    const key = { childId_curriculum_journeyKey: { childId, curriculum, journeyKey } };
    const row = await tx.journey.findFirst({ where: { childId, userId, curriculum, journeyKey } });
    const data = {
      state: payload.state as Prisma.InputJsonObject,
      contentVersion: payload.contentVersion ?? null,
    };
    if (!row) {
      const created = await tx.journey.create({
        data: { childId, userId, curriculum, journeyKey, ...data, version: 1 },
      });
      return { status: 'applied', version: created.version, changeSeq: seq(created.changeSeq) };
    }
    if (row.version !== baseVersion) {
      // Another device moved this lesson on: the device merges (progress never
      // goes backwards, first outcome per objective kept) and pushes again.
      return {
        status: 'conflict',
        version: row.version,
        changeSeq: seq(row.changeSeq),
        server: row.deletedAt
          ? null
          : {
              kind: 'journey',
              state: row.state,
              contentVersion: row.contentVersion,
              version: row.version,
            },
      };
    }
    const updated = await tx.journey.update({
      where: key,
      data: { ...data, deletedAt: null, version: { increment: 1 } },
    });
    return { status: 'applied', version: updated.version, changeSeq: seq(updated.changeSeq) };
  }

  private async deleteJourney(
    tx: Tx,
    userId: string,
    childId: string,
    curriculum: string,
    journeyKey: string,
  ): Promise<Outcome> {
    const found = await this.liveChild(tx, userId, childId);
    if (found.deleted) return { status: 'applied' };
    if (!found.child) return found.error!;
    const row = await tx.journey.findFirst({ where: { childId, userId, curriculum, journeyKey } });
    if (!row || row.deletedAt) {
      return {
        status: 'applied',
        ...(row ? { version: row.version, changeSeq: seq(row.changeSeq) } : {}),
      };
    }
    const tomb = await tx.journey.update({
      where: { childId_curriculum_journeyKey: { childId, curriculum, journeyKey } },
      data: { state: Prisma.DbNull, deletedAt: new Date(), version: { increment: 1 } },
    });
    return { status: 'applied', version: tomb.version, changeSeq: seq(tomb.changeSeq) };
  }

  private async putUsage(
    tx: Tx,
    userId: string,
    childId: string,
    deviceId: string,
    day: string,
    seconds: number,
  ): Promise<Outcome> {
    const found = await this.liveChild(tx, userId, childId);
    if (!found.child) return found.error!;
    const key = { childId_deviceId_day: { childId, deviceId, day } };
    const row = await tx.usageDaily.findUnique({ where: key });
    if (!row) {
      const created = await tx.usageDaily.create({
        data: { childId, userId, deviceId, day, seconds },
      });
      return { status: 'applied', changeSeq: seq(created.changeSeq) };
    }
    if (seconds <= row.seconds) return { status: 'applied', changeSeq: seq(row.changeSeq) };
    const updated = await tx.usageDaily.update({ where: key, data: { seconds } });
    return { status: 'applied', changeSeq: seq(updated.changeSeq) };
  }

  // ---- pull ----------------------------------------------------------------

  async pull(userId: string, since: number, limit: number) {
    const horizon = await this.prisma.serverMeta.findUnique({ where: { key: TOMBSTONE_HORIZON } });
    if (since > 0 && horizon && since < Number(horizon.value)) {
      throw Problem.gone(
        'cursor_expired',
        'Your device was offline for too long. Starting a full resync.',
      );
    }
    const rows = await this.prisma.$queryRaw<
      { entity: string; change_seq: bigint; payload: Record<string, unknown> }[]
    >`
      SELECT entity, change_seq, payload FROM (
        SELECT 'child' AS entity, c.change_seq, jsonb_build_object(
            'id', c.id, 'version', c.version, 'deleted', c.deleted_at IS NOT NULL,
            'data', CASE WHEN c.deleted_at IS NULL THEN jsonb_build_object(
              'displayName', c.display_name, 'gender', c.gender, 'avatar', c.avatar, 'palette', c.palette) END
          ) AS payload
        FROM child_profiles c WHERE c.user_id = ${userId}::uuid AND c.change_seq > ${since}
        UNION ALL
        SELECT 'settings', s.change_seq, jsonb_build_object(
            'childId', s.child_id, 'version', s.version,
            'data', jsonb_build_object(
              'arabic', s.arabic, 'breakMinutes', s.break_minutes, 'sound', s.sound, 'music', s.music,
              'narration', s.narration, 'volume', s.volume, 'boyVoice', s.boy_voice, 'girlVoice', s.girl_voice))
        FROM child_settings s WHERE s.user_id = ${userId}::uuid AND s.change_seq > ${since}
        UNION ALL
        SELECT 'attempt', a.change_seq, jsonb_build_object(
            'id', a.id, 'childId', a.child_id, 'deleted', a.deleted_at IS NOT NULL,
            'data', CASE WHEN a.deleted_at IS NULL THEN jsonb_build_object(
              'curriculum', a.curriculum, 'unitId', a.unit_id, 'contentVersion', a.content_version,
              'completed', a.completed, 'effortStars', a.effort_stars, 'completedAt', a.completed_at,
              'clientAttemptId', a.legacy_attempt_id,
              'objectives', COALESCE((SELECT jsonb_object_agg(o.objective_id, o.outcome)
                                        FROM attempt_objectives o WHERE o.attempt_id = a.id), '{}'::jsonb)) END)
        FROM unit_attempts a WHERE a.user_id = ${userId}::uuid AND a.change_seq > ${since}
        UNION ALL
        SELECT 'journey', j.change_seq, jsonb_build_object(
            'childId', j.child_id, 'curriculum', j.curriculum, 'key', j.journey_key, 'version', j.version,
            'deleted', j.deleted_at IS NOT NULL,
            'data', CASE WHEN j.deleted_at IS NULL THEN jsonb_build_object(
              'state', j.state, 'contentVersion', j.content_version) END)
        FROM journeys j WHERE j.user_id = ${userId}::uuid AND j.change_seq > ${since}
        UNION ALL
        SELECT 'usage', u.change_seq, jsonb_build_object(
            'childId', u.child_id, 'deviceId', u.device_id, 'day', u.day, 'seconds', u.seconds)
        FROM usage_daily u WHERE u.user_id = ${userId}::uuid AND u.change_seq > ${since}
      ) changes
      ORDER BY change_seq
      LIMIT ${limit + 1}`;
    const page = rows.slice(0, limit);
    return {
      changes: page.map((r) => toChange(r.entity, seq(r.change_seq), r.payload)),
      cursor: page.length ? seq(page[page.length - 1]!.change_seq) : since,
      hasMore: rows.length > limit,
    };
  }
}

function overwrittenMeta(
  entity: string,
  list: { field: string; previous: unknown }[],
): Prisma.InputJsonObject {
  // Field names and old values of settings, avatar and colours only: no names.
  return {
    entity,
    fields: list.map((o) => o.field),
    previous: Object.fromEntries(list.map((o) => [o.field, o.previous ?? null])),
  };
}

function toChange(entity: string, changeSeq: number, p: Record<string, unknown>) {
  const op = p['deleted'] ? 'delete' : 'upsert';
  const data = p['data'] ?? undefined;
  switch (entity) {
    case 'child':
      return {
        entity,
        op,
        id: p['id'],
        changeSeq,
        version: p['version'],
        ...(data ? { data } : {}),
      };
    case 'settings':
      return {
        entity,
        op: 'upsert',
        childId: p['childId'],
        changeSeq,
        version: p['version'],
        data,
      };
    case 'attempt':
      return {
        entity,
        op,
        id: p['id'],
        childId: p['childId'],
        changeSeq,
        ...(data ? { data } : {}),
      };
    case 'journey':
      return {
        entity,
        op,
        childId: p['childId'],
        curriculum: p['curriculum'],
        key: p['key'],
        changeSeq,
        version: p['version'],
        ...(data ? { data } : {}),
      };
    default:
      return {
        entity: 'usage',
        op: 'upsert',
        childId: p['childId'],
        deviceId: p['deviceId'],
        day: p['day'],
        seconds: p['seconds'],
        changeSeq,
      };
  }
}
