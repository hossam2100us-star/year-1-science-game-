"""Apply source-preserving corrections from the September teaching review."""
import json
from pathlib import Path

HINTS = {
 'unit_02.step.025': 'Think about roots taking in water, the stem holding the plant up, and leaves making food.',
 'unit_02.step.027': 'Remember what both plants received, and what was missing in the cupboard.',
 'unit_02.step.028': 'Compare the colour, strength and height of the two plants after nine days.',
 'unit_02.step.037': 'Remember the leaves in the light experiment and the water given to the plant.',
 'unit_02.step.033': 'Think about how the bean changed when it had water. What if water stops?',
 'unit_03.eye-workshop.v2': 'Find the hairs above the eye, the hairs along its edge, and the part that closes.',
 'unit_03.sense-partners.v2': 'Think about the body part you use for each discovery.',
 'unit_03.sense-stories.v2': 'Imagine doing each action. Would you listen, look, smell, taste or touch?',
 'unit_03.marbles.v2': 'Compare the numbers of marbles. Find the largest and smallest numbers.',
 'unit_03.sense-lab.v2': 'Think about how each sense helps: listening, looking, smelling, tasting or feeling.',
 'unit_03.step.041': 'Remember which sense the optometrist checks.',
 'unit_03.step.043': 'Think about the flavour of the apple and its smell.',
 'unit_03.last-discoveries.v2': 'Think about the body part doing each job.',
}

