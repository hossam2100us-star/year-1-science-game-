# Maths art revision — 12 October 2026

Mode: built-in `image_gen`, three generated illustrations using existing Science
art as style references. No CLI/API fallback. The runtime assets were first
pixel-identical lossless WebP encodings of the selected PNGs (5.9 MB). On
12 October they were re-encoded like the Science art (WebP quality 80, alpha
90; same size, transparency preserved), 1.0 MB in all, after the owner
approved a side-by-side comparison; the lossless files remain in Git history.

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

## Bird atlas — 12 October 2026 (teacher review 5)

The bird chart used one blue bird for pigeons, sparrows and crows.
`assets/images/maths-birds-v1.webp` (1536×512, 78 KB) holds a pigeon, a house
sparrow and a hooded crow in three equal cells, so no bird looks bigger than
another. The owner generated it with Google Gemini, with the objects atlas as
style reference and the prompt written for this change (three birds, side
view, same size, flat magenta background). The magenta was removed with
`tools/images/cutout.mjs` (lossless), each bird was trimmed and fitted to a
512-pixel cell, and the atlas was encoded once as WebP (quality 80, alpha 90).
`mathsBirdCells` in `maths_art.dart` maps `pigeon`, `sparrow` and `crow`.

## Everyday objects atlas — 13 October 2026 (teacher review 5)

The last 13 questions without a picture were about real objects.
`assets/images/maths-things-v1.webp` (1920×1600, 332 KB) holds 27 of them in
320-pixel cells, six to a row: spoon, shoe, bed, toothbrush, football, alarm
clock; grape, watermelon, strawberry, feather, book, chair; pillow, stone,
jug, mug, bowl, scales; ruler, parcel, flour, school bag, dinner, glass of
water; string, open eye, closed eye.

They were generated with Canva's image generator in the owner's account
(owner's approval), six objects at a time in a 3×2 grid ("children's
storybook illustration… plain flat solid magenta background, no text, no
labels, nothing touching"); the string and the two eyes in 2×1 sheets. The
first eye came out as an orange ball and was replaced. The connector returns
only 200-pixel previews, so with the owner's approval the six pictures were
placed in a working Canva design ("Maths app object pictures") and exported
as PNG at full size.

`tools/images/things-atlas.cjs` builds the atlas from the six sheets:
- the background colour is measured from each sheet's border (Canva's
  magenta is about 247, 6, 235, not pure #FF00FF);
- a pixel's transparency comes from how much magenta is mixed into it, but
  only in the background (also inside handles and chair backs) and a
  three-pixel edge around it, so the purple grape stays solid;
- edge pixels are un-mixed from the measured colour, so the white feather
  has no pink fringe;
- connected pieces go to the grid cell of their centre, so a pillow reaching
  into the next cell is not cut in two;
- each object is fitted to its cell; the exact bounds are in
  `_mathsThingBounds` in `maths_art.dart`, so a long string fills a wide
  picture.

The atlas was checked by eye on light and dark backgrounds and encoded once
as WebP (quality 80, alpha 90). `MathsArt` draws these objects by name, and
the `object` picture type shows one or more of them in a question or answer.
