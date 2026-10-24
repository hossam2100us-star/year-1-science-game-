"""Build the Year 1 English lessons from the parent companion "English Made Easy".

The companion (56 pages: 9 units, 3 term quizzes, chart skills, answer key)
was written by the family to follow Cambridge Primary English, Stage 1. It is
kept only in the local, git-ignored curriculum/ folder. Its questions,
answer key and page numbers are recorded by hand in english_content/; the
stories are the companion's own short retellings, never the class book's
text.

Owner decisions (23 October 2026): every question is answered in the app
(written and drawing tasks become a graded question on the same skill, and
the original task is the goal's home activity); the verbs booklet is left
out; English words and sentences are read by the device voice, never
isolated letter sounds.

Run from the repository root: python scripts/build_english_content.py
"""
import hashlib
import json
from pathlib import Path

from english_content import term1, term2, term3

ROOT = Path(__file__).resolve().parents[1]
CONTENT = ROOT / 'assets/content'
PLAYABLE = CONTENT / 'playable'
PDF = ROOT / 'curriculum/english/English Made Easy - Seif Hossam Nader.pdf'

# SHA-256 of the companion PDF. The PDF is not in Git; when it is present the
# build and the validator check this value against it.
SOURCE_SHA256 = 'dd379dbfa0337f8012b463d4f8e5327429d7c78371f8824908fd13cbf9c92fd1'
CONTENT_VERSION = 1

# The companion's safety note (page 3).
SAFETY = ('An adult supervises. An adult does any cutting: cut plastic has '
          'sharp edges, so cover them with tape.')
SAFETY_AR = ('لازم شخص كبير يكون موجود. الكبير هو اللي يقص: البلاستيك المقصوص '
             'حروفه حادة، فغطّوها بشريط لاصق.')
SAFETY_PAGES = [3]

PARENT_NOTE = {
    'en': 'Every question is answered in the app. Each goal has a short home '
          'activity: say the words aloud together, and let your child guess '
          'first.',
    'ar': 'كل الأسئلة الطفل بيحلها جوه البرنامج، ولكل هدف نشاط قصير في البيت. '
          'قولوا الكلمات بصوت عالي مع بعض، وسيبوا طفلك يتوقع الأول.',
}

LESSONS = [
    term1.UNIT_01, term1.UNIT_02, term1.UNIT_03, term1.QUIZ_01,
    term2.UNIT_04, term2.UNIT_05, term2.UNIT_06, term2.QUIZ_02,
    term3.UNIT_07, term3.UNIT_08, term3.UNIT_09, term3.QUIZ_03,
    term3.CHARTS,
]

# The quiz of each term sends a child who wants more practice back to the
# term's first unit, as in Maths.
PRACTICE_UNIT = {'eng_quiz_01': 'eng_unit_01', 'eng_quiz_02': 'eng_unit_04',
                 'eng_quiz_03': 'eng_unit_07'}

ISLANDS = [
    ('English Island: Term 1', 'جزيرة الإنجليزي: الفصل 1', 'FF3E7FC1',
     ['eng_unit_01', 'eng_unit_02', 'eng_unit_03', 'eng_quiz_01']),
    ('English Island: Term 2', 'جزيرة الإنجليزي: الفصل 2', 'FFD9822B',
     ['eng_unit_04', 'eng_unit_05', 'eng_unit_06', 'eng_quiz_02']),
    ('English Island: Term 3', 'جزيرة الإنجليزي: الفصل 3', 'FF3E9B5A',
     ['eng_unit_07', 'eng_unit_08', 'eng_unit_09', 'eng_quiz_03']),
    ('Chart Skills Island', 'جزيرة مهارات الرسوم', 'FF5B4BA8', ['eng_charts']),
]

