"""Presentation and parent practice from the 4 October review; source keys stay intact."""
import json
import re
from pathlib import Path

SHORT = {
    'quiz_02.step.001': 'The chair is an object; wood is the material used to make it.',
    'quiz_03.step.009': 'Magnets pull iron and steel, but not aluminium or gold.',
    'quiz_04.step.009': 'Neil Armstrong first walked on the Moon in 1969.',
    'unit_01.step.030': 'A bird moves, eats and breathes; a baby bird grows bigger.',
    'unit_02.fridge.v2': 'Roots: carrots; stems: celery; leaves: lettuce; flowers: broccoli; seeds: beans.',
    'unit_02.step.025': 'Roots take in water; stems support; leaves make food; flowers produce seeds.',
    'unit_02.bean-trail.v2': 'Day 1: seed; day 4: root; day 7: shoot; day 8: green leaves.',
    'unit_02.step.028': 'Without light, the plant has pale yellow leaves and a thin, floppy stem.',
    'unit_02.step.033': 'Without water, leaves droop and turn brown; the plant dries out and can die.',
    'unit_03.five-senses.v2': 'Eyes see, ears hear, noses smell, tongues taste, and skin feels.',
    'unit_03.body-workshop.v2': 'Your whole body has many parts to discover, from your head to your feet.',
    'unit_03.sense-partners.v2': 'Eyes see, ears hear, noses smell, tongues taste, and skin feels.',
    'unit_03.sense-stories.v2': 'Eyes see, ears hear, noses smell, tongues taste, and skin feels.',
    'unit_03.marbles.v2': 'Zara has most: 9 marbles. Jack has fewest: 5. David has 6.',
    'unit_03.sense-lab.v2': 'Five senses; tongue taste buds help taste; holding nose reduces flavour; sweet, sour, salty tastes.',
    'unit_03.last-discoveries.v2': 'Eyelashes keep dust out. The elbow is between the wrist and shoulder.',
    'unit_04.step.002': 'Spoons and chairs are objects; metal and wood are materials used to make them.',
    'unit_04.step.003': 'Window: glass; T-shirt: fabric; nail: metal; newspaper: paper.',
    'unit_04.step.004': 'Most metals are hard and shiny, and can feel cold to touch.',
    'unit_04.step.005': 'Glass is hard, can break, can be see-through, and comes in many colours.',
    'unit_04.step.007': 'Plastic and foil keep water out; cloth, paper and tissue let water through.',
    'unit_04.step.009': 'Sponge and dough squash; stone and a metal spoon stay hard.',
    'unit_04.step.011': 'Wood surrounds the pencil; graphite inside makes the writing marks.',
    'unit_04.step.013': 'Glass windows; plastic raincovers; cold, hard metals; stretching rubber bands; potters shape clay.',
    'unit_05.step.002': 'A push moves the trolley away; a pull brings it towards you.',
    'unit_05.step.003': 'A push moves the trolley away; a pull brings it towards you.',
    'unit_05.step.004': 'Push a doorbell; pull a drawer; swings and trolleys can be pushed or pulled.',
    'unit_05.step.006': 'Balloon, cork and plastic pot float; stone, metal nail and glass marble sink.',
    'unit_05.step.007': 'Snakes slither; birds fly; fish swim; kangaroos hop; babies crawl.',
    'unit_05.step.010': 'Pull a drawer open; push a doorbell to ring it.',
    'unit_05.step.011': 'Push a switch and kick a ball; pull a fridge door and a zip.',
    'unit_05.step.013': 'Push sends away; coins sink; snakes slither; bigger pushes move farther; push doorbells.',
    'unit_06.step.003': 'Hit triangles; beat drums; shake maracas; blow trumpets; pluck sitar strings.',
    'unit_06.step.008': 'Maris heard the drum furthest away: 23 steps. David took 8 steps.',
    'unit_06.step.010': "Quietest to loudest here: cat's footsteps, whisper, slamming door, thunder.",
    'unit_06.step.012': 'Beat drums; distance makes sound fainter; stones rattle; sound-makers are sources; blow trumpets.',
    'unit_07.step.003': 'Lanterns give light like lamps; brooms clean like vacuum cleaners.',
    'unit_07.step.008': 'Keep fingers and objects out of sockets; grown-ups handle plugs; keep hands dry near electrical things.',
    'unit_07.step.009': 'Plugs: fridge, air conditioner; batteries: clock, torch; neither: bicycle, book.',
    'unit_07.step.011': 'Magnets pull steel; lanterns light; batteries power torches; iron and steel are magnetic; avoid sockets.',
    'unit_08.step.003': 'Ocean: large, salty; pond: small, still; river: flowing; lake: still with land around it.',
    'unit_08.step.004': 'Whales live in oceans; crocodiles can live in rivers; frogs can live by ponds.',
    'unit_08.step.013': "Earth's surface: mostly water; oceans: salty; soil: a mixture; coal: rock; geologists study rocks.",
    'unit_09.step.003': 'Earth is round, with water covering most of its surface; the Sun supplies heat and light.',
    'unit_09.step.006': 'Neil Armstrong first walked on the Moon in 1969.',
    'unit_09.step.007': 'Visor protects eyes; gloves, hands; boots, feet; oxygen pack provides air to breathe.',
    'unit_09.step.012': 'Earth: planet, mostly blue; Sun: star; Moon: no air to breathe; astronomers study stars.',
}

