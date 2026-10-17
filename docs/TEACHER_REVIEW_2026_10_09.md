# Teacher review 4 — 9 October 2026

> **ملخص لولي الأمر:** دي المراجعة الرابعة من عين مدرس، ومعاها مقارنة بالمراجعات التلاتة اللي فاتت. أغلب ملاحظات المراجعة التالتة اتصلحت. المطلوب دلوقتي ٤ حاجات أساسية: صورة الفيشة، وعلامة الإيد اللي تحت الشاشة، ومكان الزرار اللي بيتغير، واسم المكان في Water world. الملف ده مكتوب بالإنجليزي عشان المطور يشتغل منه على طول.

Fourth teaching review of Science Adventure, following
`LATEST_TEACHER_REVIEW_2026_10_04.md` (removed on 17 October 2026; in Git history).
Each item below names what was observed, where it lives in the code, and what to change.

## How this was tested

- Revision: `main` at `9b5dab1` (5 October). `main` has since moved to `2e81558`
  (parent accounts and sync). That merge does not touch `assets/content` or the child
  scenes reviewed here, so the findings still apply. The account and sync screens were
  **not** reviewed.
- Flutter 3.47.5 web release build (`--no-web-resources-cdn`), Chromium via Playwright,
  1280×800 landscape (tablet size). For speed, the progression locks were opened in a
  local copy only.
- Played Forces, Sound, Electricity and Magnets, Planet Earth and Earth in Space,
  including deliberate wrong answers. Content statistics come from all 187 activities in
  `assets/content/playable/`.
- **Not tested:** audible playback, a physical tablet, and the Android emulator. The
  review environment has no Android SDK and no KVM, so the emulator cannot run there.
  Today's Challenge review cards and per-goal home activities were checked in code only,
  because they need a completed unit and days to pass.

## Comparison with earlier reviews

Scores out of 10 are the reviewer's judgement from play, not measurements.

| Area | Review 1 (28 Sep) | Review 2 (2 Oct) | Review 3 (4 Oct) | **Review 4** |
|---|---|---|---|---|
| Art and setting | 8 | 8 | 8.5 | **9** |
| Feedback on wrong answers and child-led correction | 3 | 7 (3 units) | 7 | **9** (all units) |
| Content and question accuracy | 6 | 6 (42 raw key explanations) | 8 | **8.5** |
| Text length and reading load | 4 | 5 | 6 | **7.5** |
| Units 7, 8 and 9 | 5 | 5 | 5 | **8** |
| Reachable controls and stable layout | 4 | 6 | 8 | **7** (regressed) |
| Retention and spaced review | 0 | 0 | 0 | **8** |
| Parent area | 4 | 6 | 6 | **7** |

### Review 3 findings: status

- [x] Push without contact. The child's hands are now on the handle (`force_trolley_scene.dart`).
- [x] Book used the newspaper art. Now `art: book` (`book-v1.webp`) in `unit_07.step.002`.
- [x] Footer text lagged one safety rule behind. It now matches each rule.
- [x] Units 7–9 showed one card at a time. Shared water landscape, a dark Sun/Earth/Moon model and illustrated safety rules (`discovery_world.dart`).
- [x] Long explanations. Visible explanations now average 9–12 words, with a maximum of 16 (was 29).
- [x] Accepted Beat/Hit replaced by the book word. The child's word now stays (`Triangle → Beat`).
- [x] Missing arrow glyph in answer summaries. Now an icon.
- [x] Child-led correction outside Materials, Forces and Sound. Verified in `unit_07.step.002`: a `?` marker, then "Check my changes".
- [x] Spaced review. Today's Challenge exists, with intervals of 1, 3, 7, 14 and 30 days (`lib/core/spaced_review.dart`).
- [ ] Quiz 3 still has five two-option questions: `quiz_03.step.001`, `002`, `004`, `005`, `009`.
- [ ] Physical-tablet check (sound, touch comfort, installation).

