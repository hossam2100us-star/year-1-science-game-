"""Child-facing editorial feedback, separate from the book's exact answer keys."""
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OVERRIDES = ROOT / 'scripts/child_feedback'


def feedback_issues(text):
    """Reject recognisable teacher notes and answer-only fragments, not vocabulary."""
    issues = []
    if not text.strip():
        return ['empty explanation']
    if re.search(r'\b[a-z]\)', text, re.IGNORECASE):
        issues.append('lettered answer key')
    if re.search(r'\baccept\s*:', text, re.IGNORECASE):
        issues.append('teacher acceptance note')
    if re.search(r"\b(?:any (?:one|two|three|four)|child[’']s own answers?)\b", text, re.IGNORECASE):
        issues.append('teacher marking instruction')
    if re.search(r'[✓✗✔✘]', text):
        issues.append('tick/cross answer key')
    if len(re.findall(r"[A-Za-z0-9]+(?:['’-][A-Za-z0-9]+)*", text)) < 2:
        issues.append('answer without an explanation')
    if re.search(r'[\u0600-\u06ff]', text):
        issues.append('child explanation must be English')
    return issues


def load_overrides(lesson_id, directory=OVERRIDES):
    path = directory / f'{lesson_id}.json'
    if not path.exists():
        return {}
    overrides = json.loads(path.read_text(encoding='utf-8'))
    if not isinstance(overrides, dict):
        raise ValueError(f'{path}: expected a map of step IDs')
    for step_id, fields in overrides.items():
        if not isinstance(fields, dict) or not fields or set(fields) - {'hint', 'explanation'}:
            raise ValueError(f'{path}: {step_id} may change only hint/explanation')
        for field, value in fields.items():
            if not isinstance(value, str) or not value.strip():
                raise ValueError(f'{path}: {step_id}.{field} must be nonempty text')
            if field == 'explanation' and feedback_issues(value):
                raise ValueError(f'{path}: {step_id}: {feedback_issues(value)}')
    return overrides


def apply_child_feedback(book, *, strict=False, directory=OVERRIDES):
    overrides = load_overrides(book['id'], directory)
    steps = {step['id']: step for step in book['steps']}
    missing = set(overrides) - set(steps)
    # Intermediate generators still contain pre-compaction IDs. The final CLI
    # and validator require every editorial entry to match a current activity.
    if strict and missing:
        raise ValueError(f"{book['id']}: unknown feedback steps: {sorted(missing)}")
    for step_id, fields in overrides.items():
        if step_id in steps:
            steps[step_id].update(fields)
    return len(set(overrides) & set(steps))


if __name__ == '__main__':
    for path in sorted((ROOT / 'assets/content/playable').glob('*.json')):
        book = json.loads(path.read_text(encoding='utf-8'))
        count = apply_child_feedback(book, strict=True)
        from refine_latest_teacher_review import refine_latest_teacher_review
        refine_latest_teacher_review(book)
        path.write_text(json.dumps(book, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
        print(f'{book["id"]}: {count} editorial entries applied')
