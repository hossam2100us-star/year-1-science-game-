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
