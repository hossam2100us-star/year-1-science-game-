"""Attach source-preserving illustrated activities without changing step IDs."""
import json
from pathlib import Path

def refresh_ourselves(book):
    if book['contentVersion'] >= 2:
        return
    for step in book['steps']:
        step['playScene'] = 'ourselves'
        number = int(step['id'].split('.')[-1])
        step['activityView'] = 'body' if number <= 19 else 'discovery'
        step['spotLabel'] = 'Place'
        if step['kind'] == 'label-diagram':
            label = step['options'][0]['label'].lower()
            step['prompt'] = f'Find the {label}. Touch its spot on the explorer, or drag the label there.'
        if number == 1:
            step['minTouches'] = len(step['options'])
        if number == 2:
            step['options'] = [o for o in step['options'] if o['id'] != 'skin']
            step['minTouches'] = 4
        if number == 3:
            step['options'] = [o for o in step['options'] if o['id'] == 'skin']
            step['minTouches'] = 1
        if 20 <= number <= 24:
            label = step['options'][0]['label'].lower()
            step['prompt'] = f'Connect {label} to the body part. Drag the card, or touch the card and its partner.'
        if number == 36:
            step['focus'] = 'Apple'
        if number == 41:
            step['focus'] = 'Optometrist'
        if number == 44:
            step['playUi'] = {'shoe':'Shoe', 'compare':'Compare my numbers',
                'smaller':'Smaller number', 'bigger':'Bigger number',
                'equal':'The two numbers are equal.',
                'result':'{big} is bigger than {small}.'}
    from compact_ourselves import compact_ourselves
    compact_ourselves(book)

def refresh_quiz(book):
    for step in book['steps']:
        number=int(step['id'].split('.')[-1])
        if number in [3,4,5]:
            step['playScene']='plant-mission'
        elif number in [6,7,9,10]:
            step['playScene']='ourselves'
            step['activityView']='body' if number==9 else 'discovery'
            if number==9:
                step['prompt']='Build the path: touch the explorer from shoulder down to fingers.'
        elif number==8:
            step['playScene']='ourselves'
            step['activityView']='discovery'
        elif number in [1,2]:
            step['playScene']='ourselves'
            step['activityView']='park' if number==1 else 'discovery'

if __name__=='__main__':
    root=Path(__file__).resolve().parents[1]/'assets/content/playable'
    for filename, refresh in [('unit_03.json',refresh_ourselves),('quiz_01.json',refresh_quiz)]:
        path=root/filename
        book=json.loads(path.read_text(encoding='utf-8'))
        refresh(book)
        path.write_text(json.dumps(book,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
