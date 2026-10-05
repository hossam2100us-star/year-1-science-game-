// Creates the settings files for one deployment (for example the Synology
// NAS trial) with fresh secrets. Nothing secret is printed.
//
//   node backend/scripts/generate-env.mjs --out-dir infrastructure/nas --public-url https://NAME.synology.me
//
// Writes two files so each container only sees what it needs:
//   db.env   database name, user and password (database + backup containers)
//   api.env  everything the API needs (including the same database password)
// Refuses to overwrite: a new signing key signs every device out, and a new
// database password would no longer match the existing database.
import { Buffer } from 'node:buffer';
import { generateKeyPairSync, randomBytes } from 'node:crypto';
import { existsSync, mkdirSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { parseArgs } from 'node:util';

const { values } = parseArgs({
  options: {
    'out-dir': { type: 'string' },
    'public-url': { type: 'string' },
    'consent-version': { type: 'string', default: 'trial-2026-10' },
    'trust-proxy': { type: 'string', default: '2' },
  },
});
const dir = values['out-dir'];
const publicUrl = values['public-url'];
if (!dir || !publicUrl || !/^https:\/\/[a-z0-9.-]+$/i.test(publicUrl)) {
  console.error('Usage: node generate-env.mjs --out-dir <folder> --public-url https://<host>');
  process.exit(2);
}
const dbFile = join(dir, 'db.env');
const apiFile = join(dir, 'api.env');
for (const file of [dbFile, apiFile]) {
  if (existsSync(file)) {
    console.error(`${file} already exists; nothing was changed.`);
    process.exit(1);
  }
}

const { privateKey } = generateKeyPairSync('ed25519');
const pem = privateKey.export({ type: 'pkcs8', format: 'pem' }).toString();
const dbPassword = randomBytes(24).toString('base64url');
const keyId = `k${new Date().toISOString().slice(0, 10).replaceAll('-', '')}`;
const header = [
  '# Science Adventure settings. PRIVATE: holds secrets.',
  '# Never commit, never send by chat or email. Keep a copy with the NAS backups.',
  '',
];

const db = [
  ...header,
  'POSTGRES_USER=science',
  `POSTGRES_PASSWORD=${dbPassword}`,
  'POSTGRES_DB=science_adventure',
  '',
];

const api = [
  ...header,
  '# Database (same password as db.env).',
  `DATABASE_URL=postgresql://science:${dbPassword}@db:5432/science_adventure`,
  '',
  '# Sign-in key. Changing it signs every device out.',
  `JWT_KEY_ID=${keyId}`,
  `JWT_PRIVATE_KEY=${Buffer.from(pem).toString('base64')}`,
  '',
  '# The address parents open; also used in emailed links.',
  `PUBLIC_WEB_URL=${publicUrl}`,
  '# Hops in front of the API: Synology reverse proxy, then the web container.',
  `TRUST_PROXY=${values['trust-proxy']}`,
  '',
  '# Email through Gmail: smtps://YOUR_ADDRESS%40gmail.com:APP_PASSWORD@smtp.gmail.com:465',
  '# (an "App password" from your Google account, not your normal password;',
  '# write @ in the address as %40).',
  'SMTP_URL=',
  'EMAIL_FROM=Science Adventure <YOUR_ADDRESS@gmail.com>',
  '',
  '# Optional: only these addresses may create accounts (comma separated).',
  '# Empty = anyone who has the link.',
  'SIGNUP_ALLOWED_EMAILS=',
  '',
  '# Google sign-in: the "Web application" OAuth client ID (not a secret).',
  'GOOGLE_CLIENT_IDS=',
  '',
  `CONSENT_VERSION=${values['consent-version']}`,
  '',
];

mkdirSync(dir, { recursive: true });
writeFileSync(dbFile, db.join('\n'), { mode: 0o600, flag: 'wx' });
writeFileSync(apiFile, api.join('\n'), { mode: 0o600, flag: 'wx' });
console.log(`Created ${dbFile} and ${apiFile}. Fill in SMTP_URL, EMAIL_FROM and GOOGLE_CLIENT_IDS in api.env.`);
