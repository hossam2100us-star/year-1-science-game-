# Test report

Every result below was actually run; anything not run says **NOT RUN** and
why. Host: Windows 11 Pro, toolchain from `.tools/` (Flutter 3.47.5,
Dart 3.13.4, JDK 21). CI: GitHub Actions (`ubuntu-latest`,
`windows-latest`).

## Baseline before any change (branch point `2089a97`, 2026-10-04)

| Check | Command | Result |
|---|---|---|
| Toolchain | `flutter --version` | Flutter 3.47.5 · Dart 3.13.4 |
| Dependencies | `flutter pub get --enforce-lockfile` | PASS |
| Static analysis | `flutter analyze` (3 lint rules) | PASS, no issues |
| Formatting | `dart format --set-exit-if-changed lib test` | FAIL: `test/lesson_navigation_test.dart` unformatted |
| Tests | `flutter test` | **224 / 224 passed** in 88 s; wrote review PNGs into `tmp/` |
| Android debug build | `flutter build apk --debug` | PASS, 233,199,084 bytes (222.4 MB) |
| Web tests | `flutter test --platform chrome` | **NOT RUN locally**: headless Chrome hangs at "loading" for every test file on this machine (also with the sandbox disabled). Runs in CI instead. |
| Release build | — | **NOT RUN locally**: no `android/key.properties` (by design). Built in CI with a throwaway key. |
| Device / emulator | — | **NOT RUN**: no device or emulator available. |

## After milestone M1 (branch `remediation/m1-audit-fixes`)

### Local

| Check | Command | Result |
|---|---|---|
| Static analysis | `flutter analyze --fatal-infos` with flutter_lints + async rules | PASS, no issues |
| Formatting | `dart format --output=none --set-exit-if-changed lib test` | PASS |
| Unit and widget tests | `flutter test --exclude-tags golden` | **286 / 286 passed** in 90 s |
| Golden tests | `flutter test --tags golden` | **5 / 5 passed** |
| Side effects | count files written to `tmp/` during a full run | **0** (was ~94 PNGs) |
| Android debug build | `flutter build apk --debug` | PASS, 198.5 MB |
| Web compile check for AUD-005 | `dart compile js` + Node run of a probe | Old `nextInt(1 << 32)`: **RangeError**; new `Ids.uuidV7`: valid, 5,000 unique |

Test files: 52 (was 35 at the audit). New suites: IDs, settings, save model
and storage corruption, recovery UI, diagnostics, parent gate, build side
effects, entry points, asset hygiene, localisation, name validation,
contrast, name batches, image budget, goldens.

### CI (GitHub Actions)

| Job | Result |
|---|---|
| analyze-and-test (ubuntu) | PASS (run on `f0f3649`) |
| web-tests (`flutter test --platform chrome test/web`) | PASS — AUD-005 verified in real Chrome |
| web-build | skipped (no `web/` target yet; added in M4) |
| content-validation (`validate_playable.py`) | PASS |
| goldens (windows-latest) | PASS, 5/5 |
| android-build (debug, obfuscated release AAB, per-ABI release APKs, permission check) | PASS: release builds succeed with obfuscation; no platform permissions in release APKs |
| security-scan: gitleaks | PASS (no secrets in history) |
| security-scan: osv-scanner | Found 30+ advisories in `pypdf 6.10.0` and 2 in `sharp 0.34.4` (local tooling only); both upgraded |

## Measurements

| Metric | Before | After | How |
|---|---|---|---|
| Bundled image bytes | 50.6 MB (29 files) | 7.1 MB | `tools/images/optimize.mjs` report |
| Images inside debug APK | ≈ 45.7 MB (audit) | 7.1 MB | zip entry sizes |
| Debug APK | 222.4 MB | 198.5 MB | file size |
| Image quality | — | PSNR 32.5-41.3 dB on the game background | same tool; owner reviewed comparisons |
| Release AAB (obfuscated, all ABIs) | never built (audit) | 61,938,245 bytes (59.1 MB) | CI, throwaway key |
| Release APK per ABI | never built | arm64 26.7 MB · armv7 24.3 MB · x86_64 28.2 MB (MiB) | CI `--split-per-abi` |
| Startup time, memory on device | NOT MEASURED | NOT MEASURED | no device available |

