"""Replace repeated plant questions with distinct source-linked activities."""
from copy import deepcopy

def refine_plants(book, source):
    if book.get('contentVersion') == 2:
        return
    old = deepcopy(book['steps'])
    by = {i+1:s for i,s in enumerate(old)}
    book['legacyStepIds']=[s['id'] for s in old]
    keep=[1,2,3,4,5,6,7,8,9,10,11,12,25,26,27,28,29,30,37,32,33]
    steps=[deepcopy(by[i]) for i in keep]
    new={i:s for i,s in zip(keep,steps)}
    originals={q['id']:q for q in source['sourceQuestions']}
    def refs(step, nums):
        step['relatedSources']=[deepcopy(by[n]['source']) for n in nums]
    fridge=new[12]
    fridge.update(id='unit_02.fridge.v2',title='My fridge collection',
      prompt='Fill the five baskets. Drag each food to the part we eat.',
      options=[by[n]['options'][0] for n in range(12,25)],
      answer={'type':'mapping','value':{by[n]['options'][0]['id']:by[n]['answer']['value'][by[n]['options'][0]['id']] for n in range(12,25)}},
      explanation='Roots: carrot and radish. Stems: celery and sugar cane. Leaves: lettuce, mint and parsley. Flowers: cauliflower and broccoli. Seeds: beans, rice, lentils and peas.',
      assessed=True,objective='u02.main.08',source=deepcopy(by[34]['source']),
      legacyMergedFrom=[by[n]['id'] for n in range(12,25)])
    refs(fridge,[39])
    refs(new[25],[36,38])
    timeline=new[26]
    timeline.update(id='unit_02.bean-trail.v2',kind='order-sequence',
      title='My growing bean story',prompt='Put the four pictures in growing order.',
      options=[{'id':'day8','label':'First green leaves','art':'bean_8'},
               {'id':'day1','label':'Nothing yet','art':'bean_1'},
               {'id':'day7','label':'Shoot grows upwards','art':'bean_7'},
               {'id':'day4','label':'Root grows downwards','art':'bean_4'}],
      answer={'type':'sequence','value':['day1','day4','day7','day8']},
      hint='Think back to the bean in the glass. Look for the root before the shoot.',
      explanation='Day 1: nothing yet. Day 4: a root goes down. Day 7: a shoot goes up. Day 8: the first green leaves open.')
    seed=new[29]
    seed.update(id='unit_02.seed-care.v2',kind='tap-choice',
      title='Wake up the seed',prompt='Choose what the seed needs to start growing.',
      options=[{'id':'water','label':'Water','art':'water'},{'id':'toys','label':'Toys','art':'toys'}],
      answer={'type':'single','value':'water'},hint='Remember the wet cotton in the glass.',
      explanation='A seed needs water to start growing.')
    new[30].update(title='Plant detective',prompt='The plant grew taller. Choose its basket.',
      kind='tap-choice',options=[{'id':'alive','label':'Alive','art':'plant'},{'id':'not_alive','label':'Not alive','art':'plant'}],
      answer={'type':'single','value':'alive'},hint='Something can be alive even if it does not walk.',
      explanation='A plant is a living thing. It grows and needs water.')
    refs(new[28],[40])
    refs(new[37],[31])
    for step in steps:
        if step.get('playScene')!='plant-lab' and not step.get('experiment'):
            step['playScene']='plant-mission'
    book['steps']=steps
    book['contentVersion']=2
    book['legacyReplacements']={by[n]['id']:fridge['id'] for n in range(12,25)}
    book['legacyReplacements'].update({
      by[26]['id']:timeline['id'],by[29]['id']:seed['id'],
      by[31]['id']:new[37]['id'],by[34]['id']:fridge['id'],by[35]['id']:fridge['id'],
      by[36]['id']:new[25]['id'],by[38]['id']:new[25]['id'],by[39]['id']:fridge['id'],by[40]['id']:new[28]['id']})