# The companion's "How to Use This Book" (page 2) and its safety note.
PARENT_RULES = [
    ('Ten to fifteen minutes is enough. Stop while your child is still enjoying it.',
     'عشر لربع ساعة كفاية. وقّفوا وطفلك لسه مبسوط.', 2),
    ('Let your child say it first: ask "What do you think?" before you explain.',
     'سيب طفلك يقول الأول: اسأله "إنت رأيك إيه؟" قبل ما تشرح.', 2),
    ('Say words, do not just spell them: say the word, stretch the sounds, clap it, then write it.',
     'قولوا الكلمات، متتهجّوهاش بس: قول الكلمة، مطّ أصواتها، صقّفها، وبعدين اكتبها.', 2),
    ('Praise the effort, not the neatness: "You listened for every sound!"',
     'امدح المجهود مش الخط الحلو: "إنت سمعت كل صوت!"', 2),
    (SAFETY, SAFETY_AR, 3),
]


def lesson_kind(lesson_id):
    if lesson_id.startswith('eng_unit_'):
        return 'unit'
    return 'quiz' if lesson_id.startswith('eng_quiz_') else 'charts'


def objective_id(lesson_id, category, n):
    kind = lesson_kind(lesson_id)
    if kind == 'unit':
        return f'eng.u{lesson_id[-2:]}.{category}.{n:02d}'
    if kind == 'quiz':
        return f'eng.q{lesson_id[-1]}.{n:02d}'
    return f'eng.charts.{n:02d}'


def short_of(part):
    short = part.get('short') or part['explanation']
    if len(short.split()) > 16:
        raise ValueError(f"{part['title']}: the explanation needs a short form")
    return short


def source(lesson, objective=None, key=''):
    return {'pages': lesson['pages'], 'questionId': objective,
            'answerKeyPages': lesson['key_pages'] if objective else [],
            'answerKeyText': key, 'sourceSha256': SOURCE_SHA256}


def card_option(index, card):
    """A story part or big-idea card: its text, or (text, picture)."""
    text, picture = card if isinstance(card, tuple) else (card, None)
    option = {'id': f'card_{index + 1}', 'label': text, 'art': 'eng_card'}
    if picture:
        option['picture'] = picture
    return option


def explore_step(lesson, index, part):
    step = {
        'id': f"{lesson['id']}.step.{index:03d}", 'kind': 'explore',
        'title': part['title'], 'prompt': part['prompt'],
        'options': [card_option(i, card) for i, card in enumerate(part['cards'])],
        'targets': [], 'answer': None, 'assessed': False, 'objective': '',
        'hint': 'Tap each card to listen.',
        'explanation': part['explanation'],
        'shortExplanation': short_of(part),
        'source': source(lesson), 'scene': lesson['scene'],
        'section': 'Explore', 'playScene': 'english', 'theme': lesson['id'],
        'minTouches': len(part['cards']),
    }
    if part.get('visual'):
        step['englishVisual'] = part['visual']
    return step


def question_step(lesson, index, part, objective, key, section):
    step = {
        'id': f"{lesson['id']}.step.{index:03d}", 'kind': part['kind'],
        'title': part['title'], 'prompt': part['prompt'],
        'options': part['options'], 'targets': part['targets'],
        'answer': part['answer'], 'assessed': True, 'objective': objective,
        'hint': part['hint'], 'explanation': part['explanation'],
        'shortExplanation': short_of(part),
        'source': source(lesson, objective, key), 'scene': lesson['scene'],
        'section': section, 'playScene': 'english', 'theme': lesson['id'],
    }
    if part.get('letters'):
        step['letters'] = part['letters']
    if part.get('visual'):
        step['englishVisual'] = part['visual']
    return step


def activity(lesson, text, text_ar, objective=None):
    return {**({'objective': objective} if objective else {}),
            'text': text, 'textAr': text_ar,
            'safety': SAFETY, 'safetyAr': SAFETY_AR,
            'pages': lesson['pages'], 'safetyPages': SAFETY_PAGES,
            'adapted': True}


