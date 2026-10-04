# Remediation progress

Maps the work back to the audit IDs. Status rules (from the task):
**VERIFIED** only when the root cause is addressed, tests were added or
updated and pass, static analysis passes, the app still builds, and the
original finding can no longer be reproduced. **FIXED** means the change is
done and tested locally but one of those checks (usually a CI or device run)
is still pending. **PARTIALLY FIXED** means the main risk is removed but part
of the recommendation remains, as described. M1 items are on branch
`remediation/m1-audit-fixes` (PR #1); M2 items on `remediation/m2-data-layer`.
Neither is merged into `main` yet.

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
Status: **VERIFIED** on the host and in CI (device run: NOT TESTED)
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
Status: **VERIFIED** (memory on a real low-RAM device: NOT MEASURED)
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
Status: **FIXED** (compiles in the debug APK; playback on a device: NOT TESTED, no device)
Files: `android/app/src/main/kotlin/com/scienceadventure/app/MainActivity.kt`
Commit: `aadaef5`

### AUD-021 — hive upstream maintenance
Status: **PARTIALLY FIXED** (M2)
Android plays on SQLite after the one-time migration; Hive is read only to
migrate and is kept frozen as a backup (ADR-0005). The `hive` dependency
remains until the web build gets its database (M4) and the backup period
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

## Security findings

| ID | Status | Where |
|---|---|---|
| SEC-01 | Documented decision (ADR-0003) | AUD-017 |
| SEC-02 | **VERIFIED** — obfuscated release AAB/APKs built in CI | AUD-001 |
| SEC-03 | **VERIFIED** | AUD-015 |
| SEC-04 | **VERIFIED** | AUD-009 |
| SEC-05 | **VERIFIED** — `lib/core/validation.dart`, `test/web/child_name_test.dart` (`28cc9cd`) | |
| SEC-06 | **BLOCKED (owner)** — creating and backing up the upload key; procedure in `docs/RELEASE.md` | |

## Recommendations

| ID | Status |
|---|---|
| REC-01 | Owner decided (ADR-0002); legal and consent text **BLOCKED (owner)** |
| REC-02 | Design accepted (ADR-0002); implementation M4 |
| REC-03 | Accepted (no photo sync by default); implementation M4 |
| REC-04 | Release build in CI; physical device test **BLOCKED (no device)** |
| REC-05 | M3 |
| REC-06 | **VERIFIED** — content-validation job passes in CI |
