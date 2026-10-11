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
| M4 | 5 + 6 + 7 | Optional accounts in the app ("this device only" vs account), sync engine, Flutter Web | PR #4, merged 2026-10-10 |
| M5 | — | Teacher review 4 fixes (M5a, first), then web parent pages and the remaining M4 items (M5b) | Draft PR #5 |

## M5 — teacher review 4 and the rest of M4 (branch `remediation/m5-teacher-review-and-web`)

Source: `docs/TEACHER_REVIEW_2026_10_09.md` (review of `main` @ `9b5dab1`). Every item was
re-checked against `main` @ `2e81558` on 2026-10-10; "Checked" says what was found.

### M5a — what children see (first; ships as the next trial APK and web image)

| # | Item | Checked | Plan | Needs |
|---|---|---|---|---|
| T4-1 | **High.** Socket safety picture: the adult points a finger at the socket | Confirmed in `electric-safety-v1.webp` (first panel); no crop removes it | New panel: socket with a safety cover, child standing back, hands behind the back, no hand near the socket. Same painted style; re-encode with `tools/images`; update the crop rectangles and the golden | **Owner:** the new picture (brief below), or approval to draw it another way |
| T4-2 | **High.** Discoveries count only on the small marker; marker, caption and Next need scrolling at 1280×800 (Electricity safety, Water world) | Confirmed: only the 48 dp `TouchCue` is tappable (`discovery_world.dart`) | Tap anywhere on the picture discovers the shown item (Electricity) or the nearest place (Water world); size the scenes so marker, caption and Next fit in 1280×800; widget test at 1280×800 with no scrolling | — |
| T4-3 | **Medium.** The action strip moves between screens | Confirmed: `Flexible` (loose) body in `lesson_player.dart`, an AUD-018 choice in M1 that this review reverses | Body `Expanded`, feedback and action strip always at the bottom of every activity; test that the strip's y position is the same on every step; regenerate goldens | — |
| T4-4 | **Medium.** Water world feedback says the description without the place name; visited places stay as hands | Confirmed: feedback and speech use `senseDescriptions[id]` only (`lesson_player.dart`) | "Ocean. The biggest water of all, and salty." on screen and in speech (only where the description does not already start with the name); visited markers show ✓ as in the plant parts | — |
| T4-5a | Low. Push: the child walks with the wagon, so the gap never grows | — | Child pushes, lets go, the wagon rolls on alone (`force_trolley_scene.dart`) | — |
| T4-5b | Low. Space: "not to scale" note means nothing to a child; the Sun is barely larger than Earth | — | Very large Sun partly off-screen; the note moves to the parent area / unit report | — |
| T4-5c | Low. Electricity hint may point to the lantern (battery lanterns exist) | — | Hint about plugs only, or a clearly visible flame in the lantern art; same objective and answer | — |
| T4-5d | Low. Quiz 3 has five two-option questions (`quiz_03.step.001/002/004/005/009`) | Confirmed | Proposal per question (keep the correct answer and objective; add a third choice or a different interaction where it helps) | **Owner/teacher:** approve each change (assessment content) |
| T4-5e | Low. Home activities appear in English, left to right, inside the Arabic parent area | Confirmed: `unit_report.dart` forces `TextDirection.ltr`; activity text exists in English only | Arabic text for each home activity (draft by the developer, reviewed by the owner), shown when the parent area is Arabic | **Owner:** review the Arabic wording |
| X-1 | Found while checking: the "Saving…" label in the lesson strip is mis-encoded (`Savingâ€¦`) | Confirmed; only occurrence in tracked text files | Fix the character; a test that no source or content file contains mis-encoded UTF-8 | — |
| X-2 | README says the app has no INTERNET permission and keeps all data on the device (the review's "not reviewed" note) | Confirmed: true before M4, not since | Rewrite for parents: device-only by default, what is sent only after choosing an account and saving a child, photos never | — |

**Status 2026-10-10:**
- **FIXED** with tests in `test/teacher_review_4_test.dart`, `test/text_encoding_test.dart` and `test/forces_scenes_test.dart`:
  - T4-2, T4-3, T4-4 and X-1 in `9c50975`;
  - T4-5a, T4-5b, T4-5c and X-2 in `1def1de`.
- Review screenshots at 1280×800 were checked by eye.
- **FIXED:** T4-1, a new picture from the owner (Gemini) placed by the developer and approved by the owner on a before/after comparison (see `CREDITS.md`).
- **FIXED** (approved by the owner on 2026-10-10):
  - T4-5d: quiz 3 questions 4 and 5 gain a third choice ("Ears", "It stays the same"); 1, 2 and 9 stay as in the book (an optional magnet test before 9 was not done);
  - T4-5e: Arabic for every home activity, goal activity and safety note.

Verification for M5a: tests above, goldens regenerated and compared by eye, emulator run at
1280×800 (Electricity safety, Water world, Space, a lesson with long and short steps), then
a release APK and a request for teacher review 5.

**Art brief for T4-1** (to generate with the same tool and style as the other pictures):
a warm painted illustration, transparent background, same mother and boy as the other two
panels (purple sweater, jeans; boy in a green hoodie). A wall socket with a white plastic
safety cover. The boy stands a step back from the wall with both hands behind his back,
smiling. The mother kneels beside him with an open palm raised towards the boy at chest
height ("stop and stay back"), her hand far from the wall. No finger, hand, plug or object
touches or points at the socket. Landscape panel, about 1:1.

### M5b — web parent pages and the rest of M4

| Item | Needs |
|---|---|
| Web parent pages: sign in (cookie session), children, reports, settings | — |
| "Sign in with Google" button in the app | **Owner:** Google Cloud OAuth client IDs (prompt phase 12) |
| Test on a real phone | **Owner:** a phone |
| `docs/FINAL_REMEDIATION_REPORT.md` | — |
| CI minutes: GitHub Free's 2,000 private minutes ran out on 2026-10-10; pull requests now run each check once, without the Windows goldens or the extra Android builds, which run on `main` and by hand before merging (`docs/RELEASE.md` §2) | Done, approved by the owner on 2026-10-11. **Owner:** wait for the monthly reset or set an Actions budget |

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
