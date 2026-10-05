// Creates a .env file with fresh secrets for one environment (for example
// the Synology NAS trial). Nothing is printed: open the file to read it.
//
//   node scripts/generate-env.mjs --out ../infrastructure/nas/.env --public-url https://science.example.synology.me
//
// Refuses to overwrite an existing file (a new JWT key signs everyone out;
// a new database password no longer matches the existing database).
import { Buffer } from 'node:buffer';
import { generateKeyPairSync, randomBytes } from 'node:crypto';
import { existsSync, writeFileSync } from 'node:fs';
import { parseArgs } from 'node:util';

const { values } = parseArgs({
  options: {
    out: { type: 'string' },
    'public-url': { type: 'string' },
    'consent-version': { type: 'string', default: 'trial-2026-10' },
  },
});
if (!values.out || !values['public-url']) {
  console.error('Usage: node scripts/generate-env.mjs --out <file> --public-url <https://...>');
  process.exit(2);
}
if (existsSync(values.out)) {
  console.error(`${values.out} already exists; nothing was changed.`);
  process.exit(1);
}

const { privateKey } = generateKeyPairSync('ed25519');
const pem = privateKey.export({ type: 'pkcs8', format: 'pem' }).toString();
const dbPassword = randomBytes(24).toString('base64url');
const keyId = `k${new Date().toISOString().slice(0, 10).replaceAll('-', '')}`;

const lines = [
  '# Science Adventure server settings. Keep this file private: it holds secrets.',
  '# Never commit it, never send it by chat or email.',
  '',
  '# Database (used by both the database and the API containers).',
  'POSTGRES_USER=science',
  `POSTGRES_PASSWORD=${dbPassword}`,
  'POSTGRES_DB=science_adventure',
  `DATABASE_URL=postgresql://science:${dbPassword}@db:5432/science_adventure`,
  '',
  '# Sign-in keys. Changing them signs every device out.',
  `JWT_KEY_ID=${keyId}`,
  `JWT_PRIVATE_KEY=${Buffer.from(pem).toString('base64')}`,
  '',
  '# The address parents open (also used in emailed links).',
  `PUBLIC_WEB_URL=${values['public-url']}`,
  '# The NAS reverse proxy is the only hop in front of the API.',
  'TRUST_PROXY=1',
  '',
  '# Email: for Gmail use smtps://YOUR_ADDRESS%40gmail.com:APP_PASSWORD@smtp.gmail.com:465',
  '# (an "App password" from your Google account, not your normal password).',
  'SMTP_URL=',
  'EMAIL_FROM=Science Adventure <no-reply@example.com>',
  '',
  '# Private trial: only these addresses can create accounts (comma separated).',
  '# Leave empty to let anyone with the link sign up.',
  'SIGNUP_ALLOWED_EMAILS=',
  '',
  `CONSENT_VERSION=${values['consent-version']}`,
  '',
];
writeFileSync(values.out, lines.join('\n'), { mode: 0o600, flag: 'wx' });
console.log(`Created ${values.out}. Fill in SMTP_URL, EMAIL_FROM and SIGNUP_ALLOWED_EMAILS.`);
