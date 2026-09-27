# Remaining islands — 27 September 2026

The user authorized completing the remaining curriculum units at the same visual
and interaction standard as the revised Biology activities.

## Runtime scope

| Unit | Activities | Main interaction |
| --- | ---: | --- |
| Material Properties | 13 | Material workshop, rain tests, shape studio |
| Forces | 13 | Push/pull slider, prediction tank, held-button sailboat |
| Sound | 12 | Instrument actions, sound boxes, distance and bar chart |
| Electricity and Magnets | 11 | Safety, magnetic predictions, power sorting |
| Planet Earth | 13 | Water habitats, soil magnifier, rocks and beach cleanup |
| Earth in Space | 12 | Day/night, suit jobs, planet painting and star drawing |
| Materials, Physics, Earth & Space quizzes | 10 each | Source-linked assessed challenges |

These are loaded by LessonLibrary and accessible through the ordinary island
unlock sequence. A separate ScienceReviewMenu opens memory-only previews and
never unlocks or replaces the child's real journey. Existing unit IDs, progress,
and prior Biology versions are preserved.

The generator is scripts/build_remaining_content.py. It does not regenerate or
change the Biology lessons. Every source question has an explicit source or
relatedSources link, including its original answer-key excerpt. Related multiple
choice goals share one compact board but retain separate objectiveEvidence.
Prediction, drawing and free sorting remain ungraded. Each quiz has ten goals.

The original curriculum remains the sole scientific source. Home activities and
safety text are copied from its extracted source files. Compound vocabulary such
as "source of sound" remains a single sticker. Definitions are only supplied when
found in the book's Word List; no definitions are invented for missing entries.

## Artwork provenance and generation briefs

Six original watercolor atlases were generated with the built-in OpenAI image
creation tool. No third-party illustrations or textbook images were used. All
assets are copied into assets/images and bundled offline. These are not CC0
stock assets. The source files remain in the tool's generated_images directory.

| Workspace asset | Generated source |
| --- | --- |
| materials-atlas-v1.png | exec-9a8d654e-85b6-430f-8434-2ab114c62cc0.png |
| physics-atlas-v1.png | exec-70544d40-4c28-4f68-b46d-f222a265fdd3.png |
| earth-atlas-v1.png | exec-16c9741e-ddd3-46d8-82b4-19ecc27e7538.png |
| electric-atlas-v1.png | exec-94196a84-dd89-42bb-8dee-3575cc6b98b5.png |
| science-extras-v1.png | exec-c2d88239-c0ee-4a2d-831a-8e01d188fe2e.png |
| science-details-v1.png | exec-44890d08-2ac9-44f7-84e1-b7fe552ee332.png |

Shared prompt direction: original warm storybook watercolor; equal 4 x 4 cells;
ivory background; generous margins; clear individual silhouettes; no captions,
labels, numbers or brands. Cell requests, in row order:

- Materials: spoon, chair, window, folded shirt; newspaper, plastic bottle,
  aluminium foil, sponge; stone, rubber band, clay pot, pencil; tissue, umbrella,
  brick, dough.
- Physics: doorbell, drawer, swing, trolley; sailboat, cork, balloon, nail;
  triangle, maracas, trumpet, sitar; drum, feather, magnet, steel key.
- Earth: pond, stream, river, lake; ocean, whale, crocodile, frog; soil, worm,
  coal, diamond; Earth, Sun, Moon, full astronaut.
- Electricity: television, vacuum cleaner, oil lantern, lamp; dishwasher, broom,
  battery, torch; fridge, wall clock, bicycle, air conditioner; plastic button,
  gold ring, steel hanger, socks.
- Extras: snake, fish, kangaroo, fully clothed crawling baby; orange, peeled
  orange, door, ball; sand, dead leaf, beetle, bag; saucepan, box, plate, thunder.
- Details: plastic pot, glass marble, paper straw, wooden block; fabric swatch,
  glass pane, paper sheet, metal block; wood, plastic, wet clay, graphite;
  astronaut visor, oxygen backpack, gloves, boots.

Runtime source-region cropping removes tile boundaries; images are not edited or
scientifically inferred by the cropping code. Data specifies every classification
and experimental outcome independently of the artwork.

## Local sound

scripts/build_science_audio.py generates seven short original synthesized WAVs.
They are illustrative instrument/percussion tones, not authentic recordings.
Waveform amplitudes and playback volume are limited; no microphone, network,
new package or permission is used. Sound respects the existing sound setting.
Browser playback uses local asset URLs; Android uses a validated MethodChannel
allowlist and MediaPlayer. Playback is stopped on leaving or backgrounding the
native activity. Actual device listening remains part of final Android QA.

## Review and verification

The focused suite mounts every new screen at 800 x 360 with enlarged text, solves
every assessed activity through its touch controls, tests source counts and quiz
denominators, checks prediction persistence before reveal, and restores free
activities without grading. It also exercises movement, sound distance, wind and
star naming. Representative widget screenshots are in tmp/unit_0N-N.png.

This completes the playable unit content for review. It is not a claim that the
separate skills area, certificate export, final Android device QA or signed APK
release are complete.

Verification results: all 99 Flutter tests passed; Dart analysis passed with no
issues; source/schema validation passed for all 194 activities. Android
`:app:compileDebugKotlin --offline` succeeded without creating a final APK.

After the final content distractors and per-object narration change, all ten
focused science tests passed again. Future experimental outcomes are not spoken
before their own prediction. Final Dart analysis and browser build passed.
