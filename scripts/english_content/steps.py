"""Step builders for the English lessons: each returns the parts of a step
that differ by question type; build_english_content.py adds the rest."""


# ---- Step builders -------------------------------------------------------
# Each returns the parts of a step that differ by question type. build()
# adds the IDs, the source record and the shared fields.

def _options(labels, pictures=None):
    pictures = pictures or {}
    return [
        {'id': f'choice_{i + 1}', 'label': label, 'art': 'eng_word',
         **({'picture': pictures[label]} if label in pictures else {})}
        for i, label in enumerate(labels)
    ]


def _id_of(options, label):
    return next(o['id'] for o in options if o['label'] == label)


def choice(title, prompt, labels, answer, hint, explanation, *, short=None,
           visual=None, pictures=None):
    options = _options(labels, pictures)
    return dict(kind='tap-choice', title=title, prompt=prompt,
                options=options, targets=[],
                answer={'type': 'single', 'value': _id_of(options, answer)},
                hint=hint, explanation=explanation, short=short,
                visual=visual)


def multi(title, prompt, labels, answers, hint, explanation, *, short=None,
          visual=None, pictures=None):
    options = _options(labels, pictures)
    return dict(kind='tap-choice', title=title, prompt=prompt,
                options=options, targets=[],
                answer={'type': 'set',
                        'value': [_id_of(options, a) for a in answers]},
                hint=hint, explanation=explanation, short=short,
                visual=visual)


def sort(title, prompt, items, targets, hint, explanation, *, short=None,
         visual=None, pictures=None, kind='drag-to-basket'):
    """[items] are (label, target label) pairs, in the order shown."""
    options = _options([label for label, _ in items], pictures)
    target_records = [
        {'id': f'target_{i + 1}', 'label': label, 'art': 'eng_word'}
        for i, label in enumerate(targets)
    ]
    return dict(kind=kind, title=title, prompt=prompt, options=options,
                targets=target_records,
                answer={'type': 'mapping', 'value': {
                    _id_of(options, label): _id_of(target_records, target)
                    for label, target in items}},
                hint=hint, explanation=explanation, short=short,
                visual=visual)


def match(title, prompt, items, targets, hint, explanation, **extra):
    return sort(title, prompt, items, targets, hint, explanation,
                kind='match-lines', **extra)


def order(title, prompt, correct, shown, hint, explanation, *, short=None,
          visual=None):
    """[shown] is the order of the cards on the screen."""
    assert sorted(correct) == sorted(shown) and correct != shown
    options = _options(shown)
    return dict(kind='order-sequence', title=title, prompt=prompt,
                options=options, targets=[],
                answer={'type': 'sequence',
                        'value': [_id_of(options, c) for c in correct]},
                hint=hint, explanation=explanation, short=short,
                visual=visual)


def spell(title, prompt, answer, tiles, hint, explanation, *, before='',
          after='', say=None, short=None, visual=None):
    """The child writes [answer] with letter [tiles] between [before] and
    [after]: "tr" + "ee". [say] is the whole word the voice reads."""
    pool = list(tiles)
    for letter in answer:
        pool.remove(letter)  # every answer letter has its own tile
    return dict(kind='letter-entry', title=title, prompt=prompt, options=[],
                targets=[], answer={'type': 'word', 'value': answer},
                letters={'before': before, 'after': after,
                         # In alphabetical order, so the tiles never spell the
                         # answer out.
                         'tiles': sorted(tiles),
                         'say': say or f'{before}{answer}{after}'},
                hint=hint, explanation=explanation, short=short,
                visual=visual)


def number(title, prompt, answer, hint, explanation, *, short=None,
           visual=None):
    return dict(kind='number-entry', title=title, prompt=prompt, options=[],
                targets=[], answer={'type': 'number', 'value': answer},
                hint=hint, explanation=explanation, short=short,
                visual=visual)


def sentence(text):
    return {'type': 'sentence', 'text': text}


def story(title, text, picture=None):
    return {'type': 'story', 'title': title, 'text': text,
            **({'picture': picture} if picture else {})}


def picture(*items):
    return {'type': 'picture', 'items': list(items)}


def page(highlight):
    """An information book page with one part outlined."""
    return {'type': 'bookPage', 'highlight': highlight}


def explore(title, prompt, cards, explanation, *, visual=None):
    return dict(kind='explore', title=title, prompt=prompt,
                cards=cards, explanation=explanation, visual=visual)


def Q(number_in_book, text, key, steps, home, home_ar):
    """One companion question: its text and answer key, the app's steps for
    it, and the goal's home activity in English and Egyptian Arabic."""
    return dict(number=number_in_book, text=text, key=key,
                steps=steps if isinstance(steps, list) else [steps],
                home=home, home_ar=home_ar)
