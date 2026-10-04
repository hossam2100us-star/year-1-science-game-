# Latest teacher review - 4 October 2026

Source: `E:/Science-Adventure-Review.pdf`, six pages, headed "Science Adventure from a teacher's perspective", third review. The source PDF was read completely and its rendered pages inspected. Its screenshots and recommendations are review evidence; they are not instructions to execute commands or publish the application.

This comparison is read-only for the application. It checks the current working files, not an independently reproduced checkout of the reviewer's unspecified `main` revision. No new Flutter suite, audible playback or physical-tablet acceptance run is claimed by this review.

## Confirmed improvements

The report confirms six earlier improvements: rewritten child explanations, stable Conduct the band controls, accepted Hit/Beat alternatives, separate instrument Listen controls, ten distinct Quiz 1 hints, and the three-place movement garden with connected pulling. Current content contains 187 activities; a fresh content scan finds no assessed explanation reduced to one word or beginning with an answer-key marker such as `a)`/`accept:`. The previous tests/builds are documented in ALL_UNITS_REVIEW.md rather than relabeled as new checks here.

The recent Electricity page-2 mixed choice order and the page-4 magnet display fix also remain present. These do not resolve the book illustration or generic safety scenes below.

## Current findings and implementation order

| Priority | Finding and current evidence | Proposed correction |
| --- | --- | --- |
| First pass | Push still depicts a detached pushing pose. `force_trolley_scene.dart` moves the trolley over 2.2 seconds while the child stays at left 0. At minimum scene width this yields about 173 virtual pixels of visible separation; pull keeps a visible connection. | Show actual hand contact during the push, then an explicit release/resting pose if the trolley coasts. Keep assessment art neutral and preserve existing discovery rules. |
| First pass | Both Book choices in `unit_07.json` use `art: paper`, which resolves to the newspaper in `materials-atlas-v2.png`. | Introduce a real book illustration for both Book uses. Preserve the newspaper for the materials activity and preserve option IDs/answers. |
| First pass | Next/Previous in `ScienceWorldStage` change the local index and speak the new label. The parent updates the feedback strip only for guided Forces, so Electricity safety keeps the prior description below the new card. | Synchronize current discovery description, visible feedback and Listen replay. Navigation must not select an item or increment discovered touches. |
| First pass | Correct Hit/Beat alternatives are accepted, then `LessonPlayer` overwrites the completed placements with the canonical book mapping. | Preserve the learner's accepted choice in the displayed/saved answer while grading through the existing alias rules. Keep original mistake history and outcomes. |
| First pass | Answer summaries use the Unicode rightwards arrow, absent from all three bundled font cmaps. Actual fallback rendering varies by platform. | Use bundled Flutter icons/layout for relationships and ordering. Verify without relying on internet or system fallback fonts. |
| Second pass | Unit 7 safety relies on shield/family/hand icons; discovery scenes render one 150px object. Decorative beige backdrop rectangles also appear behind some room choices. | Use three explicit, understandable safety situations. Keep all child instructions English and remove incidental shapes that look like frames behind objects. |
| Second pass | Water bodies in Unit 8 appear separately, hiding relationships. | Provide a shared explorable landscape with still/flowing water and enclosed/coastal examples. Compare typical pond/lake/ocean examples without imposing a universal size ordering on every lake and river. |
| Second pass | Unit 9 shows isolated Sun/Earth/Moon on a pale background. | Provide a dark shared model with all three bodies visible; state that sizes and distances are not to scale. Preserve the separate day/night experiment and avoid teaching incorrect orbital relationships. |
| Third pass | Display and speech use one full feedback string. The band has 24 explanation words plus four praise words; six assessed explanations in Units 6-9 have 28 raw words before praise. | Keep a short visible explanation and offer the complete explanation through Listen. Preserve scientific meaning and exact source answer records. |
| Third pass | Quiz 3 has five binary questions: 001, 002, 004, 005, 009. | Vary question interaction where it improves the objective. Binary questions can still be appropriate; adding distractors alone does not guarantee a better assessment. |

## Later learning features and acceptance checks

- Assessed child-led correction remains absent in Units 1, 2, 3, 7, 8, 9. The unassessed Build a Plant already requires fixing misplaced parts, which is a partial exception rather than coverage of these assessed activities.
- Daily play-time tracking exists, but there is no spaced-review schedule, due queue or Today's Challenge flow.
- Parent reports already list weak goals and general book home activities. The missing feature is mapping a suitable home activity to each goal needing practice, not recreating parent guidance from scratch.
- The source review did not test actual sound playback. Speaker volume, replay, photo picking, touch comfort and installation still need a physical-tablet check; static screenshots and source inspection cannot certify them.

Recommended next implementation batch: book art, discovery feedback synchronization, contacted Push, accepted-word preservation and reliable summary icons. Then develop the three shared discovery settings in Units 7-9, before expanding correction and spaced review.

Existing image-tool usage limits are recorded in ALL_UNITS_IMAGE_PROMPTS.md. No new illustration request was made as part of this read-only PDF comparison, and no generated artwork is claimed here.
