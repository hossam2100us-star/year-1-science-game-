# Biology presentation audit — 4 October 2026

This pass follows the request to review every unit from the beginning against the accepted storybook garden and apply the earlier usability corrections consistently. It covers Units 1–3 and the biology scenes in Quiz 1. This is a presentation pass: source links, assessed answers, IDs, objectives, minimum touch counts, content versions, previous completion groups and stored results remain intact.

## Screens inspected

- Actual Unit 1 child route: `tmp/all-units-review/unit_01/garden-garden.png`, `garden-home.png`, `garden-river.png`. These are the accepted painted garden, home and river hunts. They use GardenAdventure, not the legacy 46-page LessonPlayer walkthrough.
- Unit 1 contact sheets 1–3 were also inspected as a reference for the older source-linked activities; their primitive icon drawings are not evidence that the accepted hunt artwork has regressed.
- All 14 Unit 2 screens, all 13 Unit 3 screens and all 10 Quiz 1 screens in `tmp/all-units-review/*-contact-*.jpg`.

## Findings and implemented corrections

| Area | Finding | Correction |
| --- | --- | --- |
| Unit 1 garden, home and river | Full painted environments, clear subjects and persistent progress already match the accepted direction. | Keep these illustrations, scene geometry and assessment logic. Child save-failure text is English. |
| Unit 2 food collection | Thirteen food pictures plus five baskets crowded one screen. | A single large food appears on the greenhouse workbench. Choose or drag it to any basket, then advance to the next food. Previous food remains available for correction. All thirteen original mappings remain in the same assessment. |
| Unit 2 bean and light experiments | Child-facing prediction/help/save messages still included Arabic. | Visible instructions, prediction labels and save-failure messages are English. Predictions remain exploratory; persistence and elapsed-time logic are unchanged. |
| Unit 3 sense partner and story activities | Five or ten question pictures with all partners appeared together. | One discovery scene appears at a time, with three relevant partners that change between questions. The complete original target list and answer mappings are retained for saves and grading. |
| Unit 3 sense detective | Seven fixed alternatives crowded four different questions. The question about the number of senses also pictured the answer. | Three alternatives per question; the count question uses its written/spoken question without the answer illustration. |
| Unit 3 body and eye | Previous fixes already keep the child visible and give each anatomical location its own neutral touch marker. | Retain fixed whole-body framing, separated touch markers and neutral target colours. Selecting a body name does not highlight the correct location. |
| Quiz 1 garden choices on a phone | The old minimum tile width split `Table` into `Tabl` and `e` at 360 pixels with 1.5× text. | Measure the widest word at the actual text scale, then choose one, two or three columns that fit. Labels keep their 24-point style and accessibility scaling; callbacks and answer sets are unchanged. |

Advancing within a food/discovery activity does not award success. The original lesson controller checks the complete mapping only when the child presses **Check my discovery**, preserving mistake history and objective evidence. On reopening, the selected or first unanswered item is shown without deleting earlier choices.

## Artwork

Existing painted plants, growth experiments, foods, senses, explorers and accepted Unit 1 hunt backgrounds are retained. Music, flowers, the car and the generic toys, paper, wind and dry/drooping plant pictures were identified as the first remaining mismatched subjects.

Available exact subject illustrations are reused: music uses the accepted painted trumpet in `sound-atlas-v2.png`; flower examples use the sunflower head in `plant-lab-v1.webp`; car examples use the accepted car portrait in `garden-v2.webp`; plain paper uses the new transparent paper sheet in `science-details-v2.png`. Normalized aliases include capitalized source examples such as `Car`, plus `hear_music` and `smell_flowers`. The flower and car portraits retain their original painted surroundings; this pass does not claim they are transparent cutouts.

Wind remains a direct canvas illustration, now with flowing lines and drifting leaves. The dry/drooping plant remains a direct canvas illustration, now showing an arched stem, drooping leaves, dry soil and a shaded pot. It does not reuse a healthy plant picture. The existing recognizable toy train and ball remain until a matching painted toy asset is available. Original full explorers and sense illustrations are not replaced. Relevant rendering suites preload only the real assets used and capture these seven revised subjects in `tmp/biology-subjects-review.png`.

A proposed sixteen-subject transparent biology atlas could not be generated because the built-in image tool returned HTTP 429 `usage_limit`. No nonexistent `biology-scenes-v3.png` asset, pubspec registration or runtime reference is included. A matching painted toy scene and dedicated transparent music/flower/car/wind/drooping cutouts remain open artwork work, rather than completed changes. The attempted generation and the assets actually delivered are distinguished in `ALL_UNITS_IMAGE_PROMPTS.md`.

The plant-building workbench still deliberately shows separate empty placement regions until the child places each part. It must not show a complete plant behind empty regions, highlight the correct region when a name is selected, or count listening to a label as placement.

## Verification responsibilities

- `test/ourselves_scene_test.dart`: one visible discovery, three declared partners containing every original answer, all source-linked answers retained, count question does not display its answer, earlier wrong choices survive back navigation, objective-specific correction evidence remains accurate, complete body and neutral non-overlapping touch markers remain available for both child genders, and all thirteen activities fit small landscape with enlarged text.
- The same suite checks that `Table` occupies a single line at 360×740 and 1.5× text, keeps its unshrunk font style, and the Quiz 1 garden still accepts its complete assessed answer.
- `test/plant_variety_test.dart`: one visible food at a time, all thirteen foods remain required, next food does not grade a response, sorting by touch at tablet and small landscape sizes, saved wrong basket and current food survive reopening, back navigation and dragging can correct a basket without inventing a result.
- Existing garden, plant review, bean and light suites still cover scene progress, matching placements, prediction persistence, and old content migration.

This document records the inspected screens and implementation. The root review runs the Flutter suites, analyzer and regenerated final screen renders; actual final command results belong in `ALL_UNITS_REVIEW.md`. No physical tablet test is claimed here.
