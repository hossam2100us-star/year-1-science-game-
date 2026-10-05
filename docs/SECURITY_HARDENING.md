# Security hardening and threat model

Scope: the offline Android app as of milestone M1, plus requirements already
fixed for the account and sync work (M3/M4). Findings are from
`reports/Security_Findings.md` (SEC-01..SEC-06) and the audit register.

## 1. What is protected

| Asset | Where | Sensitivity |
|---|---|---|
| Child first name, gender, avatar | Hive box `science_adventure_v1` (app sandbox) | Personal data of a child |
| Child photo (optional) | Same box, base64 PNG ≤ 512 px, metadata stripped | Most sensitive |
| Progress, attempts, journeys, usage seconds | Same box | Educational record |
| Parent-area access | Parent gate | Child safety only |
| Release signing key | Owner's offline storage (never in Git) | Update continuity |

## 2. Threats considered (offline app)

| Threat | Mitigation in place | Residual risk |
|---|---|---|
| Another app reads the child's data | Android sandbox; no exported providers or services; `taskAffinity=""` | Low (rooted devices only) |
| Data leaves via cloud backup / device transfer | `allowBackup=false`, `fullBackupContent=false`, `data_extraction_rules.xml` excludes every domain | Low |
| Network exfiltration | No INTERNET permission; CI fails if a release APK requests any platform permission | None today |
| Photo metadata (location) leaks | Re-encoded to PNG, EXIF dropped, 20 MB input / 60 MP / 3 MB output caps | Low |
| Path traversal through the native sound bridge | Allowlist of 12 names; volume clamped | Low |
| A child reaches parent settings | Parent gate: two-digit × one-digit problem, new problem after each failure, 30 s lock after 3 failures (SEC-03) | Accepted: it is a child-safety check, **not** authentication |
| Corrupted save locks the child out | Per-child tolerant parsing, quarantine, last-good copy, rescue export (AUD-006) | Low |
| Diagnostics leak child data | `AppLog` stores error *types* and trimmed stacks only, never error text; no names/photos in messages; nothing is sent (SEC-04) | Low |
| Markup / control characters in names reach a future web page or email | Input filtered to letters, marks, space, `-`, `'`, ≤ 24 (SEC-05); output must still be encoded on the server | Low |
| Reverse engineering of release code | Release builds use `--obfuscate --split-debug-info`; R8 + resource shrinking (SEC-02) | Accepted |
| Loss of the signing key | Custody procedure in `docs/RELEASE.md` | **Owner action** (SEC-06) |
| Vulnerable dependencies / leaked secrets | `security-scan` workflow: gitleaks on full history + osv-scanner on every push and weekly | Low |

## 3. Decisions

* **Local data is not encrypted** (ADR-0003). A lost Keystore key would
  destroy every child's progress; the sandbox plus disabled backups already
  cover the realistic threats. Revisit for shared or managed devices.
* **The parent gate is not authentication.** Anything that must be
  protected against an adult (accounts, data export to a server, deletion
  on the server) will require the parent's password (M3/M4).

## 4. Changes made in M1

| ID | Change | Evidence |
|---|---|---|
| SEC-02 | Release build commands with obfuscation; CI builds an obfuscated AAB and per-ABI APKs with a throwaway key | `.github/workflows/ci-mobile.yml`, `docs/RELEASE.md` |
| SEC-03 | Stronger gate with cooldown | `lib/parent/parent_gate.dart`, `test/parent_gate_test.dart` |
| SEC-04 | Privacy-safe diagnostics | `lib/core/diagnostics/`, `test/diagnostics_test.dart` |
| SEC-05 | Name validation on input | `lib/core/validation.dart`, `test/web/child_name_test.dart` |
| SEC-06 | Key custody documented; key creation is an owner action | `docs/RELEASE.md` §4 |
| — | Secret and dependency scanning; pypdf 6.10.0 → 6.19.0 (osv findings in the local content tool) | `.github/workflows/security-scan.yml`, `scripts/requirements-content.txt` |

## 5. Requirements for accounts and sync (M3/M4)

From `Future_System_Architecture.pdf` §9-§10; these are acceptance criteria
for the later milestones.

1. Parent-owned accounts verified by email; children have no credentials.
2. Argon2id (m = 19 MiB, t = 2, p = 1, tuned to 100-300 ms), PHC strings;
   breached-password check; 12-128 character passwords; no composition rules.
