# Sound unit: complete visual and interaction review

1 October 2026. This pass addresses the request to review the whole Sound unit, including illustrations and use. Child-facing text remains English. Unit 06 retains its twelve activity IDs and objectives. Following feedback, content version 2 replaces the second Maris chart question with the David question from Chart Skills (pages 27–28); all other assessed answers remain unchanged. The original answer-key quotation is retained as provenance, and `chartQuestionSource` documents the adaptation. Predictions and observation practice remain ungraded.

## Delivered behavior

| Activity | Updated experience |
| --- | --- |
| 1 — Music studio | Five transparent instrument illustrations in a warm room. Touch plays the instrument; a separate button narrates how to play it so narration does not cover the effect. Exploration progress is saved. |
| 2 — Sound catcher | A whole face with three separate 48-pixel hand markers and neutral connector lines. No zoom or correct-answer highlight. |
| 3 — Instrument actions | The same instruments with neutral selection and action choices. Assessment pictures do not demonstrate the correct action. |
| 4 — Sound boxes | Predict → Shake → Notice. The feather asset is silent and the choice says No sound. Replay, a visible next-box action, and observation confirmation for a mismatched prediction. Original guesses remain intact. |
| 5 — Mystery sound box | Listen buttons are separate from answer selection. Listening alone cannot submit an answer, and replay after completion cannot change the score. |
| 6 — Sound walk | Prediction before playback, a whole listener in a garden, dragging/slider and equivalent near/far buttons. Both positions must be heard before comparison is complete. |
| 7 — Farther-away question | The same movable scene and replay controls, without answer/result highlighting or assessment writes during playback. |
| 8 — Drum explorers | Four walking tracks retain Annay 20, Zara 14, Maris 23 and David 8. The two discoveries ask who heard furthest (Maris) and how many steps David took (8). |
| 9 — Tapping sticks | Gentle and harder trials use the same sample at different volumes and motion strengths. Answer buttons appear in a separate section. |
| 10 — Quiet to loud | Touch a source picture to hear it, then drag it into any numbered slot. Slots support replacing, moving, removing and reinserting choices, with button alternatives. Sparse slot placements persist; a full four-slot order is required before checking. |
| 11 — Humming | Two short instructions invite the child's own voice. No microphone permission or recording, and no vibration animation that supplies the answer. |
| 12 — Final discoveries | One contextual mission at a time, with five numbered tabs, a next-discovery action and saved individual answers. Each shows only its two or three alternatives from the original question. Completed missions can be revisited without rescoring. |

On narrow screens, navigation/count controls sit above a two-line title. The owl and replay control sit above the full-width instruction, avoiding narrow columns of words with enlarged text. Larger tablet layouts retain the existing horizontal arrangement. The whole listener stays inside the scene at both distance extremes.

Sound playback interrupts narration; narration interrupts the effect. Sound-unit playback uses a 0.5 effects multiplier while respecting saved sound/volume settings. Other units retain their prior multiplier. Demonstrations are finite, replayable and respect reduced-motion settings. Guided correction and navigation preserve the original outcomes and mistake counts.

## Illustrations and generation

Both installed atlases were generated with the **built-in imagegen tool**, with transparent-background output enabled. No CLI/API-key fallback was used. They replace the earlier Sound painter; scene backgrounds remain native drawing. Existing atlases for other units remain in use.

- `E:/seif-science-game/assets/images/sound-atlas-v2.png` — 1448 × 1086 RGBA, 1,662,851 bytes. Instruments, boxes, listener, face, humming child and cat.
- `E:/seif-science-game/assets/images/sound-details-v2.png` — 1536 × 1024 RGBA, 2,440,302 bytes. Closed box, door, thunder, whispering child, stone and feather.

Both files contain actual alpha transparency; the game crops objects directly without white image tiles. The generated rows are not perfectly uniform, so the primary atlas uses measured row boundaries to keep hair/feet intact and exclude neighboring artwork.

### Exact prompt: primary atlas

