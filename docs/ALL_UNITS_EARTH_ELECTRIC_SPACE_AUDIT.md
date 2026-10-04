# Electricity, Earth and space: visual and interaction review

Review date: 4 October 2026. This pass follows the user's request to review all units from their opening screens and apply the agreed clear, exploratory presentation throughout. Child-facing copy remains English.

## Initial review

Reviewed every activity in the contact sheets and individual renders in `tmp/all-units-review`: **11 Electricity activities, 13 Earth activities and 12 Space activities**. The initial screens mostly placed all picture cards or all mapping clues on one coloured panel. Later mapping tasks had five or six questions and all their answers visible simultaneously; the Moon mission record mixed names and years in the same crowded panel. The opening water and space explorations showed a row of cards rather than a place/model the child could explore. Room collections, rock/soil questions and safety promises also shared a generic card grid.

The source-backed laboratories are retained separately: magnet predictions, soil inspection, open-ended rock grouping, beach cleanup, day/night, planet painting and star drawing. The coordinating pass owns their visual improvements and checks; this renderer does not alter their saved-state rules or turn them into assessed questions.

## New presentation

`lib/features/science/science_world_stage.dart` supplies three calm story settings: an empty warm room, a meadow/coastal landscape, and a sparse space scene. Shared transparent storybook cutouts supply the objects, water places, animals, Earth/Sun/Moon and suit parts. The scenes use whole objects and neutral hand markers; they do not zoom onto an answer, animate the correct choice or consult answer values.

- **Electricity:** explore the three safety rules one at a time. The room collection places its seven objects in a shared environment. Then-and-now, magnet claims, safety promises, power sorting and final discoveries show one current helper/clue, followed by all of its original alternatives. A target can be touched directly or accept a dragged current object. The room backdrop intentionally contains no appliance, socket or clear window that would supply an answer.
- **Earth:** opening exploration visits one complete water place at a time, preserving all five original visits. Water clues, animal homes and final discoveries present one current question with every original target. Rock and soil collections show whole cutouts within the landscape; the child's selection is editable and never moves an object to the correct group automatically. The book's water-family ordering keeps the original tap-to-order state and displays the child's own numbered path; tapping an item/path entry removes it so it can be placed again.
- **Space:** opening exploration visits one complete Earth, Moon or Sun model at a time, preserving all three required visits. Earth claims, the Moon mission record, suit jobs and final discoveries show one current question. The mission record retains all six original alternatives for both questions; no correct-name/year filtering occurs. Suit tasks retain the entire original alternative set. Single/multiple choice tasks use whole context objects and editable choice markers without correctness colours.
- **Quizzes 2–4:** use their explicit `quizContext` setting/art. An explicit `art: null` suppresses old focus metadata, including Quiz 2's clear-window image in the glass-colour claim. Opening or narrating a context never calls the answer callbacks.

## Navigation, saves and accessibility

Opening discoveries resume at the first unseen original option; mapping activities resume at the first unplaced option, or an explicitly marked review item. Previous/next controls revisit earlier choices without submitting, clearing or correcting them. Mapping's next control requires a saved choice for the current question. Discovery travel and Listen buttons do not count as touches, so all original completion requirements still apply. Already visited discoveries can replay speech without adding new evidence.

The renderer keeps `science-item-{id}` and `science-target-{id}` keys. Mapping shows only the current item key, with all target keys. Choices read only the learner's `selected`/`placements`; target options are never filtered using the answer key. Saved choices receive a neutral teal selection marker, not a correctness marker. Parent grading, guided correction, original mistake counts and completed evidence stay in the existing lesson engine.

Phone targets use full-width wrapping with a minimum 48-pixel width and 64-pixel height. Tablet targets wrap at 230 pixels. Picture/word collections use flexible heights rather than clipping enlarged text inside fixed-height cards. Scenes retain their complete model at phone width; the whole player can scroll on smaller screens. Back/navigation/listen buttons have at least 48-pixel touch areas.

## Verification handoff

`test/science_world_stage_test.dart` adds coverage for:

1. One current mapping question, every original alternative, arbitrary wrong choices retained, explicit next/back and editing.
2. First-missing/review resume with no automatic selection or placement.
3. All five water visits, with speech/navigation excluded from progress and replay excluded from duplicate evidence.
4. Collections and ordering reflecting only the child's actions.
5. Explicit-null quiz context suppressing the old focus.
6. Every non-laboratory screen in Units 7–9 and Quizzes 2–4 at 360×740 and 1280×860 with 1.5× text, checking separate targets, bounds and minimum sizes.

The coordinating pass must run the tests/analyzer, inspect final rendered scenes with installed transparent assets, and rebuild/serve the local preview. These tests have not been run independently in this subtask to avoid concurrent Flutter processes. Physical-tablet and audible-device acceptance are not claimed.

## Artwork boundary

Image generation for a bespoke room/nature/space background returned a usage-limit error. No generated `science-worlds-v2.png` was installed or referenced. All three backdrops are fully implemented in code with soft colour washes, floor/shore/moonscape detail and clear central space; they have no spinner or unavailable-image dependency. A later bespoke backdrop can replace this layer without changing any activity, answer or progress data. The generated transparent object atlases belong to the shared artwork pass and are independent of this background limit.
