# Maths integration

## Reference and architecture

The reference is the existing Science subject: `SubjectHub` → `WorldMap` →
`IslandScreen` → `LessonRoute` / `LessonPlayer`. Navigation remains
`MaterialPageRoute`. Flutter, Riverpod, Flame, the local fonts, shared theme,
mascot, lesson header, fixed feedback controls, marking engine, lesson session,
completion, parent gate and report widgets remain in use.

The addition is data driven. A separate Maths catalogue describes four islands
(three terms and Chart Skills). Eighteen units, three ten-question challenges
and Chart Skills use the existing playable JSON contract. The 273 book
questions become 292 activities: 258 assessments, 15 ungraded personal/drawing
tasks, and 19 explorations. Source drafts retain the original question and
Answer Key references; the source PDF and its personal certificate are not
bundled. See [content audit](MATHS_CONTENT_AUDIT.md) for pagination, provenance,
adaptation decisions and the book's half-past clock illustration discrepancy.

Science keeps its existing IDs, versions, catalogue, ordering and default
loaders. Maths IDs use `math_unit_01`–`math_unit_18`, `math_quiz_01`–
`math_quiz_03` and `math_charts`. Maths uses `otherSubjects.maths` in the
existing family save format and `y1.maths` in the existing SQLite/sync tables.
Child identity, settings, usage tracking and parent account permissions stay
shared. A linked child syncs Maths through the existing API; an unlinked child
stays local. No database migration, backend change or dependency upgrade is
required.

## Created files

| Files | Purpose |
| --- | --- |
| `assets/content/maths_catalog.json` | Maths subject, term islands, level ordering and bilingual parent rules |
| `assets/content/math_unit_*.json`, `math_quiz_*.json`, `math_charts.json` | 22 source drafts with SHA-256, questions, answer keys and source pages |
| `assets/content/math_support.json` | Source references for record sheets, sorting cards, self-check, glossary and certificate |
| `assets/content/playable/math_*.json` | 22 lessons, assessments, explorations, word stickers and parent activities |
| `scripts/build_maths_content.py` | Reproducible source adaptation; optional extraction from the supplied PDF |
| `scripts/validate_maths_content.py` | Source coverage, independent PDF answer comparison, visual oracles, catalogue and idempotence checks |
| `lib/features/maths/maths_stage.dart` | Maths cards using the existing selection/placement callbacks and grading engine |
| `lib/features/maths/maths_visual.dart` | Original count, ten-frame, pair, shape, fraction, clock, chart, coin, number-line and measurement drawings |
| `test/data/maths_progress_test.dart`, `test/sync/maths_sync_test.dart` | Subject/child isolation, SQLite reopen, migration and account sync checks |
| `test/maths_navigation_test.dart`, `test/maths_render_test.dart` | Navigation, resume, completion/retry, reports, stickers and every Maths screen at phone/tablet sizes |
| `docs/MATHS_CONTENT_AUDIT.md`, `docs/MATHS_INTEGRATION.md` | Content provenance and implementation/verification report |

## Modified files and reasons

| Files | Reason |
| --- | --- |
| `lib/content/catalog.dart` | Optional subject metadata and the Maths catalogue loader, keeping Science defaults |
| `lib/content/lesson.dart` | Maths/all-subject loaders, published IDs and a defaulted lesson subject |
| `lib/content/curriculum.dart` | Existing storage namespace extended with `y1.maths` |
| `lib/core/models.dart`, `lib/core/providers.dart` | Read/write only the selected subject's progress; preserve Science and other children |
| `lib/data/drift_progress_store.dart` | Map Maths to existing curriculum-scoped rows, retain opaque metadata and queue linked-child changes transactionally |
| `lib/data/sync/sync_store.dart` | Upload both curricula when a parent first saves a child in the account |
| `lib/data/migration/hive_to_drift.dart` | Include Maths rows in existing migration verification |
| `lib/features/world/subject_hub.dart`, `world_map.dart` | Add the same subject card and reuse map/level widgets with a Maths catalogue; new painted Maths island art matches the Science visual style; cards share equal space side by side on tablets |
| `lib/features/lesson/scene_kind.dart`, `scene_renderers.dart` | Register a Maths diagram renderer in the existing scene registry |
| `lib/features/lesson/lesson_player.dart` | Subject-scoped saves/restores and Maths quiz retry; compact Maths buttons on enlarged phone text |
| `lib/features/biology/sticker_album.dart` | Filter earned words by subject; retain existing Science defaults |
| `lib/parent/parent_area.dart`, `unit_report.dart` | Maths reports/rules through the existing bilingual, gated parent area |
| `pubspec.yaml` | Register the Maths catalogue and three new illustration atlases; the existing playable directory bundles lessons |
| `schemas/lesson.schema.json`, `question.schema.json` | Admit the Maths book's 83 source pages; subject validators retain each book's own page limits |
| `test/data/hive_to_drift_test.dart`, `test/lesson/scene_kind_test.dart`, `test/subject_hub_test.dart` | Cover Maths normalization, preserve the Science scene characterization and acknowledge the published new subject |
| `test/teacher_review_4_test.dart` | Make the existing Arabic parent translation check independent of a fixed 300 ms asset-loading delay, using its already loaded Science library |
| `test/goldens/subject_hub_tablet.png`, `subject_hub_phone.png` | Intended responsive subject-selection baseline updates |
| `README.md` | Explain where to find Maths and link the audits |

