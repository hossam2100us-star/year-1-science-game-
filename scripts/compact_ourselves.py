"""Consolidate repeated practice into 13 source-linked activities."""
from copy import deepcopy

def compact_ourselves(book):
    if book['contentVersion'] >= 2:
        for s in book['steps']:
            if s['id']=='unit_03.sense-partners.v2':
                s['title']='Which part helps?'
                s['prompt']='Think about each discovery. Which body part helps you find out?'
                scenes={
                    'sight':('The light turned green','traffic_light'),
                    'smell':('The bread smells burnt','bread'),
                    'touch':('The cat feels soft','cat'),
                    'hearing':('Music is playing','music'),
                    'taste':('The lemon tastes sour','lemon'),
                }
                for option in s['options']:
                    option['label'],option['art']=scenes[option['id']]
            if s['assessed']:
                relevant=[id for id in s.get('legacyMergedFrom',[]) if id in book['legacyAssessmentObjectives']]
                s['legacyCompletionGroups']=[[id] for id in relevant]
            if s['id']=='unit_03.five-senses.v2':
                s['legacyTouchSources']={'unit_03.step.002':['sight','hearing','smell','taste'],'unit_03.step.003':['touch']}
            if s.get('extraObjectives'):
                s['objectiveItems']={s['objective']:list(s['answer']['value'])}
                for objective in s['extraObjectives']:
                    s['objectiveItems'][objective]={'u03.choice.01':['hearing'],'u03.choice.02':['tongue_job'],
                        'u03.choice.03':['count'],'u03.choice.05':['arm_joint']}[objective]
                if s['id']=='unit_03.last-discoveries.v2':s['objectiveItems'][s['objective']]=['dust_guard']
        from refine_teacher_review import refine_teacher_review
        refine_teacher_review(book)
        for s in book['steps']:
            if s['id']=='unit_03.sense-partners.v2':
                s['discoveryChoices']={
                    'sight':['nose','eyes','ears'],
                    'smell':['tongue','eyes','nose'],
                    'touch':['ears','skin','tongue'],
                    'hearing':['skin','ears','eyes'],
                    'taste':['tongue','nose','skin'],
                }
            if s['id']=='unit_03.sense-stories.v2':
                s['discoveryChoices']={
                    'see_birds':['smell','hearing','sight'],
                    'soft_cat':['touch','sight','taste'],
                    'smell_flowers':['hearing','smell','touch'],
                    'example_26':['smell','taste','sight'],
                    'example_28':['hearing','smell','touch'],
                    'hear_music':['hearing','sight','smell'],
                    'sweet_honey':['sight','touch','taste'],
                    'example_25':['smell','taste','hearing'],
                    'example_27':['touch','hearing','taste'],
                    'example_29':['taste','touch','sight'],
                }
            if s['id']=='unit_03.sense-lab.v2':
                # Keep the full original answer/target list for assessment and
                # saves; show only plausible partners for the current question.
                s['questionWithoutArt']=['count']
                s['discoveryChoices']={
                    'count':['ten','ears','five'],
                    'apple_helper':['sweet','nose','ears'],
                    'tongue_job':['nose','taste_buds','ears'],
                    'taste_word':['loud','sweet','five'],
                }
            if s['id']=='unit_03.last-discoveries.v2':
                s['discoveryChoices']={
                    'dust_guard':['eyelash','nose','knee'],
                    'arm_joint':['knee','elbow','eyelash'],
                }
        return
    old = deepcopy(book['steps'])
    by = {i+1:s for i,s in enumerate(old)}
    def sid(n): return by[n]['id']
    def item(id,label=None,art=None):
        return dict(id=id,label=label or id.replace('_',' ').title(),art=art or id)
    def stage(base,id,merged,groups=None,**changes):
        s=deepcopy(by[base]);s.update(id='unit_03.'+id,**changes)
        s['legacyMergedFrom']=[sid(n) for n in merged]
        s['legacyCompletionGroups']=[[sid(n) for n in group] for group in (groups or [[n] for n in merged])]
        s.pop('spotLabel',None)
        return s
    def mapping(s,options,targets,answer):
        s.update(kind='match-lines',options=options,targets=targets,answer={'type':'mapping','value':answer})
    def extras(s,numbers):
        s['relatedSources']=[deepcopy(by[n]['source']) for n in numbers]
        s['extraObjectives']=[by[n]['objective'] for n in numbers]
    first=deepcopy(by[1]);first['prompt']='Meet our explorer! Touch a hand button and listen. Follow its line to the body part.'
    first['activityView']='body';first['legacyCompletionGroups']=[[sid(1)]]
    first['legacyMergedFrom']=[sid(1)]
    senses=stage(2,'five-senses.v2',[2,3],title='Five ways to discover',activityView='sense-story',
        prompt='You have five ways to discover the world. Touch all five senses.',
        explanation='We see with our eyes, hear with our ears, smell with our nose, taste with our tongue and touch with our skin.')
    senses['options']=[item(a,b,c) for a,b,c in [('sight','Sight','eyes'),('hearing','Hearing','ears'),('smell','Smell','nose'),('taste','Taste','tongue'),('touch','Touch','skin')]]
    senses['senseDescriptions']={o['id']:v for o,v in zip(senses['options'],[
        'We see with our eyes.','We hear with our ears.','We smell with our nose.','We taste with our tongue.','We touch with our skin.'])}
    senses['minTouches']=5
    body=stage(4,'body-workshop.v2',range(4,17),title='Explorer workshop',activityView='body',
        prompt='Choose a name, then touch the hand button pointing to that part. You can drag the name onto the button too.')
    labels=[deepcopy(by[n]['options'][0]) for n in range(4,17)]
    mapping(body,labels,[deepcopy(x) for x in labels],{x['id']:x['id'] for x in labels})
    body['kind']='label-diagram';body['explanation']='You found the explorer’s head, neck, chin, shoulder, arm, elbow, wrist, hand, fingers, leg, knee, ankle and foot.'
    body['legacyPlacementSources']={sid(n):{by[n]['options'][0]['id']:by[n]['options'][0]['id']} for n in range(4,17)}
    eye=stage(38,'eye-workshop.v2',[17,18,19,38],[[17,38],[18,38],[19,38]],
        title='Around my eye',activityView='body',scene='eye',
        prompt='Give the three eye protectors their names. Choose a name, then touch the hand button pointing to the part.')
    names=[item(x) for x in ['eyelash','eyebrow','eyelid']]
    mapping(eye,names,deepcopy(names),{x['id']:x['id'] for x in names});eye['kind']='label-diagram'
    eye['legacyPlacementSources']={sid(n):{by[n]['options'][0]['id']:by[n]['options'][0]['id']} for n in [17,18,19]}
    match=stage(33,'sense-partners.v2',[20,21,22,23,24,33,45],[[20,33],[21,33,45],[22,33],[23,33],[24,33]],
        title='Find my partner',prompt='Match each sense to the part we use.',activityView='discovery')
    extras(match,[45])
    stories=stage(42,'sense-stories.v2',[25,26,27,28,29,42],[[42]],title='My discovery trail')
    # Each source example remains available, on one board rather than five pages.
    for n in range(25,30):
        key=f'example_{n}';stories['options'].append(item(key,by[n]['prompt'],by[n]['focus']))
        stories['answer']['value'][key]=by[n]['answer']['value']
    melon=deepcopy(by[30]);melon['legacyMergedFrom']=[sid(30)];melon['legacyCompletionGroups']=[[sid(30)]]
    marbles=stage(39,'marbles.v2',[31,32,39,40],[[31,39],[32,40]],title='Biggest and smallest',
        prompt='Give the biggest-hand badge and the smallest-hand badge to the right children.',activityView='marble-match')
    mapping(marbles,[item('most','Biggest hand','big_hand'),item('fewest','Smallest hand','small_hand')],
        [item(x) for x in ['david','zara','jack']],{'most':'zara','fewest':'jack'})
    marbles['explanation']='Zara has the biggest handful: 9 marbles. Jack has the smallest: 5 marbles. David has 6.'
    marbles['legacyPlacementSources']={sid(n):{key:value} for n,key,value in [(31,'most','zara'),(39,'most','zara'),(32,'fewest','jack'),(40,'fewest','jack')]}
    detective=stage(34,'sense-lab.v2',[34,35,36,37,46,47],[[34,47],[35,46],[36],[37]],
        title='Sense detective',prompt='Complete the four discoveries. Match each card to its answer.',activityView='discovery')
    questions=[item('count','How many senses?','five'),item('tongue_job','On the tongue','tongue'),
        item('apple_helper','Hold this to make the apple harder to taste','apple'),item('taste_word','With sour and salty','lemon')]
    mapping(detective,questions,[item(x) for x in ['nose','ten','sweet','taste_buds','ears','five','loud']],
        {'count':'five','tongue_job':'taste_buds','apple_helper':'nose','taste_word':'sweet'})
    detective['explanation']='We have five senses. Taste buds are on the tongue. Smell and taste work together. Sweet, sour and salty are tastes.'
    detective['legacyPlacementSources']={sid(n):{k:v} for n,k,v in [(34,'count','five'),(47,'count','five'),(35,'tongue_job','taste_buds'),(46,'tongue_job','taste_buds'),(36,'apple_helper','nose'),(37,'taste_word','sweet')]}
    extras(detective,[46,47])
    doctor=deepcopy(by[41]);apple=deepcopy(by[43]);shoe=deepcopy(by[44])
    for s,n in [(doctor,41),(apple,43),(shoe,44)]:s.update(legacyMergedFrom=[sid(n)],legacyCompletionGroups=[[sid(n)]])
    final=stage(48,'last-discoveries.v2',[48,49],title='Two last discoveries',
        prompt='Find the part for each job.',activityView='discovery')
    mapping(final,[item('dust_guard','Keeps dust out','dust'),item('arm_joint','Between wrist and shoulder','arm')],
        [item(x) for x in ['knee','eyelash','elbow','nose']],{'dust_guard':'eyelash','arm_joint':'elbow'})
    final['explanation']='Eyelashes keep dust out. The elbow is between the wrist and shoulder.'
    final['legacyPlacementSources']={sid(48):{'dust_guard':'eyelash'},sid(49):{'arm_joint':'elbow'}}
    extras(final,[49])
    book['legacyStepIds']=[s['id'] for s in old]
    book['legacyAssessmentObjectives']={s['id']:s['objective'] for s in old if s['assessed']}
    book['steps']=[first,senses,body,eye,match,stories,melon,marbles,detective,doctor,apple,shoe,final]
    book['contentVersion']=2
    for s in book['steps']:
        s['playScene']='ourselves'
        s.pop('spotLabel',None)
        if s['answer'] and s['answer']['type']=='mapping':
            s['options']=s['options'][::2]+s['options'][1::2]
    compact_ourselves(book)

if __name__=='__main__':
    import json
    from pathlib import Path
    path=Path(__file__).resolve().parents[1]/'assets/content/playable/unit_03.json'
    book=json.loads(path.read_text(encoding='utf-8'))
    compact_ourselves(book)
    path.write_text(json.dumps(book,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