def refine_teacher_review(book):
    for s in book['steps']:
        if book['id'] == 'unit_04' and s.get('lab') == 'waterproof':
            s['observationUi'] = {
                'review': 'Look again',
                'changed': 'The result was different from your prediction. Let us look again!',
                'question': 'What did the water test show?',
                'retry': 'Look at the water and the result above. What happened?',
                'complete': 'You noticed what happened! Keep exploring.',
            }
        if book['id'] == 'unit_04' and s['assessed']:
            s['correctionUi'] = {
                'review': 'Look at this choice again',
                'start': 'Now try it yourself. Change your choices using these clues:',
                'retry': 'Keep trying. Use the discovery to help you.',
                'complete': 'You did it yourself! You can keep exploring.',
                'check': 'Check my practice',
            }
        short_prompts = {
            'unit_02.step.001': 'Touch each hand to discover plant parts.',
            'unit_02.step.006': 'Build your plant. Touch or drag pieces.',
            'unit_02.step.032': 'Make your own plant.',
            'unit_03.step.001': 'Touch a hand. Discover a body part.',
            'unit_03.body-workshop.v2': 'Match names to body parts.',
            'unit_03.eye-workshop.v2': 'Name the three eye protectors.',
            'unit_04.step.003': 'Sort objects into material drawers.',
            'unit_04.step.007': 'Pack every waterproof material.',
        }
        if s['id'] in short_prompts:
            s.setdefault('spokenPrompt', s['prompt'])
            s['prompt'] = short_prompts[s['id']]
        if s.get('workshop'):
            s['workshop']['sort'] = 'Touch an object, then a drawer.'
            s['workshop']['discover'] = 'Touch every hand. Discover each material.'
        if s['id'] in HINTS:
            s['hint'] = HINTS[s['id']]
        if s['id'] == 'unit_03.marbles.v2':
            s['title'] = 'Compare the marbles'
            s['prompt'] = 'Who holds most marbles? Who holds fewest?'
            s['explanation'] = 'Zara holds the most: 9 marbles. Jack holds the fewest: 5 marbles. David holds 6.'
            for option in s['options']:
                option['label'] = option['label'].replace('Biggest hand', 'Most marbles').replace('Smallest hand', 'Fewest marbles')
        if book['id'] == 'unit_08' and s['kind'] == 'order-sequence':
            s['prompt'] = 'Order the water places as this book shows.'
            if not s['explanation'].startswith('In this book'):
                s['explanation'] = 'In this book, the example order is: ' + s['explanation']
        if s['id'] == 'unit_08.step.013':
            # Keep the old answer IDs for saves; accept either equivalent noun.
            s['answer']['aliases'] = {'rock': 'rocks'}
            for option in s['options']:
                if option['id'] == 'coal_comes_from':
                    option['label'] = 'Coal is a type of…'
        if s['id'] == 'unit_04.step.002':
            s['prompt'] = 'Sort objects and materials.'
            for o in s['options']:
                if o['id'] == 'things_a_spoon_and_a_chair':
                    o['label'] = 'Spoon and chair'
                else:
                    o['label'] = 'Metal and wood'
                    o['art'] = 'wood'
        if book['id'] == 'unit_04':
            missions = {
                'unit_04.step.007': ('pack', 'Touch a sample to pack or unpack it. You can also drag it into the bag.'),
                'unit_04.step.009': ('squash', 'Touch an object, then a tray. You can move it again before checking.'),
                'unit_04.step.010': ('window', 'Look at the whole window. Choose the reason that makes it useful.'),
                'unit_04.step.011': ('pencil', 'Look at this pencil. Collect two material samples.'),
                'unit_04.step.013': ('missions', 'Touch a hand in the workshop, then choose a discovery below.'),
            }
            if s['id'] in missions:
                mode, instruction = missions[s['id']]
                s['workshop']['mode'] = mode
                s['workshop']['instruction'] = instruction
                s['workshop']['packed'] = 'My rain kit'
                s['workshop']['empty'] = 'Choose your materials'
                s['workshop']['remove'] = 'Touch a packed sample to take it out.'
            if s['id'] == 'unit_04.step.007':
                samples = {'plastic': 'plastic', 'cotton_cloth': 'fabric', 'paper': 'paper_sheet'}
                for o in s['options']:
                    o['art'] = samples.get(o['id'], o['art'])
            if s['id'] == 'unit_04.step.011':
                for o in s['options']:
                    o['art'] = o['id']
                s['explanation'] = 'This plain writing pencil has a wooden body and a graphite writing core.'
            if s['id'] == 'unit_04.step.008':
                s['prompt'] = 'Choose an object. Predict, then try an action.'
                s['labUi'].update({
                    'predict': 'Will its shape change?',
                    'choices': {'change': 'It will change', 'same': 'It will stay the same'},
                    'try': 'Try the action',
                    'progress': 'Actions tried',
                    'comparison': 'Results compared',
                    'changed': 'Its shape changed.', 'same': 'It kept its shape.',
                    'instruction': 'Try all four actions. Try a soft object and a hard object too.',
                })
                # Source examples: dough, band, sponge, spoon, straw and stone.
                # Unsupported actions are not offered as invented simulations.
                s['shapeActions'] = {
                    'dough': ['Twist', 'Squash'], 'sponge': ['Squash'],
                    'paper_straw': ['Bend'], 'rubber_band': ['Stretch'],
                    'metal_spoon': ['Squash'], 'stone': ['Squash'],
                }
                s['shapeResults'] = {
                    'dough': {'Twist': 'change', 'Squash': 'change'},
                    'sponge': {'Squash': 'change'}, 'paper_straw': {'Bend': 'change'},
                    'rubber_band': {'Stretch': 'change'},
                    'metal_spoon': {'Squash': 'same'}, 'stone': {'Squash': 'same'},
                }
            if s['id'] == 'unit_04.step.013':
                s['title'] = 'Finish the workshop'
                s['prompt'] = 'Solve the five workshop discoveries.'
                for o in s['options']:
                    if o['id'] == 'an_object_you_can_stretch':
                        o['art'] = 'stretch_mission'
            if s['id'] == 'unit_04.step.012':
                s['title'] = 'Build a rain shelter'
                s['prompt'] = 'Test both covers. Choose one for your shelter.'
                s['labUi']['decision'] = {
                    'question': 'Which cover will keep your shelter dry?',
                    'result': 'dry', 'retry': 'Look under each cover again. Which kept the rain out?',
                    'complete': 'Your shelter is ready for the rain!',
                }
        if s['id'] == 'unit_04.step.001':
            s['senseDescriptions']['metal'] = 'A spoon is an object. Metal is its material. Metal is usually hard, shiny and cold to touch.'
            s['senseDescriptions']['wood'] = 'A chair is an object. Wood is its material. Wood is hard and can be rough or smooth.'
        if s['id'] == 'quiz_02.step.007' and len(s['options']) == 2:
            s['options'].insert(1, {'id': 'metal_spoon', 'label': 'Metal spoon', 'art': 'spoon'})
        if s['id'] == 'quiz_02.step.005' and len(s['options']) == 2:
            s['options'].insert(1, {'id': 'hard_and_fluffy', 'label': 'Hard and fluffy', 'art': 'hard_and_fluffy'})

if __name__ == '__main__':
    for path in (Path(__file__).resolve().parents[1] / 'assets/content/playable').glob('*.json'):
        book = json.loads(path.read_text(encoding='utf-8'))
        refine_teacher_review(book)
        path.write_text(json.dumps(book, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
