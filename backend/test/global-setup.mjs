import { execFileSync } from 'node:child_process';
import { randomBytes } from 'node:crypto';
import { mkdtempSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

/** Starts PostgreSQL (unless CI provides one) and applies every migration. */
export default async function globalSetup() {
  let url = process.env.TEST_DATABASE_URL;
  if (!url) {
    const { default: EmbeddedPostgres } = await import('embedded-postgres');
    const password = randomBytes(12).toString('hex');
    const port = 55000 + Math.floor(Math.random() * 5000);
    const pg = new EmbeddedPostgres({
      databaseDir: mkdtempSync(join(tmpdir(), 'sa-e2e-')),
      user: 'e2e',
      password,
      port,
      persistent: false,
      initdbFlags: ['--encoding=UTF8', '--locale=C'],
      onLog: () => {},
    });
    await pg.initialise();
    await pg.start();
    await pg.createDatabase('e2e');
    globalThis.__EMBEDDED_PG__ = pg;
    url = `postgresql://e2e:${password}@127.0.0.1:${port}/e2e`;
    process.env.TEST_DATABASE_URL = url;
  }
  execFileSync(
    process.execPath,
    [join('node_modules', 'prisma', 'build', 'index.js'), 'migrate', 'deploy'],
    {
      env: { ...process.env, DATABASE_URL: url },
      stdio: 'pipe',
    },
  );
}
