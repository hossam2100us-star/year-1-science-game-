"""Task-specific hints and a descriptive kind for ungraded science labs."""
import json
from pathlib import Path

HINTS = {
 'unit_04': [
 '', 'An object is a thing you can use. Ask what it is made from.',
 'Look at the window, shirt, nail and newspaper. Think about their surfaces.',
 'Imagine touching a metal spoon. Think about hardness, shine and temperature.',
 'Check each claim separately. Think about a window you can see through.', '',
 'Remember which covers kept the inside of the cup dry.', '',
 'Imagine pressing each object between your hands. Would its shape change?',
 'Think about what you need to see when you look out of a window.',
 'Look at the outside of the pencil and the dark part that makes a mark.', '',
 'Use your rain and shape experiments to help with each discovery.'],
 'unit_05': [
 '', '', 'Imagine where your hand moves: away from you or towards you?',
 'Act out each movement with your hand. Which direction is the force?', '',
 'Remember where each object stopped in the water tank.',
 'Picture the animal moving. Does it use legs, wings or its whole body?', '',
 'Remember how the wind met the sail and moved the boat.',
 'Imagine opening a drawer and pressing a switch. Compare your hand movements.',
 'Compare the four actions: which move something away, and which bring it towards you?', '',
 'Use the drawer, water tank and sailboat discoveries to find each answer.'],
 'unit_06': [
 '', 'Think about the sense you use to listen.',
 'Imagine playing each instrument. What would your hands or mouth do?', '',
 'Remember the two boxes you shook. Compare the sounds you heard.', '',
 'Think about what you heard when you moved farther from the drum.',
 'Find the longest bar, then read its name and number of steps.',
 'Compare a gentle tap with a harder tap.',
 'Compare two sounds at a time. Begin with the softest one.',
 'Think about the movement under your fingers when you hum.',
 'Remember the instruments, shaking boxes and walk away from the drum.'],
 'unit_07': [
 '', 'Ask which things need a plug or a battery to work.',
 'Match the job first: cleaning, washing, light or keeping cool.', '',
 'Compare each claim with what happened during the magnet hunt.',
 'Think about the material of each object, not just its shape.',
 'Think about how a torch works when you carry it away from a socket.',
 'Remember the rules about sockets, wet hands and opening appliances.',
 'Look for a wire and plug, a battery, or an object used by hand.',
 'Think about objects that need to hold a door or a bag closed.',
 'Use the safety rules, torch and magnet experiment to help.'],
 'unit_08': [
 '', 'Picture the large blue areas on Earth.',
 'Compare size, moving water and salt water in the clues.',
 'Remember the water places shown with each animal.',
 'Think about the material each thing is made from.', '',
 'Remember the tiny things you found with the magnifier.',
 'Think about the collection a rock scientist would examine.',
 'Compare the sizes in the water family shown in the book.',
 'Think about the hard materials used for walls and paths.', '', '',
 'Use the water places, soil observations and rock collection to help.'],
 'unit_09': [
 '', '', 'Compare the round Earth and its large blue areas.',
 'Remember how the Sun is different from Earth.',
 'Think about what you feel and what helps you see on a sunny day.',
 'Remember the name and year in the Moon mission record.',
 'Think about breathing, protecting the head and protecting the feet.',
 'Remember the safety rule you heard when meeting the Sun.', '',
 'Think about a sunny day: seeing things and feeling warm.', '',
 'Use the Earth model, Sun discoveries and astronaut suit to help.'],
 'quiz_02': [
 'Name the thing first, then ask what it is made from.',
 'Choose names of materials, rather than objects made from them.',
 'Think about looking through a window.',
 'Remember which covers kept the cup dry in the rain experiment.',
 'Think about touching a metal spoon: its surface and how it feels.',
 'Imagine changing a shape with your hands in four different ways.',
 'Think about pulling gently on the objects in the shape studio.',
 'Remember the soft material shaped into a pot before drying.',
 'Think about glass windows you have seen. Are they all the same colour?',
 'Think about the materials of the kitchen objects, not their jobs.'],
 'quiz_03': [
 'Imagine your hand moving as you open the drawer.',
 'Imagine your finger moving against the doorbell button.',
 'Remember which objects stayed at the top of the water tank.',
 'Think about the word for where a sound begins.',
 'Remember listening while moving away from the drum.',
 'Imagine how your mouth makes the trumpet sound.',
 'Think about the sense you use when listening.',
 'Recall which materials moved towards the magnet in the hunt.',
 'Remember testing different metals. Did they all move?',
 'Look for a helper you can use away from a wall socket.'],
 'quiz_04': [
 'Think about the large blue areas on the Earth model.',
 'Compare the size and saltiness of the water places.',
 'Remember what you discovered with the soil magnifier.',
 'Think about the name of a scientist who examines a rock collection.',
 'Picture the Earth model you turned.',
 'Remember how the Sun is different from our planet.',
 'Think about seeing in daylight and feeling warm.',
 'Compare what the book says about the Sun and the Moon.',
 'Recall the astronaut name and the year on the Moon mission record.',
 'Think about what the astronaut needs in order to breathe.'],
}

