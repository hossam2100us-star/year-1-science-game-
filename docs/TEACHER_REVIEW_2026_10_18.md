# Teacher review 7 — 18 October 2026 (after review 6)

> **ملخص لولي الأمر:** كل ملاحظات المراجعة السادسة اتصلحت، ومنها مشكلة ضياع بيانات أول تشغيل. جربتها على ٥ ملفات جديدة والحفظ اشتغل كل مرة. البرنامج كله بقى ٩ من ١٠، وجاهز لتجربة مع طفل حقيقي. المتبقي ملاحظات صغيرة. الملف ده مكتوب بالإنجليزي عشان المطور يشتغل منه على طول.

Seventh teaching review of My School Adventures (formerly Science Adventure), following
[TEACHER_REVIEW_2026_10_17.md](TEACHER_REVIEW_2026_10_17.md).

## How this was tested

- Revision: `main` at `4d24b6a` (PRs #10, #11 and #12 merged).
- Flutter 3.47.5 web release build (`--no-web-resources-cdn`), Chromium via Playwright,
  1280×800 landscape. The **unchanged** build was used for saving and restart tests; a local
  copy with locks opened and a test-only `?jump=` parameter was used to open single questions.
  The repository was not changed.
- **Not tested:** audible playback, a physical tablet, the login page with a server, and a real child.

## Scores

| | Review 6 (17 Oct) | **Review 7** |
|---|---|---|
| Science | 8.5 | **9** |
| Maths | 8.5 | **9** |
| Whole app | 8.5 (blocked by the save bug) | **9** |

## Review 6 items — status

- [x] **First web launch loses progress.** Fixed. Five fresh browser profiles: onboarding only,
      onboarding with a 1 s wait, with a 3 s wait, with no wait, and onboarding plus a lesson
      with three counted apples. After closing and reopening, all five showed "Who is playing?"
      with the profile, and the lesson resumed with exactly 3 apples counted.
- [x] Chart and pictogram answers below the screen: answers now sit beside the chart
      (`math_charts.step.008`, `math_unit_04.step.002`, `math_unit_16.step.002`).
- [x] Socket picture: one whole wall with a real socket, the child stands back.
- [x] Balance question: "Look at the balance. Which side is heavier, A or B?"
- [x] Counting workshop hint: "You counted them all. The last number you said tells how many."
- [x] "Delete profile" moved from the child's card to the parent area.
- [x] Robot routes: choosing a route draws it on the grid, and the robot moves to where it ends.
- [~] Two-option questions: still 17 in Maths (unchanged since review 6).

## New findings (all low)

- [ ] `math_unit_16` charts: only "car" has a picture under its bar; walk, bus and bike have
      none. Give every row a picture, or none.
- [ ] The app is renamed My School Adventures, but the IndexedDB box is still
      `science_adventure_v1`. Keep it as is (renaming would lose saves); noted only so nobody
      renames it later.

## Ready for a child trial

The blocking issue is fixed. Suggested supervised session, 20 minutes on the tablet, without
helping:

1. The child opens the app alone, types or skips the name, and starts Maths.
2. Plays Numbers to 20. Note each time the child stops and looks for help, and each tap that
   does nothing.
3. Close and reopen the app: are the name and progress there?
4. Ask: what did you like most? What was hard? What would you tell a friend? Do you want to
   play again tomorrow?
5. Most telling: does the child come back to it the next day without being asked?

Also run the same restart check on the Android tablet (fresh install, onboarding, force-close,
reopen) before the trial.
