import { Injectable } from '@nestjs/common';
import { Problem } from '../common/problem';
import { type AttemptFields } from '../contract/schemas';
import { type AttemptObjective, type UnitAttempt } from '../generated/prisma/client';
import { PrismaService } from '../prisma/prisma.service';

type AttemptRow = UnitAttempt & { objectives: AttemptObjective[] };

export function attemptFields(row: AttemptRow): AttemptFields {
  return {
    curriculum: row.curriculum,
    unitId: row.unitId,
    contentVersion: row.contentVersion,
    completed: row.completed,
    effortStars: row.effortStars,
    completedAt: row.completedAt,
    clientAttemptId: row.clientAttemptId,
    objectives: Object.fromEntries(
      row.objectives.map((o) => [o.objectiveId, o.outcome as AttemptFields['objectives'][string]]),
    ),
  };
}

export function attemptDto(row: AttemptRow) {
  return { id: row.id, childId: row.childId, ...attemptFields(row) };
}

function summary(row: AttemptRow) {
  const outcomes = row.objectives.map((o) => o.outcome);
  return {
    id: row.id,
    completedAt: row.completedAt,
    completed: row.completed,
    effortStars: row.effortStars,
    objectives: outcomes.length,
    firstTry: outcomes.filter((o) => o === 'firstTry').length,
    afterHint: outcomes.filter((o) => o === 'afterHint').length,
    explained: outcomes.filter((o) => o === 'explained').length,
  };
}

/** Latest first: device time, then the time-ordered ID as a tie-break. */
function newer(a: AttemptRow, b: AttemptRow): number {
  return a.completedAt === b.completedAt
    ? b.id.localeCompare(a.id)
    : b.completedAt.localeCompare(a.completedAt);
}

/** "Best" = most first-try decisions (share), then more effort stars, then latest. */
function better(a: AttemptRow, b: AttemptRow): number {
  const share = (r: AttemptRow) =>
    r.objectives.length
      ? r.objectives.filter((o) => o.outcome === 'firstTry').length / r.objectives.length
      : 0;
  return share(b) - share(a) || b.effortStars - a.effortStars || newer(a, b);
}

interface Cursor {
  c: string;
  i: string;
}

function encodeCursor(row: AttemptRow): string {
  return Buffer.from(JSON.stringify({ c: row.completedAt, i: row.id } satisfies Cursor)).toString(
    'base64url',
  );
}

function decodeCursor(value: string): Cursor {
  try {
    const parsed = JSON.parse(Buffer.from(value, 'base64url').toString('utf8')) as Partial<Cursor>;
    if (typeof parsed.c === 'string' && typeof parsed.i === 'string') {
      return { c: parsed.c, i: parsed.i };
    }
  } catch {
    // fall through
  }
  throw Problem.badRequest('invalid_cursor');
}

@Injectable()
export class ReportsService {
  constructor(private readonly prisma: PrismaService) {}

  /** The caller has already passed ChildOwnershipGuard; queries still filter by owner. */
  async attempts(
    userId: string,
    childId: string,
    unitId: string | undefined,
    cursor: string | undefined,
    limit: number,
  ) {
    const after = cursor ? decodeCursor(cursor) : null;
    const rows = await this.prisma.unitAttempt.findMany({
      where: {
        childId,
        userId,
        deletedAt: null,
        ...(unitId ? { unitId } : {}),
        ...(after
          ? {
              OR: [{ completedAt: { lt: after.c } }, { completedAt: after.c, id: { lt: after.i } }],
            }
          : {}),
      },
      include: { objectives: true },
      orderBy: [{ completedAt: 'desc' }, { id: 'desc' }],
      take: limit + 1,
    });
    const page = rows.slice(0, limit);
    return {
      items: page.map(attemptDto),
      nextCursor: rows.length > limit ? encodeCursor(page[page.length - 1]!) : null,
    };
  }

  async summary(userId: string, childId: string) {
    const rows = await this.prisma.unitAttempt.findMany({
      where: { childId, userId, deletedAt: null },
      include: { objectives: true },
    });
    const byUnit = new Map<string, AttemptRow[]>();
    for (const row of rows) {
      const key = `${row.curriculum}\u0000${row.unitId}`;
      byUnit.set(key, [...(byUnit.get(key) ?? []), row]);
    }
    const units = [...byUnit.values()]
      .map((list) => {
        const latest = [...list].sort(newer)[0]!;
        const best = [...list].sort(better)[0]!;
        return {
          curriculum: latest.curriculum,
          unitId: latest.unitId,
          attempts: list.length,
          latest: summary(latest),
          best: summary(best),
        };
      })
      .sort((a, b) => a.curriculum.localeCompare(b.curriculum) || a.unitId.localeCompare(b.unitId));

    const usage = await this.prisma.usageDaily.groupBy({
      by: ['day'],
      where: { childId, userId },
      _sum: { seconds: true },
      orderBy: { day: 'desc' },
      take: 90,
    });
    return {
      units,
      usage: usage
        .map((u) => ({ day: u.day, seconds: u._sum.seconds ?? 0 }))
        .sort((a, b) => a.day.localeCompare(b.day)),
    };
  }
}
