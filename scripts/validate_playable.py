"""Validate runtime schema, unique answers, source coverage, and quiz weighting."""
import json
from pathlib import Path
import jsonschema
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
 for step in book['steps']:
  assert step['id'] not in seen;seen.add(step['id']);total+=1
  assert step['source']['sourceSha256']==source['sourceSha256']
  qid=step['source']['questionId']
  if qid:
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
  else: assert not step['assessed']
  if step['kind']=='predict-then-reveal':
   assert not step['assessed'] and step['frames']
 assert covered==set(originals),(file,set(originals)-covered)
 if book['quiz']:
  assert len(book['steps'])==10
  assert len({s['objective'] for s in book['steps'] if s['assessed']})==10
 else:assert book['steps'][0]['kind']=='explore'
 for sticker in book['stickers']:
  if sticker['meaningSource']=='not_defined_in_book':assert not sticker['meaning']
  else:assert sticker['meaning'].strip()
 print('PASS',file.name,len(book['steps']),'steps; all source objectives covered')
print('PASS',total,'steps; schema, IDs, answer references and prediction exclusion')
