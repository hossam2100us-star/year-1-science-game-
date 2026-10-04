# All units: visual and usability review — 4 October 2026

The request was to review the application from its beginning against the accepted garden presentation and apply the earlier usability corrections throughout. Every one of the nine units and four quizzes was reviewed. This pass implements the main interaction and layout corrections and replaces four shared image atlases. Some dedicated illustration replacements remain open because image generation reached its usage limit; those are listed explicitly below.

## Review coverage and changes

| Unit | Reviewed | Implemented in this pass |
| --- | --- | --- |
| 1 — Alive or not alive | Actual garden, home and river adventures; 46 legacy source activities as references | Preserve the three accepted painted hunts. Child save-failure text is English. The review menu opens the actual adventure route, not the legacy slideshow. |
| 2 — Plants | All 14 activities | Show one food at a time with the five original baskets, previous/next, saved choices and drag correction. Improve paper, wind and drooping-plant representations. Preserve part discovery, neutral touch markers, building and prediction experiments. |
| 3 — Ourselves | All 13 activities | One current sense question, with three declared alternatives that change with the question. Remove the answer illustration from the senses-count question. Preserve complete body framing and distinct neutral anatomical targets. Improve music/flower/car examples. |
| 4 — Materials | All 13 activities | Both illustrations appear for each named object/material pair. Whole-window context, separate phone touch areas and actionable drawer cues. Shared objects and samples use transparent art. Compound stretch artwork fits its actual phone bounds. |
| 5 — Forces | All 13 activities | Keep the accepted three-place movement garden and guided push/pull experiment. Other scenes have responsive, separate touch areas; the final trail shows one current discovery while preserving all five original targets. |
| 6 — Sound | All 12 activities | Keep the accepted illustrations, silence/observation feedback, editable sound ordering and per-question alternatives. Near/far movement is visible on a phone. Separate Listen controls in the assessed band play only the requested instrument without selecting or placing an answer. |
| 7 — Electricity and magnets | All 11 activities | Calm room setting; one safety discovery or mapping clue at a time, full original alternatives, previous/next and first-unanswered resume. Whole transparent appliances/samples. Magnet/object positions remain separate on a phone; predictions precede tests. |
| 8 — Earth | All 13 activities | One complete water place at a time; current water/habitat/badge question with full original targets. Soil has three freely chosen locations and five required touch/drag discoveries. Beach litter is collected in one scene by touch or dragging. Four visibly distinct rocks can be freely regrouped, with editable group names and persistent original group IDs. |
| 9 — Earth in space | All 12 activities | One complete model or mapping clue at a time; full original name/year/suit-job alternatives. The day/night diagram scales as a whole, keeps Sun and Earth separate and shades Earth's night side. Painting and star drawing remain ungraded. |
| Quizzes 1–4 | All 40 questions | Quiz 1 phone cards preserve whole label words at enlarged text. Quizzes 2–4 use explicit neutral contexts; `art: null` suppresses legacy focus images that would reveal an answer. Mapping quizzes show one current clue while retaining all original alternatives. Quiz 3 still has its ten original choice questions; this pass does not claim new exploratory question types. |

Child-facing instructions and feedback remain English. The Arabic review menu is a parent review tool. The new review menu includes all nine units and all four quizzes, with each opened under the existing temporary progress store.

Whole subjects, resting poses and neutral hand markers are used for assessment. Selecting a name does not highlight the correct anatomical or plant location. Navigation and instruction playback do not create answer evidence. Original grading, mistake history, source-based feedback, correction where already enabled, predictions and completed historical results remain in their existing controllers.

## Delivered artwork

Generated with the **built-in image tool**, copied into the workspace and registered in `pubspec.yaml`:

| Final saved file | Dimensions | Bytes |
| --- | --- | --- |
| `E:/seif-science-game/assets/images/materials-atlas-v2.png` | 1254 × 1254 | 1,686,919 |
| `E:/seif-science-game/assets/images/electric-atlas-v2.png` | 1254 × 1254 | 1,631,657 |
| `E:/seif-science-game/assets/images/earth-atlas-v2.png` | 1254 × 1254 | 2,560,054 |
| `E:/seif-science-game/assets/images/science-details-v2.png` | 1269 × 1240 | 1,612,946 |