# Adult-led adaptations for each assessed book objective. Original book home
# activities remain alongside these; adaptations are never labeled quotations.
ACTIVITIES = {
 'unit_01': [
  'Look at a plant, an animal and a toy together. Ask which grow and need food, and why.',
  'Watch a bird from a distance or in a video. Ask how moving, eating, breathing and growing show that it is alive.',
  'Compare a kettle picture with a growing plant. Ask whether either can grow or make new living things.',
  'Look at a dandelion and its seeds in photographs. Ask how growing and making seeds show that it is alive.',
  'Roll a toy car, then watch a pet or plant. Ask why moving alone does not mean alive.',
  'Collect photographs of living and non-living things. Let your child choose and explain one of each.',
  'Watch an animal safely. Ask which signs of life you can observe without disturbing it.',
  'Compare cloud, bread, doll, worm, mint plant and fly pictures. Ask which grow, need food and are alive.',
  'Sort pictures into living and non-living groups. Ask your child to explain one tricky choice.',
 ],
 'unit_02': [
  'Use a plant picture to find roots, stem, leaves and flowers. Match them to taking in water, support, food-making and seed-making.',
  'Draw a bean growing over several days. Ask your child to place root, shoot and leaves in order.',
  'Compare photographs of healthy and pale plants. Ask what plants need to grow well.',
  'Look at the light-test pictures together. Ask what changed in the plant kept in darkness.',
  'Compare dry and damp bean pictures with an adult. Ask why water helps a seed start growing, and why a growing plant is alive.',
  'Build a plant from paper pieces. Ask your child where each part belongs and what it does.',
  'Check a houseplant together. Ask what may happen if it has no water.',
  'Sort familiar vegetable pictures into roots, stems, leaves, flowers and seeds. Discuss one tricky example.',
  'Look at leaves on a plant. Ask how sunlight helps the plant make its food.',
 ],
 'unit_03': [
  'Describe seeing, hearing, smelling, tasting and feeling familiar things. Ask which body part helps with each of the five senses.',
  'Name the five senses. Use a tongue drawing to find taste buds; discuss how smell helps flavour and familiar sweet, sour and salty tastes.',
  'Use a face drawing to find eyebrows, eyelashes and eyelids. Discuss how each protects the eye.',
  'Make three small groups of counters. Ask which group has most and which has fewest.',
  'Pretend to visit an eye specialist using a drawing. Ask which body part the optometrist checks.',
  'Make a sentence for each sense using familiar sights, gentle sounds, smells, food tastes and textures. Ask which body part helps.',
  'Talk about the smell and taste of a familiar apple. Ask why both senses help us notice flavour.',
  'Compare two written shoe sizes. Ask which number is bigger without judging whose body is better.',
  'Find an elbow and eyelashes on a picture. Ask where the elbow is and how eyelashes help.',
 ],
 'unit_04': [
  'Name a spoon and a chair, then their materials. Ask how an object differs from its material.',
  'Sort pictures of a window, T-shirt, nail and newspaper into glass, fabric, metal and paper. Explain the material used for each object.',
  'Compare a cool metal spoon with a wooden spoon. Ask which feels hard, looks shiny and feels cooler at the same room temperature.',
  'Compare pictures of clear and coloured glass. Discuss how glass can be see-through, hard and breakable without handling broken glass.',
  'Put a few water drops on plastic and tissue over a tray. Ask which keeps the water out.',
  'Press a sponge and a smooth stone gently. Ask which changes shape and which stays hard.',
  'Compare a window with a wall. Ask which lets light through and what transparent means.',
  'Look at an intact pencil. Ask which part is wood and which part makes the marks.',
  'Choose a material for a pretend window or rain shelter. Ask why that material fits its job.',
 ],
 'unit_05': [
  'Move a toy trolley gently away and towards you. Ask your child to describe a push and a pull.',
  'Mime a doorbell, drawer, swing and trolley. Ask which are pushed, pulled or can move with either force.',
  'With an adult, compare a cork and a smooth stone in a shallow tray of water. Predict, then observe.',
  'Act out flying, crawling, hopping and slithering. Ask which animals move in those ways.',
  'Blow gently towards a paper sail on a toy boat. Ask what pushes the sail.',
  'Mime a doorbell and drawer. Ask your child to explain how each is moved.',
  'Act out a switch, zip, fridge door and ball. Ask whether each action pushes or pulls.',
  'Review the orange experiment pictures. Ask how the peel affected floating in that test.',
  'Move a toy gently with two different pushes. Compare the distance and describe what changed.',
 ],
 'unit_06': [
  'Listen to a gentle household sound. Ask which body part helps your child hear it.',
  'Mime a triangle, drum, maracas, trumpet and sitar. Match them to hitting, beating, shaking, blowing and plucking.',
  'Review the stone and feather box test. Ask why the hard stone was easier to hear.',
  'Play a quiet sound, then move farther away with an adult. Ask whether it becomes easier or harder to hear.',
  'Draw the drum explorers and their step counts. Ask who heard it furthest away, how many steps they took and how you know.',
  'Tap two wooden spoons gently, then a little harder. Ask how the loudness changes.',
  'Recall a whisper, footsteps, door and thunder. Arrange their pictures from quiet to loud as in the game.',
  'Hum gently and rest your own fingers on your throat. Ask what buzzing or shaking you feel.',
  'Find a safe sound source and describe how it makes sound. Compare hearing it near and farther away.',
 ],
 'unit_07': [
  'Sort pictures of appliances, books and chairs. Ask which need electricity to work.',
  'Compare pictures of a lamp and lantern, then a vacuum and broom. Ask what job each pair does.',
  'Use a child-safe magnet with adult-selected objects. Ask why it pulls some metals but not every metal.',
  'Predict whether an adult-selected steel object, plastic object and aluminium foil will be attracted. Test safely.',
  'Look at a closed battery torch. Ask what gives it electricity when it is away from a socket.',
  'Role-play the safety rules with pictures: keep away from sockets, dry hands, and ask a grown-up.',
  'Sort pictures into plug, battery and neither. Ask why a bicycle and book need neither.',
  'Compare fridge door seal and cupboard catch pictures with an adult. Ask how magnets help each door stay shut.',
  'Compare a safe magnet, battery torch and lantern picture. Ask how each works and review socket safety.',
 ],
 'unit_08': [
  'Look at a globe or Earth picture. Ask which colour covers most of it and what that colour represents.',
  'Compare pond, lake, river and ocean pictures. Ask which flow, which are still and which have salty water.',
  'Match whale, crocodile and frog pictures to water homes. Discuss why animals need suitable homes.',
  'Compare a stone, coal picture and diamond picture with a bottle and fabric. Ask which belong with rocks.',
  'Look at a soil photograph. Find small stones, leaves and creatures; discuss why soil is a mixture.',
  'Pretend to be geologists examining clean adult-selected stones. Ask what a geologist studies.',
  'Arrange the book water-place pictures in its example order. Compare still and flowing water without assuming all rivers are smaller than lakes.',
  'Find pictures of a stone wall and marble floor. Ask what they are made from.',
  'Sort clean stones by size, colour or texture. Explain one group and compare it with another.',
 ],
 'unit_09': [
  'Use an Earth picture to find its round shape and water. Ask where our heat and light come from.',
  'Compare Sun and Earth pictures. Ask which is a star and which is our planet.',
  'Draw the Sun lighting and warming Earth. Ask which two gifts it gives us and how its light helps plants.',
  'Look at a Moon-landing picture. Recall who first walked on the Moon and when.',
  'Draw an astronaut suit. Match visor, gloves and boots to eyes, hands and feet; explain how the oxygen pack allows breathing on the Moon.',
  'Role-play Sun safety with an indoor picture. Ask why we never look straight at the Sun.',
  'Draw Earth as round with large blue water areas. Explain why it looks mostly blue.',
  'Compare daylight and a dark room in pictures. Discuss how sunlight helps us see and plants make food.',
  'Build a pretend Sun, Earth and Moon model. Describe their roles and remind your child that model sizes and distances are not real.',
 ],
}

