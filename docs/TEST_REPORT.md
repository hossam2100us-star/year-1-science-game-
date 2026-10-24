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

## Trial release 0.5.1 (versionCode 6), 2026-10-09 — replaces 0.5.0 before distribution

- Built from `79aa417` (adds the first-run question), same command and checks as 0.5.0:
  - 48.2 MB;
  - upload key `a8:03:33:…:74:12:79`;
  - permissions `INTERNET` and the internal receiver permission only;
  - no `.debug_*` sections or app class names in either packaged `libapp.so`.
- 0.5.0 and 0.4.0 APKs and all symbol files kept outside the repository.

## Milestone M5a — teacher review 4 (branch `remediation/m5-teacher-review-and-web`, 2026-10-10)

- `flutter test`: 415 pass.
- New tests:
  - `test/teacher_review_4_test.dart`, at 1280×800 with the tablet's status (24) and navigation (60) bars: positions, taps on pictures, names first, checks, the strip's place on every step of three lessons, the Space model, Arabic parent activities;
  - `test/text_encoding_test.dart`.
- **Android 14 emulator (1280×800 tablet):**
  - Electricity safety and Space fit without scrolling;
  - the new socket picture shows;
  - a tap on the Sun itself is a discovery;
  - the action strip stays at the bottom;
  - the Arabic home activity, its safety note and the Space "not to scale" note show right to left in the parent report.
- Found on the emulator: the first layout fitted 1280×800 but not the 716 dp the app really gets between the system bars. The lesson page's SafeArea hides the bars from MediaQuery, so scene sizes now come from the window (`View`). The test now includes the bars.

## Trial release 0.5.2 (versionCode 7), 2026-10-10

- Built from `7d449d2`, with all of teacher review 4 M5a:
  - new socket picture;
  - discoveries on the whole picture;
  - fixed action strip;
  - names first;
  - push, Space, hint;
  - quiz 3 third choices;
  - Arabic parent activities.
- Same release command and checks as 0.5.1:
  - 48.3 MB;
  - upload key `a8:03:33:…:74:12:79`;
  - `INTERNET` only;
  - no debug sections or app class names in either packaged library;
  - `parent_ar.json` and the new picture are packaged.
- Local checks: `flutter analyze --fatal-infos` clean, 416 tests pass.
- GitHub Actions did not run for these commits: the account's Actions spending limit or payment stopped the jobs before they started (annotation "recent account payments have failed or your spending limit needs to be increased"). A re-run on 2026-10-11 was stopped the same way.
- The content validation therefore ran locally instead, with the CI's pinned `scripts/requirements-content.txt` in a temporary virtual environment (Python 3.13 rather than the CI's 3.12): `validate_playable.py` PASS for all 13 files, 187 steps (schema, IDs, answer references, prediction exclusion, source objectives). The other CI-only jobs (Chrome tests, goldens, the Android and web builds, the security scans, the images) have not run on M5.

## Trial release 0.6.0 (versionCode 8), 2026-10-17

- Built from `a7f7ce5` with the version set to 0.6.0+8. Includes:
  - Maths;
  - the login page;
  - teacher reviews 5 and 6;
  - the new name "My School Adventures" and Zizo's icon.
- Same command as 0.5.x (ARM only, obfuscated, `API_BASE_URL=https://school.hmsfamily.synology.me`).
- The APK:
  - 50.8 MB (53,302,637 bytes), SHA-256 `8a0bf803…a747521f`;
  - upload key `a8:03:33:…:74:12:79`;
  - permissions: `INTERNET` and Android's internal receiver permission only;
  - no debug sections or app class names in either packaged library;
  - label "My School Adventures", adaptive launcher icon.
- **Upgrade 0.5.2 → 0.6.0 in place** on the emulator. Both were built from their commits with x86_64 added for the emulator, with the same key:
  1. Before the update: a child, and one discovery of 7 in "Alive or Not Alive".
  2. After `adb install -r`: the login page opens. "Continue without the Internet" shows the child; the lesson reopens at the same step (1 / 7); Maths is listed.
- On the emulator's app drawer, the round mask shows the owl, the balloons and the rocket.
- The trial APK is ARM only, as before. It does not start on an x86_64 emulator; 0.5.2 has the same limit, and real phones are ARM.
- Staged in `C:\Users\hossa\ScienceAdventure-NAS`:
  - `downloads/science-adventure.apk`, with its `.sha256` and the renamed download page;
  - 0.5.2 moved to `previous/0.5.2+7`;
  - symbols in `symbols/0.6.0+8`.

## Trial release 0.6.1 (versionCode 9), 2026-10-23

