# Teacher review follow-up — 30 September 2026

Source: user-supplied `E:/Science-Adventure-Review.pdf` (seven pages).
This is a first implementation pass, not closure of every proposal in that report.

## Implemented

- Child-facing screens use English. Removed garden Arabic subtitles and bilingual onboarding/subject/child-selection labels. Parent screens and parent-only confirmations retain Arabic. The user's explicit English-only decision supersedes the report's Arabic-support proposal.
- Lesson feedback, replay-audio and check/continue controls sit outside the activity scroll area. Long explanations can scroll inside the bounded feedback panel; they do not push activity cards down.
- Plant food cards reserve their assigned-state space and use smaller pictures; food baskets reserve their contents area. Science cards reserve mapping labels and no longer grow with discovery descriptions. Descriptions are delivered in the fixed feedback area.
- New specific hints replace repeated Plants/Ourselves hints. Incomplete mapping feedback names the items to revisit; multi-choice feedback reports how many correct discoveries are present without awarding partial objective scores.
- Equivalent `rock`/`rocks` answers are accepted, including old saved selections. Marble badges now say Most/Fewest marbles. Water ordering explicitly refers to the book's example. Quiz 2 stretching/metal questions gain a third distractor while retaining the same correct answer and source objective.
- Materials exploration explains object versus material using the spoon/metal and chair/wood examples. The misleading spoon image for the materials label is replaced with a wood sample.
- Material Workshop introduces a room, touchable objects and material drawers. Water trials show actual material covers and an umbrella with source-defined water outcomes after a saved prediction. The unit still has 13 activities; it is not a completed redesign of every assessment mechanic.
- Safety notices use a calm colour, discovered plant parts show a check, and the non-living basket uses a general shapes symbol instead of a toy/car symbol.
- Parent reports show available in-progress objective evidence and allow opening a unit for practice without changing progression locks or fabricating completed scores. The parent gate uses a variable multiplication question instead of the fixed answer 56.

## Still open

- Guided physical correction outside Materials, Forces and Sound. Those three units require the learner to correct the answer after the second unsuccessful attempt; see the follow-ups below.
- Persistent per-item correction markers across all scene renderers, beyond the new named feedback.
- A full distractor review, shorter text in every activity, and eliminating scrolling from every scene (the fixed action/feedback area does not make every scene fit in one viewport).
- Review session length in the three active garden adventures (the legacy 46-step lesson is not the normal route), scheduled/spaced daily review, and a finished parent dashboard with targeted home activities for each objective. Existing reports already show book home activities.
- Skills, certificate/export, remaining unit redesigns, cloud account/sync, and physical-tablet testing.

## Validation

- Full suite: 115 passed, log `tmp/teacher-final-tests.log`.
- `dart analyze --fatal-infos`: no issues.
- `scripts/validate_playable.py`: 187 activities, source-objective coverage and answer references pass.
- Visual review of Materials exploration, sorting and water-trial renders. Tests cover enlarged text and small landscape, including the fridge interaction regression found and repaired during this work.
- No APK/device acceptance or deployed cloud service is claimed.

## Materials guided correction follow-up

- All assessed Materials activities now show a neutral question marker on incorrect submitted choices. Missing correct choices in a multi-select question are not identified before explanation. Editing a choice clears its marker until the next check, so moving between choices cannot reveal the answer without submitting.
- The second unsuccessful submission records the original `explained` outcome and opens practice. It does not replace the child's choices with the answer. Continue is unavailable until the learner applies the correct mapping/selection.
- Practice checks do not resubmit to the assessment engine, add mistakes or improve the original score. Correct answers after only one hint still receive the existing `afterHint` outcome.
- Practice status and markers survive restart and previous/next navigation. Legacy explained answers are not retroactively reopened for practice.
- Full suite: 122 passed (`tmp/correction-full-tests.log`). After feedback/font refinements, 11 focused correction, layout and plant tests passed (`tmp/correction-focused-tests.log`). Analyzer clean. Visually reviewed `tmp/material-correction.png`.
- This rollout is limited to unit 04. Other units, shorter unit-01 sessions and daily spaced review remain separate work.


### Water prediction follow-up — 30 September 2026
Materials activities 6 and 12 now require a saved observation check only when a tested result differs from the original prediction. A pending-material button returns the child to that result. Choosing the wrong observation gives a clue without a score or mistake; choosing the observed result unlocks continuation once all materials have been tested and all mismatches reviewed. Original guesses remain intact. Restarting or navigating back retains the pending review and confirmations. Previously completed historical activities remain completed.

Validation: 17 focused tests passed across `material_correction_test.dart` and `science_islands_test.dart`, including foil-only mismatch, umbrella mismatch, matching predictions, restart/navigation, and ungraded responses. `dart analyze --fatal-infos` is clean; content validation passes for 187 activities. Screenshot `tmp/foil-observation.png` inspected. This does not constitute physical-tablet validation.


