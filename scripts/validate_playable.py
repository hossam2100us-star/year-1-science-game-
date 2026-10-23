"""Validate runtime schema, unique answers, source coverage, and quiz weighting."""
import json
from pathlib import Path
import jsonschema
from child_feedback import feedback_issues, load_overrides
ROOT=Path(__file__).resolve().parents[1]
schema=json.loads((ROOT/'schemas/lesson.schema.json').read_text(encoding='utf-8'))
jsonschema.Draft202012Validator.check_schema(schema)
seen=set();total=0
for file in sorted((ROOT/'assets/content/playable').glob('*.json')):
 book=json.loads(file.read_text(encoding='utf-8'))
 jsonschema.validate(book,schema)
 source=json.loads((ROOT/'assets/content'/file.name).read_text(encoding='utf-8-sig'))
 assert book['sourceSha256']==source['sourceSha256']
 originals={q['id']:q for q in source['sourceQuestions']}
 covered=set()
 overrides=load_overrides(book['id'])
 assert set(overrides)<=set(s['id'] for s in book['steps']),(file,'stale child feedback IDs')
 for step in book['steps']:
  assert step['id'] not in seen;seen.add(step['id']);total+=1
  assert step['source']['sourceSha256']==source['sourceSha256']
  if step['assessed'] or step['explanation'].strip():
   assert not feedback_issues(step['explanation']),(file,step['id'],feedback_issues(step['explanation']))
  for field,text in overrides.get(step['id'],{}).items():
   assert step[field]==text,(file,step['id'],'editorial feedback was overwritten')
  qid=step['source']['questionId']
  # Maths worksheet and class-book questions are not from the companion;
  # validate_maths_content.py checks them.
  worksheet=bool(qid) and ('.sheet.' in qid or '.book.' in qid)
  if qid and not worksheet:
   covered.add(qid);assert qid in originals,(file,qid)
   assert step['source']['answerKeyText']==originals[qid]['answerKeyText']
  for related in step.get('relatedSources', []):
   rid=related['questionId']
   assert rid in originals,(file,rid)
   assert related['answerKeyText']==originals[rid]['answerKeyText']
   assert related['sourceSha256']==source['sourceSha256']
   covered.add(rid)
  if step['assessed']:
   assert qid and step['objective']==qid
   assert step['hint'].strip() and step['explanation'].strip()
  assert 'shortExplanation' in step,(file,step['id'],'short explanation missing')
  assert len(step['shortExplanation'].split())<=16,(file,step['id'],'visible explanation too long')
  if step['explanation']: assert step['shortExplanation'].strip()
  options=[o['id'] for o in step['options']]
  targets=[t['id'] for t in step['targets']]
  assert len(options)==len(set(options))
  assert len(targets)==len(set(targets))
  answer=step['answer']
  if answer:
   value=answer['value']
   if answer['type']=='single':assert value in options
   elif answer['type'] in ['set','sequence']:
    assert value and len(value)==len(set(value)) and set(value)<=set(options)
    if answer['type']=='sequence':assert set(value)==set(options)
   elif answer['type']=='mapping':
    assert set(value)==set(options) and set(value.values())<=set(targets)
   elif answer['type']=='number':assert isinstance(value,int) and not options
   elif answer['type']=='sentence':assert set(value)=={'a','op','b','c'} and not options
  else: assert not step['assessed']
  if step['kind']=='predict-then-reveal':
   assert not step['assessed'] and step['frames']
  scene=step.get('soundScene',{})
  if 'missionChoices' in scene:
   groups=scene['missionChoices']
   assert set(groups)==set(options),(file,step['id'],'mission coverage')
   for question,choices in groups.items():
    assert 2<=len(choices)<=3 and len(choices)==len(set(choices))
    assert set(choices)<=set(targets)
    assert answer['value'][question] in choices
  if 'chartQuestionSource' in step:
   adapted=step['chartQuestionSource']
   assert adapted['contentId']=='charts'
   chart=json.loads((ROOT/'assets/content/charts.json').read_text(encoding='utf-8-sig'))
   assert chart['sourceSha256']==book['sourceSha256']
   assert set(adapted['pages'])<=set(chart['sourcePages'])
   assert set(adapted['pages'])<=set(step['source']['pages'])
   assert adapted['questionText'] in chart['sourceText']
   row=next(row for row in step['table'] if row['name']==adapted['person'])
   assert answer['value'][adapted['optionId']]==f"{row['value']}_steps"
 assert covered==set(originals),(file,set(originals)-covered)
 goals={goal for step in book['steps'] if step['assessed'] for goal in [step['objective']]+step.get('extraObjectives',[])}
 activities=book.get('goalActivities',[])
 assert {a['objective'] for a in activities}==goals,(file,'goal activity coverage')
 assert len(activities)==len(goals),(file,'duplicate goal activities')
 for activity in activities:
  assert activity['text'].strip() and activity['safety'].strip() and activity['adapted'] is True
  goal_step=next(s for s in book['steps'] if activity['objective'] in [s['objective']]+s.get('extraObjectives',[]))
  allowed_pages={p for source_record in [goal_step['source']]+goal_step.get('relatedSources',[]) for p in source_record['pages']}
  assert activity['pages'] and set(activity['pages'])<=allowed_pages
  assert activity['safetyPages']==[2]
 if book['quiz']:
  assert len(book['steps'])==10
  assert len({s['objective'] for s in book['steps'] if s['assessed']})==10
 else:assert book['steps'][0]['kind']=='explore'
 if book['id']=='quiz_01':
  hints=[s['hint'].strip().casefold() for s in book['steps']]
  assert len(hints)==len(set(hints)),(file,'Quiz 1 needs a different hint for each question')
 if 'legacySoundChart' in book:
  assert not feedback_issues(book['legacySoundChart']['explanation']),(file,'legacy sound explanation')
 for sticker in book['stickers']:
  if sticker['meaningSource']=='not_defined_in_book':assert not sticker['meaning']
  else:assert sticker['meaning'].strip()
 print('PASS',file.name,len(book['steps']),'steps; all source objectives covered')
print('PASS',total,'steps; schema, IDs, answer references and prediction exclusion')
