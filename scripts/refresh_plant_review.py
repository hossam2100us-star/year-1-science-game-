"""Apply presentation improvements without changing IDs or saved evidence."""
import json
from pathlib import Path

def refresh_plant_review(book):
    for step in book['steps']:
        if step.get('experiment') == 'bean':
            step['playUi']['predict'] = 'Make a guess, then water the bean.'
            step['playUi']['saveError'] = 'Could not save yet. Please try again.'
        elif step.get('experiment') == 'light':
            step['playUi']['saveError'] = 'Could not save yet. Tap to try again. Your last saved step is safe.'
    if book.get('contentVersion') == 2:
        book['previousStepIdsV2'] = [s['id'] for s in book['steps']]
        removed = {f'unit_02.step.{n:03}' for n in range(2, 6)}
        book['steps'] = [s for s in book['steps'] if s['id'] not in removed]
        book['contentVersion'] = 3
    intro = book['steps'][0]
    intro['title'] = 'Plant parts'
    intro['prompt'] = 'Touch a hand button to discover a plant part. Follow its line to the part.'
    if book.get('contentVersion') == 3:
        book['previousStepIdsV3'] = [s['id'] for s in book['steps']]
        build = book['steps'][1]
        build.update(kind='free-plant', title='Build your plant',
            prompt='Build a plant in the pot. Choose a piece, then touch where it belongs, or drag it there.',
            options=[next(o for o in intro['options'] if o['id'] == id).copy()
                     for id in ['flower', 'roots', 'leaf', 'stem']],
            targets=[], answer=None, minTouches=4, buildChallenge=True,
            partDescriptions=intro['partDescriptions'].copy(),
            playInstruction='Build the whole plant. Watch each part come to life.',
            completionText='You built a whole plant!',
            retryText='Try another place for this part.')
        removed = {f'unit_02.step.{n:03}' for n in range(7, 10)}
        book['steps'] = [s for s in book['steps'] if s['id'] not in removed]
        book['contentVersion'] = 4
    fridge = next(s for s in book['steps'] if s['id'] == 'unit_02.fridge.v2')
    order = ['rice', 'carrot', 'lettuce', 'celery', 'beans', 'broccoli',
             'mint', 'radish', 'peas', 'sugar_cane', 'parsley', 'lentils', 'cauliflower']
    options = {o['id']: o for o in fridge['options']}
    fridge['options'] = [options[key] for key in order]
    workshop = next(s for s in book['steps'] if s['id'] == 'unit_02.step.032')
    workshop['prompt'] = 'Make your own plant. Choose a piece, then touch a hand button where it belongs. You can drag the piece there too.'
    workshop['retryText'] = 'Try another place for this part.'
    builder = next(s for s in book['steps'] if s['id'] == 'unit_02.step.006')
    builder['prompt'] = 'Build a plant in the pot. Choose a piece, then touch a hand button where it belongs, or drag it there.'

    from refine_teacher_review import refine_teacher_review
    refine_teacher_review(book)
    from refine_latest_teacher_review import refine_latest_teacher_review
    refine_latest_teacher_review(book)

if __name__ == '__main__':
    path = Path(__file__).resolve().parents[1] / 'assets/content/playable/unit_02.json'
    book = json.loads(path.read_text(encoding='utf-8'))
    refresh_plant_review(book)
    path.write_text(json.dumps(book, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
