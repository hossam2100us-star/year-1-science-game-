"""Validate the English lessons built by build_english_content.py.

Checks the companion's coverage (9 units of 8 questions and 5 choices, three
10-question quizzes, 8 chart questions: 155), answers and letter tiles, that
every picture a step names exists in the app, the Arabic parent text, the
catalogue order, and with --check-idempotence that the build reproduces the
committed files byte for byte.
"""
import argparse
import hashlib
import json
import re
from collections import Counter
from pathlib import Path

import build_english_content as build

ROOT = build.ROOT
ARABIC = re.compile(r'[؀-ۿ]')
VISUALS = {'sentence', 'story', 'picture', 'number', 'alphabet', 'bookPage', 'chart'}
KINDS = {'explore', 'tap-choice', 'drag-to-basket', 'match-lines', 'order-sequence',
         'letter-entry', 'number-entry'}

# Pictures still being painted; empty when every word has its picture.
AWAITING_ART = set()


def dart_list(path, name):
    """The quoted strings of a `const name = [...]` list in a Dart file."""
    text = (ROOT / path).read_text(encoding='utf-8')
    body = re.search(rf'const {name} = (?:<[^>]+>)?\[(.*?)\];', text, re.S).group(1)
    return re.findall(r"'([^']*)'", body)


