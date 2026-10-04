# Forces storybook artwork — 3 October 2026

The user's request is to bring Forces illustrations up to the Sound unit's visual standard. The built-in image generation tool was used successfully, with sound-atlas-v2.png as a style reference. No API/CLI fallback was used.

## Saved assets

- `E:/seif-science-game/assets/images/forces-objects-v4.png` — 1,595,463 bytes; 1254 × 1254 RGBA.
- `E:/seif-science-game/assets/images/forces-characters-v4.png` — 1,128,295 bytes; 1254 × 1254 RGBA.
- `E:/seif-science-game/assets/images/forces-details-v4.png` — 1,744,513 bytes; 1448 × 1086 RGBA.
- Combined additional asset bytes: 4,468,271. These are PNGs with original alpha, not a measured APK increase. No white-background filtering or image manipulation outside the built-in image tool was used.

The object sheet has sixteen cutouts; fifteen replace Forces objects and the extra wooden door is available for related scenes. The character sheet has three boy poses and two poses each for fish, snake, bird, kangaroo and baby. The final three cells are empty. The first object generation depicted a screw; a targeted built-in edit corrected it to a smooth nail before integration.

ForcePicture displays measured pixel rectangles, preserves transparency and gives paired poses a shared scale and floor. It replaces the previous ForceIllustrator. Objects retain independent travel; the ball rotates, the swing swings, and animal poses alternate during replay. ForceObject now shows matching transparent switch/zip illustrations. Together, the sheets replace all 22 object/animal types in Forces, plus its child reference.

## Presentation and progress

- Activity 1 now shows one discovery at a time: push, pull, roll, swim, slither, fly, hop and crawl. It has no tabs, simultaneous trolleys or picture grid. Tapping the large picture plays the movement; Next move appears after that discovery is tried. Back/replay remain available, and a restart resumes at the first unseen discovery. All eight original touch IDs are still required and retained.
- Illustrated child/trolley scenes show a stable reference for away/towards. Exploration shows push/pull gestures and a pulling rope; the assessed direction task keeps the child neutral and animates only trolley travel.
- Activity 2 now guides the child through push, pull, prediction, gentle push and bigger push, with one current instruction and one main action (two alternatives only when predicting). Dragging and a large button offer the same trolley action; a flag shows its goal. Each ball test starts from the same place. Only completed moves unlock prediction, and the original guess is retained when replaying or navigating backwards. Saved forceGuide stages are validated against visited/trial data; old tab-based saves infer the first outstanding task without discarding data.
- These two activities show their own instruction/listen control instead of the duplicated generic owl/prompt header. Stage transitions clear the old feedback; results remain in the fixed feedback bar. Instruction playback does not count a discovery or a trial. Child UI stays English.
- Tracks scale to retain a visible movement distance on small screens. The child label sits below the figure, and the first action is visible without scrolling at 360 × 740 with 1.5x text.
- No activity IDs, kinds, source keys, answer values, objectives, assessment flags, content versions or minimum-touch requirements were changed.
- Touch cues and correction controls remain reachable. Child UI remains English.

## Prompt set

### Object atlas generation

undefined

### Character atlas generation

undefined

### Nail correction

undefined

### Switch and zipper generation

Use case: illustration-story
Asset type: two transparent storybook object sprites for a children's Forces science game.
Input image is a STYLE REFERENCE ONLY, not an edit target. Match its beautiful polished watercolor/gouache material texture, fine details, warm soft shading and instantly recognizable objects.
Create one square canvas split into TWO equal vertical halves, with one large complete object centered in each half, generous transparent padding all around and a clear transparent gap between them.
LEFT half: a cream wall-mounted rocker light switch, a rectangular plate with two small screw heads and a clearly visible wide rocker button. Ordinary safe household light switch, no sockets, no electrical wires.
RIGHT half: a close-up of a real brass ZIPPER attached to a narrow strip of blue denim fabric, complete metal slider with a large visible pull tab and teeth joined below it; fabric edges and entire zipper fit inside the right half. No hands or people.
Both objects should occupy about 75 percent of the available half width and 75 percent of canvas height. Calm neutral objects, no indication of an answer or a direction.
No text, letters, numbers, arrows, labels, frame, ground, opaque tile, white matte or checkerboard. The background and space between objects must be genuinely TRANSPARENT.

