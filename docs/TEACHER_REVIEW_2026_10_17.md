# Teacher review 6 — 17 October 2026 (whole app after review 5)

> **ملخص لولي الأمر:** دي المراجعة السادسة. Maths طلعت من ٦ لـ٨٫٥ من ١٠، وكل ملاحظات المراجعة الخامسة اتصلحت تقريبًا. بس فيه **مشكلة خطيرة جديدة في نسخة الويب**: كل اللي الطفل بيعمله في أول مرة يفتح التطبيق بيضيع لما يقفل ويفتح تاني. لازم تتصلح قبل ما أي طفل يجرب. الملف ده مكتوب بالإنجليزي عشان المطور يشتغل منه على طول.

Sixth teaching review of Science Adventure, following
[TEACHER_REVIEW_2026_10_12.md](TEACHER_REVIEW_2026_10_12.md).

## How this was tested

- Revision: `main` at `886cc4f` (17 October), with PRs #5 (teacher review 4), #6 (Maths),
  #8 (login page) and #9 (SQLite in the browser) merged.
- Flutter 3.47.5 web release build (`--no-web-resources-cdn`), Chromium via Playwright,
  1280×800 landscape. Two builds:
  - **unchanged** `lib/main.dart` build, used for onboarding, saving and the child-style run;
  - a local copy with progression locks opened and a test-only `?jump=` parameter, used only to
    open single questions. The repository was not changed.
- Checked every item from review 5, captured about 20 Maths and Science screens, played the
  Maths unit 1 counting workshop with fast taps, wrong answers, leaving mid-lesson and
  reopening. Content statistics come from all 292 Maths steps.
- **Not tested:** audible playback, a physical tablet or the Android emulator (no Android SDK
  or KVM in the review environment), the login page (it did not appear in the web build,
  probably because no server is configured), parent accounts and sync, and a real child.

## Scores

Scores out of 10 are the reviewer's judgement from play, not measurements.

| | Review 5 (12 Oct) | **Review 6** |
|---|---|---|
| Science | 8.5 | **8.5** |
| Maths | 6 | **8.5** |
| Whole app | 7.5 | **8.5** once finding 1 is fixed |

## 1. Critical — progress from the first web launch is lost

Everything done in the **first** launch on the web is gone after the app is closed and opened
again: the app returns to onboarding ("My little adventure 1 / 3"), and the name, avatar and
progress are lost. From the second launch on, saving works and a lesson resumes where the child
stopped.

Reproduced 5 times on 5 fresh browser profiles (Chromium, persistent profile, unchanged build):

1. Open the app in a new profile (no previous data).
2. Complete onboarding (name, boy/girl, avatar, Start exploring). Optionally play a lesson.
3. Close the browser. Wait for the app to be idle first (tested with 3–5 s waits).
4. Open the app again in the same profile → onboarding again, nothing saved.

Control: if the app is opened once and closed **before** onboarding, then onboarding on the
second launch is kept on the third. So only data written during the first launch is lost.

After the failing first launch, the browser holds both the IndexedDB box
`science_adventure_v1` and the OPFS entry `drift_db`.

Likely area: the first-launch path in `lib/startup/storage_bootstrap.dart`
(`openProgressStore` → `HiveToDriftMigration` on the web, added in PR #9 `b17d4d6`). For example,
the first session may write to one store while the next launch reads another, or the migration
may run again over an empty Hive box.

- [ ] Fix so the first launch's onboarding and progress survive a restart on the web.
- [ ] Add a test: fresh install → onboarding → restart → profile present (web and Android).
- [ ] Run the same scenario on the Android tablet: fresh install, onboarding, force-close, reopen.

## 2. Review 5 items — status

- [x] Questions without pictures: every question now has a picture (219 of 258 have a
      `mathVisual`; the rest show pictures in their options). Tilting balance, robot grid with
      star, a real Carroll diagram to fill, drawn 2D/3D shapes.
- [x] Counting questions use the counting tool: each apple gets a number, with "Count again".
- [x] Number line: Jump forward / Jump back, and the jumps are drawn as arcs.
- [x] Select, then Check, in Science and Maths. After a wrong check, Check stays disabled until
      the choice changes.
- [x] `math_unit_02.step.005` blue and orange dots.
- [x] `math_charts.step.008` pigeon, sparrow and crow each have their own picture.
- [x] `math_unit_13.step.008` coin is now "1 pound".
- [x] No cut-off `shortExplanation`.
- [x] Option letters in order (a, b, c).
- [x] Pictogram key shows a person icon "= one person".
- [x] A hint per question in every unit and challenge.
- [x] Real step titles ("The heavier side", "Robot routes").
- [x] No "… is the answer." explanations.
- [x] Arabic parent activities: 258 different, practical activities, one per goal; the typo is fixed.
- [x] Science: the child stands away from the socket.
- [~] Two-option questions: down from 22 to 17.

## 3. New findings

### 3.1 High — answer buttons below the screen on chart questions

On a 1280×800 tablet the answer buttons are cut off at the bottom of the screen in chart and
pictogram questions, for example `math_charts.step.008` ("Sparrows") and
`math_unit_04.step.002` ("Counting votes"). The child must scroll to answer.

- [ ] Fit the chart and the answers on screen together (shorter chart, or answers beside it).

### 3.2 Medium — socket safety picture

`unit_07.step.001`, "Keep away from sockets": the wall with the socket is drawn as a separate
cut-out piece, and the socket looks like a light switch.

- [ ] Draw one complete wall, with a socket that clearly looks like a socket.

### 3.3 Medium — the balance question gives the answer

`math_unit_10.step.007`: "On this balance, B is down and A is up. Which is heavier?" The picture
is enough on its own.

- [ ] Ask "Which side is heavier?" without saying which side is down.

### 3.4 Low — counting workshop hint does not match the mistake

`math_unit_01.step.001`, part 1: after counting 7 apples correctly and choosing 8, the hint is
"Tap each object once. A marked object has already been counted."

- [ ] When everything is counted, say "The last number you said tells how many."

### 3.5 Low — "Delete profile" on the child's card

"Delete profile • Grown-ups" is shown on the child's card in "Who is playing?". It is probably
behind the parent gate, but a child sees it on every launch.

- [ ] Move profile deletion into the parent area.

### 3.6 Low — robot routes

`math_unit_15.step.009`: three long route sentences ("turn right, 2 forwards, turn left,
2 forwards") are hard for a six-year-old to picture.

- [ ] Let the child tap a route and watch the robot move before checking.

## 4. Child trial

A real child did not take part. The reviewer played like a six-year-old: fast taps, taps in
the wrong place, not reading, leaving mid-lesson and returning.

- Seven taps in under a second on the apples were all counted, in order.
- A wrong answer in the workshop gave a hint and did not block the child.
- Leaving with Home in the middle of a lesson and reopening returned to the same step
  (from the second launch on; see finding 1).
- Expected to please a child: the islands and art, counting apples by touch, jumping on the
  number line, the balance and the robot grid.
- Expected to frustrate: losing their name after the first day (finding 1), all-English text
  when sound is off or the child cannot read yet, the robot route sentences, and answers below
  the screen on charts.

The owner plans a supervised 20-minute session with a six-year-old on the tablet. Results
should be recorded in a follow-up review.

## Suggested order

1. Fix finding 1, and confirm the same scenario on the Android tablet, before any child trial.
2. Fit chart questions and their answers on one screen.
3. Socket picture, balance question wording, counting workshop hint.
4. Move "Delete profile" to the parent area; animate robot routes.