## New findings

### 1. High — the socket safety picture shows a finger on the socket

`unit_07.step.001`, rule "Keep away from sockets", art `electric-safety-v1.webp`
(cropped in `lib/features/science/discovery_world.dart`, around line 68).
The adult points a finger at the socket while telling the child to stay away. Five-year-olds
copy what they see more than what they hear, so a safety picture should never show a finger
on or near a socket.

- [ ] Replace the illustration: a socket with a safety cover, the child standing back with
      hands behind their back, and no hand within reach of the socket.

### 2. High — the hand marker and Next are below the screen; tapping the picture does not count

In Electricity's safety rules (`unit_07.step.001`) at 1280×800, the hand marker under the
picture and the "Next rule" button need scrolling. Tapping the picture itself did not count:
the counter stayed at "Discoveries 0 / 3" until the small marker was reached by scrolling.
In Water world (`unit_08.step.001`) the place name and "Next place" are also below the scene.
Children do not scroll.

- [ ] Count a tap anywhere on the illustration as the discovery, not only on the marker.
- [ ] Size the scene so the marker, caption and Next button fit in 1280×800 without
      scrolling (`science_world_stage.dart`, `discovery_world.dart`).

### 3. Medium — the main action button moves between screens

The action strip ("Keep exploring" / "Check my discovery", `lib/features/lesson/lesson_player.dart`,
around line 1048) follows the content height instead of sitting at the bottom of the screen.
Observed y positions: 760, 719, 653, 645, 564 and 555, sometimes on the same screen after
reopening it. Children learn where the button is by position, not by reading.

- [ ] Pin the feedback and action strip to the bottom of the screen on every activity.

### 4. Medium — Water world does not say the name of the place

The Water world scene itself is excellent. But tapping the ocean shows only "The biggest
water of all, and salty." without the word **Ocean**, because the feedback uses
`senseDescriptions[id]` alone (`lesson_player.dart`, around line 326). The name is the
vocabulary being taught. Visited markers also stay as hands instead of turning into ✓,
unlike the plant parts.

- [ ] Show and speak the label first: "Ocean. The biggest water of all, and salty."
- [ ] Mark visited places with ✓.

### 5. Low — small refinements

- [ ] **Push** (`force_trolley_scene.dart`): the child walks with the wagon for the whole
      2.2 s, so the gap never grows. "Push sends an object away from you" shows better if
      the child pushes, lets go, and the wagon rolls on alone.
- [ ] **Space** (`discovery_world.dart`, around line 258): "Model: sizes and distances are
      not to scale." means nothing to a five-year-old, and the Sun is drawn only slightly
      larger than Earth. Draw the Sun very large and partly off-screen, and keep the
      not-to-scale note for parents.
- [ ] **Electricity hint** (`unit_07.step.002`): "Ask which things need a plug or a battery"
      may lead a child to choose the lantern, since battery lanterns exist. Make the flame
      clearly visible in the lantern art, or word the hint around plugs only.
- [ ] **Quiz 3**: the five two-option questions above. Binary questions can be fine, but
      vary the interaction where it helps the objective.
- [ ] **Parent report**: per-goal home activity text appears in English inside the Arabic
      parent area (`lib/parent/unit_report.dart`, `textDirection: TextDirection.ltr`).
      Checked in code only.

## Not reviewed

- **Parent accounts and sync** (`2e81558`): the merge adds `android.permission.INTERNET`
  and the account screens. The README still says the game is offline and that data stays
  on the device. Parents should be told clearly what is sent before the release.
- **Today's Challenge** review cards and per-goal home activities in a real run.
- **Audible sound and a physical tablet.**

## Suggested order

1. Replace the socket safety picture.
2. Make the whole picture count as a discovery, and fit the marker and Next button without
   scrolling (Electricity safety and Water world).
3. Pin the action strip to the bottom of the screen.
4. Show the place name in Water world and mark visited places with ✓.
5. The small refinements in section 5.
