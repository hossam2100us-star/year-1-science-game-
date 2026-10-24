# Teacher review 8 — 24 October 2026 (English subject)

> **ملخص لولي الأمر:** مادة English محتواها ممتاز ومتوافق مع منهج Year 1، وأسئلتها متنوعة: كتابة حروف، وترتيب كلمات، وتصنيف، وعد مقاطع. أضعف نقطة إن أغلب أسئلتها نص من غير صور، وده صعب على طفل لسه بيتعلم يقرا لو الصوت مش شغال. البرنامج كله ٩ من ١٠. الملف ده مكتوب بالإنجليزي عشان المطور يشتغل منه على طول.

Follows [TEACHER_REVIEW_2026_10_18.md](TEACHER_REVIEW_2026_10_18.md).

## How this was tested

- `main` at `e821326` (PRs #18–#22: English, school years, Maths class-book questions, Huawei speech).
- Web release build, Chromium, 1280×800. Unchanged build for onboarding and restart; a local
  copy with locks opened and a test-only `?jump=` to open single questions.
- Read all 13 English lessons (9 units, 3 challenges, Chart Skills) with their answers; played
  story, letter-entry, number-entry, sorting and word-order screens.
- **Not tested:** audible speech, a physical tablet, a real child.

## Scores

| | Review 7 | **Review 8** |
|---|---|---|
| Science | 9 | 9 |
| Maths | 9 | 9 |
| English | — | **8** |
| Whole app | 9 | **9** |

## English: strengths

- Covers the Year 1 English book across three terms: fantasy, recounts, rhymes, traditional
  tales, instructions, poems, familiar settings, animal poems, information books.
- Varied interactions: letter tiles with a picture (`tr__` with a tree, `box__` with two boxes),
  a number pad on pictograms, tap-to-order sentences, sorting with picture cards, syllable claps.
- A hint per question and short, clear child explanations; no answer-key text.
- Good distractors (`foxs`, `eigt`, `Yesterday ali and I…`).
- First-launch saving still works (new profile, restart, profile kept).

## Findings

### 1. Medium — many English questions are text only

Fewer than half of assessed English questions have a question picture (`englishVisual`: 73 of 165;
some others show pictures on their cards), and in
`eng_unit_04` only 2 of 13. Sorting sentences into Real/Fantasy (`eng_unit_01.step.006`) and
"Is there a verb?" (`eng_unit_04.step.005`) are long sentences only. A Year 1 child who does not
yet read fluently depends fully on speech here.

- [ ] Add a picture to sentence cards where one helps (monster in the washing machine, boy with a football).
- [ ] Make sure every sentence card can be heard by tapping it before choosing a basket.

### 2. Medium — stories are long text blocks

Story explore screens (`eng_unit_01.step.001`, `eng_unit_04.step.001`) show three long
paragraphs with one small picture.

- [ ] One picture per story part (beginning, middle, end), with shorter text.

### 3. Low — content points

- [ ] `eng_unit_07.step.008`: "whispered" sorted as **scared** is debatable (people whisper when
      a baby sleeps). Use "trembled" or "shook", or accept more than one group.
- [ ] `eng_unit_09`: two assessed questions share one hint (12 hints for 13 questions).
- [ ] Content uses the name "Seif" ("Books Seif read this week"). The product is for any child;
      use a neutral name or the child's own name.
- [ ] English quizzes still have 5 two-option questions (quiz 1: 1, quiz 2: 3, quiz 3: 1), mostly true/false style.

## Child trial

Still recommended before release, on the tablet, as described in review 7.