## Milestone M2 (branch `remediation/m2-data-layer`)

### Local

| Check | Command | Result |
|---|---|---|
| Static analysis | `flutter analyze --fatal-infos` | PASS, no issues |
| Formatting | `dart format --set-exit-if-changed lib test` | PASS |
| Unit and widget tests | `flutter test --exclude-tags golden,benchmark` | **340+ passed** (latest full run: 340 + 9 lesson tests) |
| Golden tests | `flutter test --tags golden` | 5 / 5 passed |
| Android debug build | `flutter build apk --debug` | PASS; `libsqlite3.so` packaged for arm64-v8a, armeabi-v7a, x86_64 |
| Journey characterization | 4,134 saved states | identical restore results before and after the migration-registry refactor; a deliberate mutation is detected |
| Typed journey round-trip | 8,000+ saved and migrated journeys | exact round-trip through `JourneyState` |
| Hive → SQLite migration matrix | `test/data/hive_to_drift_test.dart` | 12 / 12 passed |
| SQLite store | `test/data/drift_store_test.dart` | 7 / 7 passed (one changed journey = 1 write; unchanged save = 0) |
| Startup storage choice | `test/data/storage_bootstrap_test.dart` | 7 / 7 passed |

### Measurements (development PC, Windows; not a tablet)

| Metric | Before (Hive blob) | After (SQLite) |
|---|---|---|
| One save, 10 children with photos (4.15 MB save) | 115-118 ms | 26 ms |
| Statements written when one journey changes | whole blob | 1 |
| Usage writes per hour of play | 360 | 60 |
| One-time migration of that family | — | 1.67-1.72 s |

Real-device startup time and memory: **NOT MEASURED** yet (no phone or
tablet connected); emulator figures below.

### Android emulator (2026-10-05)

Emulator: Android 14 (API 34, x86_64 Google APIs image), AVD
`low_ram_tablet` — 2 GB RAM, 4 cores, 1280×800. The host GPU driver
crashed the emulator twice (an emulator/graphics-driver fault, not the
app), so the later checks ran with software rendering
(`-gpu swiftshader_indirect`). The host CPU is much faster than a cheap
tablet, so timings are optimistic. Debug builds only.

| Check | How | Result |
|---|---|---|
| Upgrade keeps saved progress (AUD-004, AUD-006) | Installed the old `main` build (`2089a97`); created two children through the UI; played 3 of 7 discoveries in unit 1 "Garden explorers"; copied the Hive file off the device (34,722 bytes); installed the M2 build **over it** with `adb install -r` | **PASS.** First launch created `science_adventure.sqlite`; both children shown; the unit resumed at 3 / 7 with the same three discoveries starred; the grown-ups area shows "3 of 7, 3 first time". The Hive file is still there (34,762 bytes: unchanged data plus the 40-byte migration marker). |
| Saving after the move | Played one more discovery, force-stopped the app (and the emulator itself crashed once), relaunched | **PASS.** Resumed at 4 / 7; the grown-ups area shows 4 of 7. |
| Child order on the chooser | Compared before and after | Same as the old build: the child who played last is listed last (existing behaviour, unchanged). |
| Scene sounds (AUD-020) | Unit 6 "Music studio": tapped all five instruments, then 12 rapid taps alternating two instruments | **PASS.** All five counted ("5 / 5"); Android's audio service lists the app's player as `state:started` while a sound plays; each new tap replaces the previous player; no ANR, crash or frozen screen in `logcat`. |
| Home during a sound | Tapped an instrument, pressed Home after 0.3 s, reopened | **PASS.** Sound stopped (no started player left); same process resumed at the same screen. |
| Cold start | `adb shell am start -W` after `force-stop`, three runs | 3.6 / 3.9 / 4.0 s (debug build, software rendering). First launch after the upgrade, including the migration: 6.8 s (host GPU). The old build's first launch was 9.6 s (debug). |
| Memory (AUD-008) | `dumpsys meminfo`: in unit 6, back on the grown-ups area, then after opening and leaving four units three times | Total PSS 281 → 286 → 293 → 296 → 295 MB: it levels off instead of growing with each unit (debug build, which is much larger than release). |

