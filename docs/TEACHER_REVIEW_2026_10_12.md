# Teacher review 5 — 12 October 2026 (Maths and the whole app)

> **ملخص لولي الأمر:** دي المراجعة الخامسة، وأول مرة تتقيّم فيها مادة Maths. العلوم بعد تصليحات المراجعة الرابعة بقت ٨٫٥ من ١٠. Maths ٦ من ١٠: تغطيتها للمنهج ممتازة، وفقرات «Try it together» من أحسن حاجة في اللعبة، بس أغلب أسئلتها نص وزراير من غير صورة. البرنامج كله ٧٫٥ من ١٠. قبل ما Maths تتدمج لازم تتصلح الأخطاء اللي في جدول القسم ٤. الملف ده مكتوب بالإنجليزي عشان المطور يشتغل منه على طول.

Fifth teaching review of Science Adventure, following
[TEACHER_REVIEW_2026_10_09.md](TEACHER_REVIEW_2026_10_09.md). First review of the Maths subject.

## How this was tested

- Revisions: PR #6 `feature/maths` at `e58924b` (Maths, stacked on PR #5) and PR #5
  `remediation/m5-teacher-review-and-web` at `57bdeb8` (teacher review 4 fixes, merged into #6).
- Flutter 3.47.5 web release build (`--no-web-resources-cdn`), Chromium via Playwright,
  1280×800 landscape. In a local copy only, progression locks were opened and a test-only
  `?jump=` parameter was added to open any step directly. The repository was not changed.
- Played the Maths subject hub, island map and the unit 1 counting workshop; captured about
  30 Maths questions across the units; answered wrongly on purpose. Content statistics come
  from all 292 Maths steps in `assets/content/playable/math_*.json`.
- **Not tested:** audible playback, a physical tablet, the Maths parent report in a real run,
  and parent accounts and sync.

## Scores

Scores out of 10 are the reviewer's judgement from play, not measurements.

| | Review 4 (9 Oct) | **Review 5** |
|---|---|---|
| Science | 8 | **8.5** |
| Maths | — | **6** |
| Whole app | 8 | **7.5** |

## Science: review 4 fixes (verified on PR #5)

- [x] Socket picture: the adult raises a hand to the child and no finger is near the socket.
      Small remaining point: the child stands right beside the socket; move the child back.
- [x] Tapping the picture counts as a discovery, and Next fits on screen without scrolling.
- [x] Water world: the name comes first ("River. Big moving water…") and visited places get ✓.
- [x] Push: the child pushes, lets go, and the wagon rolls on alone.
- [x] Space: the Sun is large and partly off-screen; the "not to scale" line is gone.
- [x] Quiz 3: two-option questions gained a third choice.

## Maths: strengths

- **Full curriculum coverage:** 18 units over 3 terms, 273 book questions: numbers to 20,
  addition and subtraction, shapes, graphs, fractions, time and measurement.
- **"Try it together" is excellent.** In unit 1 the child taps each apple, each one gets a
  number, a repeated tap is not counted twice, then "How many altogether?". The next part
  spreads the same apples and asks "How many now?" — conservation of number, a key Year 1 idea.
- **The visuals that exist are good:** clocks are correct (hour hand between 7 and 8 at
  half past 7), ten frames, bar charts and halves.
- **Local context:** pounds and piastres, names such as Mona and Omar.
- **Good distractors:** 51 against 15, "Omar wrote sixteen as 61".
- **Guided correction** after two mistakes works in Maths too.

## Maths: findings

### 1. High — most questions have no picture

- Only **81 of 258 assessed questions (31%)** have a `mathVisual`. The rest are text and buttons.
- **28 questions refer to something that is not shown.** Examples:
  - `math_unit_10.step.007` "On this balance, B is down and A is up. Which is heavier?" —
    no balance, only two buttons A and B.
  - `math_unit_15.step.009` "The robot faces up. Choose both routes…" — no robot, grid or
    star, only three long sentences.
  - `math_unit_07.step.005` "Sort the numbers into the Carroll diagram" — no diagram.
  - `math_unit_03.step.007` "Sort flat drawings and solid objects" — words only (tin, ball,
    dice). 2D/3D cannot be learnt without pictures.
- Many questions test vocabulary, not understanding: "A block graph is made of…",
  "Fraction means…", "Every graph needs a…".

Full list of the 28 (prompt refers to a picture, no `mathVisual`):
`math_quiz_01` 004, 005, 006 · `math_quiz_02` 006 · `math_quiz_03` 007 ·
`math_unit_01` 012 · `math_unit_02` 012 · `math_unit_03` 013 · `math_unit_04` 010, 011, 012, 014 ·
`math_unit_06` 010 · `math_unit_07` 005, 010, 013, 014 · `math_unit_08` 007, 014 ·
`math_unit_10` 007, 011, 012 · `math_unit_15` 009, 010 · `math_unit_16` 010, 013, 014 ·
`math_unit_18` 010.

- [ ] Give every question something to look at, and where possible to touch: a tilting
      balance, a robot moving on a grid, a real Carroll diagram to drag numbers into, pictures
      for 2D and 3D shapes.
- [ ] Turn vocabulary questions into questions about a picture.

### 2. High — questions do not use what the workshop taught

- **Counting:** in the workshop each tapped apple gets a number. In the next question
  (`math_unit_01.step.002`, "Count the apples", 8 apples) the apples cannot be tapped.
- **Number line:** `math_unit_02.step.003` "Start at 5 and count on 3" shows a static line.
  The explanation says "Three forward jumps", but no jump is ever shown.

- [ ] Keep the counting tool active in counting questions.
- [ ] Let the child make the jumps on the number line, and animate them in the explanation.

### 3. High — one tap is graded at once

Single-choice questions grade the first tap immediately, with no Check button. Five-year-olds
tap by accident often, and that tap is recorded as a mistake in the parent report.

- [ ] Select first, then Check, as in the matching questions.

### 4. High — content errors (fix before merging)

| Step | Problem |
|---|---|
| `math_unit_02.step.005` | The explanation says "4 blue dots and 3 orange dots", but every dot is orange. The groups differ only in size, which can suggest a big dot is worth more. |
| `math_charts.step.008` | Pigeons, sparrows and crows all use the same blue bird picture. |
| `math_unit_04` pictogram | Each person is a red circle, and the first row is apples, so the circles look like apples. "Key: one person" has no key picture. The answer buttons are below the screen. |
| `math_unit_13.step.008` | A coin reads "100 piastres". Egypt has no such coin; it is 1 pound. The question only tests which number is biggest. |
| `math_unit_08.step.014`, `math_unit_18.step.011` | `shortExplanation` stops mid-sentence: "…depth as well as", "…halfway toward". The shortening step in `scripts/build_maths_content.py` cuts sentences. |
| `math_unit_12`, `math_unit_13` | Option letters appear as b, c, a instead of a, b, c. |

### 5. Medium — hints and titles

- [ ] Many units repeat one hint for every question. All three term challenges use "Think about
      the objects, number track or equal groups" for all 10 questions. The number-line question
      gets "Think whether things join the group or leave it". Science fixed this in review 1;
      Maths needs a hint per question.
- [ ] Step titles are all "Maths discovery 2", "Maths discovery 7" (already listed as open in PR #6).
- [ ] 90 of 258 explanations start "… is the answer.", which becomes repetitive.
- [ ] After returning to a workshop step, "Try the next idea" is below the screen.

### 6. Low — small points

- [ ] Arabic parent activities follow one template ("اتكلّم مع طفلك في السؤال ده: «…»
      استخدموا حاجات آمنة من البيت…") rather than an activity per goal. Typo: "خلّي طفلك يشرح
      فكّر إزاي" should read "خلّي طفلك يشرح هو فكّر إزاي" (`assets/content/maths_parent_ar.json`).
- [ ] Six questions repeat word for word between units and challenges, for example "How many
      days are in a week?". Fine for review, but vary the numbers.
- [ ] 22 Maths questions have only two options.

## Suggested order

1. Before merging Maths: fix the cut-off explanations, the blue/orange dots, the bird pictures
   and the coin.
2. Add pictures to the 28 questions that refer to something not shown (balance, robot,
   Carroll diagram, 2D/3D).
3. Select-then-Check for single-choice questions.
4. Tappable apples in counting questions; visible jumps on the number line.
5. A hint per question and real step titles.