```text
Use case: scientific-educational. Asset type: one production game sprite atlas for an English science adventure for ages 5-7. Create a cohesive, beautifully polished children's storybook watercolor and gouache illustration sprite sheet on a genuinely TRANSPARENT background. Strict 4 columns by 3 rows of equal square cells, one separate centered cutout per cell, no overlaps, generous 12% clear margin inside each cell, no grid lines, no labels, no numbers, no letters, no backdrop or cast shadows. All objects seen from a clear slight front three-quarter angle. Row 1 left to right: (1) steel musical triangle with small separate striker, (2) golden trumpet with clearly recognizable valves and bell, (3) a pair of colorful wooden maracas, (4) recognizable traditional sitar with long fretted neck and rounded gourd body, not a guitar. Row 2 left to right: (1) warm red wooden cylindrical drum with ivory drumhead and two resting sticks, (2) two wooden tapping sticks crossed gently, (3) closed plain kraft cube box with translucent front inspection window showing one small gray stone inside, (4) identical closed box and window showing one soft ivory feather inside. Row 3 left to right: (1) delightful child listener aged 6, full body, mustard t-shirt blue trousers and sneakers, warm expressive small facial features, brown hair, relaxed standing pose, both hands visible and feet fully included, (2) close-up friendly child head and shoulders front view with both ears, eyes and nose clearly distinguishable, (3) same close-up child with one hand gently touching their throat and lips softly closed to hum, no vibration marks, (4) fluffy ginger cat walking quietly. Make this finished premium educational-game artwork, soft natural textures with crisp enough silhouettes for tablet screens, warm welcoming palette, believable proportions, no flat stick figures, no white image tiles, no implied correct-answer glow. Strict atlas geometry and transparent alpha are essential.
```

### Exact prompt: detail atlas

```text
Use case scientific-educational. Production sprite atlas supplement for a polished storybook science game ages 5-7. One genuinely transparent cutout sheet, strict 3 columns x 2 rows equal square cells, one centered separate illustration per cell, 12% transparent margin all sides, no grid lines no words no letters no numbers no backgrounds no decorative badges or glow. Warm watercolor/gouache children's picture-book style with carefully finished textures and silhouettes. Row1 left to right: plain CLOSED kraft cardboard cube box, warm wooden door partly open with small subtle motion strokes near edge suggesting it has just slammed (no scary person), soft blue-gray thunderstorm cloud with a small warm golden lightning bolt. Row2 left to right: friendly brown-haired child age6 mustard t-shirt, HEAD AND SHOULDERS, front three-quarter face, one palm softly cupped beside closed lips as if whispering (avoid shushing index finger), a single natural gray rounded stone, a single delicate ivory feather. Consistent style across all6 sprites, soft fine detail, clearly recognizable on a small tablet, no white tiles or background shadow. Actual transparent alpha, no text whatsoever.
```

## Audio and verification

`scripts/build_science_audio.py` generates twelve local assets, including cat footsteps, whisper, door and thunder, plus a silent feather-box file. These are synthesized PCM, not recorded instruments or speech. Files are mono 16-bit at 22,050 Hz, with no clipped samples. Measured RMS follows cat footsteps < whisper < door < thunder; the feather file contains only zero samples. The two stick trials share one sample. Android's local sound allowlist includes the four added names.

- Final `dart analyze --fatal-infos`: no issues (`tmp/sound-review-v2-analyze.log`).
- Full `flutter test` for the preceding visual pass: **149 passed**, including 12 Sound tests (`tmp/sound-review-v2-full-tests.log`). This run includes the narrow-screen header fix; the later four feedback changes have separate validation below.
- Content/source validation: **187 activities**. Activity IDs, objectives and assessment flags remain stable. Version 2's David chart variant has explicit source metadata; the other assessed answers are unchanged. The Sound refiner is idempotent.
- Rendered/reviewed all twelve screens in `tmp/sound-scenes/`, with enlarged-text/small-landscape coverage. The phone-face test checks distinct 48-pixel targets, a bounded title and full-width prompt at 360 pixels and 1.5× text.
- Successful local web build and HTTP 200 checks for the page, JavaScript, both generated atlases and audio. The preview server was restarted after the old process had stopped. Local review: `http://127.0.0.1:8765/review/sound-review-v2/?preview=biology-v1&lesson=unit_06&step=1`.

Browser-control automation failed to initialize its Windows sandbox, so real audible browser playback was not verified. Physical-tablet sound, touch and visual acceptance remain pending. This pass does not complete the remaining units, cloud accounts or the final APK.

## Four feedback changes

The new chart variant has separate provenance and content-version migration so an old saved 23-step answer is not assessed as a new David answer. Completed historical results and their original Maris question remain available; unfinished attempts retain their first chart answer and mistake history while clearing only the obsolete second choice.

Sound order uses the existing placements map with keys `0`–`3` to preserve empty positions. Its selected sequence is derived in slot order, contains only valid unique option IDs, and is assessed only when all four slots are filled. Playing a source picture writes no answer. Placement and rearrangement remain separate from checking and guided correction.

The content validator now checks every final discovery has two or three unique valid alternatives including its correct answer. It also verifies that the David question occurs in the Chart Skills source, its pages are included, and the answer matches David's original chart value. `test/sound_audio_test.dart` confirms silent feather PCM and audible stone PCM.