## Verification

- Full application suite: **174 tests passed in 48 seconds**, after the main artwork, exploration and neutral-assessment changes (`tmp/forces-storybook-full-tests.log`).
- After adding the final switch/zip images and responsive scene scaling: **19 affected Forces/science tests passed in 24 seconds** (`tmp/forces-storybook-final-focused.log`). These include all 22 cutouts, all 13 Forces screens, both directions with a fixed child, 240 dp scene width, reduced motion, all eight discoveries across restart, correction/navigation and all assessed science activities.
- `dart analyze --fatal-infos`: no issues (`tmp/forces-storybook-analyze.log`).
- All **187** activities pass source/schema/content validation. Comparison against `tmp/forces-before-v4.json` confirms preservation of protected fields across all 13 Forces activities.
- Visually inspected the complete cutout sheet, both exploration areas, activities 2/3, and mid-motion scenes at tablet/narrow widths. Renders are generated under `tmp/forces-scenes/`.

The results above belong to the initial artwork pass. The current one-at-a-time presentation follows the user's subsequent feedback that pages 1/2 were crowded. Current validation and review links are recorded below.

Physical-tablet and user visual acceptance remain pending; this change does not claim to complete artwork in units 07–09.

## Previous artwork review (v4)

The release web preview built successfully in 70.7 seconds (`tmp/forces-storybook-preview-build.log`). The loopback server was restarted; the versioned page, JavaScript, unit-05 JSON and all three artwork PNGs return HTTP 200. Served JavaScript/content/image hashes match their built/source files. Changed preview Dart files and pubspec match the workspace. The Codex browser-open request was queued; this is not a claim of a completed browser interaction walkthrough.

Review: http://127.0.0.1:8765/review/forces-storybook-v4/?preview=biology-v1&lesson=unit_05&step=1

No APK, cloud publishing, database setup or Git commit/push was performed in this artwork pass.

## Simplified pages 1/2 verification (v5)

- Final full application suite: **176 tests passed in 79 seconds** (`tmp/forces-simple-full-tests.log`), after the guided instruction/feedback cleanup. This supersedes the older artwork-only counts above.
- Final `dart analyze --fatal-infos`: no issues (`tmp/forces-simple-analyze.log`). All **187** activities pass source/schema/content validation, and the Forces refiner is idempotent. Comparison against `tmp/forces-before-v5.json` confirms that the protected fields of all 13 activities and their content version remain unchanged.
- Regression tests cover the required eight discoveries, playback without progress, restoration at the first unseen movement, legacy guided-lab saves, the original prediction, same-start ball tests, correction/navigation and neutral assessed scenes. No stage can skip a missing required task.
- The initial main action is visible without scrolling at 360 x 740 and 1.5x text. Compact portrait/landscape targets remain reachable. The final phone renders of both initial pages were visually inspected; render outputs are under `tmp/forces-scenes/`.
- Preview source files, content, pubspec and the three artwork sheets match the workspace. Physical-device acceptance remains pending.

### Current local review

The subsequent garden story presentation for activity 1 is documented in `docs/FORCES_GARDEN_STORY.md`; its v6 review supersedes the linear v5 activity-1 interface below. Activity 2 retains its guided flow.

The final v5 release web build succeeded in **76.6 seconds** (`tmp/forces-simple-preview-build.log`). The loopback preview server was restarted. The versioned page has the correct base path; its JavaScript, unit-05 JSON and all three artwork sheets return HTTP 200 and match their built/source hashes. The Codex browser-open request was queued; visual verification used Flutter renders, not a completed browser walkthrough.

Review: http://127.0.0.1:8765/review/forces-simple-v5/?preview=biology-v1&lesson=unit_05&step=1

The JavaScript build is successful; existing Flutter TTS WebAssembly dry-run and Cupertino-font warnings do not establish WebAssembly compatibility. No APK, physical-device check, cloud publishing or Git commit/push was performed.

