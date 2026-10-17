# Remediation progress

Maps the work back to the audit IDs. Status rules (from the task):
**VERIFIED** only when the root cause is addressed, tests were added or
updated and pass, static analysis passes, the app still builds, and the
original finding can no longer be reproduced. **FIXED** means the change is
done and tested locally but one of those checks (usually a CI or device run)
is still pending. **PARTIALLY FIXED** means the main risk is removed but part
of the recommendation remains, as described. M1 items are on branch
`remediation/m1-audit-fixes` (PR #1); M2 items on `remediation/m2-data-layer`;
M3 on `remediation/m3-backend`. None is merged into `main` yet.

Common verification for every M1 item: `flutter analyze --fatal-infos`
clean; `flutter test` 286/286 + goldens 5/5; `flutter build apk --debug`
passes (see `docs/TEST_REPORT.md`).

---

### AUD-001 — Non-reproducible build, no CI
Status: **VERIFIED** — CI run on `f0f3649` green on every job, including obfuscated release AAB/APKs (59.1 MB AAB; 24.3-28.2 MB per-ABI APKs)
Files: `.github/workflows/ci-mobile.yml`, `.github/workflows/security-scan.yml`, `dart_test.yaml`, `docs/RELEASE.md`
Verification: CI runs pinned Flutter 3.47.5 from a clean runner: lockfile
restore, format, analyze, tests, Chrome tests, goldens (Windows), content
validation, debug APK, obfuscated release AAB/APKs with a throwaway key,
permission check; gitleaks + osv-scanner. Toolchain and signing documented.
Commits: `bdea700`, `2d330d8`, `5c5d73d`, `8e43c26`

### AUD-002 — LessonPlayer god class
Status: **PARTIALLY FIXED** (M2)
Done: scene selection is `SceneKind.of(step)`; one renderer per scene in
`SceneRenderer.registry` behind the `LessonSceneHost` interface (the
~250-line branch in `build()` is a lookup and the player imports no scene
widget); pure `StepRules` for assessment/progression; header and completion
are widgets; the player moved to `lib/features/lesson` with the session.
`lesson_player.dart` 1,423 → 1,161 lines.
Remaining: interaction state and save orchestration still live in the
widget state. Extracting a `LessonController` is the next step; the
registry and rules are the seams it needs.
Tests: all 340 behaviour tests unchanged and passing;
`test/lesson/scene_kind_test.dart` (every content step → same scene as the
old branch order; registry covers every kind; rules),
`test/lesson/lesson_completion_test.dart`
Commits: `07ec617`, `a381e08`

### AUD-003 — Untyped Map state
Status: **PARTIALLY FIXED** (M2)
Done: `JourneyState`/`StepState` type the saved lesson journey with
strict field types (a wrong type is a `FormatException` at the storage
boundary), validated outcomes, unknown keys and scene state kept verbatim.
`AppController.saveJourney` validates every lesson journey and asserts an
exact round-trip in debug builds, so all widget tests exercise real save
shapes. `SceneKind` types the scene choice.
Remaining: scene configuration inside lesson JSON (`labUi`,
`forceScene`, `soundScene`…) is still read as maps; the content is
schema-validated at build time. `avoid_dynamic_calls` stays off: 351
hits (≈ 120 in `lib/`, mostly science lab/sound/force scenes; the rest in
tests reading saved maps).
Tests: `test/migrations/journey_state_test.dart` (8,000+ journeys
round-trip exactly; malformed types rejected)
Commit: `0d58615`

### AUD-004 — Full Hive blob rewritten on every interaction
Status: **VERIFIED** on the host, in CI and on the Android emulator (real device: NOT TESTED)
Done: Drift/SQLite with normalised tables, foreign keys and CHECK
constraints; repositories; `DriftProgressStore` writes only changed rows
in one transaction (one changed journey = 1 statement; unchanged save = 0);
photos in their own table; per-device usage counters; outbox table ready;
one-time verified migration from Hive (see AUD-006/`docs/MIGRATION_PLAN.md`);
play time buffered and written once a minute or when play stops.
Measured (host, 10 children with photos, 4.15 MB save): Hive save 115-118
ms → SQLite save 26 ms; migration 1.67-1.72 s. Release APKs now bundle
`libsqlite3.so` per ABI.
Tests: `test/data/drift_store_test.dart` (round-trip, write counts,
cascade delete, other-device usage, constraints, curriculum isolation),
`test/data/hive_to_drift_test.dart` (12-case migration matrix),
`test/data/storage_bootstrap_test.dart`, `test/web/usage_buffer_test.dart`,
`test/data/storage_benchmark_test.dart` (tagged `benchmark`)
Emulator: the old `main` build with two children and a unit in progress
was upgraded in place to the M2 build; both children and the exact
in-progress state survived, later saves persisted across a force-stop, and
the Hive file was left in place (see `docs/TEST_REPORT.md`).
Commits: `569783c`, `cfe524c`, `c08e13e`, `313d264`

### AUD-005 — Web delete-child failure
Status: **VERIFIED**
Files: `lib/core/ids.dart`, `lib/core/providers.dart`
Tests: `test/web/ids_test.dart` (UUIDv7 format, timestamp, ordering, 5,000
unique, provider-level delete of the only child, add child)
Verification: root cause reproduced with `dart compile js` (old call throws
`RangeError` because `1 << 32 == 0` under dart2js); new generator verified
the same way and by the CI Chrome job (`flutter test --platform chrome test/web`).
Commit: `5b0f067`

### AUD-006 — No save-corruption recovery
Status: **VERIFIED**
Files: `lib/core/models.dart`, `lib/core/storage.dart`, `lib/main.dart`,
`lib/startup/startup_problem.dart`, `lib/parent/parent_area.dart`
Tests: `test/web/save_model_test.dart` (per-child tolerance, quarantine kept
verbatim through every family operation, legacy v1), `test/storage_recovery_test.dart`
(real Hive box: last-good copy, unreadable copy preserved before overwrite,
both unreadable → nothing deleted, write over unreadable copy, 10-minute
backup policy, deleted child purged from backup), `test/recovery_ui_test.dart`
Notes: tolerance is per record, not per value — an unknown enum makes that
child's record quarantined (kept and exportable) instead of silently
rewriting the value.
Commit: `e0876ec`

### AUD-007 — Migrations hard-coded in session/UI
Status: **VERIFIED** (M2)
Done: `JourneyMigrations` registry keyed by (lesson, saved version, bundled
version) with pure functions outside widgets; unknown versions are refused.
`LessonSession.restore` is a call into it.
Verification: 4,134 saved states characterized before the move restore to
identical results afterwards; a deliberate mutation is detected.
Tests: `test/migrations/journey_characterization_test.dart`,
`test/migrations/journey_migrations_test.dart`
Commits: `b43f04e`, `181e2d8`

### AUD-008 — Heavy images, unbounded cache
Status: **VERIFIED** (2 GB emulator: memory levels off after repeated
unit visits; real low-RAM device: NOT MEASURED)
Files: `lib/core/image_budget.dart`, `lib/features/biology/lesson_player.dart`,
`lib/main.dart`, `tools/images/`, `assets/images/*`, `pubspec.yaml`
Tests: `test/image_budget_test.dart`; full suite and goldens after re-encode
Measured: bundled images 50.6 MB → 7.1 MB; debug APK 222.4 → 198.5 MB;
PSNR 32.5-41.3 dB; owner approved comparisons. Flame cache released per
unit; Flutter cache capped at 64 MB.
Commits: `51e8a76`, `c01637e`, `0e784fc`, `18a5add`

### AUD-009 — Swallowed exceptions, misleading errors
Status: **VERIFIED**
Files: `lib/core/diagnostics/*`, `lib/core/widgets.dart`, call sites across `lib/`
Tests: `test/diagnostics_test.dart` (classification, only storage-full says
"free space", error text never stored, ring buffer bound, stack trimmed,
showSaveError logs and shows the real cause)
Notes: the remaining `catch (_)` blocks either rethrow, are documented as
already logged by the save queue, or follow a logged failure.
Commit: `ff39294`

### AUD-010 — Test gaps, tests writing files
Status: **VERIFIED**
Files: `test/support/review_images.dart`, 12 scene tests, `test/goldens/*`, CI
Verification: a full run writes 0 files to `tmp/`; 5 goldens; storage,
corruption, provider and web tests added (see AUD-005/006).
Remaining (later milestones): integration tests on devices, repository tests on in-memory SQLite (M2).
Commit: `8e43c26`

### AUD-011 — No localisation system
Status: **VERIFIED** for the parent area and system dialogs; child UI stays English by decision (ADR-0004)
Files: `l10n.yaml`, `lib/l10n/*`, `lib/parent/*`, `lib/features/onboarding/child_chooser.dart`
Tests: `test/l10n_test.dart` (every key translated, placeholders match,
delete dialog follows the setting); Arabic parent-area golden unchanged.
Commit: `140acb5`

### AUD-012 — Repository bloat, dead code
Status: **VERIFIED**
Removed: `force_creature.dart` (620 lines), 24 unbundled images (48.4 MB,
recoverable from history; 17 verified pixel-identical to bundled WebP).
Tests: `test/asset_hygiene_test.dart` (every image bundled, every bundled image exists, no unreachable Dart file)
Not done: rewriting Git history to shrink the pack (destructive; owner decision).
Commit: `1a052f2`

### AUD-013 — Minimal lint rules
Status: **VERIFIED** (`avoid_dynamic_calls` still off; see AUD-003)
Files: `analysis_options.yaml` (flutter_lints 6.0.0 + async/type-safety rules), 61 files
Verification: `flutter analyze --fatal-infos` clean; no `// ignore` added.
Commit: `1fbd2fa`

### AUD-014 — Preview routes in production entry point
Status: **VERIFIED**
Files: `lib/main.dart`, `lib/main_preview.dart`, `scripts/preview_browser.ps1`
Tests: `test/entry_points_test.dart`
Commit: `3beda33`

### AUD-015 / SEC-03 — Weak parent gate
Status: **VERIFIED**
Files: `lib/parent/parent_gate.dart` and call sites
Tests: `test/parent_gate_test.dart` (new problem every failure, 30 s lock
shared across reopen, problem range, owl gender), existing gate tests
Commit: `4927829`

### AUD-016 — Side effects and futures in build()
Status: **VERIFIED**
Files: `lib/main.dart`, `lib/features/onboarding/profile_editor.dart`,
`lib/core/game_image.dart` and 4 image call sites
Tests: `test/build_side_effects_test.dart`
Commit: `aaaa7b4`

### AUD-017 / SEC-01 — Plaintext local PII
Status: **VERIFIED as a documented decision** (ADR-0003, threat model in `docs/SECURITY_HARDENING.md`)
Notes: photos move to private files in M2; tokens will only live in Keystore-backed storage (M4).

### AUD-018 — UI polish defects
Status: **VERIFIED** (a, b, c, d, e, f, g)
Files: `subject_hub.dart`, `world_map.dart`, `alive_adventures.dart`,
`lesson_player.dart`, `design.dart`, `widgets.dart`, `body_workshop.dart`, `parent_gate.dart`
Tests: `test/web/contrast_test.dart`, `test/name_batches_test.dart`,
`test/parent_gate_test.dart`, hub goldens, existing anatomy tests unchanged
Commits: `4927829` (d), `33f232f`

### AUD-019 — copyWith cannot reset voice
Status: **VERIFIED**
Tests: `test/web/settings_test.dart`
Commit: `16c575b`

### AUD-020 — MediaPlayer.prepare on the main thread
Status: **VERIFIED** on the Android 14 emulator (real device: NOT TESTED)
Emulator: every unit 6 instrument plays (Android lists the player as
started), rapid taps replace the previous sound, Home stops it, and
`logcat` shows no ANR or crash.
Files: `android/app/src/main/kotlin/com/scienceadventure/app/MainActivity.kt`
Commit: `aadaef5`

### AUD-021 — hive upstream maintenance
Status: **PARTIALLY FIXED** (M2)
Android and the web play on SQLite after the one-time migration (the web
since ADR-0019); Hive is read only to migrate and is kept frozen as a
backup (ADR-0005). The `hive` dependency remains until the backup period
(two releases) ends.

### AUD-022 — README links an untracked APK
Status: **VERIFIED**
Files: `README.md`, `docs/RELEASE.md`
Commit: `e1a0447`

### AUD-023 — Lesson IDs not namespaced
Status: **FIXED** (M2) — by a different route than suggested (ADR-0010)
Stored attempts and journeys carry a `curriculum` column (`y1.science`)
that is part of the key; the progress repository reads and writes only its
own curriculum. A second year or subject can reuse `unit_01` without
colliding; bundled content and saves keep their IDs, so nothing had to be
renamed. Test: curriculum isolation in `test/data/drift_store_test.dart`.
Commit: `952f088`

### AUD-024 / 025 / 026 — Curriculum scalability (addendum)
Status: documented as future work: a catalog of catalogs per year and
subject; a reusable activity library (the renderer registry of AUD-002 is
the seam); per-year content packs (lossy WebP already cut assets by 86%).

---

## M3 — server, contract and accounts (branch `remediation/m3-backend`)

Built against `Future_System_Architecture.pdf` §5-§12 and the owner's goal
of a private trial on a Synology NAS. Decisions that refine the
architecture: ADR-0011 to ADR-0016.

| Item | Status | Evidence |
|---|---|---|
| OpenAPI 3.1 contract (`api/openapi.yaml`): every §11 endpoint, problem+json, cursor pagination, Idempotency-Key | **VERIFIED** | Redocly lint clean; every response in the 68 end-to-end tests is validated against it (the check found and fixed two real contract bugs) |
| NestJS service (`backend/`): config, problem filter, redacted logging, request ids, helmet, body limits, rate limits, health probes | **VERIFIED** | unit + end-to-end tests; built server smoke-run against local PostgreSQL |
| PostgreSQL schema with constraints, change sequence, tombstones, processed mutations, audit log | **VERIFIED** | migration applies to an empty database; `prisma migrate diff` reports no drift; owner and UTF-8 guards tested |
| Parent auth: register/verify/resend, login, refresh rotation + reuse detection, logout/all, forgot/reset, change password, delete with grace, export | **VERIFIED** | `auth.e2e-spec.ts` (19), `account.e2e-spec.ts` (5) |
| BOLA/IDOR protection (§10) | **VERIFIED** | `bola.e2e-spec.ts`: every REST resource and every sync mutation as another family → 404 / `child_not_found`, data unchanged |
| Sync push/pull with per-entity merge rules (§12, §14) | **VERIFIED (server)** | `sync.e2e-spec.ts` (17) and `merge.spec.ts` (12, incl. 2,000 randomised merges); device side in M4 |
| Docker image, CI (`ci-backend.yml`: lint, types, tests on PostgreSQL 17, drift check, image build, Trivy, non-root check) | **FIXED** | runs on the pull request; Docker is not installed on this PC, so the image was not built locally |
| Dart API client (REC-05) | **Changed** (ADR-0014) | generator output was unusable for the sync unions; a hand-written, contract-tested client comes with M4 |
| NAS deployment (web + API + database behind the NAS reverse proxy) | **VERIFIED** (M4) | live at the trial address; see `docs/TEST_REPORT.md` |

## M4 — app accounts and sync (branch `remediation/m4-app-sync`)

Device side of `Future_System_Architecture.pdf` §8-§14. Decision: ADR-0018
(accounts and sync on the device); Google sign-in (ADR-0017) is ready on the server.

| Item | Status | Evidence |
|---|---|---|
| Typed API client, refresh token in the Keystore, access token in memory | **VERIFIED** | `test/remote/api_client_test.dart` (11); session survives an app restart on the emulator |
| Device-only by default, no network object at all in that mode | **VERIFIED** | `test/account/account_controller_test.dart`; `test/parent/account_panel_test.dart` (no request before sign-in) |
| Stable attempt IDs across saves (sync identity) | **VERIFIED** | `test/data/attempt_ids_test.dart` |
| Outbox written in the save transaction, linked children only, coalesced | **VERIFIED** | `test/sync/outbox_test.dart` (11) |
| Database schema 2 (outbox `put`), rows kept | **VERIFIED** | `test/data/schema_migration_test.dart`; 0.4.0 → 0.5.0 upgrade on the emulator kept the child and its progress |
| Sync engine: batches, pull pages in one transaction, applied between saves | **VERIFIED** | `test/sync/two_devices_test.dart` (11) against an in-memory server with the backend's rules |
| Same scenarios against the real backend | **VERIFIED (local)** | `test/sync/live_backend_test.dart`: 6/6 against NestJS + PostgreSQL 17, no refused change |
| Merge rules on the device (§14): progress never goes backwards, conflicts kept for the parent | **VERIFIED** | `test/domain/journey_merge_test.dart` (8, incl. 2,000 randomised merges); name conflict scenario |
| Parent account tab: consent, sign in / create / reset, link child by child, sync status, sign out, leave, delete | **VERIFIED** | widget tests; full flow on the emulator against a local backend (account created, child linked, server received it) |
| Google sign-in button | TODO | needs the OAuth client IDs (owner step) |
| Web parent pages | TODO | |
| Release APK for the trial with the server address | TODO | after the web pages |

## Security findings

| ID | Status | Where |
|---|---|---|
| SEC-01 | Documented decision (ADR-0003) | AUD-017 |
| SEC-02 | **VERIFIED** — obfuscated release AAB/APKs built in CI | AUD-001 |
| SEC-03 | **VERIFIED** | AUD-015 |
| SEC-04 | **VERIFIED** | AUD-009 |
| SEC-05 | **VERIFIED** — `lib/core/validation.dart`, `test/web/child_name_test.dart` (`28cc9cd`) | |
| SEC-06 | **FIXED** — upload key created 2026-10-05 outside the repository (`scripts/create_upload_key.ps1`), local obfuscated release APKs signed with it; the two offline backups are the owner's step (**BLOCKED (owner)**) | |

## Recommendations

| ID | Status |
|---|---|
| REC-01 | Owner decided (ADR-0002); legal and consent text **BLOCKED (owner)** |
| REC-02 | **VERIFIED** on Android (M4): device-only by default, accounts opt-in, children linked one by one |
| REC-03 | **VERIFIED**: photos are never part of a mutation (`SyncOutbox.childFields`); the consent and link texts say so |
| REC-04 | Release build in CI and locally with the upload key; Android 14 emulator run passed (upgrade, sounds, memory); real-device test pending |
| REC-05 | Changed: hand-written client checked against the contract instead of generated code (ADR-0014); in use since M4 and checked against the real backend |
| REC-06 | **VERIFIED** — content-validation job passes in CI |
