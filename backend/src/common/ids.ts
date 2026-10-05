import { randomBytes } from 'node:crypto';

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;

/** Lower-case canonical UUID text (the only form the API accepts). */
export function isUuid(value: unknown): value is string {
  return typeof value === 'string' && UUID.test(value);
}

/**
 * RFC 9562 UUIDv7: 48-bit Unix milliseconds, then random bits. Same layout
 * as the app's `Ids.uuidV7`, so server and device IDs sort the same way.
 */
export function uuidv7(now: number = Date.now(), random: Buffer = randomBytes(10)): string {
  const bytes = Buffer.alloc(16);
  bytes.writeUIntBE(now, 0, 6);
  random.copy(bytes, 6, 0, 10);
  bytes[6] = (bytes[6]! & 0x0f) | 0x70;
  bytes[8] = (bytes[8]! & 0x3f) | 0x80;
  const hex = bytes.toString('hex');
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20)}`;
}