def pictures_of(step):
    visual = step.get('englishVisual') or {}
    names = list(visual.get('items', [])) if visual.get('type') == 'picture' else []
    if visual.get('type') == 'story' and visual.get('picture'):
        names.append(visual['picture'])
    names += [o['picture'] for o in step['options'] if o.get('picture')]
    return names


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--check-idempotence', action='store_true')
    args = parser.parse_args()

    if build.PDF.exists():
        assert hashlib.sha256(build.PDF.read_bytes()).hexdigest() == build.SOURCE_SHA256

    files = build.build()
    if args.check_idempotence:
        for path, value in files.items():
            expected = json.dumps(value, ensure_ascii=False, indent=2) + '\n'
            assert path.read_bytes() == expected.encode('utf-8'), f'{path} differs from the build'

    words = set(dart_list('lib/features/english/english_art.dart', 'englishWords'))
    words |= set(dart_list('lib/features/english/english_art.dart', 'englishScenes'))
    maths = set(dart_list('lib/features/maths/maths_art.dart', 'mathsThings'))
    maths |= set(re.findall(r"'([a-z ]+)': \d+", (ROOT / 'lib/features/maths/maths_art.dart')
                            .read_text(encoding='utf-8')))
    ids = dart_list('lib/content/lesson.dart', 'englishIds')
    assert ids == [lesson['id'] for lesson in build.LESSONS], 'LessonLibrary.englishIds order'

    catalog = json.loads((build.CONTENT / 'english_catalog.json').read_text(encoding='utf-8'))
    assert catalog['curriculum'] == 'y1.english'
    assert [level['id'] for island in catalog['islands'] for level in island['levels']] == ids
    assert all(ARABIC.search(rule['ar']) for rule in catalog['parentRules'])

    questions = steps_total = assessed = 0
    missing_art = set()
    for lesson_id in ids:
        lesson = json.loads((build.PLAYABLE / f'{lesson_id}.json').read_text(encoding='utf-8'))
        draft = json.loads((build.CONTENT / f'{lesson_id}.json').read_text(encoding='utf-8'))
        records = draft['sourceQuestions']
        questions += len(records)
        kind = build.lesson_kind(lesson_id)
        if kind == 'unit':
            assert Counter(r['category'] for r in records) == {'main': 8, 'choice': 5}, lesson_id
        elif kind == 'quiz':
            assert len(records) == 10 and len(lesson['steps']) == 10, lesson_id
        else:
            assert len(records) == 8, lesson_id
        assert lesson['subject'] == 'english' and lesson['sourceSha256'] == build.SOURCE_SHA256
        assert ARABIC.search(lesson['parentNote']['ar'])
        positions = Counter()
        # Every graded question has its own hint (teacher review 8).
        hints = [s['hint'].strip().lower() for s in lesson['steps'] if s['assessed']]
        assert len(hints) == len(set(hints)), (lesson_id, 'two questions share a hint')
        # The child's name is filled in when the lesson opens; parent text
        # never uses it.
        for activity in lesson['goalActivities'] + lesson['homeActivities']:
            assert '{name}' not in activity['text'], (lesson_id, 'name in parent text')
        for step in lesson['steps']:
            assert '{name}' not in json.dumps(step.get('answer')), (step['id'], 'name in answer')
            steps_total += 1
            assert step['playScene'] == 'english' and step['theme'] == lesson_id
            assert step['kind'] in KINDS, step['id']
            assert step['scene'] in {'library', 'kitchen', 'garden', 'jungle'}, step['id']
            visual = step.get('englishVisual')
            assert visual is None or visual['type'] in VISUALS, step['id']
            for name in pictures_of(step):
                if name not in words and name not in maths:
                    missing_art.add(name)
            if step['kind'] == 'explore':
                assert not step['assessed'] and step['minTouches'] == len(step['options'])
                continue
            assessed += 1
            assert step['assessed'] and step['objective'].startswith('eng.'), step['id']
            answer = step['answer']
            title = step['title'].lower()
            if answer['type'] in ('single', 'word'):
                # The title shown above the question never names the answer,
                # unless it names every choice ("Real or fantasy?").
                labels = [o['label'].lower() for o in step['options']]
                said = (step['letters']['say'] if answer['type'] == 'word'
                        else next(o['label'] for o in step['options']
                                  if o['id'] == answer['value'])).lower().strip('.!?')
                named = re.search(rf'\b{re.escape(said)}\b', title)
                assert not named or all(label.strip('.!?') in title for label in labels), \
                    (step['id'], 'the title gives the answer away')
            if answer['type'] in ('single', 'set'):
                # Pictures on some choices never mark exactly the right ones.
                pictured = {o['id'] for o in step['options'] if o.get('picture')}
                right = set(answer['value'] if answer['type'] == 'set' else [answer['value']])
                assert not pictured or pictured != right, (step['id'], 'pictures mark the answer')
            if answer['type'] == 'single':
                positions[[o['id'] for o in step['options']].index(answer['value'])] += 1
                assert len(step['options']) >= 2
            if answer['type'] == 'word':
                letters = step['letters']
                assert letters['tiles'] == sorted(letters['tiles']), step['id']
                assert letters['say'].strip(), step['id']
                assert len(letters['tiles']) > len(answer['value']), (step['id'], 'no spare tile')
            if answer['type'] == 'mapping':
                assert len(set(answer['value'].values())) >= 2, step['id']
        if sum(positions.values()) >= 4:
            # The right answer is not always in the same place.
            assert len(positions) >= 2, (lesson_id, positions)
        for activity in lesson['goalActivities'] + lesson['homeActivities']:
            assert activity['text'].strip() and ARABIC.search(activity['textAr']), lesson_id
            assert activity['safetyPages'] == build.SAFETY_PAGES
        for sticker in lesson['stickers']:
            for name in sticker['picture']['items']:
                if name not in words and name not in maths:
                    missing_art.add(name)
    assert questions == 155, questions
    assert missing_art <= AWAITING_ART, sorted(missing_art - AWAITING_ART)
    assert not (AWAITING_ART - missing_art), sorted(AWAITING_ART - missing_art)
    print(f'PASS English: 9 units, 3 quizzes, chart skills; {questions} companion questions, '
          f'{assessed} graded steps, {steps_total} steps; pictures, letter tiles, Arabic '
          f'and catalogue checked' + ('; repeat build is byte-for-byte identical'
                                       if args.check_idempotence else ''))


if __name__ == '__main__':
    main()