3. Access JWT ≈ 15 min (asymmetric, `kid` rotation, no PII); refresh token
   opaque 256-bit, only its hash stored, rotation with reuse detection that
   revokes the whole family.
4. Android: refresh token in Keystore-backed `flutter_secure_storage`, access
   token in memory. Web: refresh token in an `HttpOnly; Secure;
   SameSite=Strict` cookie scoped to `/api/v1/auth`, access token in memory,
   CSRF header on refresh. Never `localStorage` for long-lived tokens.
5. Every query scoped by the `user_id` from the token; child resources
   resolved with `id AND user_id`; cross-account access returns 404; BOLA
   tests for every resource.
6. Generic auth errors (no account enumeration); rate limits per IP and
   account; audit log without passwords, tokens or child PII.
7. Photos not synced by default; export and deletion endpoints (14-day
   grace period).
8. Never logged: passwords, tokens, Authorization/Cookie headers, child
   names, photos, plaintext emails.

## 6. Server controls implemented in M3

Each requirement from section 5, where it lives, and the test that checks it
(`backend/`; tests run against a real PostgreSQL 17).

| # | Control | Where | Test |
|---|---|---|---|
| 1 | Parent accounts only; email verification; sync blocked until verified | `auth.service.ts`, `sync.controller.ts` | `auth.e2e-spec.ts` (verify flow, `email_not_verified`) |
| 2 | Argon2id m=19 MiB t=2 p=1, PHC strings, rehash on sign-in; 12-128 code points after NFKC; HIBP k-anonymity check (fails open, logged) | `password.service.ts`, `contract/schemas.ts` | hash format, short password, no plaintext stored |
| 3 | EdDSA access JWT 15 min with `kid`, no PII; opaque 256-bit refresh token, SHA-256 hash stored, rotation, reuse revokes the family + email alert; 30-day sliding / 90-day absolute | `jwt.ts`, `token.service.ts`, `auth.service.ts` | `jwt.spec.ts` (tamper, alg confusion, expiry), rotation/reuse/race tests |
| 3b | Session checked on every request: sign-out, password change and deletion take effect at once | `jwt.guard.ts` | "signs out at once" |
| 4 | Web refresh token only in `HttpOnly; SameSite=Strict; Path=/api/v1/auth` cookie, CSRF header required | `auth.controller.ts` | web cookie test |
| 5 | Owner from the token only; repositories always take `userId`; `:childId` resolved with owner and not deleted, else 404; database trigger rejects a row whose owner differs from its child's | `child.repository.ts`, `child-ownership.guard.ts`, migration | `bola.e2e-spec.ts` (every REST resource and every sync mutation as another family) |
| 6 | Generic sign-in and sign-up answers; rate limits per IP (all routes, tighter on auth) and per account+IP for failed sign-ins with growing delay | `auth.service.ts`, `attempt-limiter.ts`, `app.module.ts` | lockout test, rate-limit test, `attempt-limiter.spec.ts` |
| 7 | No photo fields in the API at all; export (3/hour) and deletion with a 14-day grace period, erased by the maintenance job; sign-in during the grace period cancels it | `users.service.ts`, `maintenance.service.ts` | `account.e2e-spec.ts` |
| 8 | Logs never contain bodies; redaction of auth headers, cookies, passwords, tokens, emails, child names; IPs truncated (/24, /48); audit log holds no emails or names | `common/logging.ts`, `audit.service.ts` | `logging.spec.ts`; audit checked after erasure; smoke run checked the real log |
| 9 | RFC 9457 errors without stack traces; helmet (CSP `default-src 'none'`, nosniff, no `x-powered-by`); 64 KB body limit (1 MB for sync push) | `problem.filter.ts`, `app.factory.ts` | `platform.e2e-spec.ts` |
| 10 | Configuration validated at boot, no secret defaults, `*_FILE` secrets, refuses rate limits off or the test mailer in production, errors name variables but never values | `config/config.ts` | `config.spec.ts` |
| 11 | Database refuses non-UTF-8 encodings (Arabic names) | first migration | "refuses to install on a database that cannot store Arabic names" |
| 12 | Container runs as `node` (non-root), health check, migrations on start; image scanned by Trivy in CI | `backend/Dockerfile` | `ci-backend.yml` |

Known limits (trial scale): rate-limit and failed-sign-in counters are in
memory (one API container); emails are sent after the response without a
retry queue; the breached-password check fails open when the service is
unreachable.