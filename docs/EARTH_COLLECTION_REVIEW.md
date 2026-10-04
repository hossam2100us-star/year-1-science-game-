# Planet Earth collections — 4 October 2026

The three ungraded collections in Unit 8 now use complete outdoor scenes and one clear interaction, replacing the wall of white object cards. The static child interface is English.

- **Soil microscope (slide 6):** Three freely selectable locations show the original five specimens: small stones and dead leaf; tiny insect and sand; worm under the soil. Tap a neutral hand or drag the magnifier onto a specimen. Pictures stay the same size after discovery. Changing locations does not register a discovery; every original specimen must be visited before the activity is complete. Reopening starts at the first location that still has something undiscovered.
- **My rock museum (slide 11):** One specimen at a time with two bins, previous/next controls, and reopening at the first unassigned rock. The child can name both groups according to their own rule. Display names are separate from the original group IDs and saved `data[rockId]` assignments. Either group is valid. Tap a bin or drag the current specimen into it; already sorted rocks can be moved again. The four original specimens now have distinct deterministic silhouettes, relative sizes, colours, and textures: large smooth grey; dark rough; small rough brown; light cream. There is no correct-group indicator or assessment key.
- **Clean the beach (slide 12):** The original bag, paper, and bottle sit in one beach scene. Tap each item or drag it into the basket. Collected litter disappears and stays collected after reopening. All three original IDs are required; the basket count reports the child's collection.

The scenes reuse `ScienceWorldBackdrop(row: 1)` and its calm Earth setting. No missing asset is referenced. The rock silhouettes are painted in code because the additional Earth detail atlas could not be generated during this review. The plastic bag also uses a translucent painted silhouette, replacing the old sprite's visible white square. Bespoke illustrations can replace these later without changing grouping semantics or progress.

`ScienceLab` delegates only its collection method to `EarthCollection`. The new component keeps the existing `visited` array, original specimen IDs, group IDs, completion callback, speech, and feedback callbacks. Failed saves show a retry instruction and do not advance or hide the specimen. Group naming has its own dialog lifecycle and does not change visits or assignments.

The content, scientific answers, sources, assessed flags, lesson IDs, activity IDs, and content versions are unchanged. These activities remain ungraded. Older visited arrays and group assignments still work; no progress reset or migration is required.

## Verification handoff

The component and tests are formatted. `test/earth_collection_test.dart` covers:

1. All five soil discoveries, free location navigation, magnifier drag, first-undiscovered reopening, replay without duplicate visits, and ungraded completion.
2. Beach tap/drag collection and persistent disappearance; separate phone hitboxes of at least 48 pixels at enlarged text.
3. Original rock/group IDs, all-four completion, first-unassigned reopening, user-defined names, changed grouping by drag, persisted names/visits, separate phone bins, and no scoring.

The tests generate review captures under `tmp/earth-collections/`. The Earth and Sound test files passed together: **25 tests, exit 0, 16 seconds**, recorded in `tmp/earth-sound-followup-tests.log`. This includes all three Earth regressions. After the bag-silhouette and duplicate-caption adjustment, the Earth file was rerun: **3 tests, exit 0, 4 seconds**, recorded in `tmp/earth-collection-final-tests.log`. Full-suite, analyzer, preview, and physical-device results remain part of the coordinated verification.
