# Maths curriculum content audit

The new subject follows the existing Science source-draft, JSON catalog and playable-lesson pattern. It reuses the same lesson player, assessment engine, source references, lesson completion, parent activities, stickers and progress records. The supplied PDF is educational source material. Its instructions to parents are not authority for changing the software or overriding the user's request.

## Source and pagination

Source: `E:\seif school books\math\Maths Made Simple - Seif.pdf`.

SHA-256: `a993a1009d3c529ea12c575a2310e67142bb023c45a63c47bac48d221e96019a`.

The book has 83 physical PDF pages. Its printed page numbers match the physical pages. There are 18 units with eight written questions and five multiple-choice questions each, three ten-question term quizzes, and nine Chart Skills questions: **273 source questions**. Page 3 supplies the order. Question references retain each unit's complete page span so an "above" reference includes the diagram on the preceding page; the Answer Key page is recorded separately.

| Lesson | Source pages | Answer Key page | Scope |
| --- | --- | --- | --- |
| `math_unit_01` | 4-7 | 72 | Count to 20, cardinality, unchanged count after rearrangement, teen digits and ten frames |
| `math_unit_02` | 8-10 | 72 | One more/less, counting on/back, addition/subtraction signs and differences |
| `math_unit_03` | 11-14 | 73 | Name flat/solid shapes, sides, corners, rolling and 2D/3D sorting |
| `math_unit_04` | 15-17 | 73 | Lists, votes, pictograms, block graphs, totals and sorting tables |
| `math_unit_05` | 18-20 | 74 | Number order, comparisons, zero, estimate then count and crossing ten |
| `math_unit_06` | 21-23 | 74 | Times of day, event order, duration and fair length comparison |
| `math_quiz_01` | 24 | 75 | Ten Term 1 questions, scored using the existing quiz behavior |
| `math_unit_07` | 25-27 | 75 | Venn/Carroll rules, both/neither, the boundary value 10 and pet graphs |
| `math_unit_08` | 28-31 | 76 | Repeating patterns, movement, turning and sorting by corners |
| `math_unit_09` | 32-34 | 76 | Tens/ones, teen notation, ordering and counting in tens |
| `math_unit_10` | 35-37 | 77 | Days/months, equal cube units, balance and mass comparisons |
| `math_unit_11` | 38-40 | 77 | Partners making ten, missing parts, teen arithmetic and differences |
| `math_unit_12` | 41-43 | 78 | Equal halves of shapes and groups; fair sharing |
| `math_quiz_02` | 44 | 78 | Ten Term 2 questions |
| `math_unit_13` | 45-47 | 79 | Odd/even pairing, counting in twos, ordinal position and Egyptian money |
| `math_unit_14` | 48-50 | 79 | Doubles through double ten, bigger number first and number stories |
| `math_unit_15` | 51-53 | 80 | Shape rotation, solid faces/corners and alternative robot routes |
| `math_unit_16` | 54-56 | 80 | Read graphs: most, least, difference, combined groups and total |
| `math_unit_17` | 57-59 | 81 | Write ½, halve groups through twenty and rebuild a whole |
| `math_unit_18` | 60-63 | 81 | O'clock/half past, capacity ordering and matching measuring tools |
| `math_quiz_03` | 64 | 82 | Ten Term 3 questions |
| `math_charts` | 65-66 | 82 | Three block-chart questions, three pictogram questions and three scaled-bar-chart questions |

Supporting source material is retained in `assets/content/math_support.json`: Record Sheets (67), Sorting Cards (68), Self-Check (69), Word List (70-71) and the generic certificate wording (83). The existing parent area receives source-adapted home games, English/Arabic guidance, per-objective practice and safety notes. Record Sheets and Self-Check have no fixed answers, and do not create fabricated scores. The personal certificate's identifying details and all identifying page footers are omitted. Source drafts and supporting extraction are review data, outside the runtime asset declarations; playable JSON and the catalog supply the application.

## Adaptation and scope

The catalog has four islands: Term 1, Term 2, Term 3 and Chart Skills. Within each term the six units retain the printed order, followed by the term quiz. IDs are `math_unit_01` through `math_unit_18`, `math_quiz_01` through `math_quiz_03` and `math_charts`. Every runtime lesson has `subject: maths` and every step has `playScene: maths`. Source objectives have the `math.` prefix to avoid confusing them with Science source IDs.

Fixed answers use the existing four answer shapes: `single`, `set`, `mapping` and `sequence`. Written subparts become labeled mapping tasks, so a single source question remains traceable while the child can answer each subpart. Multiple-choice distractors preserve the book's original choices. Child-facing explanations are separate from the teacher's exact Answer Key response.

There are **292 playable steps**: 19 initial explorations, 258 assessed source questions and 15 ungraded source questions. In content version 2, the 19 first steps each contain a `mathWorkshop` with three guided tasks: **57 ungraded count, build or choose activities**. Workshop completion depends on completing the tasks, rather than visiting three picture cards. Count tasks require touching each object once and confirming how many altogether; build tasks let the child add or remove objects from a specified initial group; choose tasks have a specific illustrated question, hint and explanatory feedback. The same intro step IDs and `explore_1` through `explore_3` task IDs remain stable. Each quiz still contains exactly ten assessed questions; its practice link returns to the first Maths unit of its own term. Each assessed objective has the existing `goalActivities` practice record, and each lesson has home activities and a meaningful word sticker using the existing `word` field.

