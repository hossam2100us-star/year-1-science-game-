"""Audit Maths source coverage, answers, diagrams, navigation and reproducibility.

Run with --source-pdf PATH for an independent comparison with the supplied PDF.
Run with --check-idempotence to rebuild and verify byte-for-byte reproducibility
and that every existing Science content file remains untouched.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CONTENT = ROOT / 'assets/content'
EXPECTED_IDS = ([f'math_unit_{n:02d}' for n in range(1,19)]
    + [f'math_quiz_{n:02d}' for n in range(1,4)] + ['math_charts'])
KNOWN_PAGES = [(4,7,72),(8,10,72),(11,14,73),(15,17,73),(18,20,74),(21,23,74),
    (25,27,75),(28,31,76),(32,34,76),(35,37,77),(38,40,77),(41,43,78),
    (45,47,79),(48,50,79),(51,53,80),(54,56,80),(57,59,81),(60,63,81)]
REVIEW5_PICTURES={'math_quiz_01':[4,5,6],'math_quiz_02':[6],'math_quiz_03':[7],'math_unit_01':[12],
    'math_unit_02':[12],'math_unit_03':[13],'math_unit_04':[10,11,12,14],'math_unit_06':[10],
    'math_unit_07':[5,10,13,14],'math_unit_08':[7,14],'math_unit_10':[7,11,12],'math_unit_15':[9,10],
    'math_unit_16':[10,13,14],'math_unit_18':[10]}
FREE_QUESTIONS = {'math.u01.main.05','math.u01.main.08','math.u03.main.08',
    'math.u04.main.08','math.u06.main.08','math.u07.main.08','math.u08.main.04',
    'math.u12.main.07','math.u12.main.08','math.u14.main.08','math.u15.main.06',
    'math.u16.main.08','math.u17.main.08','math.u18.main.03','math.u18.main.07'}


def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def normalized(text):
    return ' '.join(text.replace('—','-').replace('–','-').replace('−','-').split()).casefold()


def selected_labels(step):
    labels={o['id']:o['label'] for o in step['options']+step['targets']}
    answer=step['answer']
    if answer['type']=='mapping':
        return {labels[k]:labels[v] for k,v in answer['value'].items()}
    if answer['type']=='single': return labels[answer['value']]
    return [labels[v] for v in answer['value']]


def question(books,qid):
    return next(s for b in books.values() for s in b['steps'] if s['source']['questionId']==qid)


def expect(books,qid,value):
    step=question(books,qid)
    actual=selected_labels(step)
    assert actual==value,(qid,'answer',actual,value)
    return step


def visuals(value):
    if isinstance(value,dict):
        if 'type' in value and value['type'] in {'count','shape','clock','chart','numberLine','pattern','fraction','groups','money','ruler','text','missing','balance','sky','venn','robot','carroll'}:
            yield value
        for child in value.values(): yield from visuals(child)
    elif isinstance(value,list):
        for child in value: yield from visuals(child)


def audit_visuals(book):
    for visual in visuals(book):
        kind=visual['type']
        if kind=='count':
            assert isinstance(visual['count'],int) and 0<=visual['count']<=20
            assert visual.get('arrangement','row') in {'row','scattered','tenFrame','pairs'}
            if visual.get('arrangement')=='tenFrame': assert visual['count']<=10
        elif kind=='clock':
            assert 1<=visual['hour']<=12 and visual['minute'] in [0,30]
        elif kind=='chart':
            assert visual['title'] and visual['unit']
            assert visual['style'] in ['pictogram','block','bar']
            assert visual['rows'] and len({r['label'] for r in visual['rows']})==len(visual['rows'])
            assert all(isinstance(r['value'],int) and r['value']>=0 for r in visual['rows'])
            if 'axisMax' in visual:
                assert isinstance(visual['axisMax'],int) and visual['axisMax']>=max(r['value'] for r in visual['rows'])
            if 'tickStep' in visual:
                assert isinstance(visual['tickStep'],int) and visual['tickStep']>0
                assert visual.get('axisMax',max(r['value'] for r in visual['rows'])) % visual['tickStep']==0
        elif kind=='shape':
            assert visual['shape'] in ['circle','oval','triangle','square','rectangle','cube','cuboid','sphere','cylinder','cone','pyramid']
        elif kind=='fraction':
            assert visual['parts'] in [2,4] and 0<=visual['shaded']<=visual['parts']
            assert isinstance(visual['equal'],bool)
        elif kind=='numberLine': assert visual['start']<visual['end']
        elif kind=='money': assert visual['unit']=='piastres' and all(c in [25,50,100] for c in visual['coins'])
        elif kind=='ruler': assert isinstance(visual['units'],int) and 1<=visual['units']<=10
        elif kind=='balance':
            left,right=visual['left']['count'],visual['right']['count']
            assert 1<=left<=9 and 1<=right<=9
            # The side holding more goes down.
            assert visual['tilt']==('left' if left>right else 'right' if right>left else 'level')
        elif kind=='sky': assert visual['time'] in ['morning','midday','night']
        elif kind=='venn':
            assert len(visual['labels'])==2
            assert all(i['region'] in ['left','right','both','outside'] for i in visual['items'])
        elif kind=='robot':
            assert visual['facing'] in ROBOT_FACINGS and visual['routes']
            assert all(0<=visual[k][0]<visual['cols'] and 0<=visual[k][1]<visual['rows'] for k in ['start','star'])
            assert all(set(route)<={'F','B','L','R'} for route in visual['routes'].values())
        elif kind=='carroll': assert len(visual['columns'])>=2


ROBOT_FACINGS=['up','right','down','left']
ROBOT_MOVES=[(0,-1),(1,0),(0,1),(-1,0)]


def robot_end(visual,route):
    """Where a route leaves the robot (the picture draws the same moves)."""
    (x,y),facing=visual['start'],ROBOT_FACINGS.index(visual['facing'])
    for move in route:
        if move=='R': facing=(facing+1)%4
        elif move=='L': facing=(facing+3)%4
        else:
            dx,dy=ROBOT_MOVES[facing]; sign=1 if move=='F' else -1
            x,y=x+sign*dx,y+sign*dy
    return [x,y]


def audit_workshop(book):
    """Completion must represent a guided maths action, rather than card visits."""
    intro=book['steps'][0]
    workshop=intro['mathWorkshop']
    assert intro['kind']=='explore' and not intro['assessed'] and intro['answer'] is None
    assert intro['objective']=='' and intro['source']['questionId'] is None
    assert workshop['title'] and workshop['goal'] and workshop['scene'] in {'orchard','workshop','village','harbour'}
    assert 2<=len(workshop['tasks'])<=3
    assert [t['id'] for t in workshop['tasks']]==[o['id'] for o in intro['options']]
    assert len({t['id'] for t in workshop['tasks']})==len(workshop['tasks'])
    assert 'Tap every discovery' not in intro['prompt'] and intro['title']!='Maths explorers'
    for task in workshop['tasks']:
        assert task['mode'] in {'count','build','choose'}
        assert task['prompt'].strip() and task['feedback'].strip() and task['hint'].strip()
        assert task['feedback']!=workshop['goal'] and len(task['prompt'].split())<=32
        if task['mode']=='count':
            assert isinstance(task['count'],int) and 1<=task['count']<=10
            assert task['arrangement'] in {'row','scattered'}
            assert task['item'] in {'apple','star','bean','counter'}
        if task['mode']=='build':
            assert isinstance(task['target'],int) and 0<=task['target']<=20
            assert isinstance(task['initialCount'],int) and 0<=task['initialCount']<=20
            assert task['initialCount']!=task['target']
            assert task['item'] in {'apple','star','bean','counter'}
            assert task['maxCount']>=max(task['initialCount'],task['target']) and task['maxCount']<=20
            assert task['arrangement'] in {'row','tenFrame'}
            continue
        choices=task['choices']
        assert 2<=len(choices)<=4 and len({c['id'] for c in choices})==len(choices)
        assert len({c['label'] for c in choices})==len(choices)
        assert task['correctId'] in {c['id'] for c in choices}
        if task['mode']=='count':
            chosen=next(c for c in choices if c['id']==task['correctId'])
            assert chosen['value']==task['count'] and chosen['label']==str(task['count'])
    return workshop


def audit_source_pdf(path,drafts):
    """Compare against a fresh PDF read, independently of builder constants."""
    import pdfplumber
    digest=hashlib.sha256(path.read_bytes()).hexdigest()
    with pdfplumber.open(path) as pdf:
        assert len(pdf.pages)==83
        pages=[p.extract_text() or '' for p in pdf.pages]
    for ident,draft in drafts.items():
        assert draft['sourceSha256']==digest,(ident,'source digest')
        for record in draft['sourceQuestions']:
            answer_pages='\n'.join(pages[p-1] for p in record['answerKeyPages'])
            if record['category']=='choice':
                n=int(ident[-2:])
                block=answer_pages.split(f'Unit {n} — ',1)[1]
                block=re.split(r'\n(?:Unit \d+ — |Quiz \d+ — )',block,1)[0]
                block=normalized(block.split('Choose the correct answer:',1)[1])
                # Each answer key lists MCQs inline, separated by bullets.
                matches=re.findall(r'(?:^|\s•\s)([1-5])\s+(.+?)(?=\s•\s[1-5]\s|$)',block)
                actual=dict((int(i),t.split('maths made simple',1)[0].strip()) for i,t in matches)
                assert normalized(record['answerKeyText'])==actual[record['number']],(record['id'],'PDF MCQ answer differs',actual)
            else:
                # Main/quiz keys preserve the whole teacher response verbatim.
                assert normalized(record['answerKeyText']) in normalized(answer_pages),(record['id'],'PDF answer text differs')
    print('PASS PDF SHA-256 and all 273 original Answer Key responses independently verified.')


def audit_diagram_answers(books):
    # Independent, source-reviewed visual oracles. These checks catch changed
    # graph counts, answer labels, shaded parts and clock parameters together.
    step=expect(books,'math.u01.main.01','8'); assert step['mathVisual']['count']==8
    step=expect(books,'math.u01.main.02','13'); assert step['mathVisual']['count']==13
    expect(books,'math.u01.main.03',{'11, 12, __, 14':'13','14, 15, __, 17':'16','17, __, 19, 20':'18'})
    step=expect(books,'math.u01.main.04',{'A':'4','B':'6','C':'10'})
    assert [v['count'] for v in step['mathVisual']['items']]==[4,6,10]
    expect(books,'math.u02.main.04','4 + 3 = 7')
    assert [v['count'] for v in question(books,'math.u02.main.04')['mathVisual']['items']]==[4,3]
    fruit=question(books,'math.u04.main.01')['mathVisual']; f={r['label']:r['value'] for r in fruit['rows']}
    assert fruit['unit']=='one person'
    assert f=={'apple':4,'banana':2,'orange':3,'mango':1}
    expect(books,'math.u04.main.01',str(f['apple']))
    expect(books,'math.u04.main.02',max(f,key=f.get)); expect(books,'math.u04.main.03',min(f,key=f.get))
    expect(books,'math.u04.main.04',str(f['banana']+f['orange'])); expect(books,'math.u04.main.05',str(sum(f.values())))
    # Boundary values must not accidentally go into "less than 10".
    expect(books,'math.u07.main.04',{'3':'less than 10','12':'not less than 10','7':'less than 10','15':'not less than 10','9':'less than 10','18':'not less than 10','10':'not less than 10'})
    expect(books,'math.u09.main.01','14'); expect(books,'math.u09.main.02','19')
    for q,total in [('math.u09.main.01',14),('math.u09.main.02',19)]:
        assert sum(v['count'] for v in question(books,q)['mathVisual']['items'])==total
    step=expect(books,'math.u10.main.05','6'); assert step['mathVisual']['units']==6
    expect(books,'math.u12.main.01',['a','c'])
    parts={o['label']:o['visual'] for o in question(books,'math.u12.main.01')['options']}
    assert {k for k,v in parts.items() if v['equal']}=={'a','c'} and parts['c']['orientation']=='diagonal'
    expect(books,'math.u13.main.01',['2','8','14'])
    step=expect(books,'math.u13.main.02','odd'); assert step['mathVisual']['count']==7 and step['mathVisual']['arrangement']=='pairs'
    step=expect(books,'math.u13.main.05','3rd'); assert 'third star from the left' in step['prompt']
    step=expect(books,'math.u13.main.07','b')
    assert [v['coins'] for v in step['mathVisual']['items']]==[[50],[100],[25]]
    expect(books,'math.u15.main.08',['2 forwards, turn right, 2 forwards','turn right, 2 forwards, turn left, 2 forwards'])
    school=question(books,'math.u16.main.01')['mathVisual']; s={r['label']:r['value'] for r in school['rows']}
    assert school['unit']=='one child'
    assert s=={'walk':6,'bus':4,'car':3,'bike':2}
    expect(books,'math.u16.main.01',str(s['walk'])); expect(books,'math.u16.main.02',str(s['bus']))
    expect(books,'math.u16.main.03',max(s,key=s.get)); expect(books,'math.u16.main.04',min(s,key=s.get))
    expect(books,'math.u16.main.05',str(s['walk']-s['car'])); expect(books,'math.u16.main.06',str(sum(s.values())))
    assert question(books,'math.u16.main.08')['mathVisual']==school
    expect(books,'math.u17.main.05',['a','c'])
    parts={o['label']:o['visual'] for o in question(books,'math.u17.main.05')['options']}
    assert {k for k,v in parts.items() if v['shaded']/v['parts']==0.5}=={'a','c'}
    step=expect(books,'math.u18.main.01',"4 o'clock"); assert (step['mathVisual']['hour'],step['mathVisual']['minute'])==(4,0)
    step=expect(books,'math.u18.main.02','half past 7'); assert (step['mathVisual']['hour'],step['mathVisual']['minute'])==(7,30)
    expect(books,'math.u18.main.05',{'measure a pencil':'ruler','weigh flour':'scales','measure water':'jug'})
    expect(books,'math.u18.main.06',['jug','bowl','mug'])
    step=expect(books,'math.q03.09',"2 o'clock"); assert (step['mathVisual']['hour'],step['mathVisual']['minute'])==(2,0)
    expect(books,'math.charts.01','4'); expect(books,'math.charts.02','cars'); expect(books,'math.charts.03','10')
    assert question(books,'math.charts.01')['mathVisual']['unit']=='one toy'
    expect(books,'math.charts.04','Wed'); expect(books,'math.charts.05','4'); expect(books,'math.charts.06','2')
    expect(books,'math.charts.07','8'); expect(books,'math.charts.08','crows'); expect(books,'math.charts.09','9')
    assert [r['value'] for r in question(books,'math.charts.07')['mathVisual']['rows']]==[6,8,3]
    assert question(books,'math.charts.04')['mathVisual']['unit']=='one star earned'
    assert question(books,'math.charts.07')['mathVisual']['unit']=='one bird'
    bird_visuals=[t['visual'] for t in books['math_charts']['steps'][0]['mathWorkshop']['tasks'] if t.get('visual',{}).get('style')=='bar']
    bird_visuals += [question(books,f'math.charts.{n:02d}')['mathVisual'] for n in [7,8,9]]
    assert len(bird_visuals)==4
    assert all(v['axisMax']==10 and v['tickStep']==2 for v in bird_visuals)
    assert all([r['value'] for r in v['rows']]==[6,8,3] for v in bird_visuals)
    assert sum(1 for book in books.values() for v in visuals(book) if v.get('tickStep')==2)==4
    assert question(books,'math.u07.main.05')['mathVisual']['unit']=='one child'
    print('PASS counting, place value, graph arithmetic, sorting boundaries, ordinal, money, halves and clock diagrams.')


def audit(check_idempotence=False,pdf_path=None):
    import jsonschema
    schema=read(ROOT/'schemas/lesson.schema.json')
    drafts={ident:read(CONTENT/f'{ident}.json') for ident in EXPECTED_IDS}
    books={ident:read(CONTENT/'playable'/f'{ident}.json') for ident in EXPECTED_IDS}
    arabic=read(CONTENT/'maths_parent_ar.json')
    question_ids=set(); step_ids=set(); free_ids=set(); assessed=0; total_steps=0; workshops=[]; numeric_positions=[]
    source_hash={d['sourceSha256'] for d in drafts.values()}; assert len(source_hash)==1
    for ident,book in books.items():
        draft=drafts[ident]; jsonschema.validate(book,schema)
        assert book['subject']=='maths' and book['id']==ident and book['contentVersion']==2 and draft['contentVersion']==2
        expected=10 if ident.startswith('math_quiz_') else 9 if ident=='math_charts' else 13
        assert len(draft['sourceQuestions'])==expected,(ident,'source count')
        records={q['id']:q for q in draft['sourceQuestions']}
        assert not question_ids & records.keys(); question_ids.update(records)
        covered=set()
        assert book['sourceSha256']==draft['sourceSha256']
        if ident.startswith('math_unit_'):
            start,end,key=KNOWN_PAGES[int(ident[-2:])-1]
            assert draft['sourcePages']==list(range(start,end+1))
            assert all(q['answerKeyPages']==[key] for q in records.values())
        if book['quiz']:
            assert len(book['steps'])==10 and all(s['assessed'] for s in book['steps'])
            assert book['practiceUnitId'] in EXPECTED_IDS and book['practiceUnitId'].startswith('math_unit_')
        else:
            first=book['steps'][0]; assert first['kind']=='explore'
            assert 0<first['minTouches']<=len(first['options'])
            workshops.append(audit_workshop(book))
        for step in book['steps']:
            assert step['id'] not in step_ids; step_ids.add(step['id']); total_steps+=1
            assert step['playScene']=='maths'
            assert step['source']['sourceSha256']==draft['sourceSha256']
            qid=step['source']['questionId']
            if qid:
                assert qid in records; covered.add(qid)
                assert step['source']['answerKeyText']==records[qid]['answerKeyText']
            if step['assessed']:
                assessed+=1; assert step['objective']==qid
                assert step['answer'] is not None and qid not in FREE_QUESTIONS
                if step['answer']['type']=='single' and all(o['label'].isdigit() for o in step['options']):
                    numeric_positions.append(next(i for i,o in enumerate(step['options']) if o['id']==step['answer']['value']))
                if step['answer']['type']=='sequence':
                    assert [o['id'] for o in step['options']]!=step['answer']['value'],(step['id'],'sequence already solved')
            elif qid:
                free_ids.add(qid); assert step['kind']=='story' and step['answer'] is None
                assert step['objective']=='' and step['parentReview']['en']==records[qid]['answerKeyText']
            assert all(1<=p<=83 for p in step['source']['pages']+step['source']['answerKeyPages'])
            assert len(step['shortExplanation'].split())<=16
        assert covered==records.keys(),(ident,'missing source coverage',records.keys()-covered)
        assert {a['objective'] for a in book['goalActivities']}=={s['objective'] for s in book['steps'] if s['assessed']}
        assert all(s['word'] and s['meaning'] for s in book['stickers'])
        assert all(a['textAr'] and a['safetyAr'] for a in book['homeActivities']+book['goalActivities'])
        # Each activity has its own Arabic from maths_parent_ar.json (the first
        # version gave all 280 the same generic sentence).
        assert all(a['textAr']==arabic['goal'][f"{ident}/{a['objective']}"] for a in book['goalActivities']),(ident,'goal Arabic')
        assert all(a['textAr']==arabic['home'][ident] for a in book['homeActivities']),(ident,'home Arabic')
        assert all(a['safetyAr']==arabic['safety'][a['safety']] for a in book['homeActivities']+book['goalActivities'])
        audit_visuals(book)
        for step in book['steps']:
            visual=step.get('mathVisual') or {}
            if visual.get('type')=='robot':
                labels={o['id']:o['label'] for o in step['options']}
                assert set(visual['routes'])==set(labels.values()),(step['id'],'robot routes')
                reach={label for label,route in visual['routes'].items() if robot_end(visual,route)==visual['star']}
                assert reach=={labels[i] for i in step['answer']['value']},(step['id'],'robot answer')
            if visual.get('type')=='numberLine' and 'from' in visual:
                # Jumps stay on the line; where they land (or how far they go)
                # is the correct answer.
                at=visual['from']; assert visual['start']<=at<=visual['end']
                for move in visual['jumps']:
                    at+=move; assert visual['start']<=at<=visual['end'],(step['id'],'jump off the line')
                expected=at if visual['ask']=='landing' else abs(at-visual['from'])
                labels={o['id']:o['label'] for o in step['options']}
                assert labels[step['answer']['value']]==str(expected),(step['id'],'number line answer')
            if visual.get('type')=='carroll':
                assert visual['columns']==[t['label'] for t in step['targets']],(step['id'],'carroll')
    assert len(question_ids)==273 and free_ids==FREE_QUESTIONS and assessed==258 and total_steps==292
    # Teacher review 5: these questions talked about something not shown.
    for ident,numbers in REVIEW5_PICTURES.items():
        for n in numbers:
            step=next(s for s in books[ident]['steps'] if s['id']==f'{ident}.step.{n:03d}')
            assert step.get('mathVisual') or any(o.get('visual') for o in step['options']),(step['id'],'no picture')
    assert len(workshops)==19 and len({w['title'] for w in workshops})==19
    assert len({w['goal'] for w in workshops})==19
    tasks=[t for w in workshops for t in w['tasks']]
    assert len(tasks)==57 and {t['mode'] for t in tasks}=={'count','build','choose'}
    assert len({t['prompt'] for t in tasks})>=55 and len({t['feedback'] for t in tasks})>=55
    assert {0,1,2}<=set(numeric_positions)
    assert max(numeric_positions.count(p) for p in set(numeric_positions))/len(numeric_positions)<0.5,'A predictable numeric answer position remains'
    first=books['math_unit_01']['steps'][0]['mathWorkshop']['tasks']
    assert first[0]['mode']=='count' and first[0]['count']==7 and first[0]['item']=='apple'
    assert first[1]['mode']=='choose' and first[1]['visual']['count']==7 and first[1]['visual']['arrangement']=='scattered'
    assert next(c for c in first[1]['choices'] if c['id']==first[1]['correctId'])['label']=='7'
    assert first[2]['mode']=='build' and first[2]['target']==10 and first[2]['arrangement']=='tenFrame'
    catalog=read(CONTENT/'maths_catalog.json')
    levels=[l for i in catalog['islands'] for l in i['levels']]
    assert len(catalog['islands'])==4 and len(levels)==22
    assert {l['id'] for l in levels}==set(EXPECTED_IDS)
    assert len({l['id'] for l in levels})==22
    assert catalog['title']=='Maths' and catalog['subject']=='maths' and catalog['contentVersion']==2
    assert all('Seif Hossam Nader' not in p.read_text(encoding='utf-8-sig') for p in CONTENT.glob('math*.json'))
    support=read(CONTENT/'math_support.json')
    assert support['sourceSha256'] in source_hash and support['sortingCards']['numbers']==list(range(1,21))
    audit_diagram_answers(books)
    if pdf_path: audit_source_pdf(pdf_path,drafts)
    if check_idempotence:
        all_paths=list(CONTENT.rglob('*.json'))
        before={p:hashlib.sha256(p.read_bytes()).hexdigest() for p in all_paths}
        subprocess.run([sys.executable,str(ROOT/'scripts/build_maths_content.py')],check=True)
        assert all_paths==list(CONTENT.rglob('*.json')),'Build changed the content file inventory'
        assert all(hashlib.sha256(p.read_bytes()).hexdigest()==digest for p,digest in before.items()),'Build is not idempotent or touched protected content'
        print('PASS repeat build is byte-for-byte identical; all existing Science content is unchanged.')
    print(f'PASS Maths: 18 units, 3 quizzes, 9 chart questions; {len(question_ids)} sources, {assessed} assessed, 15 ungraded, {total_steps} steps; 19 workshops and 57 guided tasks.')


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source-pdf',type=Path)
    parser.add_argument('--check-idempotence',action='store_true')
    args=parser.parse_args()
    audit(args.check_idempotence,args.source_pdf)
