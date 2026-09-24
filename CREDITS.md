# Asset and content credits

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

No music or sound-effect files are included yet. English narration uses installed offline system voices via flutter_tts.


## Garden illustration (2026-09-23)

assets/images/garden-v2.png: original image generated for this project using the built-in image generation tool, with a targeted refinement. No third-party artwork or book illustrations were used. Not represented as a CC0 asset. Prompts and provenance: docs/GARDEN_ART_PROMPT.md. The game renders source regions of the same asset for matching object portraits. Existing sound/third-party licenses are unchanged.

## Illustrated islands and plants (2026-09-24)

assets/images/islands-v2.png, assets/images/bean-stages-v1.png, and assets/images/greenhouse-v1.png: original images generated for this project with the built-in image generation tool. No third-party artwork or textbook images were used; these are not described as CC0 stock. Exact prompts and source review are in docs/ISLANDS_AND_BEAN_ART.md. All files are bundled for offline use.


- `assets/images/plant-lab-v1.png`: original artwork generated with OpenAI imagegen for this project; no third-party illustration copied. Prompt and use: `docs/PLANT_LAB_ART.md`.


- `assets/images/light-room-v1.png` and `assets/images/light-plants-v1.png`: original artwork generated with OpenAI imagegen for the light experiment. No third-party illustration copied. Prompts and source notes: `docs/LIGHT_TEST_ART.md`.