SAFETY = {
 'unit_01': 'An adult supervises. Observe animals without touching, feeding or disturbing them.',
 'unit_02': 'An adult prepares materials. Use clean beans and pots; do not eat experiment seeds or plants.',
 'unit_03': 'Use safe familiar objects. No unknown tasting, eye touching, small counters for children who mouth objects, or loud sounds.',
 'unit_04': 'An adult supervises. No broken glass, sharp objects, hot materials or swallowing small pieces.',
 'unit_05': 'An adult supervises. Use gentle forces and shallow water; keep small objects away from mouths.',
 'unit_06': 'Keep sounds gentle and away from ears. Do not shout or make sudden loud noises.',
 'unit_07': 'Never touch sockets, wires or mains electricity. Only an adult handles plugs. No loose batteries or small powerful magnets.',
 'unit_08': 'Use clean adult-selected samples or pictures. Stay away from open water, unknown rocks and dirty soil; wash hands.',
 'unit_09': 'Never look straight at the Sun. Use indoor pictures and models; never aim binoculars or telescopes at the Sun.',
}

# Objective IDs select both the activity and its safety guidance. A shuffled
# quiz or a merged screen must not silently inherit the preceding topic.
QUIZ_UNITS = {
    **{f'quiz01.{i:02d}': unit for i, unit in enumerate(
        ['unit_01', 'unit_01', 'unit_02', 'unit_02', 'unit_02',
         'unit_03', 'unit_03', 'unit_01', 'unit_03', 'unit_03'], 1)},
    **{f'quiz02.{i:02d}': 'unit_04' for i in range(1, 11)},
    **{f'quiz03.{i:02d}': unit for i, unit in enumerate(
        ['unit_05', 'unit_05', 'unit_05', 'unit_06', 'unit_06',
         'unit_06', 'unit_06', 'unit_07', 'unit_07', 'unit_07'], 1)},
    **{f'quiz04.{i:02d}': 'unit_08' if i <= 4 else 'unit_09'
       for i in range(1, 11)},
}