### Materials activities 7–13 — interactive missions
- 7: a rain kit accepts material samples by touch or drag. Packed samples can be removed; original grading and guided correction remain in use. Plastic/fabric samples replace bottle/shirt illustrations.
- 8: a saved prediction precedes each supported shape action. Dough twists/squashes, the band stretches, the sponge squashes and the straw bends; spoon/stone squash trials keep their shape. Completion requires all four action types and comparison of a changing and unchanged object. Original guesses are retained and ungraded. Source examples and movement types are in JSON, not hard-coded assessment keys.
- 9: touch/drag objects into two squash trays, retaining editable placements and existing grading.
- 10: a full window scene supplies context for the explanation question; options retain identical neutral styling before a choice.
- 11: a plain wooden pencil and its graphite core are visible alongside actual material samples, replacing the misleading chair/shirt option art. No eraser or metal ring is pictured for this two-material adaptation.
- 12: after the paper/plastic trials and any mismatched-prediction review, choose the dry cover for the umbrella. The final choice is ungraded and saved; the displayed umbrella switches to the chosen cover.
- 13: five workshop discoveries share a room with touch cues and text-only discovery choices. The stretching task uses an action symbol instead of picturing the answer.

Stable activity IDs, answer IDs and source-objective references preserve progress and assessment history; completed historical activities stay completed. Unit 04 retains 13 activities. Other units and cloud/device work remain outside this phase. Existing Materials 1–6 are retained and covered by the assessment/layout suite.

Validation for this pass: all 129 tests passed (`tmp/material-missions-full-tests.log`). After shortening the progress display, the 4 mission interaction/render tests passed again (`tmp/material-missions-visual-final.log`). Analyzer clean; all 187 activities pass content validation. Reviewed renders of activities 7–13 in `tmp/material-missions/`; automated coverage includes 800×360 at 1.5× text, drag/touch, correction, restart and ungraded trials. Web preview built locally. Physical-tablet acceptance is still pending.


### Direct preview return navigation
Fixed review links opening a lesson directly above the real home/child chooser. The review now owns a nested map → island → lesson route stack under one temporary progress store. Completion and the home button return to the matching island; its back button returns to the science map. The same preview child and completed attempt remain available when reopening lessons. Preview maps explicitly allow review access without fabricating prerequisite completions or weakening real progression locks.

Validation: 14 focused tests passed (`tmp/preview-navigation-tests.log`), covering completion/home return, correct island, same child, re-entry, unchanged real save/locks, and existing plant/light/subject navigation. Analyzer clean. Preview data remains temporary and is not claimed to survive a browser reload.


### Forces and movement — unit 05
- Exploration uses a shared movement scene with neutral touch cues and replayable motion demonstrations. Assessments keep movement answers hidden until submitted; the direction task shows the requested direction rather than reading the answer key.
- The trolley can be dragged towards/away from a fixed person, with equivalent accessible push/pull buttons. A second tab within the same activity compares a gentle and bigger push on the same ball. Each trial animates from the same start, preserves the original prediction, and stores visited movements/trials separately from grades.
- Float/sink choices are pictured and tappable. Mismatched results require observation confirmation before continuation. The tank assessment accepts touch or drag placements in surface/bottom zones without auto-correcting placements.
- Animal, household and final discovery tasks share contextual scenes and named touch cues. Switch/zip illustrations replace abstract toggle/arrows. The final sinking-object prompt does not picture its answer.
- A sailboat prediction must be saved before tapping/holding wind can move the boat. Guesses remain ungraded.
- All assessed Forces tasks now use guided correction: the learner changes choices after explanation, while the original outcome and mistake count remain unchanged during practice.
- All 13 activities, answer IDs and objective/source references are retained. Mapping answer types remain for save compatibility, rendered as scene selections and tank placement rather than connection lines. This is not a claim that every activity is a physical simulation. Units 6–9 remain separate redesign work.

Validation: full suite 135 passed (`tmp/forces-full-tests.log`), analyzer clean, content validation passes 187 activities. New tests cover trolley drag, prediction persistence, tank correction/navigation, disabled sailboat movement before prediction, and larger-text touch access. Reviewed renders for all 13 screens (`tmp/forces-scenes/`). Local web build only; physical-tablet testing remains pending.

### Forces motion and transparent artwork — 1 October 2026
Replaced the Forces raster tiles with twenty original code-drawn cutouts (`force_picture.dart`), plus the existing switch/zip drawings. These have no rectangular background. The Forces scene, tank objects, boat and track share this artwork; other units retain their existing atlases. Bird wings, fish fins/tail, snake body and crawling limbs articulate independently. Kangaroo motion has three short hops; balls and trolley wheels rotate with travel. Only the most recently touched object replays. Demonstrations finish, remain replayable, respect reduced motion, and never consult assessment answers. Grading, content IDs and saved progress are unchanged.

