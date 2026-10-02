# Review remediation — 27 September 2026

## Follow-up — 28 September 2026 (review of `49e8316`)

- Both child widget tests load the catalog through `WidgetTester.runAsync`, fixing the order-dependent hang when the whole suite runs.
- Child cards now offer parent-gated deletion with a separate named confirmation and cancel action. Deletion removes the child's profile/photo, all subject progress, settings and usage from local storage. The next saved child becomes active; deleting the last child returns to profile creation.
- Hive compaction now considers removed children and photo changes across every child, including inactive profiles. This is local app-data deletion, not a guarantee about operating-system backups.
- Fresh empty-profile IDs prevent late writes from restoring a deleted child. Tests cover survivor progress, active/inactive/last deletion, stale child updates, the parent gate and cancellation.
- Full `flutter test --reporter expanded`: **113 passed in 40 seconds**; log: `tmp/audit-latest-tests.log`. `dart analyze --fatal-infos`: no issues. Earlier counts below describe earlier revisions.
- Lossy image compression, richer units 4–9/Quiz 3, skills, certificate/export, the final parent dashboard and physical-tablet acceptance remain open. Firebase/login/cloud sync are not configured.

The supplied review concerns commit `46ec735`. This record distinguishes verified repairs from product work that remains open. It does not describe the whole game as finished.

## Verified repairs

- `test/light_test.dart` locates the light experiment by its content identity and derives progress labels and the next index from the lesson. It no longer assumes activity 11 of 21.
- Every screenshot-writing test creates its output directory recursively. A fresh checkout does not need a tracked `tmp` directory.
- Anatomy now uses separate 64 dp touch buttons with leaders to the picture. Taps no longer choose the closest invisible anatomical point. Existing tests exercise every part for both characters; additional assertions check that markers never overlap.
- Replaced the 104 generic hint fields in units 4–9 and quizzes 2–4 with task-specific hints, or empty hints for ungraded activities where a hint is not shown. Every assessed activity has a nonempty hint. The generator applies the same refinement so a rebuild retains the fixes.
- Ungraded science experiments use `science-lab`, with schema and model support. Actual plant construction retains `free-plant`. Existing prediction and scoring tests still pass.
- Runtime images use lossless WebP. Each converted image was compared pixel-for-pixel in RGBA with its PNG original. Original PNGs remain as source artwork; `pubspec.yaml` explicitly bundles only the WebP versions. PNG total: 44,555,560 bytes; WebP total: 32,894,264 bytes; saving: 26.2%. This is not a measurement of final APK size.
- Updated section 28 of the master instructions to the current 187 activities: 9 units and 4 quizzes, including 14 plant activities. Earlier 194-activity wording is historical.

## Verification

- Full `flutter test --no-pub`: **104 passed**, after the image references and touch markers were updated. The local run log is `tmp/final-review-tests.log` (generated, not committed).
- `dart analyze --fatal-infos`: no issues.
- `scripts/validate_playable.py`: 187 activities pass schema, references, source-objective coverage and prediction exclusion.
- Visually inspected rendered anatomy markers. Flutter tests cover both boy and girl, enlarged text and small landscape layout.
- Conversion initially exposed old PNG names in garden content; those references and their content generator were updated before the successful full run.
- No physical Android tablet verification has been performed in this review. Browser/test success must not be reported as device verification.

## Product work still open

1. **Interaction quality in units 07–09 and Quiz 3.** Materials, Forces and Sound now have interaction passes (see docs/TEACHER_REVIEW_REMEDIATION.md). Their visual/device acceptance is still pending; Forces art needs further refinement after user feedback. Continue with Electricity, preserving each source objective and assessment weight.
2. **Skills area.** The source includes three chart types, chart creation, recording observations and 20 self-check statements. These need a dedicated playable area and ungraded persistence; they are not implemented by this repair.
3. **Certificate and export.** The source certificate exists, but the runtime certificate and parent-only export are not implemented. Export must follow the specified MediaStore/SAF behavior and be tested on actual Android devices.
4. **Final parent experience.** ParentArea and UnitReport already provide settings, latest/best attempts, objective details, retry links and home activities. The remaining work is a consolidated final dashboard and access to the missing skills/certificate, not creating a parent area from nothing.
5. **Physical-device acceptance.** Verify offline English voices, selecting/replacing/deleting a photo, restored progress, export on supported Android versions, and installation/update. No final APK is claimed or delivered here.

These open items remain requirements, not completed features. Asset-size estimates and passing unit tests are not evidence of educational quality.
