import { Injectable } from '@nestjs/common';
import { type ChildFields, DEFAULT_SETTINGS, type Settings } from '../contract/schemas';
import { type ChildProfile, type ChildSettings } from '../generated/prisma/client';
import { type Tx } from '../prisma/prisma.service';

/**
 * Every query takes the owner's user ID (§5, §10): there is deliberately no
 * "find child by id" without an owner, so a guessed ID from another family
 * behaves exactly like an ID that does not exist.
 */
interface LiveFields {
  displayName: string;
  gender: 'boy' | 'girl';
  avatar: number;
  palette: ChildFields['palette'];
}
export type LiveChild = ChildProfile & LiveFields;

export const MAX_CHILDREN = 10;

export function isLive<T extends ChildProfile>(row: T | null): row is T & LiveFields {
  return row !== null && row.deletedAt === null;
}

export function childFields(row: LiveChild): Required<ChildFields> {
  return {
    displayName: row.displayName,
    gender: row.gender,
    avatar: row.avatar,
    palette: row.palette,
    // Saved before school years (or by an app that sent none): Year 1.
    schoolYear: row.schoolYear ?? 'y1',
  };
}

export function childDto(row: LiveChild) {
  return {
    id: row.id,
    ...childFields(row),
    version: row.version,
    createdAt: row.createdAt.toISOString(),
    updatedAt: row.updatedAt.toISOString(),
  };
}

export function settingsFields(row: ChildSettings): Settings {
  return {
    arabic: row.arabic,
    breakMinutes: row.breakMinutes,
    sound: row.sound,
    music: row.music,
    narration: row.narration,
    volume: row.volume,
    boyVoice: row.boyVoice,
    girlVoice: row.girlVoice,
  };
}

export function settingsDto(row: ChildSettings) {
  return { ...settingsFields(row), version: row.version };
}

@Injectable()
export class ChildRepository {
  /** Any row with this ID owned by `userId`, including a tombstone. */
  findOwned(tx: Tx, userId: string, childId: string): Promise<ChildProfile | null> {
    return tx.childProfile.findFirst({ where: { id: childId, userId } });
  }

  async findLive(tx: Tx, userId: string, childId: string): Promise<LiveChild | null> {
    const row = await this.findOwned(tx, userId, childId);
    return isLive(row) ? row : null;
  }

  async listLive(tx: Tx, userId: string): Promise<LiveChild[]> {
    const rows = await tx.childProfile.findMany({
      where: { userId, deletedAt: null },
      orderBy: [{ createdAt: 'asc' }, { id: 'asc' }],
    });
    return rows.filter(isLive);
  }

  countLive(tx: Tx, userId: string): Promise<number> {
    return tx.childProfile.count({ where: { userId, deletedAt: null } });
  }

  /** True when the ID is taken by anyone (any family, live or deleted). */
  async idTaken(tx: Tx, childId: string): Promise<boolean> {
    return (await tx.childProfile.count({ where: { id: childId } })) > 0;
  }

  async create(tx: Tx, userId: string, id: string, fields: ChildFields, settings?: Settings) {
    const child = (await tx.childProfile.create({
      data: { id, userId, ...fields, version: 1 },
    })) as LiveChild;
    const prefs = await tx.childSettings.create({
      data: { childId: id, userId, ...(settings ?? DEFAULT_SETTINGS), version: 1 },
    });
    return { child, settings: prefs };
  }

  async update(
    tx: Tx,
    userId: string,
    child: LiveChild,
    fields: Partial<ChildFields>,
  ): Promise<LiveChild> {
    const updated = await tx.childProfile.update({
      where: { id: child.id, userId },
      data: { ...fields, version: { increment: 1 } },
    });
    return updated as LiveChild;
  }

  /**
   * Deleting a child erases their data at once (privacy intent, §14 "delete
   * wins"); only a tombstone with the ID remains so other devices learn of
   * the deletion on their next sync.
   */
  async tombstone(tx: Tx, userId: string, childId: string): Promise<ChildProfile> {
    await tx.childSettings.deleteMany({ where: { childId, userId } });
    await tx.unitAttempt.deleteMany({ where: { childId, userId } });
    await tx.journey.deleteMany({ where: { childId, userId } });
    await tx.usageDaily.deleteMany({ where: { childId, userId } });
    return tx.childProfile.update({
      where: { id: childId, userId },
      data: {
        displayName: null,
        gender: null,
        avatar: null,
        palette: null,
        schoolYear: null,
        deletedAt: new Date(),
        version: { increment: 1 },
      },
    });
  }

  settings(tx: Tx, userId: string, childId: string): Promise<ChildSettings | null> {
    return tx.childSettings.findFirst({ where: { childId, userId } });
  }

  async updateSettings(tx: Tx, userId: string, childId: string, fields: Partial<Settings>) {
    return tx.childSettings.update({
      where: { childId, userId },
      data: { ...fields, version: { increment: 1 } },
    });
  }
}