Image-generation was attempted for transparent watercolor sprites but returned a usage-limit error; no generated asset was produced or installed. The delivered artwork is code-native illustration. Reviewed screenshots of all thirteen screens, all cutouts and a mid-flight pose in `tmp/forces-scenes/`. Six focused tests and all 137 full-suite tests passed (`tmp/forces-motion-full-tests.log`); analyzer clean. Web preview built successfully. Physical-tablet visual acceptance remains pending.

### Forces illustration detail — 1 October 2026
After visual feedback, replaced the five simple creature silhouettes with detailed original articulated illustrations in `force_creature.dart`: shaded bodies, individual bird feathers, fish scales/fin rays, tapered patterned snake, kangaroo muzzle/ears/fur/toes, and toddler facial features, hands and patterned romper. Object silhouettes now use soft material shading, finer edges, drawer wood grain and a trolley rim. Movement scene illustrations are slightly larger. Transparent backgrounds, replay, reduced-motion handling, touch keys and assessment behavior are preserved.

Built-in image generation was tried again but still returned usage_limit_reached; no generated image was installed. This pass edits native illustrations, without raster background filtering. Analyzer clean and all six Forces interaction/render tests passed (`tmp/forces-art-tests.log`), including small landscape at enlarged text. Reviewed first screen, mid-flight pose and the full contact sheet in `tmp/forces-scenes/`. The 137-test full-suite result belongs to the preceding motion pass; the full suite was not repeated for this illustration-only pass. Tablet and user visual acceptance remain pending.

Update, 3 October 2026: built-in image generation succeeded. Three transparent storybook sheets now replace all 22 Forces object/animal types and the child reference, matching Sound's style. Activity 1 separates forces from other movement within the same activity; the eight required touches and all 13 activity IDs/answers remain intact. Assessed direction artwork keeps the child neutral. See `docs/FORCES_ART_REDESIGN.md` for generation prompts, saved files and current validation. This supersedes the native-art implementation described above; user/device visual acceptance remains pending.

### Sound scenes — 1 October 2026
Unit 06 retains twelve stable activity IDs and all original source objectives/answers. The band uses transparent instrument illustrations and replayable exploratory playing poses; the assessment does not demonstrate the action. Hearing uses a whole face with three neutral, non-overlapping touch markers. Box trials save predictions before shaking, support direct scene touch/replay, and require an ungraded observation check for mismatches. The sound walk saves a prediction first, then compares the same drum near/far; moving alone cannot complete it. Dragging and the slider save position after release, and either touching the drum or its alternative button plays it. Text reports the tested result for muted use. Original predictions remain unchanged and ungraded.

Walking tracks preserve Annay 20, Zara 14, Maris 23 and David 8; question-specific name/number choices show the child's placed answers. Sticks compare one original local PCM sound at two volumes before choosing an assessed answer. Sound order has editable numbered slots; humming asks the child to try their own voice without recording it. Five final discoveries use context without duplicating the correct stone/trumpet as the only prompt image. Guided correction now includes all assessed Sound tasks, retaining scores and mistakes through restart/navigation. Historical completed responses remain completed.

Validation: all 143 tests passed (`tmp/sound-full-tests.log`). After adding visible chart placements, the six Sound tests passed again (`tmp/sound-final-focused.log`), analyzer is clean, and all 187 activities pass source/schema checks. Reviewed all twelve rendered screens in `tmp/sound-scenes/`, including enlarged-text/small-landscape touch reachability. The Sound refiner is idempotent. `sticks.wav` is valid original mono PCM and is accepted by the Android sound channel; browser assets remain local. Audio is illustrative synthesis, not recorded instruments. This is browser/widget validation; physical-tablet acceptance remains pending. Forces art is still flagged for a later visual pass following the user's feedback. Units 07–09 and Quiz 3 interaction redesign remain open.

### Sound activity 7 playback — 1 October 2026
Fixed a missing interaction: the farther-away question had a static drum with no playback hook. It now reuses the movable listener scene with drum touch/replay button and an accessible slider. Playback follows listener distance, has no answer/result highlighting and does not write assessment state. Replaying after answering preserves the outcome and mistake count. Experimental playback stops current narration. Eighteen focused Sound/narration/science tests passed (`tmp/sound-replay-focused.log`); analyzer and 187-activity validation clean. Reviewed screen 7 and enlarged-text reachability; web build succeeds and the drum WAV serves with HTTP 200. Browser automation was unavailable due to a local sandbox initialization error, so real audible playback and physical-tablet acceptance were not confirmed.

