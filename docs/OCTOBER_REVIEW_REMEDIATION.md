# Teaching review of 2 October 2026: first fixes, 3 October 2026

The user approved starting the feedback and Sound interaction fixes from the
seven-page `E:/Science-Adventure-Review.pdf`. This pass does not complete every
recommendation in the report.

## Delivered

- Reviewed all 187 runtime activities and the active garden scenes. Rewrote 142
  activity explanations and 14 hints, including ten distinct Quiz 1 hints.
  Explanations use child-facing English sentences tied to the displayed choices.
  Authentic `source.answerKeyText` remains verbatim; IDs, scientific answer
  values, objectives, assessed flags and content versions are unchanged.
- Edited feedback lives in `scripts/child_feedback/*.json`. The content builders
  and refiners apply these overlays; run `python scripts/child_feedback.py` after
  other content changes. `validate_playable.py` rejects lettered answer lists,
  teacher acceptance/marking notes, tick/cross keys and one-word explanations. It
  also detects overwritten editorial entries, obsolete IDs and repeated Quiz 1
  hints. The guard is a mechanical check, not a substitute for teaching review.
- Conduct the band reserves its instruction and answer-caption rows from the
  first render. Text height adapts to width and scaling; selecting an instrument,
  placing an answer or replaying narration does not move the action buttons.
- Only this activity accepts Hit and Beat for either percussion instrument.
  Book answer values stay intact. Wrong-item messages, review markers and
  objective evidence use the same alias comparison as the grading engine.
- Restoring an assessed activity rebuilds feedback from current content and
  the saved outcome, instead of replaying obsolete cached wording. Original
  answers, mistakes, correction status and grades survive. Historical completed
  Maris questions retain Maris and their 23-step answer, with a prose explanation.
  Ungraded laboratory feedback and observation state remain unchanged.

## Evidence

- 30 focused Sound scene/progress tests passed, including fixed button geometry
  at 1280x800 and at compact width with 1.5x text, alternative percussion answers,
  genuinely wrong actions, guided correction and old saved wording.
- All **168 Flutter tests passed in 66 seconds**
  (`tmp/teacher-feedback-full-tests.log`). Three Python guard tests passed.
- `dart analyze --fatal-infos` is clean
  (`tmp/teacher-feedback-analyze.log`); all 187 activities pass schema/source and
  child-feedback validation. Protected-field comparison against HEAD confirms
  sources, answer values, IDs, versions and score flags are unchanged. Applying
  the feedback, teaching, Forces and Sound refinements again is idempotent.
- Screen 3's tablet render was visually reviewed. Audible browser playback and
  acceptance on a physical tablet remain separate checks.
- The local JavaScript web build succeeded in 52.9 seconds
  (`tmp/teacher-feedback-preview.log`). The page, main JavaScript and Materials/
  Sound JSON return HTTP 200. All 13 built lesson hashes and both changed preview
  Dart files match their sources. Current preview:
  `http://127.0.0.1:8765/review/teacher-feedback-v2/?preview=biology-v1&lesson=unit_06&step=3`.

## Corrections to the report and remaining work

The reported 42 source-key matches are not automatically 42 poor explanations:
some keys already contain complete teaching sentences. Parent reports already
show book home activities and goals for practice; objective-specific home
recommendations are still missing. Unit 1's legacy JSON has 46 steps, but normal
navigation opens three scene adventures rather than 46 consecutive slides.
Cloud login/synchronisation is not implemented; progress storage is local.

The first Forces exploration still needs a clear person/hand reference and a
separate treatment of animal motion. Guided manual correction outside Materials,
Forces and Sound, units 7-9 and Quiz 3 redesign, daily spaced review, skills,
certificate/export and device testing remain open.
