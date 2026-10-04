# Forces and Sound review — 4 October 2026

This is the Forces/Sound part of the requested review of every unit, starting from the beginning. The review preserves the accepted movement garden, guided experiment, and Sound illustrations. The child interface remains English.

## Evidence and changes

All 13 Forces and 12 Sound screens were inspected in the full-unit captures under `tmp/all-units-review/unit_05/` and `tmp/all-units-review/unit_06/`, with their two contact sheets. Those captures are the starting point, rather than evidence of the final edits. Current verification and refreshed captures are produced by the coordinating review run.

- Fixed-size Forces scene cards could overlap on a phone. The board now chooses its column count and picture size from the available width, with separate flowing cells and clipped picture bounds. The neutral hand cues select objects; they do not consult the answer key or mark the correct answer.
- The final Forces trail previously presented the five questions as objects in one scene. It now presents one illustrated question and its prompt at a time, with numbered revisit controls and a next-discovery button. All five original targets remain available. Existing responses and the original grading remain intact, including completed review without rescoring.
- A padded phone gave the Sound listener almost no travel, making near/far difficult to see. The entire drum/listener scene now scales from a complete 640-pixel scene. The listener travels a meaningful distance, its touch area stays separate from the drum, and drag distances account for the scene scale. Move-near, move-far, slider, and Listen controls remain accessible alternatives.
- The graded Sound band needed a way to hear an instrument without selecting an answer. Each instrument now has its own Listen button. Listening replays only that instrument and does not call answer selection, placement, completion, or grading. Choosing the instrument and assigning its playing action remain separate.
- The Sound band reserves space for answer captions and uses responsive columns, so choosing an instrument or assigning its action does not shift the other hitboxes. The walking chart moves its answer tray below the tracks on narrow screens or enlarged text, preserving readable lanes.
- The existing Sound box observation feedback was retained: a mismatched prediction requires an observation, and a wrong observation produces visible retry feedback. The feather remains silent in this experiment. Replay does not replace the original prediction.
- Sound's final trail continues to show only the defined two or three choices for the current question. Its original full target catalogue is retained, including answers saved by earlier versions.

## Screen-by-screen outcome

| Unit / screen | Outcome |
| --- | --- |
| Forces 1 — movement garden | Keep the accepted illustrated garden, its Gate/Lawn/Pond zones, freely chosen order, eight required touches, and only the touched subject moving. |
| Forces 2 — push/pull playground | Keep the guided push, pull, prediction, gentle push, bigger push sequence. Full child/reference scene, one current task, and the saved original prediction. |
| Forces 3 — trolley directions | Keep both full scenes. The child's neutral pose does not signal push/pull in assessment. |
| Forces 4 — forces around us | Adapt scene cells to phone width; keep the object cutouts and all original force choices. |
| Forces 5 — tank exploration | Keep prediction before each test and source-linked observations. |
| Forces 6 — tank keeper | Keep the neutral object touch/drag controls, float/sink destinations, and correction flow. |
| Forces 7 — animal moves | Adapt the scene cells; keep full animal drawings and neutral selection cues. |
| Forces 8 — sailboat breeze | Keep prediction before wind, replay, and the moving boat. |
| Forces 9 — sailboat force | Keep the complete sailboat and the original force choices. |
| Forces 10 — home helpers | Adapt scene cells; retain drawer and doorbell illustrations. |
| Forces 11 — my four moves | Adapt scene cells; retain all four jobs and their original grading. |
| Forces 12 — orange surprise | Keep both whole-object variants and prediction/observation rather than revealing the result beforehand. |
| Forces 13 — movement trail | One question at a time; saved choices and the complete original target set. |
| Sound 1 — music studio | Keep illustrated instruments, responsive rows, replay, five required explorations, and separate explanations. |
| Sound 2 — sound catcher | Keep the complete face with separated neutral hand markers; no zoom or correct-part colour cue. |
| Sound 3 — conduct the band | Add separate Listen controls; keep selection and action mapping independent from playback. |
| Sound 4 — sound boxes | Keep prediction/test/observation phases and visible wrong-observation retry feedback. |
| Sound 5 — box detective | Keep Listen separate from assessed choice; the feather box remains silent. |
| Sound 6 — sound walk | Show visibly distinct near/far positions in the scaled complete scene; retain the predicted result and both required listening trials. |
| Sound 7 — farther away | Use the same scaled scene; listening and moving do not choose or grade the answer. |
| Sound 8 — drum explorers | Keep the source-linked David question and Maris furthest question; use the readable answer tray below tracks when compact. |
| Sound 9 — tapping sticks | Keep independently replayable gentle/harder taps and separate answer controls. |
| Sound 10 — sound order | Keep tap-to-listen, explicit drag destinations, and placement/reordering buttons as a touch alternative. Listening alone does not rank a sound. |
| Sound 11 — own hum | Keep the complete child illustration and simple instructions for the child's own voice. |
| Sound 12 — sound trail | Keep one prompt at a time with its defined two or three alternatives and completed review without rescoring. |

The accepted Forces and Sound illustrations are retained in this pass. The evidenced problems here were crowded layout, small-screen hitboxes, invisible near/far travel, and incomplete listening controls. New illustration generation is handled separately in the full-unit image review.

## Preservation

No lesson IDs, step IDs, question IDs, scientific answer keys, aliases, objective links, source references, assessed flags, target IDs, required exploration counts, or content versions are changed by this review. No child progress is reset. The refiner scripts generate the checked-in presentation metadata for the same lessons.

The v6 garden and guided Forces implementation predate this audit and remain accepted. Sound's version-two David chart migration, feather experiment behavior, and mission-choice catalogue also predate this audit and remain intact.

## Verification handoff

Changed Dart files have been formatted. Python refiners have been applied and verified idempotent. A comparison against the saved pre-review content verified unchanged protected fields, option IDs/labels, and content versions across all 25 screens; the scoped whitespace check also passed. The focused tests added or extended for this pass cover:

1. Phone Forces scene rectangles remain separate, within the screen, and at least 48 pixels in each dimension with enlarged text.
2. The final five Forces mappings show one prompt, keep all original targets, save each response, and allow completed revisit without modifying progress or score.
3. Graded band listening calls the intended sound only, animates that instrument only, and leaves selections, placements, progress, and grading unchanged; its controls remain touchable on a phone.
4. Phone and tablet near/far scenes keep listener and drum touch areas separate, keep the listener inside the scene, and provide more than 60 pixels of visible travel on the phone.

Run `test/forces_scenes_test.dart` and `test/sound_scenes_test.dart` together with the full suite and content validator. This sub-review does not claim a Flutter test result, analyzer result, fresh preview build, or physical-tablet test; those are reported by the coordinating review after execution.