GOAL_TEXT = {
 'quiz01.01': 'Sort pictures of a cat, tree, baby and toys. Ask which are living and how you can tell.',
 'quiz01.02': 'Compare a baby and grown animal in pictures. Ask for two signs of life, such as growing and breathing.',
 'quiz01.03': 'Point to roots on a whole-plant picture. Ask which part takes water from the soil.',
 'quiz01.04': 'Compare healthy and pale plant pictures. Ask which two things the plant needs: water and light.',
 'quiz01.05': 'Compare the light-test pictures. Ask what colour the leaves became after time in the dark cupboard.',
 'quiz01.06': 'Name sight, hearing, smell, taste and touch. Describe a familiar discovery for each sense, then count all five.',
 'quiz01.07': 'Use a tongue drawing and describe a familiar food taste. Ask which body part helps us taste.',
 'quiz01.08': 'Roll a toy car gently. Ask why moving does not make it alive: can it grow or make new living things?',
 'quiz01.09': 'Use a whole-body picture. Follow shoulder, arm, elbow, wrist, hand and fingers in order; ask where each part is.',
 'quiz01.10': 'Pretend to visit an optometrist using drawings. Ask who checks our eyes, helps us see clearly and may give us glasses.',
 'quiz02.01': 'Draw a wooden chair. Ask which word names the object and which names the material it is made from.',
 'quiz02.02': 'Use pictures of wood, metal, plastic and glass. Name four materials and an object made from each.',
 'quiz02.03': 'Compare a clear window with a wooden wall in pictures. Ask which material is see-through.',
 'quiz02.04': 'Put a few water drops on plastic and tissue over a tray with an adult. Ask which cover keeps water out.',
 'quiz02.05': 'Compare a cool metal spoon with a wooden spoon. Ask which feels hard and looks shiny.',
 'quiz02.06': 'With adult-selected safe flexible materials, try twisting, stretching, squashing and bending. Name how each changes shape.',
 'quiz02.07': 'Gently stretch a large rubber band with an adult. Ask how its length changes; keep it away from faces.',
 'quiz02.08': 'Shape a pretend pot from safe modelling clay. Ask which material a potter uses and why it can be shaped.',
 'quiz02.09': 'Compare photographs of clear, blue and red glass. Ask whether all glass is red and explain the different colours.',
 'quiz02.10': 'Look at an intact spoon and pan with an adult. Ask which material they are made from; compare with a towel.',
 'quiz03.01': 'Mime opening a drawer towards you. Ask whether this is a push or a pull.',
 'quiz03.02': 'Mime pressing a doorbell button in. Ask whether your finger pushes or pulls the button.',
 'quiz03.03': 'Compare cork, closed plastic bottle and stone test pictures. Ask which stayed at the water surface and which sank.',
 'quiz03.04': 'Listen to a gentle hum. Ask what made the sound and why the sound-maker is called its source.',
 'quiz03.05': 'Play a quiet sound, then move farther away with an adult. Ask whether the sound becomes louder or quieter.',
 'quiz03.06': 'Mime playing a trumpet. Ask which action makes its sound: blowing, shaking or plucking.',
 'quiz03.07': 'Listen to a gentle household sound. Ask which part of the body helps us hear it.',
 'quiz03.08': 'With an adult, compare pictures of iron, steel, plastic and wood. Ask which two metals a magnet attracts.',
 'quiz03.09': 'Review a magnet test with iron, steel and aluminium foil. Ask why being metal does not always mean being attracted.',
 'quiz03.10': 'Look at a closed battery torch. Ask what powers its light when it is away from a socket.',
 'quiz04.01': 'Look at a globe or Earth picture. Ask what covers most of the surface and makes it look blue.',
 'quiz04.02': 'Compare the book pond, lake, river and ocean pictures. Ask which is the largest water place shown and has salty water.',
 'quiz04.03': 'Look at a soil photograph. Find two things such as small stones and dead leaves; explain that soil is a mixture.',
 'quiz04.04': 'Pretend to be a scientist examining clean adult-selected stones. Ask what a geologist studies.',
 'quiz04.05': 'Draw Earth next to a ball picture. Ask which shape describes our planet.',
 'quiz04.06': 'Compare Sun and Earth pictures indoors. Ask which is a star that makes its own heat and light.',
 'quiz04.07': 'Draw the Sun lighting and warming Earth. Ask which two gifts it gives us: heat and light.',
 'quiz04.08': 'Compare Sun and Moon pictures indoors. Ask which supplies our heat and light and why the Moon does not make its own light.',
 'quiz04.09': 'Look at a Moon-landing photograph. Recall Neil Armstrong and the year 1969 as the first Moon walk.',
 'quiz04.10': 'Draw an astronaut oxygen pack. Ask why it supplies air to breathe when there is no air to breathe on the Moon.',
 'u01.choice.01': 'Compare pictures of a tree, car and toy. Ask which grows and needs food, and explain why.',
 'u01.choice.02': 'Care for a plant with an adult. Ask why living things need water as well as food.',
 'u01.choice.03': 'Compare a toy made in a factory with a growing plant. Ask whether being made in a factory is a sign of life.',
 'u01.choice.04': 'Compare baby and adult bird pictures. Ask what changes as a baby bird grows.',
 'u01.choice.05': 'Find new leaves on a plant or in photographs. Ask how growing shows that the plant is alive.',
 'u02.choice.02': 'Look at leaves on a plant picture. Ask how sunlight helps leaves make the plant\'s food.',
 'u03.choice.01': 'Describe hearing gentle music or a bird sound. Ask which body part helps us hear.',
 'u03.choice.02': 'Use a tongue drawing to locate taste buds. Ask which body part helps us taste familiar food.',
 'u03.choice.03': 'Name sight, hearing, smell, taste and touch with familiar examples. Count how many senses there are.',
 'u03.choice.04': 'Find eyelashes on a face drawing. Ask how they help keep dust out of our eyes.',
 'u03.choice.05': 'Follow a whole arm in a picture from shoulder to wrist. Ask which joint lies between them.',
 'u04.choice.01': 'Compare window and wall pictures. Ask why clear glass is useful when we need to see through a window.',
 'u04.choice.02': 'Compare plastic and tissue covers over a tray with adult-applied water drops. Ask which material keeps rain out.',
 'u04.choice.03': 'Compare a cool metal spoon with a wooden spoon. Ask why the metal can feel cold and hard.',
 'u04.choice.04': 'Gently stretch a large rubber band with an adult. Ask which material gets longer when pulled; keep it away from faces.',
 'u04.choice.05': 'Shape a pretend pot from safe modelling clay. Ask what material a potter shapes to make pots.',
 'u05.choice.01': 'Push a toy gently away from you. Ask which direction a push sends it.',
 'u05.choice.02': 'Compare the coin and cork experiment pictures. Ask which object sank and which floated.',
 'u05.choice.03': 'Mime a snake moving along the floor. Ask what slithering means and how it differs from flying or hopping.',
 'u05.choice.04': 'Move a toy gently with two different pushes. Ask which bigger push moved it farther in this test.',
 'u05.choice.05': 'Mime pressing a doorbell. Ask whether the button needs a push or a pull.',
 'u06.choice.01': 'Mime a drumstick moving onto a drum. Ask what beating the drum does to make a sound.',
 'u06.choice.02': 'Play a quiet sound and move farther away with an adult. Ask whether it becomes fainter or louder.',
 'u06.choice.03': 'Review the stone and feather box test pictures. Ask which box sounded louder and why.',
 'u06.choice.04': 'Hum gently. Ask what made the sound and what the term source of sound means.',
 'u06.choice.05': 'Mime blowing a trumpet, shaking maracas and plucking strings. Ask which instrument makes a sound when blown.',
 'u07.choice.01': 'Compare steel key, plastic button and sock pictures. Ask which object a magnet attracts and why.',
 'u07.choice.02': 'Compare lamp and flame-lantern pictures. Ask which older tool gave light before electric lamps.',
 'u07.choice.03': 'Look at a closed battery torch. Ask what gives it electricity away from a wall socket.',
 'u07.choice.04': 'Review a magnet test with iron, steel and aluminium foil. Ask which metals are attracted in the test.',
 'u07.choice.05': 'Use socket safety pictures. Ask whether fingers or objects ever belong in sockets and who handles plugs.',
 'u08.choice.01': 'Look at a globe or Earth picture. Ask what covers most of its surface and makes it look blue.',
 'u08.choice.02': 'Compare the book water-place pictures. Ask which place has a large area of salty water.',
 'u08.choice.03': 'Look at a soil photograph and name stones, leaves and other parts. Ask why soil is a mixture.',
 'u08.choice.04': 'Compare coal, wood and plastic pictures. Ask which belongs with rocks.',
 'u08.choice.05': 'Pretend to examine clean adult-selected stones as a geologist. Ask which materials geologists study.',
 'u09.choice.01': 'Compare Earth and Sun pictures indoors. Ask which is our planet and which is a star.',
 'u09.choice.02': 'Look at a Sun picture indoors. Ask why the Sun belongs with stars rather than planets.',
 'u09.choice.03': 'Draw Earth with large blue water areas. Ask why our planet looks mostly blue.',
 'u09.choice.04': 'Draw an astronaut oxygen pack on the Moon. Ask what is missing there that the astronaut needs to breathe.',
 'u09.choice.05': 'Pretend to study star pictures indoors. Ask what an astronomer studies and how this differs from studying rocks.',
}