### Drum audibility and listener refinement — 1 October 2026
User reported a very faint drum and disliked the listener illustration. Replaced only drum.wav with two original beats, upper harmonics and a fast attack; peak 0.8, RMS 0.1424, no clipped samples (previous peak 0.2, RMS 0.0445). Drum-only playback multiplier is now 0.5 instead of 0.35; distance attenuation ends at 0.35 rather than 0.15 in activities 6 and 7. Both trials still use exactly the same sample and honor saved sound/volume settings. Other instrument files/levels stay unchanged. Replaced the stick-limb listener with an original shaded child illustration including clothing, hands, hair, expression and shoes. Responsive sizing/travel prevents cropping at either scene edge on phone/tablet widths. Eighteen focused Sound/science tests passed (tmp/drum-character-final-tests.log); analyzer clean. Reviewed updated screen 7. File measurements do not confirm audible quality on the user's device; listening/visual acceptance remain pending.

### Whole Sound unit: illustrations and use — 1 October 2026
Replaced the Sound painter with two original transparent atlases generated through built-in imagegen. All twelve screens were reviewed. The band separates instrument audio from action narration; listening does not select or grade an answer in the mystery-box and ordering questions. Boxes show Predict → Shake → Notice and an explicit next-box action. Distance trials provide near/far buttons and retain the original guesses. Walking tracks keep the book's original data; stick trials separate playback from the answer. Sound ordering supports moving/removing/reinserting choices, with persistence and guided correction. The final activity presents one contextual discovery at a time and allows completed review without rescoring. Face markers are neutral, distinct and 48 pixels; the whole listener remains within scene bounds. Narrow-screen titles and instructions now use full-width layouts instead of wrapping into cramped columns with enlarged text.

All original activity/answer IDs, source/objective references and assessment flags remain stable. The refiner is idempotent. Twelve local original synthesized PCM sounds include footsteps, whisper, door and thunder; file checks confirm format, no clipping and the intended RMS ordering. These are illustrative effects, not instrument recordings. Sound effects interrupt narration and vice versa, respect saved settings and use multiplier 0.5 in unit 06.

Final validation after the phone-layout fix: analyzer clean; **149 full-suite tests passed**, including **12 Sound tests** (`tmp/sound-review-v2-analyze.log`, `tmp/sound-review-v2-full-tests.log`). Content validation passes all 187 activities. Reviewed all twelve rendered screens plus enlarged-text reachability. Local web build succeeds, and the page/JavaScript/new atlases/audio serve with HTTP 200 after restarting the stopped preview server. Browser-control automation could not initialize its local sandbox; audible playback and physical-tablet acceptance remain unverified. Exact asset paths, prompts and detailed behavior are recorded in [Sound unit redesign](SOUND_UNIT_REDESIGN.md). Units 07–09, Quiz 3, deferred Forces artwork and the other product milestones remain open.

### Sound: four feedback corrections — 3 October 2026

- The feather-box file now contains silent PCM, and the laboratory's choice says No sound. The stone remains audible; an audio test checks both files rather than relying on labels.
- Activity 8's second question now asks how many steps David took: 8. Content version 2 records the Chart Skills source on pages 27–28 in `chartQuestionSource`, retaining the original answer-key quotation as provenance. `legacySoundChart` preserves the question and result for completed historical Maris attempts. For unfinished old attempts, migration clears only the obsolete second chart choice and keeps the first answer and mistakes.
- Activity 10 separates listening from placement: tapping a source plays it without changing the answer; dragging places it into any of four numbered slots. Sparse placements, swaps, removal and accessible Place buttons persist. Checking requires a full order; editing and replay do not rescore completed work.
- Activity 12 presents each discovery's original two or three alternatives, including the exact choices for questions 2 and 3. The validator checks unique valid alternatives and the chart adaptation against its stated source.

The twelve activity IDs, objectives and assessment flags remain stable. The changed David answer belongs to an explicit source-backed version, rather than silently reinterpreting stored Maris answers. Child-facing text remains English.

Final validation: **22 focused tests passed** (13 scene, 8 progress and 1 audio). The generic science integration test was updated from tap-to-order to placement and its targeted run passed (`tmp/sound-feedback-assessed-tests.log`). Analyzer is clean (`tmp/sound-feedback-analyze.log`); **all 159 full-suite tests passed in 62 seconds** (`tmp/sound-feedback-full-tests.log`), and **187 activities pass content validation** (`tmp/sound-feedback-content.log`). The preceding 149-test result remains historical.

The final local web build succeeded in **54.6 seconds** (`tmp/sound-feedback-preview.log`). After the server restart, the page, main JavaScript, unit-06 JSON and feather WAV returned HTTP 200; the served feather SHA-256 and built unit-06 JSON hash match their source files. Current review: `http://127.0.0.1:8765/review/sound-feedback-v3/?preview=biology-v1&lesson=unit_06&step=4`. Audible browser playback and physical-tablet acceptance remain unverified. No APK, deployment or commit is claimed.
