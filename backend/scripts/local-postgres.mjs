// Runs a local PostgreSQL 17 for development on machines without Docker.
//
//   node scripts/local-postgres.mjs            start and keep running (Ctrl+C stops)
//   node scripts/local-postgres.mjs --reset    wipe the local data first
//
// Data lives in backend/.local-db (git-ignored). The connection string is
// printed once; it only accepts connections from this computer.
import { randomBytes } from 'node:crypto';
import { existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import EmbeddedPostgres from 'embedded-postgres';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const dataDir = join(root, '.local-db');
const secretFile = join(root, '.local-db.secret');
const port = Number(process.env.LOCAL_PG_PORT ?? 54320);

if (process.argv.includes('--reset')) {
  rmSync(dataDir, { recursive: true, force: true });
  rmSync(secretFile, { force: true });
}

const fresh = !existsSync(join(dataDir, 'PG_VERSION'));
if (!existsSync(secretFile)) {
  writeFileSync(secretFile, randomBytes(18).toString('base64url'), { mode: 0o600 });
}
const password = readFileSync(secretFile, 'utf8').trim();

const pg = new EmbeddedPostgres({
  databaseDir: dataDir,
  user: 'science',
  password,
  port,
  persistent: true,
  initdbFlags: ['--encoding=UTF8', '--locale=C'],
  onLog: () => {},
});

if (fresh) {
  mkdirSync(dataDir, { recursive: true });
  await pg.initialise();
}
await pg.start();
if (fresh) await pg.createDatabase('science_adventure');

console.log(`DATABASE_URL=postgresql://science:${password}@127.0.0.1:${port}/science_adventure`);
console.log('Local PostgreSQL is running. Press Ctrl+C to stop.');

const stop = async () => {
  await pg.stop();
  process.exit(0);
};
process.on('SIGINT', stop);
process.on('SIGTERM', stop);
setInterval(() => {}, 1 << 30);