Not yet run on a real phone or tablet, and not yet with a release build on
a device.
## Milestone M3 (branch `remediation/m3-backend`)

Server in `backend/` (NestJS 11, Prisma 7, PostgreSQL 17); contract in
`api/openapi.yaml`. Locally the tests start an embedded PostgreSQL 17.10
(UTF-8); CI uses a `postgres:17` service container.

| Check | Command | Result |
|---|---|---|
| Contract lint | `npm run openapi:lint` (Redocly, recommended rules) | PASS (2 documented ignores: health probes have no 4xx) |
| Format | `npm run format:check` | PASS |
| Lint | `npm run lint` (typescript-eslint, type-checked rules) | PASS |
| Types | `npm run typecheck` (strict, `noUncheckedIndexedAccess`) | PASS |
| Unit tests | `npm test` | **37 / 37** (merge rules incl. 2,000 randomised merges, JWT, config, log redaction, sign-in limiter) |
| End-to-end tests | `npm run test:e2e` | **68 / 68** in ≈ 23 s: auth 19, children 9, BOLA 12, sync 17, account 5, platform 6 — every response validated against the OpenAPI contract |
| Migrations | `prisma migrate deploy` on an empty database, then `prisma migrate diff --exit-code` | PASS, no drift |
| Build | `npm run build` | PASS |
| Smoke run | built `dist/src/main.js` against local PostgreSQL | health/ready OK, register 202, login 200, pull before verification 403; the server log contained no password, email or token |
| Docker image + Trivy | `ci-backend.yml` | **NOT RUN locally** (no Docker on this PC); runs in CI |

Bugs the tests found and that were fixed before commit: a trigger
condition PostgreSQL does not short-circuit; two contract schemas that
rejected valid responses (`allOf` with `additionalProperties: false`); a
Windows test database created as WIN1252 that rejected an Arabic name
(now refused by the first migration); invalid JSON reported as a generic
400.

First CI run on the pull request found two more problems, fixed in a follow-up
commit: `backend/src/common/secrets.ts` had not been committed (the root
`.gitignore` protects every `secrets.*` file; the module, which holds no
secrets, was renamed `hashing.ts` instead of weakening that rule), and
osv-scanner reported `deepmerge-ts` 7.1.5 (GHSA-ggr8-5vv4-36mx) and `mysql2`
3.15.3 (GHSA-3f6p-5ww8-9rcr, GHSA-rgwj-5xj2-c3m3), both pulled in by the Prisma
CLI 7.10.0. npm `overrides` pin the fixed versions (8.0.2, 3.24.5); unit 37/37,
end-to-end 68/68 and the build pass with them.

## Synology trial deployment (2026-10-05, done by a DevOps agent session)

| Item | Result |
|---|---|
| NAS | DS920+ (x86_64), DSM 7.4.1; project `science-adventure` in Container Manager |
| Address | `https://school.hmsfamily.synology.me` via the existing `hmsfamily.synology.me` DDNS, wildcard Let's Encrypt certificate and port 443; reverse proxy → `localhost:8480` |
| Containers | db, api (healthy), web, backup all running; first daily dump written |
| From outside the house | `/` 200, `/download/` 200, `/healthz` 200; the APK link 404s until the file is added |
| Network | not carrier-grade NAT; 443 reachable from outside |

Findings and what changed in the package afterwards:
- Container Manager does not create bind-mount folders: `data/postgres` and
  `backups` are now a documented setup step.
- The `json-file` log driver hid logs in Container Manager: the compose file
  now leaves logging to Synology's default driver.
- Two HSTS headers (DSM and nginx): nginx no longer sends one.
- Fonts were sent uncompressed (`.ttf` had no MIME type): nginx now knows
  `font/ttf`/`font/otf`, and the image pre-compresses all static files with
  `gzip -9` (`gzip_static`).
- Still open: Container Manager shows environment variables (including the
  database URL) in its General tab to NAS administrators; moving secrets to
  `*_FILE` mounts is a later hardening step.
## Trial release 0.4.0 (versionCode 4), 2026-10-09