A completion test exposed an existing final-screen bug: narration checked the
current scene after the session had moved past its last step. The player now
guards that check when the session is finished. This narrow correction allows
the shared celebration and retry path to work; it does not regrade a result.

## Original integration verification (11 October)

The initial integration checks passed on 11 October 2026. These historical results predate the visual and teaching revision below. Working logs are under the ignored
`tmp/` directory and review images are under the ignored `build/review/maths/`
directory.

| Check | Result |
| --- | --- |
| `dart analyze lib test` | No issues |
| Existing Science source validator | 157 source questions passed |
| Existing playable JSON validator | All 479 Science + Maths steps passed |
| Maths validator with original PDF and repeat-build check | All 273 Answer Key references matched; 258 assessments, 15 ungraded tasks and 292 steps passed; repeat builds are byte-identical and preserve Science |
| Full Flutter suite excluding separately run goldens/benchmark | 429 passed, one live-backend test skipped because `SYNC_LIVE_URL` is not configured |
| Golden comparisons | All five passed; only the intended tablet subject-hub baseline changed |
| Existing storage benchmark | Passed: 10 children, 200 attempts, 2,000 objectives, 130 journeys; SQLite save mean 17.1 ms, migration 1,360 ms on this PC |
| Responsive lesson verification | All 292 Maths steps rendered in the production player at 390×844 and 1280×800 with 1.5× text; navigation additionally passed at 800×360 with 1.5× text and 390×844 with 2× text |
| Interaction/persistence checks | Maths completion, quiz retry, resume, back navigation, reports, stickers, per-child/subject isolation, SQLite reopen, migration and sync passed alongside existing Science tests |
| Production web build | Passed: `build/web-maths/` |
| Android debug build | Passed: `build/app/outputs/flutter-apk/app-debug.apk` |
| APK signature/content | v2 signature verified; Maths catalogue and all 22 lessons bundled, byte-identical to validated content |
| Web package/content | All 22 Maths lessons byte-identical to validated content; HTML, JS, catalogue and lesson HTTP checks returned 200 with no-cache headers |
| Actual browser check | Subject hub → Maths → Term 1 → lesson → save → reopen at saved step → map → subjects; original Science map also opened; console warning/error log empty during these checks |
| Actual browser viewport check | Lesson inspected at 1280×800 and 390×844; temporary viewport reset afterwards |
| Final diff review | No changes to existing Science JSON, dependency lockfile, Android configuration, database schema, backend or global design; `git diff --check` passed |

Commands used for the final Flutter checks (after sourcing
`scripts/environment.ps1`):

```powershell
dart analyze lib test
flutter test --no-pub --dart-define=REVIEW_IMAGES=true --exclude-tags golden,benchmark --reporter expanded
flutter test --no-pub test/goldens/screens_golden_test.dart --reporter expanded
flutter test --no-pub test/data/storage_benchmark_test.dart --reporter expanded
flutter build web --release --no-pub --no-web-resources-cdn --no-wasm-dry-run --output build/web-maths
flutter build apk --debug --no-pub
```

The local preview is `http://127.0.0.1:8766/review/maths-v2-final/`. It is served by
the existing `scripts/serve_preview.py`; it is local and has not been published.
The current APK is a debug build; see the latest revision verification below.
Its existing Internet and app-internal receiver permissions are unchanged.

## Practical limits

The book's personal answers and drawing tasks are discussed with an adult;
they have no fabricated automatic score. Paper support pages are retained as
source data rather than a separate document editor. Science's existing daily
spaced review remains on its Science map. Maths has unit/quiz replay, parent
practice and word stickers. Physical Android touch, installed offline TTS and
speaker audibility require an actual device check.

The successful builds emitted existing toolchain warnings about the
`flutter_tts` Kotlin plugin, SDK XML version support and an unbundled Cupertino
font family. Maths uses bundled Material icons. Dependencies and build
configuration were kept unchanged as requested; these warnings did not prevent
either build.

Pre-existing `output/` transfer files are untouched. No commit, deployment or
publication is part of this addition.

## Visual and teaching revision (12 October 2026)