All four files contain actual alpha transparency, with alpha ranges 0–255. Original references remain in the repository. The replaced four opaque WebP files are excluded from the application asset list. Existing accepted transparent Forces and Sound illustrations are reused for matching shared subjects rather than duplicating those images.

The generated subjects slightly cross nominal row boundaries. Full-quarter crops initially included pieces of adjacent pictures. Final pixel bounds were measured read-only from alpha silhouettes, padded by five pixels and registered in `science_atlas_crops.dart`; the generated image files were not filtered or retouched. The final paper alias uses its measured bounds as well. The exact delivered prompts and pending prompt specifications are in [ALL_UNITS_IMAGE_PROMPTS.md](ALL_UNITS_IMAGE_PROMPTS.md).

## Verification completed

- Final `dart analyze --fatal-infos`: **No issues found** (`tmp/all-units-review/analyze-final.log`).
- Final full Flutter suite: **199 passed, no failures**, 108 seconds (`tmp/all-units-review/full-tests-final.log`). Earlier 198-test results predate the final Quiz 1 phone-label regression.
- After measured crop changes, all **36 affected tests** passed. After the last Quiz 1/menu changes, all **20 navigation/biology tests** passed; these preceded the final 199-test full run.
- `scripts/validate_playable.py`: **187 activities** pass schema, IDs, answer references, source coverage and prediction exclusion (`tmp/all-units-review/content-final.log`).
- Protected comparison against the pre-review snapshots: all 187 activities in 13 books retain IDs, kinds, option/target IDs, assessed answers, sources, objectives, versions and laboratory completion rules (`tmp/all-units-review/protected-final.json`). Owned presentation refiners are also idempotent, as recorded in the sub-reviews.
- Final visual capture harness passed: all **187 source activities**, the **three actual garden adventures**, and **13 phone opening screens**. Contact sheets are `tmp/all-units-review/final-*-contact-*.jpg`; detailed Earth and biology captures supplement them. The final Quiz 1 label change is covered by its subsequent rendering/regression test.
- Release web build succeeded in **118.7 seconds** (`tmp/all-units-review/web-build-final.log`).

The static captures cover complete screens and phone layouts; they do not certify audible playback or a physical tablet. Browser UI automation could not initialize because its Windows sandbox helper failed to apply ACLs. HTTP/source verification and the rendered Flutter screens are the actual evidence for this delivery; a request to open the review tab was queued in Codex.

