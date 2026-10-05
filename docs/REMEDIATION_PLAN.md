# Remediation Plan — Science Adventure

Sources of truth: `reports/Software_Technical_Audit_Report.pdf` (audit of `9fbdaf4`, score 63/100),
`reports/Future_System_Architecture.pdf`, and the companion registers in `reports/`.

Baseline for this plan: `main` @ `2089a97` (one commit after the audited `9fbdaf4`; it adds spaced
review, today's challenge, discovery world and the audit reports). Every finding below was re-checked
against `2089a97` before work started — the "Verified?" column records what was found.

Work happens on branches `remediation/m1-audit-fixes` → `remediation/m2-data-layer` → … with one
draft pull request per milestone. `main` is only changed by the owner merging a PR.

Status values: TODO · IN_PROGRESS · BLOCKED · FIXED · VERIFIED · NOT_APPLICABLE.
Detailed evidence per item lives in `docs/REMEDIATION_PROGRESS.md`.

## Milestones

| Milestone | Roadmap phases | Content | Gate |
|---|---|---|---|
| M1 | 0 + 1 | CI, reproducible build, all low-risk AUD/SEC fixes on the current Hive app | Draft PR #1 |
| M2 | 2 | Typed models, migration registry, LessonPlayer split, Drift + zero-loss Hive migration | Draft PR #2, **owner review pause** |
| M3 | 3 + 4 | OpenAPI 3.1 contract, NestJS + PostgreSQL backend, parent email auth, BOLA tests | Draft PR #3 |
| M4 | 5 + 6 + 7 | Optional accounts in the app ("this device only" vs account), sync engine, Flutter Web | Draft PR #4 |

## Audit issues

| ID | Finding | Severity | Verified? | Files | Proposed Fix | Tests | Status |
|---|---|---|---|---|---|---|---|
| AUD-001 | Non-reproducible build, no CI | HIGH | Yes — no `.github/`, toolchain only in gitignored `.tools/` | `.github/workflows/`, `scripts/`, `docs/RELEASE.md` | `ci-mobile.yml` (pinned Flutter 3.47.5, `--enforce-lockfile`, format, `analyze --fatal-infos`, tests, chrome tests, APK + web build, content validators), `security-scan.yml`, documented toolchain + release signing | CI run | VERIFIED |
| AUD-002 | `LessonPlayer` god class | HIGH | Yes — 1,423 LOC, `build()` 663-1191 | `lib/features/biology/lesson_player.dart` | `LessonController` + `SceneRenderer` registry, one renderer per play scene; characterization tests first | widget tests per scene | PARTIALLY FIXED (M2) |
| AUD-003 | Untyped `Map<String,dynamic>` state | HIGH | Yes — 190 `json['…']` accesses | `lib/content/lesson.dart`, `session.dart`, scenes | Typed models (freezed/json_serializable) with `extras` for unknown keys, strict + versioned parsing | model + legacy tests | PARTIALLY FIXED (M2) |
| AUD-004 | Full Hive blob rewritten on every interaction / 10 s | HIGH | Yes — `storage.dart:34-51`, `main.dart:155` | `lib/core/storage.dart`, `providers.dart` | Drift/SQLite normalized tables, repositories, outbox, photos as files, usage buffered 60 s | repository + migration tests | VERIFIED (M2) |
| AUD-005 | Web delete-child failure (`nextInt(1<<32)`) | MEDIUM | Yes — `providers.dart:54` | `lib/core/providers.dart`, new `lib/core/ids.dart` | UUIDv7 generator from secure random bytes | provider test, `--platform chrome` | VERIFIED |
| AUD-006 | No save-corruption recovery | MEDIUM | Yes — `main.dart:50`, hard casts / `byName` | `models.dart`, `storage.dart`, `main.dart` | Tolerant per-child parsing, corrupt records preserved in quarantine, last-good backup key, recovery screen with rescue export | storage corruption tests | VERIFIED |
| AUD-007 | Migrations hard-coded in session/UI | MEDIUM | Yes — `session.dart:11-293`, `lesson_player.dart:88-104` | `lib/features/biology/session.dart` | Versioned pure migration registry outside widgets | table-driven tests vs recorded outputs | VERIFIED (M2) |
| AUD-008 | Heavy images, unbounded Flame cache | MEDIUM | Yes — no `clearCache`/`evict` in `lib/` | scenes, `assets/images`, `pubspec.yaml` | Evict on leaving a unit, bounded `imageCache`, lossy WebP (owner approves comparisons first) | cache test, size table | VERIFIED |
| AUD-009 | Swallowed exceptions, misleading errors | MEDIUM | Yes — 38 `catch (_)` + 11 `catchError` | across `lib/` | `AppLog` (package:logging, ring buffer, PII redaction), typed failure categories, accurate messages | logger + message tests | VERIFIED |
| AUD-010 | Test gaps, tests write files to `tmp/` | MEDIUM | Yes — 11 test files write PNGs to `tmp/` | `test/` | Review renders opt-in to `build/review/`, golden tests, real Hive storage tests, web runs | — | VERIFIED |
| AUD-011 | No localisation system | MEDIUM | Yes — inline `t(ar, en)` helpers, no ARB | `lib/parent/*`, `lib/features/onboarding/*` | `flutter gen-l10n` with `app_en.arb` / `app_ar.arb`; child-UI language recorded as ADR | l10n widget tests | VERIFIED |
| AUD-012 | Repo bloat, dead code | MEDIUM | Yes — `force_creature.dart` unused, ~21 unreferenced images | `lib/features/science/force_creature.dart`, `assets/images/` | Delete only verified-unreferenced files (recoverable from Git history) | asset-reference test | VERIFIED |
| AUD-013 | Minimal lint rules | LOW | Yes — 3 rules, no lints package | `analysis_options.yaml` | `flutter_lints` + async/safety rules, fix causes in stages | analyze | VERIFIED |
| AUD-014 | Preview routes in production entry point | LOW | Yes — `main.dart:91-132` | `lib/main.dart` | `lib/main_preview.dart`; production app has no preview routes | route test | VERIFIED |
| AUD-015 | Weak parent gate | LOW | Yes — same problem after failure, unlimited tries | `lib/parent/parent_gate.dart` | New problem per attempt, cooldown after 3 failures, harder problems | gate widget tests | VERIFIED |
| AUD-016 | Side effects / futures in `build()` | LOW | Yes — `main.dart:81-83`, 4 `FutureBuilder(Flame.images.load)` sites | `main.dart`, `illustrated_art.dart`, `plant_mission_stage.dart`, `force_picture.dart`, `force_garden_scene.dart` | `ref.listen` / memoised futures in `State` | widget tests | VERIFIED |
| AUD-017 | Plaintext local PII (mitigated) | LOW | Yes — base64 photo inside Hive blob | `storage.dart` | Threat model; keep sandbox storage; tokens only in Keystore (M4); photos as files (M2) | — | VERIFIED |
| AUD-018 | UI polish defects | LOW | To re-check per item | hub, map, gate, lesson screens | Duplicate subtitle, ellipsis + tooltip, wrap rules, disabled contrast ≥ 3:1, gender-aware owl, layout scaling, body-parts batches of 4-6 (same objectives/scoring) | widget tests | VERIFIED |
| AUD-019 | `copyWith` cannot reset voice | LOW | Yes — `models.dart:77-78` | `lib/core/models.dart` | Sentinel-based `copyWith` | unit test | VERIFIED |
| AUD-020 | `MediaPlayer.prepare()` on main thread | LOW | Yes — `MainActivity.kt:33` | `android/.../MainActivity.kt` | `prepareAsync()` + `onPrepared` | build + emulator | VERIFIED (emulator) |
| AUD-021 | Hive upstream maintenance | INFO | Yes — `hive 2.2.3` | `pubspec.yaml` | Replaced by Drift in M2 (no interim fork) | — | PARTIALLY FIXED (M2) |
| AUD-022 | README links untracked APK | INFO | Yes — `README.md:3` | `README.md` | Remove link, document GitHub Releases + build commands | — | VERIFIED |
| AUD-023 | Lesson IDs not namespaced by year/subject | HIGH (expansion) | Yes | catalog, saves | Namespaced IDs + save migration | migration tests | FIXED (M2) |
| AUD-024 | Subject / lesson list hard-coded | MEDIUM | Yes — `LessonLibrary.availableIds` | `lib/content/lesson.dart`, `subject_hub.dart` | Document catalog-of-catalogs design; implement when a second subject exists | — | DOCUMENTED |
| AUD-025 | Bespoke scene code per unit | HIGH (expansion) | Yes | `lib/features/**` | Renderer registry (M2) is the seam; reusable activity library is future work | — | DOCUMENTED |
| AUD-026 | Asset size grows per subject-year | MEDIUM (projection) | Projection | `pubspec.yaml` | Lossy WebP now; content packs later | — | DOCUMENTED |
## Security findings

| ID | Finding | Severity | Verified? | Files | Proposed Fix | Tests | Status |
|---|---|---|---|---|---|---|---|
| SEC-01 | Child PII plaintext in sandbox | LOW | Yes | `storage.dart` | = AUD-017 | — | VERIFIED |
| SEC-02 | No Dart obfuscation | LOW | Yes | build docs/scripts | `--obfuscate --split-debug-info` for release, symbols kept private | CI release build | VERIFIED |
| SEC-03 | Weak parent gate | LOW | Yes | `parent_gate.dart` | = AUD-015 | gate tests | VERIFIED |
| SEC-04 | Swallowed errors, no diagnostic trail | LOW | Yes | `lib/` | = AUD-009 | logger tests | VERIFIED |
| SEC-05 | No name character validation | INFO | Yes | `profile_editor.dart` | Validate on input (letters, space, `-`, `'`, 1-24); legacy names untouched | validator tests | VERIFIED |
| SEC-06 | Release never built with final key | INFO | Yes — no `android/key.properties` locally | `docs/RELEASE.md` | Key creation, two offline backups, Play App Signing, custody doc | — | BLOCKED (owner creates key) |

## Recommendations

| ID | Recommendation | Verified? | Proposed Fix | Status |
|---|---|---|---|---|
| REC-01 | Privacy/legal decision before accounts | Owner decided 2026-10-04: build optional parent accounts with a "this device only" mode | ADR; consent text and privacy policy remain the owner's legal deliverable | BLOCKED (legal text) |
| REC-02 | Offline-first, accounts optional | — | Local DB is source of truth; local-only mode makes zero network calls | TODO (M4) |
| REC-03 | No child photo sync by default | — | Photos excluded from sync payloads | TODO (M4) |
| REC-04 | Release AAB with obfuscation, device test | No device available | CI release build with ephemeral key; device test is a manual owner action | TODO / BLOCKED (device) |
| REC-05 | Generate Dart API client from OpenAPI | — | Hand-written client checked against `api/openapi.yaml` (generator rejected, ADR-0014) | TODO (M4) |
| REC-06 | CI gate for content validation | Python not on PATH locally | `validate_playable.py` in CI | VERIFIED |
