# Forces movement garden story — 3 October 2026

## Request and scope

The user accepted the simpler first two Forces activities, then proposed a garden story like the existing Alive or not Alive garden so the child discovers movements within a place. The new garden stays inside activity `unit_05.step.001`; it does not add slides or replace activity 2's guided experiment. This supersedes only activity 1's linear one-picture presentation from `FORCES_ART_REDESIGN.md` v5.

The child can freely revisit three story places:

- **Gate:** “Our garden visit begins at the gate. Try a push and a pull.” The two targets are push and pull with the existing boy/trolley artwork.
- **Lawn:** “Our friends are playing on the lawn. Tap them to watch.” The three targets are the rolling ball, hopping kangaroo and crawling baby.
- **Pond:** “Who is moving by the pond? Tap a friend to find out.” The three targets are the swimming fish, slithering snake and flying bird.

A place has only two or three interaction targets to avoid the previous crowded presentation. Existing polished Forces object/character cutouts are integrated into one cohesive storybook background. The child touches a visible hand to replay the corresponding movement; ordinary neutral hand cues do not preselect a correct answer, highlight an answer in advance or create a score. Targets must be at least 48 logical pixels, reachable and non-overlapping at phone/tablet widths and enlarged text. Listening alone must not count as a discovery.

The story places are freely navigable, while completion still requires all eight original discovery IDs. Existing progress remains usable; revisiting and replaying do not clear visited discoveries. Child instructions are English and bundled assets work offline. No login, cloud publishing, APK or physical-device testing is part of this presentation change.

## Source preservation and content validation

The title is `The movement garden` and the prompt is `Explore the garden. Tap a hand to see what moves.` New `forceScene` display fields are generated reproducibly by `scripts/refine_forces.py`: `gardenProgress`, `gardenSpots`, `gardenStories`, `gardenPush` and `gardenPull`. Movement descriptions and animation IDs are unchanged.

Content checks completed with the bundled Python runtime and existing local validation dependencies:

- All **187** playable activities pass schema, source/objective coverage, IDs, answer references and prediction exclusion checks.
- Comparison against `tmp/forces-before-v6.json` confirms all **13** Forces activities preserve IDs, kinds, option/target sets, answers, assessment flags, objectives, source keys and minimum touches. The content version remains unchanged.
- The other **12** Forces activities are exactly unchanged. Activity 1 still requires all **eight** original discoveries; descriptions and motion identifiers are unchanged.
- Running the refiner again produces the same actual file bytes (including Windows line endings).

## Original background generation

The built-in image generation tool successfully created the original opaque background using the local garden and Forces sheets as style references. The project asset is **`E:/seif-science-game/assets/images/forces-garden-v6.png`**, **2172 x 724**, **3,021,659 bytes**. The original remains at `C:/Users/hossa/.codex/generated_images/01a0def0-70b9-7420-9429-9c1395336189/exec-99f76963-6e00-4f72-92d4-38752d435c17.png`; the asset was copied without image editing or alpha manipulation. No CLI/API fallback was used.

It is a background only: the existing Forces cutouts and neutral interaction cues are layered by Flutter. Camera crops preserve the painting's aspect ratio; a wide viewport reveals more surroundings while a phone visits its selected habitat. This is a place view, with no auto-zoom to a selected answer. The gate retains a fixed illustrated child while one trolley demonstrates either push or pull. Its two action buttons are inside the scene so the first action is visible at phone size. Only the last touched subject animates, and its tap area stays fixed. Responsive travel margins keep the animated bird/fish within the scene; reduced motion retains neutral poses. Markers sit close to each subject. The fish is placed in the water and the kangaroo on the lawn.

Garden navigation clears the previous explanation, displays the current story once and narrates that instruction. Listening to a story does not count a touch; listening to a chosen subject replays its explanation. Saved progress determines the first place with an unseen movement; a gate restored after push uses pull as its first replay action. All eight discoveries remain required.

Exact saved generation prompt from `tmp/forces-garden/prompt.txt`:

```text
Use case: illustration-story
Asset type: original opaque panoramic background painting for a children's touch-and-movement garden game.
Input image 1 (garden-v2.png) is a STYLE/MOOD REFERENCE ONLY: warm, beautiful children's storybook garden. Input image 2 (forces-objects-v4.png) is a MATERIAL/BRUSH STYLE REFERENCE ONLY: polished gouache/watercolor texture and soft warm shading. Do not reproduce any of the reference subjects.
Create a very wide 3:1 panoramic garden, arranged as THREE equal-width square habitat regions beside one another, seamlessly joined by the same garden path and distant fence, with matching daylight, viewpoint and horizon. Do not draw any borders or frames separating them.
LEFT THIRD: a small wooden garden gate and low flowering bushes in the UPPER background; generous empty flat golden garden path over the LOWER TWO THIRDS for a boy and a moving toy trolley to be layered by the game. Gate remains background scale.
MIDDLE THIRD: an open safe grassy lawn with a softly curving pale path near the lower edge; low flowers only around the perimeter. The whole central lawn is empty and unobstructed for three moving foreground sprites. Calm sky above.
RIGHT THIRD: a quiet garden pond seen from a slightly elevated side view, blue still water in the LOWER RIGHT HALF, with clear empty water for one swimming fish sprite; a sturdy leafy tree on the LEFT EDGE and its branch framing an open sky area at TOP RIGHT for a flying bird; an empty dry bank in LOWER LEFT for a snake sprite. The pond and dry bank must be distinct.
Composition: all three regions are intended to be shown one at a time at phone size. Large calm shapes, clear depth, beautiful textured foliage at edges only, lots of negative space and modest background detail. The middle and right habitat foregrounds occupy 60% of height. Straight-on readable storybook scenery, cohesive palette of sage greens, warm ochre paths and soft turquoise water. Soft sunny light, fine hand-painted texture.
Strict constraints: BACKGROUND ONLY. No people, babies, kangaroos, snakes, birds, fish, cats or other animals. No trolley, car, ball, toys, swing or interactive objects. No text, letters, numbers, labels, arrows, icons, touch markers, UI, watermark, checkerboard, white image tiles or blank white panels. No dramatic perspective or busy flowers in the empty sprite spaces. The artwork is opaque edge-to-edge.
```

## Application verification and local preview

- Initial integrated Forces/science check: **22 tests passed in 19 seconds** (`tmp/forces-garden-focused-tests.log`). After final habitat placement, nearby cues and responsive travel changes, all **12 Forces tests passed in 8 seconds** (`tmp/forces-garden-final-focused.log`).
- These checks cover free exploration, eight discoveries across restart, no credit from navigation/listening, current story shown once, clearing old feedback, stable non-overlapping touch targets of at least 48 logical pixels, animation replay/bounds/reduced motion, assessed-scene neutrality, guided lab and all 13 Forces screens. The first action stays visible without scrolling at 360 x 740 with 1.5x text; controls remain reachable in compact landscape.
- Visually inspected the original background and the final gate/lawn/pond compositions on phone and tablet. Render outputs are in `tmp/forces-scenes/`, including `garden-{gate,lawn,pond}-{360,1280}.png`.

- Full application suite: **177 tests passed in 99 seconds** (`tmp/forces-garden-full-tests.log`). After the review caught stale narration on reopening the garden, the shared resume-place resolver clears that old feedback and narrates the new habitat story. All **22 affected Forces/science regression tests then passed in 63 seconds** (`tmp/forces-garden-final-regression.log`), including resumed story/feedback assertions. The full-suite count belongs to the integrated garden before this final narrow restoration fix.
- Final `dart analyze --fatal-infos`: **no issues** (`tmp/forces-garden-analyze.log`). Final source/pubspec/content/background hashes in the preview checkout match the workspace. Content validation remains clean for all **187** activities, with protected fields preserved.
- The final JavaScript release web preview built successfully in **102.3 seconds** (`tmp/forces-garden-final-preview-build.log`). Existing Flutter TTS WebAssembly dry-run and Cupertino-font warnings remain; no WebAssembly compatibility is claimed.
- The loopback server was restarted. The versioned page, JavaScript, unit-05 content, the three original Forces sheets and the garden background return HTTP 200. Served script/content/image hashes match their built/source files. The Codex browser-open request was queued; visual QA used Flutter renders rather than a completed browser interaction walkthrough.

Review: http://127.0.0.1:8765/review/forces-garden-v6/?preview=biology-v1&lesson=unit_05&step=1

Physical-device/user visual acceptance and audible browser playback remain pending. No APK, cloud publishing, account/database changes or Git commit/push was performed.