Local review: [all nine units and four quizzes](http://127.0.0.1:8765/review/all-units-review-v1/?preview=science-v1). The separate review store protects real progress; it is not a production deployment. The served page, script, content, artwork and audio hashes are checked in `tmp/all-units-review/preview-final.json`.

## Remaining illustration work

The first remaining image request, transparent extraction of the old Physics atlas, returned HTTP 429 `usage_limit`. The prepared Extras, Biology and three-scene background requests were therefore not generated. No unavailable asset is referenced at runtime and no API/CLI fallback was used.

Priorities for the next art pass:

1. Dedicated matching storybook illustrations for toys, wind and dry/drooping plants; transparent flower/car/music cutouts. Current flower/car portraits still include their painted surroundings, while toys/wind/drooping plants use clear native drawings.
2. Remaining Physics/Extras subjects that still use the older paper-backed artwork, particularly key and sand/dead-leaf/insect/pan/plate examples. The magnet's opaque cell is now excluded by a display silhouette clip, as recorded below; a standalone transparent bitmap remains pending. Most Forces objects, moving animals and instruments already reuse the accepted transparent art; the beach bag now has a translucent native illustration.
3. More literal book, stone-wall and marble-floor examples. The current collection reuses newspaper/brick/stone samples; those still need dedicated illustrations.
4. Bespoke painted room, nature and space backgrounds. The working code-drawn backgrounds are calm and complete, but are not claimed to match the accepted garden's detailed painted art.

Physical-tablet checks for touch comfort, speaker volume, photo picking and installation remain external acceptance work. Skills, certificates, final parent dashboard and cloud accounts are separate existing roadmap work, outside this visual review.

Detailed audits: [Biology](ALL_UNITS_BIOLOGY_AUDIT.md), [Materials and quizzes](ALL_UNITS_MATERIALS_QUIZZES_AUDIT.md), [Forces and Sound](ALL_UNITS_FORCES_SOUND_AUDIT.md), [Electricity/Earth/Space](ALL_UNITS_EARTH_ELECTRIC_SPACE_AUDIT.md), [Earth collections](EARTH_COLLECTION_REVIEW.md).

## Electricity page 2 — mixed choices (2026-10-04)

The appliance collection previously displayed all four electricity-powered objects together. Its presentation now uses a complete `choiceOrder` permutation: lamp, vacuum cleaner, book, chair, television, lantern, dishwasher. This breaks the contiguous answer group and avoids a phone layout with exactly one correct answer in every row. Positions remain stable when the child selects, deselects or revisits the activity.

The source options, answer IDs, grading and progress format are preserved. `ScienceWorldStage` applies this metadata only to collection choices; invalid or incomplete metadata falls back to the full original list. The science presentation refiner reproduces the order and remains idempotent.

Verification for this focused follow-up: all eight `science_world_stage_test.dart` tests passed, including mixed-order and stable-selection regressions at 360 × 740 and 1280 × 860. `dart analyze --fatal-infos` is clean; all 187 content activities and their protected answer/source fields pass validation. These are focused follow-up checks; the 199-test full-suite result above belongs to the preceding complete review.

The complete activity was rendered and visually checked at tablet and phone sizes (`tmp/all-units-review/electric-mix-1280.png` and `electric-mix-360.png`). The release web rebuild succeeded in 49.5 seconds, and five HTTP responses confirm the new route serves the current script, mixed content and artwork (`electric-mix-build.log`, `electric-mix-preview.json`).

Local review: [Electricity page 2](http://127.0.0.1:8765/review/electric-mix-v2/?preview=biology-v1&lesson=unit_07&step=2).

## Electricity page 4 — remove the magnet's paper frame (2026-10-04)

The magnet still resolved the opaque cell in `physics-atlas-v1.webp`. The lab and drag feedback have no white container. A central `SciencePicture` override now displays the same painted magnet through `MagnetPicture`: a close source crop and silhouette clip exclude the surrounding paper and open the U-shaped gap onto the actual scene. This applies to resting and dragged magnets, Electricity focus/matching screens, Quiz 3 and the review-menu icon. The original raster and its red/blue paint, metal tips and highlights are preserved; this is a rendering fix, not a newly generated transparent image file.

The built-in image-edit attempt for a standalone transparent magnet returned HTTP 429 `usage_limit_reached`. No fallback API/CLI or raster filtering was used. Its exact prompt and future asset specification are recorded in [ALL_UNITS_IMAGE_PROMPTS.md](ALL_UNITS_IMAGE_PROMPTS.md).

The complete rectangular touch area remains active through a passive opaque pointer listener, so touching the open center still starts a drag. The visual clip introduces no competing gesture handler and does not change prediction gates.

Verification: the final combined run passed all 13 tests (12 permanent artwork/island tests plus the capture harness), including actual rendered-pixel checks for transparent outer corners and inner opening, preserved red/blue halves and metal tips, dragging by the open center, and the existing magnet prediction/persistence checks. Twelve lesson/quiz captures and four further phone/tablet captures with actual drag feedback passed and were visually reviewed. The drag harness explicitly checks the resting child is replaced and the feedback magnet is mounted; its screenshot boundary includes the root overlay. `dart analyze --fatal-infos` is clean. This focused presentation change does not alter lesson content, answers or saved progress. Evidence: `tmp/all-units-review/magnet-frame-tests-final.log`, `magnet-frame-analyze-final.log` and `magnet-frame-{phone,tablet}-{rest,drag}.png`.

Local review: [Electricity page 4](http://127.0.0.1:8765/review/magnet-frame-v3/?preview=biology-v1&lesson=unit_07&step=4).

The final release web build succeeded in 73.1 seconds (`magnet-frame-build-final.log`). Six HTTP responses and source/hash checks confirm the new route serves the final magnet renderer, source artwork and the preceding page-2 mixed choices (`magnet-frame-preview.json`).
