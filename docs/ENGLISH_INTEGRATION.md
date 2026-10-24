# English integration

English is the third Year 1 subject (owner request, 23 October 2026;
ADR-0022). It follows the family's parent companion **English Made Easy**
(56 pages), written to follow Cambridge Primary English, Stage 1 (Learner's
Book 1 and Workbook 1). The companion and the class books are in the local,
git-ignored `curriculum/` folder; they are copyrighted and never committed.
The English verbs booklet in the same folder is left out (owner decision:
it goes beyond Year 1).

## What the child plays

| Island | Lessons |
|---|---|
| Term 1 | Fantasy Stories, Recounts, Traditional Rhymes, Big Challenge: Term 1 |
| Term 2 | Traditional Tales, Instructions, Simple Rhyming Poems, Big Challenge: Term 2 |
| Term 3 | Stories with Familiar Settings, Animal Poems, Information Books, Big Challenge: Term 3 |
| Chart Skills | A pictogram (books read this week) and a bar chart (rhyme families) |

- **Units** open with one to three story or "big idea" steps. Each part of a
  story is a card the child taps to hear it read; the step goes on when every
  part has been heard. The stories are the companion's own short retellings
  (Aqsa's Adventures, Tiddalik, Not So Fast Songololo…), never the class
  book's text.
- **All 155 companion questions** (9 units × 8 questions and 5 choices, 3 ×
  10 quiz questions, 8 chart questions) are answered in the app: 186 steps,
  165 of them graded. A question with several parts is one goal with up to
  three steps (tree and coat for "write the missing sounds").
- **Writing and drawing tasks** ("draw your own fantasy creature", "write two
  sentences about yesterday") become a graded question on the same skill
  (choose the fantasy sentence written correctly; build "Yesterday, I played
  in the park." from word cards). The task itself is the goal's home
  activity.
- **Question types:** choose one, choose all that apply (the oa words, the
  words that need a capital), sort into groups (real or fantasy, noun or
  verb, a or an), match (rhyming pairs, animal and verb), put in order (a
  sentence, the steps of an instruction), spell with letter tiles (new), and
  the Maths number pad for chart questions.
- **Sound:** the device voice reads whole words and sentences. Tapping a card
  reads it; a spelling question has a button that reads the whole word
  ("tree"). Letter tiles are silent: isolated letter sounds are never spoken
  (owner decision).
- **Pictures:** each word a question is about has a small picture, so a
  child who cannot read it yet still knows it. Twelve come from the Maths
  pictures (apple, sock, book…); the others are in the English atlas. A
  sentence, a short passage, a number, the alphabet with a gap and a page of
  an information book (with the part a question asks about outlined) are
  drawn by the app. Pictures never show which answer is right.

## Parents

- Every goal has a home activity in English and Egyptian Arabic, taken from
  the companion's "Try It at Home" games and questions; the safety note is
  the companion's (page 3: an adult does any cutting).
- The guide tab shows the companion's "How to Use This Book" rules for
  English, after Science and Maths.
- Results, stars, stickers (one word per unit: fantasy, recount, rhyme…),
  the practice unit after a term challenge, sync and the web work as for
  Maths. English progress is kept under `y1.english`.

## Art (24 October 2026)

Generated in Canva Dream Lab in the owner's account (owner's approval); the
Canva connector's image tool was switched off for the team, so the prompts
were typed in Dream Lab in the owner's Chrome and each picture was saved by
the owner.

| File | What | Size |
|---|---|---|
| `assets/images/english-islands-v1.webp` | Four islands in a 2 × 2 picture: stories (book, castle, monster), tales (frog, lion, cottage), familiar places (town, park, school, jungle), charts (bar-chart hills, lighthouse) | 2048×1157, 472 KB |
| `assets/images/english-backdrops-v1.webp` | Four settings in a 2 × 2 picture: reading corner, kitchen, rainy garden, jungle | 2048×1157, 442 KB |
| `assets/images/english-words-v1.webp` | 62 word pictures, eight to a row in 256-pixel cells, in the order of `englishWords` | 2048×2048, 760 KB |
| `assets/images/english-scenes-v1.webp` | 24 story scenes (teacher review 8), four to a row in 448×252 cells, in the order of `englishScenes` | 1792×1512, 759 KB |

The word pictures were made six at a time (eleven sheets, "children's
storybook illustration… plain flat solid magenta background, no text"), the
best of Dream Lab's four versions chosen for each. `tools/images/english-atlas.cjs`
builds all three files; the magenta cut-out it shares with the Maths
everyday-objects atlas is now `tools/images/magenta-cut.cjs`. The subject
card fills its 2:1 frame from the 16:9 islands picture (a little sea is
cut at the top and bottom); the map shows each island whole.

The story scenes were made four at a time (six pictures, "four separate
children's storybook illustrations… in a 2 by 2 grid… with a thin white
gap… no text"). `tools/images/english-scenes.cjs` finds the white gaps,
cuts each picture into its four scenes and builds the atlas. A story part
shows its scene beside the text (above it on a phone); some sentence cards
show one too, and as with the word pictures, pictures never mark exactly
the right cards.

Some text uses `{name}` ("Books {name} read this week", "{name}'s day").
`Lesson.forChild` puts in the playing child's name when an English lesson
opens (or "Sam" when there is none); IDs, answers and parent activities
never contain it, and the validator checks that.

## Files

| Files | Purpose |
|---|---|
| `scripts/english_content/` | The companion's questions, answer key, page numbers, stories, Arabic home activities, by term |
| `scripts/build_english_content.py` | Builds the catalogue, 13 lessons and 13 source records; checks the PDF's SHA-256 when it is present |
| `scripts/validate_english_content.py` | Coverage (155), answers, letter tiles, titles that do not give the answer away, pictures, Arabic, catalogue order, byte-for-byte repeat build (CI) |
| `assets/content/english_catalog.json`, `assets/content/eng_*.json`, `assets/content/playable/eng_*.json` | Built content |
| `lib/features/english/` | `EnglishStage`, `EnglishVisual`, letter tiles (`WrittenWord`), the art |
| `lib/content/curriculum.dart`, `lesson.dart`, `school_years.dart`, `assets/content/years.json` | `y1.english`, the lesson list, Year 1's third subject |
| `lib/games/question_engine.dart`, `lib/features/lesson/step_rules.dart`, `lesson_player.dart` | The `word` answer; story steps read part by part |
| `lib/features/world/subject_hub.dart`, `world_map.dart`, `lib/features/biology/sticker_album.dart`, `lib/parent/` | The English card and islands, stickers, guides |
| `schemas/lesson.schema.json`, `scripts/validate_playable.py` | `letter-entry` and `word`; the English safety page |
| `test/english_test.dart` | Subject, catalogue, Arabic, pictures, spelling, story, sorting, every step on a tablet and on a phone with big text, SQLite |
| `tools/images/english-atlas.cjs`, `english-scenes.cjs`, `magenta-cut.cjs`, `assets/images/english-*.webp` | The art |

To change the content, edit `scripts/english_content/` and run
`python scripts/build_english_content.py`, then
`python scripts/validate_english_content.py --check-idempotence`.

## Checks (24 October 2026)

- `validate_english_content.py --check-idempotence` and `validate_playable.py`
  pass (703 steps in all subjects).
- `flutter analyze --fatal-infos` and `dart format` are clean.
- All 567 tests pass, including the 12 in `test/english_test.dart`: all 186
  English steps open at 1280×800 and at 390×844 with 1.5× text with no
  overflow, a spelling question is played wrong then right (after the hint),
  a story goes on only after every part is heard, and English progress
  reopens from SQLite next to Maths.
- Review images of every step (`--dart-define=REVIEW_IMAGES=true`,
  `build/review/english/`) were checked by eye. Fixed after the check: titles
  that named the answer ("Missing sounds: tree"), a story that did not fit a
  tablet, chart answers below the screen (they now sit beside the chart, as
  in Maths), unstyled sorting buttons and a missing arrow glyph, cards of
  different heights, and eight questions where only the right answer had a
  picture (the validator now refuses both kinds of give-away).
- The five golden images pass; only the tablet subjects screen changed (three
  cards in one row).

This is an AI teaching-design adaptation, not approval from a human teacher.