- `flutter build apk --release --obfuscate --split-debug-info=… --target-platform android-arm,android-arm64`: 46.7 MB; signed with the upload key (certificate SHA-256 `a8:03:33:…:74:12:79`, the key created on 2026-10-05); no permissions besides Android's internal receiver permission.
- Smoke test of the same code built for x86_64 on the Android 14 emulator (release, obfuscated):
  - cold start 2.6-6.4 s;
  - a child was added through onboarding;
  - a discovery in unit 1 was answered;
  - after a force-stop and relaunch the unit resumed at 1 / 7 with that discovery starred;
  - no crash, ANR or plugin error in `logcat`.
- Obfuscation symbols kept outside the repository for decoding crash reports.
## Milestone M4 — accounts and sync on the device (branch `remediation/m4-app-sync`)

### Local (2026-10-09)

- `flutter analyze --fatal-infos`: no issues; `dart format --set-exit-if-changed`: clean.
- `flutter test`: all tests pass (394 before the account tab, plus the panel tests).
- New suites: API client 11, account mode 7, attempt IDs 4, journey merge 8 (incl. 2,000 randomised merges), outbox 11, schema 1 → 2 migration 1, two devices 11 (in-memory server with the backend's rules), account tab 3.
- **Against the real backend** (NestJS + PostgreSQL 17 embedded, `REQUIRE_VERIFIED_EMAIL_FOR_SYNC=false`, memory mailer): `SYNC_LIVE_URL=http://localhost:3999 flutter test test/sync/live_backend_test.dart` → 6/6 (link, progress from two devices, name conflict, settings from both, journey merge, removal); no change refused by the server.

### Android emulator (2026-10-09, Android 14, x86_64)

- **Upgrade 0.4.0 → 0.5.0 in place** (release, obfuscated, same upload key, `adb install -r`): the child and the unit 1 progress (3 of 7 discoveries) were still there; the database moved from schema 1 to 2.
- The parent area shows the new "Parent account" tab, device-only by default, in Arabic (right to left).
- **Account flow against a local backend** (debug build, `API_BASE_URL=http://10.0.2.2:3999`):
  - consent dialog (continue disabled until the three points are ticked);
  - account created and signed in from the app;
  - the session survived reinstalling and restarting the app (refresh token in the Keystore-backed store);
  - the child was added to the account after the confirmation, sync reported "everything is saved", and the server listed the child and its settings.
- Found and fixed on the way:
  - the bold "في" in the link button rendered with a clipped tail (button reworded);
  - two cards had the same title;
  - dates followed the device language instead of the parent's.
- Not tested on the emulator against the trial server: creating an account there would send a real verification email; that is part of the owner's trial.

## Trial release 0.5.0 (versionCode 5), 2026-10-09

- Built from `ffd5a4a` (parent accounts and sync on Android; the later web-only change does not affect Android):
  `flutter build apk --release --obfuscate --split-debug-info=… --target-platform android-arm,android-arm64 --dart-define=API_BASE_URL=https://school.hmsfamily.synology.me` → 48.1 MB.
- Signed with the upload key (certificate SHA-256 `a8:03:33:…:74:12:79`, same as 0.4.0, so it installs over it). Permissions: `INTERNET` and Android's internal receiver permission only.
- Obfuscation checked in the packaged `libapp.so` (arm64 and arm): no `.debug_*` sections, no class names of the app.
- The same code built for x86_64 upgraded 0.4.0 in place on the Android 14 emulator with the child and progress kept (see M4 above).
- Symbols kept outside the repository with the 0.4.0 ones; the 0.4.0 APK kept aside for a rollback.
- Not yet done: a first account on the trial server (needs a real email address) and a real phone.

### First-run question (2026-10-09, owner request)

- Builds with a server now ask once, before onboarding: "play on this device only" or "parent account".
- Tests: `test/parent/account_choice_test.dart` (4):
  - device only: no gate and no request;
  - not asked again;
  - the account branch needs the gate and the consent, then signing in brings the account's children;
  - a child created while signed in is offered to the account behind the gate.
- Also `test/account/account_controller_test.dart`: the choice survives a restart.
- Emulator (fresh install, debug build):
  - the question shows in Arabic;
  - the account branch passes the gate and the consent to the sign-in page;
  - "Continue to the game" opens onboarding;
  - after a force-stop and relaunch the question is not asked again.