def refine_latest_teacher_review(book):
    activities = {}
    for index, step in enumerate(book['steps']):
        explanation = step.get('explanation', '')
        short = SHORT.get(step['id'], re.split(r'(?<=[.!?])\s+', explanation)[0])
        assert len(short.split()) <= 16, (step['id'], short)
        step['shortExplanation'] = short
        if book['id'] == 'unit_07':
            for item in step['options'] + step['targets']:
                if item['id'] == 'book': item['art'] = 'book'
        if book['id'] == 'quiz_03':
            modes = {0: 'drawer-gesture', 1: 'doorbell-action', 3: 'source-drop', 4: 'distance-observe'}
            if index in modes: step['quizInteraction'] = modes[index]
        if not step['assessed']: continue
        for goal in [step['objective']] + step.get('extraObjectives', []):
            if goal in activities: continue
            if book['quiz']:
                unit = QUIZ_UNITS[goal]
            else:
                unit = book['id']
            text = GOAL_TEXT.get(goal)
            if text is None:
                # Main book question numbers map to the explicitly ordered
                # activities above. Choice and quiz goals require their own text.
                assert '.main.' in goal, ('Missing goal activity', goal)
                number = int(goal.rsplit('.', 1)[-1])
                text = ACTIVITIES[unit][number - 1]
            sources = [step['source']] + step.get('relatedSources', [])
            source = next((s for s in sources if s['questionId'] == goal), step['source'])
            activities[goal] = {'objective': goal, 'text': text,
                'safety': SAFETY[unit], 'pages': source['pages'], 'safetyPages': [2],
                'adapted': True}
    book['goalActivities'] = list(activities.values())

if __name__ == '__main__':
    root = Path(__file__).resolve().parents[1] / 'assets/content/playable'
    for path in sorted(root.glob('*.json')):
        book = json.loads(path.read_text(encoding='utf-8'))
        refine_latest_teacher_review(book)
        path.write_text(json.dumps(book, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