Maths now uses three painted illustration atlases: four islands, four learning
settings and sixteen individual objects. Subject cards have the same proportions
and appear side by side at tablet widths. Art paths and prompt briefs are in
[MATHS_ART_V2.md](MATHS_ART_V2.md). All exact quantities and markings are still
rendered from validated data. Object crops use measured source-pixel bounds.

All 19 introductory steps now contain 57 purposeful tasks. The first counts
seven apples individually, checks seven after rearrangement, then builds ten
counters. Guided hints and completion are saved in the existing lab state; they
create no assessment score. Build tasks allow overshooting and taking objects
away. Diagrams supplied with a task remain visible during construction.

Maths content version 2 migrates existing journeys by stable step ID. An old
intro-only tap record is reset when the child is still on that intro. Later
progress, results, earned stars and attempt identity are preserved. Completed
legacy intros remain completed when reached by back navigation.

Numeric answer positions now vary deterministically without changing answer
IDs or graded semantics. All 273 source answers still match the original PDF.

This is an AI teaching-design review, not approval from a human teacher.
[MATHS_TEACHING_REVIEW.md](MATHS_TEACHING_REVIEW.md) gives the unit-by-unit
learning rationale and primary NCETM/EEF references.

Revision checks: `dart analyze lib test` reports no issues. The full Flutter
suite passed 460 tests, with the one live-backend test skipped because
`SYNC_LIVE_URL` is absent. Five visual baseline tests passed after intentional
updates to both responsive subject-hub baselines. All 292 Maths screens were
rendered at phone/tablet sizes with enlarged text. All 19 workshops and 57
tasks were completed through widget interactions, including failure rollback
and resume tests. The PDF comparison and repeat-build validator both passed.
Logs: `build/maths-v2-full-tests.log`, `maths-v2-goldens.log`,
`maths-v2-web.log`, `maths-v2-apk.log`. Review images are in `build/review/`.
The successful full run follows a repaired test-only image decoding wait in
`subject_hub_test.dart`; real decoded Maths art is now awaited explicitly.

Final web and Android debug builds passed. All 26 Maths content/art
files are byte-identical in both packages. APK size: 213552222 bytes.
SHA-256: `93ff066bac3c85ebfded7bd57ce0ec15f818b46a25cacd94c7233c011fe971f4`.

## Review fixes (12 October 2026)

A second review (analyzer, all tests, both content validators, and a
1280×800 tablet emulator with its status and navigation bars) found these
and fixed them on the same branch (PR #6):

| Finding | Fix | Check |
| --- | --- | --- |
| Counting touches were lost: each touch locked the objects while it was saved. On the emulator seven quick touches counted three and numbered the apples out of order | A touch shows at once; saves run in touch order; a failed save returns to the last saved state as before | Widget test with slow saves; emulator: ten quick "Add one" touches gave ten |
| On the tablet the workshop answers and next button were below the screen; 90 of 255 questions had answers below the action strip | The workshop scrolls to new answers and buttons; the painted setting is a strip on short screens and left out above charts; short answers share one row | Test over every question with the tablet bars: 251 fit, 4 are 8–36 points from it; emulator |
| All 280 parent activities had one generic Arabic sentence | `assets/content/maths_parent_ar.json` (approved by the owner) with Arabic for each activity; the build reads it and the validator checks it | Validators, repeat build |
| `drift_progress_store.dart` unformatted; parent retry labels outside the ARB files; scene-kind test skipped Maths; Maths validator not in CI | Formatted; ARB keys; a Maths scene test; CI content job runs the validator | Format, analyzer, tests |

The three illustration atlases were lossless WebP (5.9 MB); after the owner
approved a side-by-side comparison they are re-encoded like the Science art
(1.0 MB, same size and transparency). Not changed yet: step titles shown to the child
are generic ("Maths discovery 2"), every Maths sticker shows the same icon,
and the old-content migration (v1 to v2) covers data that never shipped.

## A picture in every question (teacher review 5, 13 October 2026)

Every one of the 258 graded questions now shows a picture; before, 115 did.
Most are drawn in code from the content (`PICTURES` in
`scripts/build_maths_content.py`, keyed by question ID): ten frames and tens,
two-colour counters for doubles, halves and number bonds, socks in pairs,
number lines to jump along, the week and the year as a circle, times of day,
clocks, coins, fractions, 2D and 3D shapes, a toy car, Venn and Carroll
diagrams, a robot grid and a podium. A picture never marks the answer.

The 13 questions about real objects (a spoon, a bed, a feather, scales, a
jug...) use the everyday objects atlas `maths-things-v1.webp`
(docs/MATHS_ART_V2.md). The validator fails if a graded question has no
picture (`AWAITING_ART` in `scripts/validate_maths_content.py` is empty).
