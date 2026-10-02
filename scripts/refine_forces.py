"""Source-preserving Forces scene and experiment presentation."""
import json
from pathlib import Path

def refine_forces(book):
    if book['id'] != 'unit_05':
        return
    modes={1:'movement',3:'direction',4:'home',6:'tank',7:'animals',9:'boat',10:'home',11:'jobs',13:'discoveries'}
    descriptions={
        'push':'Push sends an object away from you.', 'pull':'Pull brings an object towards you.',
        'roll':'The ball rolls.', 'swim':'The fish swims.', 'slither':'The snake slithers.',
        'fly':'The bird flies.', 'hop':'The kangaroo hops.', 'crawl':'The baby crawls.',
    }
    for number,s in enumerate(book['steps'],1):
        if number in modes:
            s['forceScene']={
                'mode':modes[number],
                'instruction': 'Touch a hand, then choose a movement.' if number != 6 else 'Touch an object, then a place in the tank. You can also drag it.',
                'you':'You', 'progress':'Discoveries placed',
            }
        if s['assessed']:
            s['correctionUi']={
                'review':'Look at this choice again',
                'start':'Now try it yourself. Change your choices using these clues:',
                'retry':'Keep trying. Use the discovery to help you.',
                'complete':'You did it yourself! You can keep exploring.',
                'check':'Check my practice',
            }
        if number==1:
            s['prompt']='Touch a hand. Watch how things move.'
            s['senseDescriptions']=descriptions
            s['forceScene']['instruction']='Explore every movement. You can watch each one again.'
            s['motions']={k:k for k in descriptions}
        if number==2:
            s['prompt']='Move the trolley. Compare two pushes on the ball.'
            s['labUi'].update({
                'you':'You', 'push':'Push away', 'pull':'Pull closer',
                'moveStage':'Move the trolley', 'compareStage':'Compare two pushes',
                'instruction':'Drag the trolley away from you and back, or use the buttons.',
                'compare':'Start the same ball in the same place. Try both pushes.',
                'gentle':'Gentle push', 'strong':'Bigger push',
                'result':'The bigger push sent the same ball further.',
                'progress':'Moves explored', 'pushProgress':'Pushes compared',
                'prediction':'Which push will send the ball further?',
                'test':'Try this push',
            })
        if number==3:
            s['title']='Trolley directions'
            s['prompt']='Watch each trolley move. Choose push or pull.'
            s['forceScene']['instruction']='Touch a trolley to watch. You are at the left of each track.'
            s['motions']={'away_from_you':'push','towards_you':'pull'}
            s['explanation']='A push moves the trolley away from you. A pull brings it towards you.'
        if number in (4,10,11):
            s['forceScene']['instruction']='Touch an object in the scene. Choose the force for its job.'
        if number==6:
            s['explanation']='The balloon, cork and plastic pot float. The stone, metal nail and glass marble sink.'
        if number==7:
            s['prompt']='Choose how each living thing moves.'
        if number==8:
            s['prompt']='Predict first. Then make some wind.'
            s['labUi'].update({'prediction':'What will happen when you blow?',
                'choices':{'moves':'The boat will move','still':'The boat will stay still'},
                'result':'Moving air pushed the boat.', 'observe':'What happened to the boat?',
                'retry':'Look where the boat is now. Did it move?',
            })
        if number==9:
            s['forceScene']['instruction']='Remember the wind experiment. Choose the force.'
        if number==11:
            s['prompt']='Find two pushes and two pulls in this room.'
            s['forceScene']['instruction']='Touch each job, then choose its force. Check after all four.'
        if number==13:
            s['title']='Finish the movement trail'
            s['prompt']='Use your experiments to solve five discoveries.'
            s['forceScene']['instruction']='Touch a discovery, then choose its answer.'
            for o in s['options']:
                if o['id']=='sinks_in_water': o['art']='tank_question'
            s['explanation']='A push sends an object away. A metal coin sinks. A snake slithers. A bigger push sends the ball further. Ringing a doorbell uses a push.'
        if s.get('lab')=='tank':
            s['labUi']['pictureChoices']=True
            s['observationUi']={
                'review':'Look again',
                'changed':'The result was different from your prediction. Let us look again!',
                'question':'What did the water test show?',
                'retry':'Look at the object in the water. Where did it stop?',
                'complete':'You noticed what happened! Keep exploring.',
            }

if __name__=='__main__':
    path=Path(__file__).resolve().parents[1]/'assets/content/playable/unit_05.json'
    book=json.loads(path.read_text(encoding='utf-8'))
    refine_forces(book)
    path.write_text(json.dumps(book,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
