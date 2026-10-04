# Materials and quizzes: whole-app visual review

Review date: 4 October 2026. This document records the materials/quiz portion of the user's request to review every unit from the beginning and carry the agreed visual and interaction rules across the app. Child-facing instructions remain English.

## Screens reviewed

Reviewed the initial contact sheets and activity images in `tmp/all-units-review`: all 13 Materials activities and all 40 quiz questions. Quiz 1's garden, plant and body renderers belong to the biology review; this pass changes presentation data only for the 30 questions in Quizzes 2–4. It preserves the original question types rather than claiming a new physical simulation for every quiz.

## Materials fixes

- **Activity 2, object versus material:** each named pair now has both pictures. “Spoon and chair” shows a spoon and a chair; “Metal and wood” shows the two material samples. The same pair remains visible while dragging and after placement. `workshop.pairedExamples` is separate presentation data; original option/target IDs and answer mapping stay unchanged.
- **Activities 1 and 13, room exploration:** phone positions no longer extend beyond the scene or overlap neighbouring touch areas. Seven material samples in the opening room and five discoveries in the final room use separate neutral markers. These markers identify where to touch, without identifying the right answer.
- **Sorting drawers:** the touch cue appears only while an object is selected or being dragged over a drawer. Empty, inactive drawers no longer invite an action that cannot do anything. Drag and touch-to-place remain equivalent.
- **Activity 5, glass claims:** the context shows a complete window, consistently with Activity 10. It has no labels, selected answer, zoom or result marker. Activity 11 keeps the complete plain wooden writing pencil and visible writing core, without an unrelated eraser or metal ring.
- **Water and shape laboratories:** retain their sample-focused, code-drawn demonstrations. A cloth or plastic sample is not represented by an unrelated shirt or bottle in the water trial. Outcomes appear after prediction/testing; the original prediction is retained and any mismatch requires the existing observation step. Shape tests continue to offer only source-supported actions for each material.

The shared artwork pass replaces the old opaque Materials and Science Details atlas samples with transparent storybook cutouts. The room, object pairs, material samples, sorting tasks and quiz choices share the same artwork through `SciencePicture`. Asset installation and final visual renders are verified by the coordinating pass; this document does not claim that merely generating an atlas completes that verification.

## Quiz context and neutrality

All 30 questions in Quizzes 2–4 now have a question setting in `quizContext`: workshop, rain, water, sound, electricity, Earth or space. The context provides a whole object or a place to think about, without performing the answer or submitting a choice.

An explicit `art: null` suppresses a legacy focus where one sample would supply a required choice or a visual counterexample. This applies to the materials collection, stretching choice, all-glass-is-red claim, kitchen collection and floating-object collection. In particular, Quiz 2 question 9 must not show its old clear-window focus. The magnet claim uses a neutral magnet instead of its old sample of foil. Existing option pictures remain available for the child to choose.

Quiz 3 retains ten assessed questions with their original answers and weighting. Adding context does not make replay/audio count as an answer, introduce automatic corrections or turn the assessment into an ungraded experiment. No claim is made that the still-choice-based question types have all been converted to exploratory games.

## Implementation and checks

- UI: `lib/features/science/material_workshop.dart`.
- Reproducible data: `scripts/refine_science_review.py`; generated `unit_04.json`, `quiz_02.json`, `quiz_03.json` and `quiz_04.json`.
- Material regression coverage: `test/material_missions_test.dart` adds pair-picture and nonoverlapping 360×740 room bounds checks at 1.5× text. Existing tests cover dragging, correction, resumed predictions and ungraded shape/water trials.
- Quiz regression coverage: `test/quiz_presentation_test.dart` covers all 30 contexts opening at phone width without invoking selection/placement callbacks, plus suppression of the legacy glass-claim focus and an explicit child selection.
- Protected comparison uses the captured pre-review books in `tmp/all-units-review/before`. It compares each book's content version/source hash and every activity's ID, kind, full options, full targets, answer, assessment/objective/source fields and laboratory rules. Presentation metadata is kept outside those protected structures.

Python comparison completed successfully for **43 activities** (13 Materials activities and 30 quiz questions), including source references and laboratory rules. Each of the four book refiners is idempotent. The machine-readable result is `tmp/materials-quizzes-protected-check.json` and the check is reproducible with `tmp/check_materials_quizzes_audit.py`.

The coordinating agent runs Flutter tests, analyzer, final renders and the rebuilt local web preview after shared artwork/renderer changes are integrated. Results from this subtask alone must not be presented as a completed full-suite run or physical-tablet acceptance.
