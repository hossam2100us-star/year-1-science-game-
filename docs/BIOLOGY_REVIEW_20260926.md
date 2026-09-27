# Ourselves and Biology quiz review — 26 September 2026

## Delivered

- All 49 existing Ourselves steps use the new illustrated renderer. Step IDs,
  content version, answers, source references and assessment objectives remain stable.
- Body labels attach to the actual character, with enlarged head, arm, hand and
  leg views. Eye labels attach to an enlarged eye. Tap and drag are both supported.
- Exploration and the two introductory sense scenes require touching their parts.
- Sense matching supports drag or touch; everyday examples have explicit illustrations.
- Marble choices show the source counts: David 6, Zara 9, Jack 5.
- Shoe comparison has two illustrated controls. Changes save before comparison;
  the activity remains ungraded.
- The 10-question Biology quiz reuses plant illustrations, a park collection,
  sense pictures and an interactive shoulder-to-fingers trail. Its score stays /10.
- Browser review accepts `preview=biology-v1`, optional `lesson=quiz_01`,
  and a one-based `step`. It uses a separate in-memory store and does not replace
  the child's persistent progress.

## Source and artwork

The scientific content is retained from the existing extracted source records in
`assets/content/unit_03.json` (PDF pages 8–10, answer key page 35) and the existing
quiz records. No answer or scientific outcome was added from an external source.

Original illustrations are drawn in `body_scene.dart`, `biology_art.dart` and
`shoe_measure.dart`. The shared normalized geometry defines anatomy and hit targets.
The image-generation request was rejected by the provider; no generated bitmap
was used. Existing plant assets remain unchanged.

## Validation and remaining work

Final checks: `dart analyze --fatal-infos` passed, all 83 Flutter tests passed,
and `scripts/validate_playable.py` passed for all 126 current playable steps.

Regression tests cover correct anatomy target selection, hint evidence, restoring
progress, sense matching, source marble counts, ungraded measurement, quiz order,
and rendering all 49 steps at 800×360 with 1.5× text. Actual screen captures are
rendered in `tmp/ourselves-*.png` for visual inspection.

This delivers the Ourselves renderer and quiz presentation, not a final sign-off
on the entire Biology island. Parent review, further scene polish, full curriculum
coverage review of the earlier garden activities, and physical Android narration
and interaction testing remain. No final APK was built.