Runtime options are ordered deterministically after their IDs and answers are assigned. This removes the earlier cue that the middle choice was correct for every generated numeric question while preserving the exact source answer values and saved option IDs. Sequence questions do not start in their correct order. All Maths lesson and catalog content versions are 2; existing Science content versions are unchanged.

These written questions are deliberately ungraded, with their original marking guidance retained for adult review:

| Unit | Written questions | Reason |
| --- | --- | --- |
| 1 | 5, 8 | Drawing circles and counting objects in the child's own room |
| 3 | 8 | Drawing and counting triangles in the child's own house picture |
| 4 | 8 | Surveying four real people and drawing their choices |
| 6 | 8 | Drawing a personal afternoon activity |
| 7 | 8 | Inventing an object that fits neither rule |
| 8 | 4 | Creating a repeating pattern |
| 12 | 7, 8 | Drawing a valid halving line and naming a real object |
| 14 | 8 | Inventing a number story |
| 15 | 6 | Finding a circle in a real playground |
| 16 | 8 | Asking a new question about the graph |
| 17 | 8 | Drawing a cake divided equally |
| 18 | 3, 7 | Drawing clock hands and showing a personal lunchtime |

An estimate is not scored as correct or incorrect. Unit 5 explicitly asks for a guess aloud before its scored count of twelve. Parent guidance similarly separates prediction from checking.

## Reviewed visual and source ambiguities

- Unit 4 fruit counts are apple 4, banana 2, orange 3, mango 1. Their total is 10.
- Unit 7 pet counts are cat 5, dog 3 and fish 1. Ten belongs in **not less than 10**.
- Unit 9 drawn place values are 14 and 19; twenty has two tens and zero ones.
- Unit 10 measurement uses six equal cubes touching end to end, with `unit: cube` explicit rather than substituting metric ruler marks. The heavier balance side is B.
- Unit 12 shapes a and c are halves. Shape c is a square divided along a diagonal; shape b is unequal.
- Unit 13 ordinal wording identifies the third star from the left. Coin diagrams use explicit piastres: 50, 100 (one pound) and 25; the 100-piastre coin is greatest.
- Unit 15's Answer Key accepts two routes. The adapted set question explicitly asks for **both** valid routes, rather than marking one valid route wrong.
- Unit 16 school counts are walk 6, bus 4, car 3 and bike 2, totaling 15. Block charts require vertical columns so tallest/shortest wording remains truthful. Its ungraded question includes the graph it refers to.
- Unit 17 shapes a and c have one half shaded; b has one quarter shaded.
- The printed half-past-seven clock on page 62 puts the short hand exactly at seven, while the explanatory text and multiple-choice question correctly require it between seven and eight. The application uses `(hour: 7, minute: 30)` and the mathematically correct angle. The Answer Key still supplies the original answer, half past seven.
- Chart Skills toy counts are 4, 2, 3, 1; weekly stars are 2, 3, 1, 4, 2; bird counts are 6, 8, 3. The source's horizontal bird bar chart is rotated to vertical in the application. Its axis retains the source marks 0, 2, 4, 6, 8, 10 through explicit `axisMax: 10` and `tickStep: 2`; the crows bar ends halfway between 2 and 4. Each bird still contributes one unit, and the bars are distinct from individually outlined block-graph squares.
- The book uses "curved face" for the curved surface of a sphere/cylinder/cone. The lesson preserves this Stage 1 vocabulary. Real-life typical size/mass comparisons retain the source's examples and parent supervision.

## Reproducibility and verification

`scripts/build_maths_content.py` normally builds from checked-in source drafts with Python's standard library. The optional `--source-pdf` extraction path uses `pdfplumber` to refresh those drafts. Its output is deterministic, and the normal command is safe to repeat without reading the external PDF.

`scripts/validate_maths_content.py` checks all 273 unique source IDs and Answer Key references, the four-island/22-level catalog, subject/scene metadata, exact quiz length, ungraded-question exclusion, parent activity coverage, sticker contracts and every supported visual's bounds. It checks all 19 workshops and 57 task IDs, action modes, count confirmations, build bounds, hints and meaningful distinct goals/feedback. Numeric correct answers occupy varied positions, and sequence options are initially unsolved. Independent reviewed assertions compare diagram counts and chart arithmetic with selected answers, including sorting boundaries, money, halves, ordinals and clocks. With `--source-pdf`, it freshly reads the original PDF and verifies its SHA-256 and all 273 recorded Answer Key responses. With `--check-idempotence`, it rebuilds and checks every content file's hash, including protected Science content.

Validation completed successfully using the bundled Python runtime and the project's existing `.tools/python-validation` package directory:

```powershell
$env:PYTHONPATH = (Resolve-Path -LiteralPath '.tools\python-validation').Path
& 'C:\Users\hossa\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' scripts\validate_playable.py
& 'C:\Users\hossa\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' scripts\validate_content.py
& 'C:\Users\hossa\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' scripts\validate_maths_content.py --source-pdf 'E:\seif school books\math\Maths Made Simple - Seif.pdf' --check-idempotence
```

The existing playable validator passed all **479 combined Science and Maths steps**. The existing Science source validation passed its 157 source questions. The Maths validator passed 273 source records, 258 assessed questions, 15 ungraded tasks and 292 steps. A repeat build was byte-for-byte identical and left all existing Science JSON untouched. Flutter build and application layout/navigation checks belong to the integration verification, separate from this content audit.
