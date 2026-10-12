# Maths art revision — 12 October 2026

Mode: built-in `image_gen`, three generated illustrations using existing Science
art as style references. No CLI/API fallback. Runtime assets are pixel-identical
lossless WebP encodings of the selected PNGs; transparency is preserved.

## Saved assets and prompt set

The following production briefs summarize the prompt set used:

1. `assets/images/maths-islands-v2.webp` — Create a vivid children's storybook
   world, matching the lush painted Science islands. Four distinct islands in a
   2×2 layout: counting orchard, shape workshop, time/sharing village and chart
   harbour. Turquoise water, warm sunlight, appealing detailed scenes. No text.
   This is decorative navigation art, never a question's numerical evidence.
2. `assets/images/maths-objects-v2.webp` — Transparent 4×4 atlas of individual
   rich painted objects: apple, gold star, turquoise sock, blue cube; bean, bird,
   coral counter, empty basket; horizontal pencil pointing right, ball, car,
   doll; banana, orange, mango and a blank wooden clock face. Separate objects,
   no labels or mathematical markings. Runtime controls exact counts and time.
3. `assets/images/maths-backdrops-v2.webp` — Four colourful storybook settings
   in a 2×2 atlas: orchard with a rabbit, shape workshop, village courtyard,
   harbour. Each setting has an empty foreground table/work area, ready for
   runtime learning objects. No text and no foreground objects that could be
   mistaken for the items being counted.

All assets are explicitly bundled in `pubspec.yaml`. Crops are maintained in
`lib/features/maths/maths_art.dart`; numerical diagrams remain deterministic in
`maths_visual.dart`. Counting, clock hands, ruler measurements, shape geometry,
fractions and chart scales come from the validated content, not generated text.

## Original generated files

Originals remain under
`C:/Users/hossa/.codex/generated_images/01a1299d-5714-7690-b7c8-53ea2968dac5/`:

- Islands: `exec-08ba4929-9bea-4b4b-94a9-a9de1dac7019.png`
- Objects: `exec-0ccbceac-2b2a-4c36-ba93-c358bae79037.png`
- Backdrops: `exec-e1573f99-756b-4acf-b7a5-8c1a98d2bf94.png`

The application uses workspace copies only. Teaching rationale and the limit
of the AI review are recorded in `MATHS_TEACHING_REVIEW.md`.