- Built from `chore/release-0.6.1` (main `e712a7f` with the version set to 0.6.1+9). Includes:
  - Maths: every question inside the app, the number pad and the worksheet questions (PR #13);
  - the update check and its banner (PR #14, ADR-0020);
  - pypdf 6.21.1 for the curriculum script (security scan).
- Same command as 0.6.0 (ARM only, obfuscated, `API_BASE_URL=https://school.hmsfamily.synology.me`).
- The APK:
  - 50.9 MB (53,406,193 bytes), SHA-256 `1faf1b7d…fcb9b4c1`;
  - upload key `a8:03:33:…:74:12:79`, version 0.6.1 (9);
  - permissions: `INTERNET` and Android's internal receiver permission only, as in 0.6.0;
  - no app class names in either packaged library;
  - native libraries the same as 0.6.0 (one small `x86_64` plugin library, as before).
- Checks before the release: PRs #13 and #14 merged together on a scratch copy, 537 tests, 5 goldens, analyze, format and both content validators pass; full `ci-mobile` green on each PR.
- **Upgrade 0.6.0 → 0.6.1 in place** on the emulator. Both were built for x86_64 from their commits with the same key:
  1. In 0.6.0: a new child, Maths unit 1 played to step 6 of 14, the old "Try it at home" step, then the app closed.
  2. After `adb install -r`: the login page opens. "Continue without the Internet" shows the child; unit 1 reopens at 6 / 14, now the new "Count the circles" question with the number pad. 9 is accepted with its explanation.
  - A unit test now covers the same case (`test/maths_written_answers_test.dart`).
- Update check on the emulator (debug build against a stand-in server on the PC): the banner shows, "Update" asks the parent gate, "Later" lasts across restarts, Settings shows the version, one request per launch. Opening the download page in the browser was not tested there (the stand-in server is http; the app opens https pages only). It is checked once 0.6.1 and `version.json` are on the family server.
- Staged in `C:\Users\hossa\ScienceAdventure-NAS`:
  - `downloads/science-adventure.apk` with its `.sha256`, and `downloads/version.json` (9, 0.6.1), uploaded last;
  - 0.6.0 moved to `previous/0.6.0+8`;
  - symbols in `symbols/0.6.1+9`.

## School years, stage 1 (ADR-0021), 2026-10-23

- App:
  - `flutter analyze --fatal-infos` and `dart format` are clean.
  - 553 tests pass, including:
    - `test/school_years_test.dart`: the list of years, the child's year, the subjects screen, the parent area;
    - `test/sync/school_year_sync_test.dart`: a server from before school years, the year on two devices, Year 2 progress;
    - the schema 2 → 3 upgrade in `test/data/schema_migration_test.dart`.
  - Goldens: the subjects screen (tablet and phone) and parent Settings were updated after a visual check. The only change is the new year line; the phone image still shows Maths loading, as before.
- Server:
  - 37 unit and 78 end-to-end tests pass on a real PostgreSQL 17. Two of the end-to-end tests are new: the school year through sync and through the children API.
  - The new migration applies, and `prisma migrate diff` finds no difference.
  - Type check, lint, Prettier and the OpenAPI lint are clean.
- Emulator, in-place upgrade from 0.6.1 (schema 2, release key, x86_64 build):
  - The child, and Maths unit 1 at step 6 / 14 with its answer, are kept.
  - The subjects screen shows "Year 1 • سنة أولى".
  - Settings shows the school year with the note that other years will appear there.
  - No errors in the log.

## Maths class-book topics, 2026-10-23

- 20 new graded questions in units 8, 15, 16 and 18 (docs/MATHS_INTEGRATION.md).
- Content checks:
  - `validate_maths_content.py --check-idempotence` passes: 311 graded, 330 steps. It also checks the grid answers by following each question's moves;
  - `validate_playable.py` passes.
- `flutter analyze --fatal-infos` and `dart format` are clean.
- 555 tests and the 5 goldens pass, including:
  - `test/maths_class_book_test.dart`, which renders every new question on a 1280x800 screen;
  - the tablet fit test, which covers the new questions too.
- Review images (`--dart-define=REVIEW_IMAGES=true`) were checked by eye. Two drawings were redrawn after the check: the prism, and the ball behind the box.

## Dependency advisories, 2026-10-24

The security scan failed on every branch after new advisories were published:

| Package | Advisory | Was | Now | How |
|---|---|---|---|---|
| zod | GHSA-mrhx-c7xc-m3w5 (high) | 4.6.5 | 4.6.6 | direct dependency |
| nodemailer | GHSA-85x2-q946-cp5h, GHSA-8c8m-p3m8-cjg8, GHSA-m943-m63m-w62w | 10.0.14 | 10.1.4 | direct dependency |
| multer | GHSA-q7qp-rjg7-q26m (high) | 2.4.0 | 2.5.0 | npm `overrides`: `@nestjs/platform-express` pins 2.4.0 exactly |
| body-parser | GHSA-27r3-jxmh-p828 (high) | 2.3.0 | 2.4.0 | lockfile update inside express's `^2.3.0` |
| fast-uri | GHSA-333x-w4r6-6crp, GHSA-w74x-v6f9-j3xg, GHSA-wjr9-j795-jxcr, GHSA-xhq7-xmqj-769h | 3.1.8 | 3.1.9 | lockfile update inside ajv's `^3.0.1` |
| pypdf | GHSA-6c7f-9265-g8fw, GHSA-gmh7-3g9r-mjh5, GHSA-jr96-gvgh-j3r4 (high) | 6.21.1 | 6.21.2 | `scripts/requirements-content.txt` |

The accepted sprintf-js entry (GHSA-hp3w-g68c-fv3c) was removed from
`backend/osv-scanner.toml` because the advisory was withdrawn.

- Server: `npm audit` finds 0 vulnerabilities. Type check and lint are clean, the build passes, and 37 unit and 78 end-to-end tests pass on a real PostgreSQL 17.
- Content: with pypdf 6.21.2, `validate_maths_content.py --check-idempotence` (the repeat build is byte-for-byte identical) and `validate_playable.py` pass.
- The app itself has no changed packages. pypdf is used only by the content scripts on the PC.

## English, the third Year 1 subject (ADR-0022), 2026-10-24

- Content (docs/ENGLISH_INTEGRATION.md): all 155 questions of the English Made Easy companion as 186 steps, 165 graded.
  - `validate_english_content.py --check-idempotence` passes: coverage, answers, letter tiles, titles and pictures that do not give the answer away, Arabic home activities, catalogue order, and a byte-for-byte repeat build. It now runs in CI.
  - `validate_playable.py` passes for all subjects (703 steps).
- `flutter analyze --fatal-infos` and `dart format` are clean.
- 567 tests and the 5 goldens pass. New:
  - `test/english_test.dart` (12 tests): the subject and its progress key `y1.english`, the catalogue, Arabic and pictures for every goal, exact spelling, a spelling question played wrong then right, a story that goes on only after every part is heard, sorting into Real and Fantasy, all 186 steps at 1280x800 and at 390x844 with 1.5x text, and English progress reopening from SQLite next to Maths;
  - `test/lesson/scene_kind_test.dart`: every English step uses the English scene.
- Golden: the tablet subjects screen now shows three cards in one row (intended).
- Review images of every English step (`--dart-define=REVIEW_IMAGES=true`) were checked by eye before and after the art.
- The server needs no change: it already accepts `y1.english`.

## Trial release 0.6.2 (versionCode 10), 2026-10-24

- Built from `chore/release-0.6.2` (main `c9f71c9` with the version set to 0.6.2+10). Includes:
  - school years, stage 1 (PR #16, ADR-0021; database schema 3);
  - the Maths class-book questions (PR #17);
  - the dependency security updates (PR #18);
  - English, the third Year 1 subject (PR #20, ADR-0022).
- Same command as 0.6.1 (ARM only, obfuscated, `API_BASE_URL=https://school.hmsfamily.synology.me`).
- The APK:
  - 52.8 MB (55,374,107 bytes), SHA-256 `c9e3a22a…ecc98cc43`;
  - upload key `a8:03:33:…:74:12:79`, version 0.6.2 (10);
  - permissions: `INTERNET` and Android's internal receiver permission only, as in 0.6.1;
  - native libraries as in 0.6.1 (one small `x86_64` plugin library, as before);
  - the English catalogue, all 13 English lessons and the three English pictures are inside.
- **Upgrade 0.6.1 → 0.6.2 in place** on the emulator, both built for x86_64 from their commits with the same key:
  1. In 0.6.1 (built from `02e0868`): a new child, Nour; Maths unit 1, step 1 with three apples counted; the app closed.
  2. After `adb install -r`: no update banner (0.6.2 is newer than the server's 0.6.1). "Continue without the Internet" shows Nour; the subjects screen shows "Year 1 • سنة أولى" and three cards; Maths unit 1 reopens at step 1 with the same three apples counted.
  3. English: the map shows the four painted islands; unit 1's story is read part by part and goes on after all three; the spelling question accepts "tree" (e, e) with its explanation.
- Staged in `C:\Users\hossa\ScienceAdventure-NAS`:
  - `downloads/science-adventure.apk` with its `.sha256`, and `downloads/version.json` (10, 0.6.2), uploaded last;
  - 0.6.1 moved to `previous/0.6.1+9`;
  - symbols in `symbols/0.6.2+10`.

## Speech on a Huawei tablet, and trial release 0.6.3 (versionCode 11), 2026-10-24

The owner installed 0.6.2 on a real tablet, a HUAWEI MatePad T (AGRK-L09, Android 10, no Google services), and heard no sound. Checked over USB:
- The only speech engine is Huawei's (`com.huawei.hiai`). A separate test app (removed afterwards) showed that it offers offline English voices (`en`, `en-US` and an unusual `en-Qaag`) and speaks them.
- The app's voice settings showed "no English voice ready", although the voices were listed: one failed call had turned speech off for the rest of the session.
- **Cause, reproduced:** Android stops the speech engine in the background. The app's next call then fails (`not bound to TTS engine`; choosing the voice throws a `PlatformException`), and the app marked speech as unavailable until it was closed.

**Fix (`lib/core/narration.dart`):**
- When speaking fails, the app binds the default engine again (`setEngine`) and tries once more. A failure never turns speech off for the session.
- With no voice at start-up, it looks again at most every 20 seconds.
- A voice the engine cannot find by name falls back to its language.
- Plain English locales (`en`, `en-GB`, `en-US`) are chosen before unusual ones such as `en-Qaag`.

**Checks:**
- New tests in `test/narration_test.dart`:
  - a stopped engine is reconnected and the sentence still plays;
  - the automatic voice is a plain English one;
  - the language fallback.
- 570 tests and the 5 goldens pass; analyze and format are clean.
- On the tablet, with the release key installed over the child's data:
  - with the engine force-stopped in the middle of the English story, 0.6.2 stayed silent;
  - the fixed build bound the engine again within 0.1 s and spoke (three speech audio tracks).
  - The owner heard the speech.
- APK 0.6.3 (11):
  - 52.8 MB, SHA-256 `e259768d…4068149a`;
  - upload key `a8:03:33:…:74:12:79`, same permissions;
  - installed on the tablet in place and speaks.
- Staged in `C:\Users\hossa\ScienceAdventure-NAS`:
  - the APK, `.sha256` and `version.json` (11, 0.6.3, uploaded last);
  - 0.6.2 moved to `previous/0.6.2+10`;
  - symbols in `symbols/0.6.3+11`.

Seen on the same tablet, not changed here: its screen is 800 points high with larger text, so the first English story step needs a short scroll.

## Teacher review 8 (English), 2026-10-24

Fixes for `docs/TEACHER_REVIEW_2026_10_24.md`, all in one change (owner's choice):
- **Stories:** shorter parts, each with its own painted scene: Aqsa, the recount (unit 2), Tiddalik, Songololo and the two "more stories" screens. 24 scenes made in Canva Dream Lab (Education account, saved by the owner), built by `tools/images/english-scenes.cjs` into `english-scenes-v1.webp` (1792×1512, 759 KB).
- **Sentence cards:** pictures on the Real/Fantasy, verb, story-setting, beginning/middle/end and reduce/reuse/recycle cards. On a tablet they go two to a row, so nothing scrolls. A story screen with pictures leaves out the setting banner. With four stories the pictures are a little smaller.
- **Content:**
  - "whispered" → "trembled" in the feelings sort;
  - the chart and the recount use the playing child's name (`Lesson.forChild`, "Sam" when there is none; English only, because the Science garden uses `{name}` for the thing explored). Today's Challenge fills it in too;
  - the home activity no longer names Seif;
  - every graded question in a lesson has its own hint;
  - the five two-choice quiz questions and one unit question have a third choice.
- **Unchanged:** step IDs, answers, objectives, scoring and saved journeys. The validator now checks unique hints and that `{name}` never appears in answers or parent text.

**Checks:**
- 579 tests pass (1 skipped) with the goldens; analyze and format are clean.
- New English tests:
  - the name is filled in (Nour, or Sam), with IDs and answers unchanged, and no "Seif" anywhere;
  - the garden text is left alone;
  - every story part has a scene;
  - "trembled";
  - tapping a sentence card reads it aloud before it goes in a basket.
- English and playable validators pass; the English build is byte-for-byte repeatable.
- Every English step at 1280×800 and at 390×844 with 150% text: no overflow. The review images were checked by eye: stories and sorting screens fit a tablet without scrolling.
