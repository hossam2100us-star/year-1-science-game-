"""Content build guard: teacher notes stay in source provenance, not feedback."""
import copy
import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))
from child_feedback import apply_child_feedback, feedback_issues


class ChildFeedbackTest(unittest.TestCase):
    def test_rejects_report_examples_and_allows_child_explanations(self):
        for text in [
            'a) materials b) objects',
            'a) TRUE b) FALSE c) TRUE d) FALSE',
            'quieter and fainter (accept: softer, harder to hear)',
            "Child's own answers. Pushes: pressing a switch.",
            'Any two: eye, ear.',
            'a) ✗ b) ✓',
            'glass', 'pull.', 'Neil',
        ]:
            with self.subTest(text=text):
                self.assertTrue(feedback_issues(text))
        for text in [
            'A spoon is an object. Metal is its material.',
            'A sound gets quieter as you move away.',
            'An astronomer studies stars and planets.',
            'Glass lets light through, so you can see outside.',
        ]:
            with self.subTest(text=text):
                self.assertEqual(feedback_issues(text), [])

    def test_editorial_overrides_cannot_change_sources_or_grading(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            file = root / 'unit_04.json'
            book = {'id': 'unit_04', 'steps': [{
                'id': 'unit_04.step.002', 'assessed': True,
                'objective': 'u04.main.01', 'explanation': 'a) materials b) objects',
                'answer': {'type': 'mapping', 'value': {'spoon': 'objects'}},
                'source': {'answerKeyText': 'a) materials b) objects'},
            }]}
            original = copy.deepcopy(book)
            file.write_text(json.dumps({'unit_04.step.002': {
                'explanation': 'A spoon is an object. Metal is its material.'
            }}), encoding='utf-8')
            apply_child_feedback(book, strict=True, directory=root)
            for field in ['source', 'answer', 'assessed', 'objective']:
                self.assertEqual(book['steps'][0][field], original['steps'][0][field])
            file.write_text(json.dumps({'unit_04.step.002': {
                'answer': {'value': 'changed'}
            }}), encoding='utf-8')
            with self.assertRaises(ValueError):
                apply_child_feedback(book, directory=root)

    def test_final_build_rejects_stale_override_ids(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / 'unit_04.json').write_text(json.dumps({'removed.step': {
                'explanation': 'Glass lets light through.'
            }}), encoding='utf-8')
            with self.assertRaises(ValueError):
                apply_child_feedback({'id': 'unit_04', 'steps': []}, strict=True, directory=root)


if __name__ == '__main__':
    unittest.main()
