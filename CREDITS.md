# Asset and content credits

## Ourselves review — 26 September 2026

`lib/features/biology/body_scene.dart`, `biology_art.dart` and `shoe_measure.dart`
contain original code-drawn educational artwork: explorer characters, eye and sense
illustrations, everyday objects, quiz objects and shoes. No external or copied book
artwork is used. Geometry is shared with the interactive body targets. See
`docs/BIOLOGY_REVIEW_20260926.md` for the source and validation notes.

No book illustrations, copyrighted characters, stock photos, or downloaded character art are included.

| Asset | Origin | License |
| --- | --- | --- |
| `lib/core/mascot.dart` (Zizo, Zizi, fox, bunny, cat) | Original vector artwork drawn in project code | Original project asset |
| `lib/features/world/island_art.dart` | Original vector island scenes | Original project asset |
| `assets/animations/celebrate.json` | Original 1.2-second particle animation | Original project asset |
| Android flask launcher icon | Original vector in `android/app/src/main/res/drawable/ic_launcher.xml` | Original project asset |
| `assets/fonts/Fredoka.ttf` | [Google Fonts / Fredoka](https://github.com/google/fonts/tree/main/ofl/fredoka) | SIL Open Font License 1.1; see Fredoka-OFL.txt |
| `assets/fonts/Nunito.ttf` | [Google Fonts / Nunito](https://github.com/google/fonts/tree/main/ofl/nunito) | SIL Open Font License 1.1; see Nunito-OFL.txt |
| `assets/fonts/Cairo.ttf` | [Google Fonts / Cairo](https://github.com/google/fonts/tree/main/ofl/cairo) | SIL Open Font License 1.1; see Cairo-OFL.txt |
| Material Icons, bundled by Flutter | [Google Material Design Icons](https://github.com/google/material-design-icons/blob/master/LICENSE) | Apache License 2.0 |
| Flutter | [Flutter SDK](https://github.com/flutter/flutter/blob/master/LICENSE) | BSD 3-Clause |
| `test/fixtures/portrait_with_metadata.png` | Original solid-colour synthetic test image with dummy metadata | Original project test fixture; never bundled in the app |

Font binaries and their accompanying licenses are local assets. No font download occurs at runtime. The dependency license registry is included by Flutter.

Curriculum: the parent's supplied `Science_Made_Simple.pdf`, used as a local reference only. The PDF is excluded from Git and application bundles. No permission to redistribute the PDF or its illustrations is assumed. The only runtime educational navigation data in Phase 1 is `assets/content/catalog.json`, with the parent guide adapted from page 2. Extracted question drafts are not bundled.

A user-selected profile photo is supplied by the parent through the system picker, is never a repository asset, and is never uploaded. Only a resized PNG is retained in private local storage; image metadata is discarded. No camera is used.

Local illustrative synthesized sound effects are bundled; no external recordings are used. English narration uses installed offline system voices via flutter_tts.


## Garden illustration (2026-09-23)

assets/images/garden-v2.webp (bundled; its earlier PNG master is in Git history): original image generated for this project using the built-in image generation tool, with a targeted refinement. No third-party artwork or book illustrations were used. Not represented as a CC0 asset. Prompts and provenance: docs/GARDEN_ART_PROMPT.md. The game renders source regions of the same asset for matching object portraits. Existing sound/third-party licenses are unchanged.

## Illustrated islands and plants (2026-09-24)

assets/images/islands-v2.webp, assets/images/bean-stages-v1.webp, and assets/images/greenhouse-v1.webp (PNG masters in Git history): original images generated for this project with the built-in image generation tool. No third-party artwork or textbook images were used; these are not described as CC0 stock. Exact prompts and source review are in docs/ISLANDS_AND_BEAN_ART.md. All files are bundled for offline use.


- `assets/images/plant-lab-v1.webp`: original artwork generated with OpenAI imagegen for this project; no third-party illustration copied. Prompt and use: `docs/PLANT_LAB_ART.md`.


- `assets/images/light-room-v1.webp` and `assets/images/light-plants-v1.webp`: original artwork generated with OpenAI imagegen for the light experiment. No third-party illustration copied. Prompts and source notes: `docs/LIGHT_TEST_ART.md`.

# Plant review illustrations — 26 September 2026

Original code-drawn illustrations in `plant_workshop.dart`: toy car and ball,
paper sheets, wind, a brown drooping plant, and separate workshop plant pieces.
No external artwork or book illustrations are copied. The workshop is ungraded;
its roots, stem, leaves and flower follow the existing source-linked activity.

## Ourselves illustrations — 27 September 2026

`assets/images/explorer-boy-v2.webp`, `explorer-girl-v2.webp`, `five-senses-v2.webp`
and `sense-objects-v2.webp` are original artwork generated for this project with
the built-in OpenAI image-generation tool. They are bundled for offline use;
no textbook illustrations or third-party character artwork were copied. These
are not represented as CC0 stock. Generation briefs and provenance are recorded
in `docs/OURSELVES_V2_REVIEW.md`.

## Remaining science islands — 27 September 2026

Six original project image atlases are bundled in `assets/images`: materials,
physics, earth, electric, science-extras and science-details. Bundled now:
physics-atlas-v1 and science-extras-v1 (WebP), and the v2 materials, earth,
electric and science-details atlases; the superseded v1 files are in Git history.
Generated using the built-in OpenAI image tool; no textbook art or third-party
characters copied. Not represented as CC0 stock. Generation briefs and source
filenames are in `docs/REMAINING_ISLANDS_REVIEW.md`.

Seven local WAVs in `assets/audio` are original synthesized illustrative tones,
created by `scripts/build_science_audio.py`; no external recordings are used.

## Sound unit review — 1 October 2026

`assets/images/sound-atlas-v2.webp` and `assets/images/sound-details-v2.webp`
are original transparent illustrations generated for this project using the
built-in OpenAI image-generation tool. No textbook illustrations or third-party
character artwork were copied, and these are not represented as CC0 stock.
Exact prompts and installed asset paths are in `docs/SOUND_UNIT_REDESIGN.md`.

The current twelve WAVs in `assets/audio` are original illustrative PCM synthesis
from `scripts/build_science_audio.py`, including tapping sticks, cat footsteps,
whisper, door and thunder alongside the instrument and box effects. They are
not recordings of instruments, people or animals. No external audio is used.
Following Sound-box feedback, `feather.wav` is a valid silent PCM asset containing
only zero samples; it represents the feather trial without an audible impact.

## Repository clean-up — 4 October 2026 (AUD-012)

24 image files that were never bundled were removed from the working tree:
the superseded v1 atlases (earth, electric, materials, science-details; PNG
and WebP) and the PNG masters of bundled WebP files. They remain available in
Git history (any commit before the clean-up). 17 masters were pixel-identical
to the bundled WebP; bean-stages-v1, greenhouse-v1 and light-plants-v1 PNGs
were earlier drafts of the refined, bundled WebP art.

## Lossy WebP re-encode — 4 October 2026 (AUD-008)

All 29 bundled images were re-encoded as WebP (quality 80, alpha 90) at
their exact pixel size with tools/images/optimize.mjs after the owner
approved side-by-side comparisons (PSNR 32.5–41.3 dB on the game
background). Bundled art went from 50.6 MB to 7.1 MB. The previous PNG and
lossless WebP files remain in Git history. The artwork and its provenance
are unchanged.

## Socket safety picture — 10 October 2026 (teacher review 4, T4-1)

assets/images/electric-safety-socket-v2.webp replaces the first panel of
electric-safety-v1.webp (where the adult pointed a finger at the socket).
The owner generated it with Google Gemini from the earlier panels as style
and character reference, using the prompt written for this change (socket
with a safety cover, no hand near it). Its flat magenta background was
removed with tools/images/cutout.mjs, then encoded as WebP (quality 80,
alpha 90) at 1024×921. No third-party or book artwork was used. The other
two panels of electric-safety-v1.webp are unchanged.

## Socket safety picture — 12 October 2026 (teacher review 5)

assets/images/electric-safety-socket-v3.webp replaces electric-safety-socket-v2.webp
(in Git history): the teacher asked for the child to stand farther from the
socket. The owner generated it with Google Gemini by editing v2 with the prompt
written for this change (same mother and boy, the boy moved next to the mother,
the socket untouched). The magenta background was removed with
tools/images/cutout.mjs (lossless), part of the empty space between the boy and
the wall was cut so the gap is about the boy's width, and the result was
encoded once as WebP (quality 80, alpha 90) at 1024×708, 83 KB.

## Maths bird pictures — 12 October 2026 (teacher review 5)

assets/images/maths-birds-v1.webp: a pigeon, a house sparrow and a hooded crow
for the Maths bird chart. The owner generated it with Google Gemini, using the
Maths objects atlas as style reference and the prompt written for this change.
Background removal and encoding as described in docs/MATHS_ART_V2.md. No
third-party or book artwork was used.

## Maths everyday objects — 13 October 2026 (teacher review 5)

assets/images/maths-things-v1.webp: 27 everyday objects (a spoon, a bed, a
feather, kitchen scales, a jug, an open and a closed eye...) for the Maths
questions about real things. Generated in the owner's Canva account with
Canva's image generator, with prompts written for this change (objects in a
grid on flat magenta, no text), exported at full size from a working design
the owner approved, then cut out and arranged with
tools/images/things-atlas.cjs as described in docs/MATHS_ART_V2.md. No
third-party or book artwork was used.
