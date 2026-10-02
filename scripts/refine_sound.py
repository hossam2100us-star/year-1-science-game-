"""Sound scenes, including a source-linked David chart variant with migration."""
import copy
import json
from pathlib import Path


def refine_sound(book):
    if book['id'] != 'unit_06':
        return
    chart = book['steps'][7]
    if 'legacySoundChart' not in book:
        book['legacySoundChart'] = copy.deepcopy({
            key: chart[key] for key in ['options', 'answer', 'hint', 'explanation', 'source']
        })
        book['legacySoundChart']['soundScene'] = {
            'targetGroups': {
                'furthest_listener': ['annay', 'zara', 'maris', 'david'],
                'maris_took': ['8_steps', '14_steps', '20_steps', '23_steps'],
            },
        }
    book['contentVersion'] = 2
    modes = {1: 'band', 2: 'hearing', 3: 'band', 5: 'boxes', 7: 'distance',
             8: 'chart', 9: 'sticks', 10: 'order', 11: 'hum', 12: 'discoveries'}
    for number, step in enumerate(book['steps'], 1):
        if number in modes:
            step['soundScene'] = {
                'mode': modes[number],
                'instruction': 'Touch a hand to explore.' if number == 1 else
                    'Touch an instrument, then choose its action.' if number == 3 else
                    'Touch a discovery, then choose its answer.' if number == 12 else
                    'Choose a question, then read the walking tracks.' if number == 8 else
                    'Touch each picture to listen. Drag the sounds into order, quietest first.' if number == 10 else
                    'Use your experiment to choose.',
                'progress': 'Discoveries placed', 'you': 'You',
                'gentle': 'Try a gentle tap', 'harder': 'Try a harder tap',
                'quietFirst': 'Quietest first', 'steps': 'steps',
                'listen': 'Listen', 'answerFor': 'Choose for:',
                'explored': 'Instruments explored', 'hearAction': 'Hear how to play it',
                'near': 'Move near', 'far': 'Move far',
                'moveEarlier': 'Move earlier', 'moveLater': 'Move later',
                'remove': 'Remove this sound', 'emptySlot': 'Drag a sound here',
                'placeHere': 'Place the sound here',
                'dragHint': 'Drag a sound here', 'placeSound': 'Place this sound',
                'chooseToPlace': 'Choose a sound to place',
                'orderSlot': 'Sound position',
                'humSteps': '1. Touch your throat gently.  2. Hum with your own voice.',
                'yourAnswer': 'Your choice', 'answerPrompt': 'Now choose your answer', 'mission': 'Discovery',
                'nextMission': 'Next discovery', 'walkStart': 'Everyone starts at the same drum.',
                'missions': {
                    'play_a_drum': 'Which action plays this drum?',
                    'louder_shaken_box': 'Which object made the louder box?',
                    'instrument_you_blow': 'Which instrument do you blow?',
                    'walk_away_from_sound': 'What happens to sound as you walk away?',
                    'something_making_a_sound': 'What do we call something making a sound?',
                },
            }
        if step['assessed']:
            step['correctionUi'] = {
                'review': 'Look at this choice again',
                'start': 'Now try it yourself. Change your choices using these clues:',
                'retry': 'Keep trying. Use your experiment to help you.',
                'complete': 'You did it yourself! You can keep exploring.',
                'check': 'Check my practice',
            }
        if number == 1:
            step['title'] = 'Music studio'
            step['prompt'] = 'Explore the music studio. Play every instrument.'
            step['soundScene']['instruction'] = 'Touch an instrument to hear it. Ask the studio how to play it.'
        elif number == 2:
            step['prompt'] = 'Find the body part you use to hear. Touch its hand marker.'
            step['soundScene']['instruction'] = 'Look at the whole face. Which part catches sounds?'
        elif number == 4:
            step['prompt'] = 'Predict for each box. Shake it and compare what happens.'
            step['labUi'].update({'pictureChoices': True, 'replay': 'Shake and listen again',
                                  'progress': 'Boxes explored',
                                  'phases': ['Predict', 'Shake', 'Notice'],
                                  'prediction': 'What do you think this box will sound like?',
                                  'yourPrediction': 'Your prediction', 'nextBox': 'Try the other box'})
            step['labUi']['choices'] = {'loud': 'Loud', 'quiet': 'No sound'}
            step['labUi']['result'] = 'What happened'
            step['explanation'] = 'The stone rattled against the box. The soft feather made no sound in this experiment.'
            step['observationUi'] = {
                'review': 'Listen again',
                'changed': 'The result was different from your prediction. Let us compare again!',
                'question': 'What did this box sound like?',
                'retry': 'Shake and listen again. Compare this box with the other box.',
                'complete': 'You noticed what happened! Keep exploring.',
            }
        elif number == 6:
            step['prompt'] = 'Move the listener. Play the same drum near and far away.'
            step['labUi'].update({'you': 'Listener', 'listen': 'Play the drum',
                                  'instruction': 'Move near, play the drum. Move far, play it again.',
                                  'phases': ['Predict', 'Listen twice', 'Compare'],
                                  'progress': 'Places compared', 'replay': 'Play again',
                                  'middle': 'Between the two places',
                                  'prediction': 'What will happen to the same sound further away?',
                                  'choices': {'fainter': 'It will become fainter', 'louder': 'It will become louder'},
                                  'yourPrediction': 'Your prediction',
                                  'heardNear': 'Near the drum: a louder sound.',
                                  'heardFar': 'Further away: a fainter sound.',
                                  'result': 'The same drum sounded fainter from further away.'})
        elif number == 7:
            step['soundScene'].update({
                'instruction': 'Move the listener and play the drum. Then choose your answer.',
                'you': 'Listener', 'listen': 'Play the drum again',
            })
        elif number == 8:
            step['prompt'] = 'Read the walking tracks to answer two discoveries.'
            step['options'] = [
                {'id': 'furthest_listener', 'label': 'Who heard furthest?', 'art': 'furthest_listener'},
                {'id': 'david_took', 'label': 'How many steps did David take?', 'art': 'david_took'},
            ]
            step['answer']['value'] = {'furthest_listener': 'maris', 'david_took': '8_steps'}
            step['hint'] = "Find the longest track, then read David's number of steps."
            step['explanation'] = 'Maris heard the drum from furthest away: 23 steps. David took 8 steps.'
            step['source']['pages'] = [17, 18, 27, 28]
            step['chartQuestionSource'] = {
                'contentId': 'charts', 'pages': [27, 28],
                'person': 'David', 'optionId': 'david_took',
                'questionText': 'How many steps did David take before he lost the sound?',
                'answerText': '8 steps, read from the original walking data.',
                'adaptation': 'Question two uses the Chart Skills David question instead of repeating Maris. The original unit answer-key quotation is retained as provenance.',
            }
            step['soundScene']['targetGroups'] = {
                'furthest_listener': ['annay', 'zara', 'maris', 'david'],
                'david_took': ['8_steps', '14_steps', '20_steps', '23_steps'],
            }
        elif number == 9:
            step['prompt'] = 'Try two taps on the same sticks. How can you make the sound louder?'
            step['soundScene']['instruction'] = 'Listen to both taps. The buttons below are for your answer.'
        elif number == 10:
            step['prompt'] = 'Listen to the sounds. Drag them from quietest to loudest.'
        elif number == 11:
            step['soundScene']['instruction'] = 'Try this with your own voice. Touch gently. Choose what you felt.'
        elif number == 12:
            step['title'] = 'Finish the sound trail'
            step['prompt'] = 'Solve five discoveries. You can go back to change your choices.'
            step['soundScene']['instruction'] = 'Try one discovery at a time. Use the numbers to revisit one.'
            choices = {
                'play_a_drum': ['blowing', 'beating', 'plucking'],
                'louder_shaken_box': ['feather', 'stone'],
                'instrument_you_blow': ['trumpet', 'sitar', 'triangle'],
                'walk_away_from_sound': ['louder', 'fainter'],
                'something_making_a_sound': ['source_of_sound', 'sink_of_sound'],
            }
            step['soundScene']['missionChoices'] = choices
            existing = {target['id'] for target in step['targets']}
            labels = {'blowing': 'Blowing', 'plucking': 'Plucking', 'feather': 'Feather',
                      'sitar': 'Sitar', 'triangle': 'Triangle', 'louder': 'Louder',
                      'sink_of_sound': 'Sink of sound'}
            for target_id, label in labels.items():
                if target_id not in existing:
                    step['targets'].append({'id': target_id, 'label': label, 'art': target_id})
            for option in step['options']:
                if option['id'] == 'louder_shaken_box':
                    option['art'] = 'sound_box'
                elif option['id'] == 'instrument_you_blow':
                    option['art'] = 'band_question'
            step['explanation'] = 'Beat a drum. A sound becomes fainter as you walk away. A stone makes the louder shaken box. Anything making a sound is its source. Blow a trumpet.'


if __name__ == '__main__':
    path = Path(__file__).resolve().parents[1] / 'assets/content/playable/unit_06.json'
    book = json.loads(path.read_text(encoding='utf-8'))
    refine_sound(book)
    path.write_text(json.dumps(book, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
