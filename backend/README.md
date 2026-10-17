# My School Adventures API

Parent accounts and offline-first progress sync for the My School Adventures
app. The contract is [`../api/openapi.yaml`](../api/openapi.yaml); design
decisions are ADR-0011 to ADR-0016 in
[`../docs/ARCHITECTURE_DECISIONS.md`](../docs/ARCHITECTURE_DECISIONS.md) and
the security controls are listed in
[`../docs/SECURITY_HARDENING.md`](../docs/SECURITY_HARDENING.md) §6.

Gameplay never depends on this server: the app works fully offline and
without an account.

## Run it locally (Windows, no Docker)

```powershell
cd backend
npm ci
node scripts/local-postgres.mjs          # keeps running; prints DATABASE_URL
```

In a second terminal:

```powershell
cd backend
$env:DATABASE_URL = '<the URL printed above>'
npx prisma migrate deploy
copy .env.example .env                   # then fill in JWT_PRIVATE_KEY (see below)
npm run build
node dist/src/main.js
```

`node scripts/generate-env.mjs --out <file> --public-url <url>` creates a
complete settings file with fresh secrets (an Ed25519 signing key and a
database password) without printing them.

With Docker, `docker compose -f ../infrastructure/docker-compose.dev.yml up -d`
starts PostgreSQL 17 and Mailpit (emails at http://localhost:8025).

## Tests

| Command | What |
|---|---|
| `npm test` | unit tests (no database) |
| `npm run test:e2e` | end-to-end tests on a real PostgreSQL 17 (embedded locally, `TEST_DATABASE_URL` in CI); every response is checked against the OpenAPI contract |
| `npm run lint`, `npm run typecheck`, `npm run format:check`, `npm run openapi:lint` | static checks |

## Layout

```
src/
  app.factory.ts      HTTP setup: security headers, body limits, proxy trust
  config/             environment validation (fails fast, no secret defaults)
  common/             problem+json errors, logging redaction, ids
  contract/           request schemas (mirror api/openapi.yaml)
  auth/               sign-up, sessions, passwords, JWT, guards
  children/           child profiles, settings, reports (owner-scoped repository)
  sync/               push/pull and the merge rules
  users/              account, devices, export, deletion
  maintenance/        hourly clean-up and erasure after the grace period
prisma/               schema and SQL migrations (constraints, change-number trigger)
test/                 end-to-end, contract and BOLA tests
```