# Neutral question settings: no result, animation, correctness marker or supplied
# option is selected by this data. Deliberately omit a focus for collection and
# claim tasks where one sample could give away a required choice.
QUIZ_CONTEXTS = {
 'quiz_02': [
  ('workshop', 'chair'), ('workshop', None), ('workshop', 'window'),
  ('rain', 'umbrella'), ('workshop', 'spoon'), ('workshop', 'dough'),
  ('workshop', None), ('workshop', 'pot'), ('workshop', None),
  ('workshop', None),
 ],
 'quiz_03': [
  ('workshop', 'drawer'), ('workshop', 'doorbell'), ('water', None),
  ('sound', 'drum'), ('sound', 'drum'), ('sound', 'trumpet'),
  ('sound', 'drum'), ('electric', 'magnet'), ('electric', 'magnet'),
  ('electric', 'battery'),
 ],
 'quiz_04': [
  ('earth', 'earth'), ('water', None), ('earth', 'soil'),
  ('earth', 'stone'), ('space', 'earth'), ('space', 'sun'),
  ('space', 'sun'), ('space', 'moon'), ('space', 'astronaut'),
  ('space', 'astronaut'),
 ],
}


def refine_quiz_presentation(book):
    contexts = QUIZ_CONTEXTS.get(book['id'])
    if contexts is None:
        return
    assert len(contexts) == len(book['steps']), book['id']
    for step, (setting, art) in zip(book['steps'], contexts):
        step['quizContext'] = {'setting': setting, 'art': art}

def refine_science_review(book):
    hints = HINTS[book['id']]
    assert len(hints) == len(book['steps']), book['id']
    for step, hint in zip(book['steps'], hints):
        step['hint'] = hint
        if step.get('lab') and step['kind'] == 'free-plant':
            step['kind'] = 'science-lab'
    if book['id'] == 'unit_04':
        for step in book['steps']:
            if step.get('lab'):
                if step['lab'] == 'waterproof':
                    step['waterScene'] = 'umbrella' if step['id'].endswith('012') else 'cup'
                continue
            number = int(step['id'].split('.')[-1])
            step['workshop'] = {
                'mode': 'collect' if number in (7, 11) else 'workshop',
                'focus': {2: 'spoon', 4: 'spoon', 5: 'window', 10: 'window', 11: 'pencil'}.get(number, 'spoon'),
                'discover': 'Touch a hand marker to discover a material. Explore every object.',
                'sort': 'Choose an object or discovery, then touch a drawer. You can change your choices before checking.',
            }
            if number == 3:
                step['prompt'] = 'Put each object in its material drawer. Drag it, or touch the object and then a drawer.'
            elif number == 7:
                step['prompt'] = 'Pack every waterproof material for the rain. Touch again to take one out.'

    from refine_teacher_review import refine_teacher_review
    refine_teacher_review(book)
    if book['id'] == 'unit_04':
        for step in book['steps']:
            if step['id'] == 'unit_04.step.002':
                # The two labels name pairs: both examples must be pictured.
                # This is presentation data, separate from the original options.
                step['workshop']['pairedExamples'] = {
                    'things_a_spoon_and_a_chair': ['spoon', 'chair'],
                    'what_things_are_made_from_metal_and_wood': ['metal', 'wood'],
                }
    refine_quiz_presentation(book)
    if book['id'] == 'unit_07':
        # Mix the room collection without changing source option order or keys.
        book['steps'][1]['choiceOrder'] = [
            'lamp', 'vacuum_cleaner', 'book', 'chair',
            'television', 'lantern', 'dishwasher',
        ]
    from refine_forces import refine_forces
    refine_forces(book)
    from refine_sound import refine_sound
    refine_sound(book)
    from child_feedback import apply_child_feedback
    apply_child_feedback(book)
    from refine_latest_teacher_review import refine_latest_teacher_review
    refine_latest_teacher_review(book)

if __name__ == '__main__':
    root = Path(__file__).resolve().parents[1] / 'assets/content/playable'
    for id in HINTS:
        path = root / f'{id}.json'
        book = json.loads(path.read_text(encoding='utf-8'))
        refine_science_review(book)
        path.write_text(json.dumps(book, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