def build_lesson(lesson):
    steps, goals, records = [], [], []
    for part in lesson.get('explore', []):
        steps.append(explore_step(lesson, len(steps) + 1, part))
    quiz = lesson.get('quiz', False)
    groups = [('main', lesson['questions'], 'Challenge' if quiz else 'Discover'),
              ('choice', lesson.get('choices', []), 'Practice')]
    for category, questions, section in groups:
        for question in questions:
            objective = objective_id(lesson['id'], category, question['number'])
            records.append({
                'id': objective, 'category': 'quiz' if quiz else category,
                'number': question['number'], 'sourceText': question['text'],
                'answerKeyText': question['key'],
                'sourcePages': lesson['pages'],
                'answerKeyPages': lesson['key_pages'],
            })
            for part in question['steps']:
                steps.append(question_step(lesson, len(steps) + 1, part,
                                           objective, question['key'], section))
            goals.append(activity(lesson, question['home'],
                                  question['home_ar'], objective))
    stickers = []
    if lesson.get('sticker'):
        word, meaning, art = lesson['sticker']
        stickers.append({
            'id': f"{lesson['id']}.sticker", 'word': word, 'art': 'eng_word',
            'picture': {'type': 'picture', 'items': [art]},
            'meaning': meaning, 'meaningSource': 'adapted_from_big_idea',
            'sourcePages': lesson['pages'],
        })
    playable = {
        'schemaVersion': 1, 'contentVersion': CONTENT_VERSION,
        'id': lesson['id'], 'subject': 'english', 'title': lesson['title'],
        'quiz': quiz, 'sourcePages': lesson['pages'],
        'sourceSha256': SOURCE_SHA256, 'parentNote': PARENT_NOTE,
        'steps': steps, 'stickers': stickers, 'goalActivities': goals,
        'homeActivities': [activity(lesson, *lesson['home'])],
    }
    if quiz:
        playable['practiceUnitId'] = PRACTICE_UNIT[lesson['id']]
    draft = {
        'schemaVersion': 1, 'contentVersion': CONTENT_VERSION,
        'id': lesson['id'], 'subject': 'english',
        'kind': lesson_kind(lesson['id']), 'term': lesson['term'],
        'title': lesson['title'], 'ar': lesson['ar'],
        'sourcePages': lesson['pages'], 'sourceSha256': SOURCE_SHA256,
        'status': 'adapted_for_the_app', 'sourceQuestions': records,
    }
    return playable, draft


def level(lesson):
    entry = {'id': lesson['id'], 'title': lesson['title'], 'ar': lesson['ar']}
    if lesson.get('quiz'):
        entry['quiz'] = True
    return entry


def catalog():
    by_id = {lesson['id']: lesson for lesson in LESSONS}
    return {
        'schemaVersion': 1, 'contentVersion': CONTENT_VERSION,
        'subject': 'english', 'curriculum': 'y1.english',
        'title': 'English', 'ar': 'الإنجليزي',
        'welcome': 'Welcome to English Island! Start with a story in Term 1.',
        'sourcePages': [2, 3],
        'islands': [
            {'title': title, 'ar': ar, 'color': color,
             'levels': [level(by_id[i]) for i in ids]}
            for title, ar, color, ids in ISLANDS
        ],
        'parentRules': [{'en': en, 'ar': ar, 'sourcePage': page}
                        for en, ar, page in PARENT_RULES],
    }


def write(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n',
                    encoding='utf-8', newline='\n')


def build():
    """Every file this script writes, by path."""
    files = {CONTENT / 'english_catalog.json': catalog()}
    for lesson in LESSONS:
        playable, draft = build_lesson(lesson)
        files[PLAYABLE / f"{lesson['id']}.json"] = playable
        files[CONTENT / f"{lesson['id']}.json"] = draft
    return files


def main():
    if PDF.exists():
        digest = hashlib.sha256(PDF.read_bytes()).hexdigest()
        if digest != SOURCE_SHA256:
            raise SystemExit(f'{PDF.name} changed: {digest}')
    files = build()
    for path, value in files.items():
        write(path, value)
    steps = sum(len(v['steps']) for p, v in files.items() if p.parent == PLAYABLE)
    print(f'Wrote {len(files)} files, {steps} English steps')


if __name__ == '__main__':
    main()
