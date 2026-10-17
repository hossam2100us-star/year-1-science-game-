"""Build Maths using the existing source-draft and playable lesson contracts.

The normal build reads the checked-in, reviewed source drafts. To re-extract
those drafts from the supplied parent companion, pass --source-pdf PATH.
No schoolbook PDF or personal certificate is bundled in the application.
"""
from __future__ import annotations

import argparse
import functools
import hashlib
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CONTENT = ROOT / 'assets/content'
META = [
    ('Numbers to 20', 'الأعداد حتى ٢٠', 4, 7, 72),
    ('Addition and Subtraction', 'الجمع والطرح', 8, 10, 72),
    ('Shapes, Direction and Movement', 'الأشكال والاتجاه والحركة', 11, 14, 73),
    ('Statistical Methods', 'الجداول والرسوم البيانية', 15, 17, 73),
    ('Numbers to 20 - Order and Zero', 'ترتيب الأعداد والصفر', 18, 20, 74),
    ('Time and Measurement', 'الوقت والقياس', 21, 23, 74),
    ('Statistical Methods - Sorting Diagrams', 'مخططات التصنيف', 25, 27, 75),
    ('Shapes, Direction and Movement - Patterns and Directions', 'الأنماط والاتجاهات', 28, 31, 76),
    ('Numbers to 20 - Tens and Ones', 'العشرات والآحاد', 32, 34, 76),
    ('Time and Measurement - Days, Length and Mass', 'الأيام والطول والكتلة', 35, 37, 77),
    ('Addition and Subtraction - Pairs and Differences', 'مكملات العشرة والفرق', 38, 40, 77),
    ('Fractions - Halves', 'الكسور والأنصاف', 41, 43, 78),
    ('Numbers to 20 - Odd, Even, Order and Money', 'الفردي والزوجي والترتيب والنقود', 45, 47, 79),
    ('Addition and Subtraction - Doubles and Counting On', 'الضعف والعد التصاعدي', 48, 50, 79),
    ('Shapes, Direction and Movement - Faces, Corners and Turns', 'الأوجه والأركان والدوران', 51, 53, 80),
    ('Statistical Methods - Reading Graphs', 'قراءة الرسوم البيانية', 54, 56, 80),
    ('Fractions - One Half (½)', 'النصف ½', 57, 59, 81),
    ('Time and Measurement - Clocks, Capacity and Tools', 'الساعة والسعة وأدوات القياس', 60, 63, 81),
]
MCQ = [
    ['how many altogether','16','10','13','5'],
    ['add','4','backwards','7','5'],
    ['sphere','cuboid','4 corners','circle','circle'],
    ['one person','most','blocks (squares)','3','the same size and lined up'],
    ['nothing','17','9','estimate','10'],
    ['night','evening','a bed','ends','shorter'],
    ['both','not less than 10','outside the hoops','one child','most popular'],
    ['red','4','backwards','changing the way you face','solid - you can hold it'],
    ['1 ten and 3 ones','15','40','4, 11, 18','one ten'],
    ['12 months','down','no gaps','Sunday','a watermelon'],
    ['6 and 4','2','16','10','15'],
    ['equal','2','one half','3','equal parts of a whole'],
    ['pair up with none left over','9','3rd','pounds and piastres','2'],
    ['12','9','3 + 7','18','16'],
    ['keeps its name','1 pointy corner','one curved face','6 faces','3 sides'],
    ['most','3','6','title','zero'],
    ['one of two equal parts','8','one whole','9','fold the ends together'],
    ['12','between 5 and 6','scales','capacity','30 minutes'],
]
SAFETY = 'An adult supervises. Keep small objects away from younger children. An adult handles scissors. Use water at the sink, away from electrical items.'
SAFETY_AR = 'لازم شخص كبير يكون موجود. خلّي الحاجات الصغيرة بعيد عن الأطفال الأصغر، والكبير يمسك المقص. أنشطة المية تكون عند الحوض وبعيد عن الكهرباء.'


def dump(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    # LF on every OS, as in Git (.gitattributes), so a Windows build changes nothing.
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf-8', newline='\n')


def clean(text):
    return '\n'.join(line for line in text.splitlines() if not line.startswith('Maths Made Simple - prepared for')).strip()


def norm(text):
    return ' '.join(text.replace('—','-').replace('–','-').split())


def numbered(text):
    matches = list(re.finditer(r'(?m)^(\d+)\. ', text))
    return [(int(m.group(1)), text[m.end():matches[i+1].start() if i+1 < len(matches) else len(text)].strip(), m.start()) for i,m in enumerate(matches)]


def extract_source(pdf_path):
    import pdfplumber
    digest = hashlib.sha256(pdf_path.read_bytes()).hexdigest()
    with pdfplumber.open(pdf_path) as pdf:
        pages = [clean(p.extract_text() or '') for p in pdf.pages]
    assert len(pages) == 83
    for n,(title,ar,start,end,keypage) in enumerate(META,1):
        source_text = '\n'.join(pages[start-1:end])
        heading = f'Questions — Unit {n}'
        introduction, questions = source_text.split(heading,1)
        main_text, choice_text = questions.split(f'Choose the correct answer — Unit {n}',1)
        key = pages[keypage-1]
        marker = f'Unit {n} — '
        key = key.split(marker,1)[1]
        key = re.split(r'\n(?:Unit \d+ — |Quiz \d+ — )',key,1)[0]
        answers = dict((i,t) for i,t,_ in numbered(key.split('Choose the correct answer:',1)[0]))
        records=[]
        for category, block, expected_count in [('main',main_text,8),('choice',choice_text,5)]:
            parsed=numbered(block)
            assert len(parsed)==expected_count,(n,category,parsed)
            for qnum,text,_ in parsed:
                page_refs=[p for p in range(start,end+1) if re.search(rf'(?m)^{qnum}\. ',pages[p-1]) and (('Choose the correct answer' in pages[p-1]) if category=='choice' else True)]
                # The source range remains precise at unit level, including the
                # diagram referred to by "above" on a preceding page.
                records.append({'id':f'math.u{n:02d}.{category}.{qnum:02d}','category':category,'number':qnum,
                    'sourceText':text,'answerKeyText':answers[qnum] if category=='main' else MCQ[n-1][qnum-1],
                    'sourcePages':list(range(start,end+1)),'answerKeyPages':[keypage],
                    'reviewStatus':'extracted_needs_game_adaptation'})
        dump(CONTENT/f'math_unit_{n:02d}.json',{'schemaVersion':'0.1.0','contentVersion':1,'id':f'math_unit_{n:02d}',
            'kind':'unit','subject':'maths','title':title,'ar':ar,'term':(n-1)//6+1,
            'sourceSha256':digest,'sourcePages':list(range(start,end+1)),
            'introductionText':introduction.strip(),'sourceQuestions':records,
            'activities':[],'playableQuestions':[],'status':'source_draft'})
    for n,(page,keypage) in enumerate([(24,75),(44,78),(64,82)],1):
        block=pages[page-1].split('ten marks altogether.',1)[1].split('My score:',1)[0]
        key=pages[keypage-1].split(f'Quiz {n} — Term {n}',1)[1]
        key=re.split(r'\n(?:Unit \d+ — |Chart Skills)',key,1)[0]
        answers=dict((i,t) for i,t,_ in numbered(key))
        records=[{'id':f'math.q{n:02d}.{i:02d}','category':'quiz','number':i,'sourceText':t,
            'answerKeyText':answers[i],'sourcePages':[page],'answerKeyPages':[keypage],
            'reviewStatus':'extracted_needs_game_adaptation'} for i,t,_ in numbered(block)]
        assert len(records)==10
        dump(CONTENT/f'math_quiz_{n:02d}.json',{'schemaVersion':'0.1.0','contentVersion':1,
            'id':f'math_quiz_{n:02d}','kind':'quiz','subject':'maths','title':f'Big Challenge: Term {n}',
            'ar':f'تحدي الفصل الدراسي {n}','term':n,'sourceSha256':digest,'sourcePages':[page],
            'sourceQuestions':records,'scoreBands':[{'min':8,'max':10,'label':'excellent'},{'min':5,'max':7,'label':'keep practising'},{'min':0,'max':4,'label':'play the games again'}],
            'activities':[],'playableQuestions':[],'status':'source_draft'})
    chart_records=[]
    key=pages[81].split('Chart Skills',1)[1].split('Record Sheets,',1)[0]
    answers=dict((i,t) for i,t,_ in numbered(key))
    for page in [65,66]:
        # Chart section headings ("1. A block chart") are not questions.
        text=re.sub(r'(?m)^[123]\. A (?:block chart|pictogram|bar chart)\s*$', '', pages[page-1])
        for i,t,_ in numbered(text):
            t=t.splitlines()[0].strip()
            chart_records.append({'id':f'math.charts.{i:02d}','category':'chart','number':i,'sourceText':t,
                'answerKeyText':answers[i],'sourcePages':[page],'answerKeyPages':[82],
                'reviewStatus':'extracted_needs_game_adaptation'})
    assert len(chart_records)==9
    dump(CONTENT/'math_charts.json',{'schemaVersion':'0.1.0','contentVersion':1,'id':'math_charts',
        'kind':'skills','subject':'maths','title':'Chart Skills','ar':'مهارات قراءة الرسوم',
        'sourceSha256':digest,'sourcePages':[65,66],'sourceQuestions':chart_records,
        'activities':[],'playableQuestions':[],'status':'source_draft'})
    dump(CONTENT/'math_support.json',{'schemaVersion':1,'contentVersion':1,'subject':'maths',
        'sourceSha256':digest,'sourcePages':[2,67,68,69,70,71,83],
        'recordSheets':{'sourcePages':[67],'text':pages[66]},
        'sortingCards':{'sourcePages':[68],'numbers':list(range(1,21)),
            'shapes':['circle','triangle','square','rectangle','cube','cuboid','sphere','cylinder','cone','pyramid']},
        'selfCheck':{'sourcePages':[69],'text':pages[68]},
        'wordList':{'sourcePages':[70,71],'text':pages[69]+'\n'+pages[70]},
        'certificate':{'sourcePages':[83],'title':'Little Mathematician',
            'message':'For finishing all eighteen units, counting carefully, asking questions and trying again.'},
        'note':'Personal certificate details and identifying footers are omitted.'})


def count(n,item='dot',arrangement='row'):
    return {'type':'count','count':n,'item':item,'arrangement':arrangement}


def shape(name,**kwargs):
    return {'type':'shape','shape':name,**kwargs}


def groups(*items):
    return {'type':'groups','items':list(items)}


def chart(title,rows,style='block',unit='one item',*,axisMax=None,tickStep=None):
    result={'type':'chart','title':title,'rows':[{'label':k,'value':v} for k,v in rows], 'style':style,'unit':unit}
    if axisMax is not None: result['axisMax']=axisMax
    if tickStep is not None: result['tickStep']=tickStep
    return result


def line(start=0,end=20,**kwargs):
    return {'type':'numberLine','start':start,'end':end,**kwargs}


def jumps(start,end,origin,moves,ask='landing'):
    """A number line the child jumps along from origin (teacher review 5).

    moves are the jumps the explanation shows: +3 is three forward jumps.
    ask says whether the answer is where they land or how far they went.
    """
    return {**line(start,end),'from':origin,'jumps':moves,'ask':ask}


def single(prompt,correct,choices,visual=None,explanation=None,hint=None,option_visuals=None):
    return {'type':'single','prompt':prompt,'correct':str(correct),'choices':[str(c) for c in choices],
            'visual':visual,'explanation':explanation,'hint':hint,'optionVisuals':option_visuals or {}}


def number(prompt,n,visual=None,explanation=None,hint=None):
    choices=[str(n+1),str(n),str(n+2 if n==0 else n-1)]
    return single(prompt,n,choices,visual,explanation,hint)


def tf(prompt,answer,explanation=None,visual=None):
    return single(prompt,'True' if answer else 'False',['True','False'],visual,explanation=explanation)


def balance(left,right,left_label=None,right_label=None):
    """A pan balance with equal cubes; the side holding more goes down."""
    def side(n,label): return {'count':n,**({'label':label} if label else {})}
    return {'type':'balance','left':side(left,left_label),'right':side(right,right_label),
        'tilt':'left' if left>right else 'right' if right>left else 'level'}


def sky(time):
    return {'type':'sky','time':time}


def venn(labels,items):
    return {'type':'venn','labels':labels,'items':[{'item':i,'region':r} for i,r in items]}


def robot(routes,*,cols=4,rows=5,start=(0,2),facing='up',star=(2,0)):
    """A grid with a robot, its facing and a star; routes are F, B, L and R moves."""
    return {'type':'robot','cols':cols,'rows':rows,'start':list(start),'facing':facing,'star':list(star),'routes':routes}


def carroll(columns):
    return {'type':'carroll','columns':columns}


def shapes(*names):
    return {name:shape(name) for name in names}


def mapping(prompt,pairs,targets,visual=None,explanation=None):
    return {'type':'mapping','prompt':prompt,'pairs':pairs,'targets':[str(t) for t in targets],
            'visual':visual,'explanation':explanation}


def multiple(prompt,choices,correct,visual=None,explanation=None,option_visuals=None):
    return {'type':'set','prompt':prompt,'choices':[str(c) for c in choices],'correct':[str(c) for c in correct],
            'visual':visual,'explanation':explanation,'optionVisuals':option_visuals or {}}


def ordered(prompt,values,visual=None,explanation=None):
    return {'type':'sequence','prompt':prompt,'correct':[str(v) for v in values],
            'choices':[str(v) for v in values[1:]+values[:1]],'visual':visual,'explanation':explanation}


def free(prompt,visual=None):
    return {'type':'free','prompt':prompt,'visual':visual,'explanation':'Try it with an adult. Talk about what you found.'}


def stable_order(items,key):
    """Portable repeatable ordering; correctness is never encoded by position."""
    return sorted(items,key=lambda item:hashlib.sha256(f'{key}/{item["id"]}'.encode()).digest())


def practice_choices(labels,correct,visuals=None):
    choices=[{'id':f'answer_{i+1}','label':str(label),**({'visual':visuals[str(label)]} if str(label) in (visuals or {}) else {})} for i,label in enumerate(labels)]
    correct_id=next(c['id'] for c in choices if c['label']==str(correct))
    return choices,correct_id


# Before counting (the workshop's own hint) and after a wrong number: the
# choices appear only once every object is counted, so a wrong number means
# the last count was not taken as the answer (teacher review 6).
COUNT_TAP_HINT='Tap each object once. A marked object has already been counted.'
COUNT_LAST_HINT='You counted them all. The last number you said tells how many.'
# The workshop's own hint where its first count needs a different start.
WORKSHOP_START_HINTS={'math_unit_05':'Your guess is not scored. Tap each bean once to find the count.'}


def count_practice(prompt,total,item,feedback,*,arrangement='row',hint=None):
    choices,correct_id=practice_choices([max(0,total-1),total,total+1],total)
    for choice in choices: choice['value']=int(choice['label'])
    return {'mode':'count','prompt':prompt,'count':total,'item':item,'arrangement':arrangement,
        'choices':choices,'correctId':correct_id,'feedback':feedback,
        'hint':hint or COUNT_LAST_HINT}


def build_practice(prompt,target,item,feedback,*,initial=0,arrangement='row',visual=None,hint=None):
    task={'mode':'build','prompt':prompt,'target':target,'item':item,'initialCount':initial,
        'arrangement':arrangement,'maxCount':20,'feedback':feedback,
        'hint':hint or 'Add or take away one at a time. Count your group, then check.'}
    if visual: task['visual']=visual
    return task


def choose_practice(prompt,labels,correct,feedback,*,visual=None,option_visuals=None,hint=None):
    choices,correct_id=practice_choices(labels,correct,option_visuals)
    task={'mode':'choose','prompt':prompt,'choices':choices,'correctId':correct_id,'feedback':feedback,
        'hint':hint or 'Look at the picture and think about the question before choosing.'}
    if visual: task['visual']=visual
    return task


def guided_workshops():
    """Short, ungraded actions that teach the concept before the book questions."""
    fruit=FRUIT
    days={'type':'pattern','items':[{'type':'text','text':day} for day in ['Sun','Mon','Tue','Wed','Thu','Fri','Sat']]}
    birds=chart('Birds we saw from the balcony',[('pigeons',6),('sparrows',8),('crows',3)],'bar','one bird',axisMax=10,tickStep=2)
    toys=chart('Toys in the box',[('cars',4),('balls',2),('dolls',3),('blocks',1)],unit='one toy')
    stars=chart('Stars earned this week',[('Sun',2),('Mon',3),('Tue',1),('Wed',4),('Thu',2)],'pictogram','one star earned')
    half_circle={'type':'fraction','shape':'circle','parts':2,'shaded':1,'equal':True}
    unequal={'type':'fraction','shape':'rectangle','parts':2,'shaded':1,'equal':False}
    data={
    1:('Count for Owl','Count each object once, say how many altogether, and make a group of ten.','orchard',[
        count_practice('Tap each apple once to count the apples for Owl.',7,'apple','You counted each apple once. Seven is the last count, so there are seven apples altogether.'),
        choose_practice('The same seven apples are spread out. None joined or left. How many now?',[6,7,8],7,'Still seven! Moving apples changes where they are, not how many there are.',visual=count(7,'apple','scattered'),hint='Think about whether an apple joined or left. You may count again to check.'),
        build_practice('Make a group of ten counters. Fill the ten frame, one counter in each space.',10,'counter','Ten counters fill all ten spaces. The number ten tells us how many altogether.',arrangement='tenFrame',hint='Each space holds one counter. Count the filled spaces before checking.'),
    ]),
    2:('Join and take away','See how adding and taking away change a group.','orchard',[
        count_practice('Tap the three beans once each. How many are in the starting group?',3,'bean','There are three beans to start with.'),
        build_practice('Three beans are ready. Add two more beans, then check the new group.',5,'bean','Three beans and two more make five: 3 + 2 = 5.',initial=3,hint='Keep the three you started with. Add one, then one more.'),
        build_practice('Seven beans are ready. Take away two beans, then check what is left.',5,'bean','Taking two away from seven leaves five: 7 - 2 = 5.',initial=7,hint='Remove one bean, then one more. Count only the beans that remain.'),
    ]),
    3:('Shape detectives','Use sides, corners and flat or solid parts to recognise shapes.','village',[
        choose_practice('Choose the flat shape with three straight sides.',['triangle','circle','square'],'triangle','A triangle has three straight sides and three corners.',option_visuals={s:shape(s) for s in ['triangle','circle','square']},hint='Trace the sides with your finger and count them.'),
        choose_practice('Which whole object is a solid cube?',['cube','square','circle'],'cube','The cube is solid. A square is the flat shape on each of its faces.',option_visuals={s:shape(s) for s in ['cube','square','circle']},hint='Look for a shape with depth, rather than only a flat drawing.'),
        choose_practice('This shape has turned. What is its name now?',['triangle','square','rectangle'],'square','It is still a square. Turning leaves its four equal sides and four corners unchanged.',visual=shape('square',rotation=45),hint='Count the sides and corners. Turning does not stretch the shape.'),
    ]),
    4:('Build a fruit vote','Link one vote to one picture, then read the fruit choices.','village',[
        choose_practice('Each picture is one person. How many people chose apple?',[3,4,5],4,'Four apple pictures stand for four people.',visual=fruit,hint='Read the apple label, then count the pictures in that row.'),
        build_practice('Make one counter for each of the four apple votes.',4,'counter','Four votes need four counters: one counter for each person.',visual=fruit,hint='One person needs one counter. Stop when every apple vote has a counter.'),
        choose_practice('Which fruit has the most votes?',['apple','banana','mango'],'apple','Apple has the most pictures, so it has the most votes.',visual=fruit,hint='Compare equal-size pictures from the same starting line.'),
    ]),
    5:('Guess, check and compare','Use counting to check a guess; notice zero and larger numbers.','orchard',[
        count_practice('Guess how many beans aloud first. Then tap each bean to check.',6,'bean','Your guess was a prediction. Counting shows six beans; a different guess is part of learning.',arrangement='scattered',hint='Your guess is not scored. The last number you counted tells how many.'),
        build_practice('Three counters are ready. Take them all away to make zero.',0,'counter','Zero means none. The tray is empty because all three counters were taken away.',initial=3,hint='Remove every counter. An empty tray shows zero.'),
        choose_practice('Which group is larger: twelve or seventeen?',[12,17],17,'Seventeen is larger than twelve. Five more objects make the larger group.',visual=groups({**count(12),'label':'12'},{**count(17),'label':'17'}),hint='Compare the groups, or count onward from twelve to seventeen.'),
    ]),
    6:('A day and its lengths','Use time-of-day words and compare lengths from the same start.','village',[
        choose_practice('You wake up and eat breakfast. Which part of the day is this?',['morning','afternoon','night'],'morning','Breakfast after waking up is usually in the morning.',visual={'type':'text','text':'Wake up → breakfast'},hint='Think about the beginning of your usual school day.'),
        choose_practice('Which takes longer: a blink or a night of sleep?',['a blink','a night of sleep'],'a night of sleep','A blink is very short. A night of sleep lasts much longer.',visual={'type':'text','text':'Blink  /  sleep'},hint='Think about whether each activity ends quickly or lasts for hours.'),
        choose_practice('Both pencil ends start at the same line. Which pencil is shorter?',['A','B'],'A','Pencil A ends first when both start together, so A is shorter.',visual=groups({'type':'ruler','units':3,'item':'pencil','label':'A'},{'type':'ruler','units':5,'item':'pencil','label':'B'}),hint='Compare the far ends after checking that the starting ends line up.'),
    ]),
    7:('Two sorting rules','Ask both sorting questions, including both and neither.','workshop',[
        choose_practice('A red car is red and has wheels. Which sorting group fits it?',['red only','wheels only','both','neither'],'both','Both rules are true. A red car belongs in the overlap.',visual=groups({'type':'text','text':'Red? Yes'},{'type':'text','text':'Wheels? Yes'}),hint='Ask separately: is it red? Does it have wheels? Two yes answers mean both.'),
        choose_practice('A green leaf is not red and has no wheels. Which group fits it?',['red only','both','neither'],'neither','Neither rule is true. The green leaf belongs outside both hoops.',visual=groups({'type':'text','text':'Red? No'},{'type':'text','text':'Wheels? No'}),hint='Neither means that both sorting questions have a no answer.'),
        choose_practice('Put ten in a sorting box: is ten less than ten?',['less than 10','not less than 10'],'not less than 10','Ten is equal to ten. It is not less than ten.',visual={'type':'text','text':'10'},hint='Less than means smaller. Equal is not smaller.'),
    ]),
    8:('Patterns and robot turns','Continue a repeating part and use the direction a robot faces.','harbour',[
        choose_practice('Red circle, blue square, red circle, blue square. Choose what comes next.',['red circle','blue square','yellow triangle'],'red circle','The repeating part is red circle, blue square. It starts again with red circle.',visual={'type':'pattern','items':[shape('circle',color='red'),shape('square',color='blue')]*2},option_visuals={'red circle':shape('circle',color='red'),'blue square':shape('square',color='blue'),'yellow triangle':shape('triangle',color='yellow')},hint='Say the two-shape part aloud twice, then start it again.'),
        choose_practice('The robot faces up. It turns right. Which way does it face now?',['up','right','left'],'right','A right turn changes its facing direction from up to right.',visual={'type':'text','text':'Robot faces ↑'},option_visuals={'up':{'type':'text','text':'↑'},'right':{'type':'text','text':'→'},'left':{'type':'text','text':'←'}},hint='Keep it in the same place. Only change the way it faces.'),
        choose_practice('Take three steps forwards, then one backwards. How many steps forwards from the start?',[1,2,3],2,'Three forwards and one back leaves two steps forwards from the start.',visual=line(0,4,markers=[0]),hint='Start at zero. Count three forward jumps, then one backward jump.'),
    ]),
    9:('Build tens and ones','Keep a whole ten together, then add the extra ones.','workshop',[
        choose_practice('One ten and four ones make which number?',[14,41,4],14,'One whole ten and four extra ones make fourteen.',visual=groups({**count(10,arrangement='tenFrame'),'label':'one ten'},{**count(4),'label':'ones'}),hint='Start with ten, then count on the four extra ones.'),
        build_practice('Ten counters are ready. Add six extra ones to make sixteen.',16,'counter','Sixteen is one ten and six ones. The ten stays a whole group.',initial=10,hint='Keep the ten you started with. Count on six extra counters.'),
        choose_practice('Two complete tens have no extra ones. What number is that?',[2,12,20],20,'Two tens make twenty; there are zero extra ones.',visual=groups(count(10,arrangement='tenFrame'),count(10,arrangement='tenFrame')),hint='Each full frame is ten. Count whole tens: ten, twenty.'),
    ]),
    10:('Measure fairly','Use equal touching cubes, the day sequence and a balance.','workshop',[
        choose_practice('How many same-size cubes cover the pencil with no gaps?',[5,6,7],6,'Six equal cubes cover the whole pencil length without gaps.',visual={'type':'ruler','units':6,'unit':'cube','item':'pencil'},hint='Count each cube once. Gaps would leave part of the length unmeasured.'),
        choose_practice('Which day comes after Monday?',['Sunday','Tuesday','Friday'],'Tuesday','Tuesday comes after Monday in the repeating week.',visual=days,hint='Find Monday in the day row, then read the next day.'),
        choose_practice('On a balance, B goes down and A goes up. Which object is heavier?',['A','B'],'B','The heavier side goes down, so object B is heavier.',visual={'type':'text','text':'A ↑       B ↓'},hint='Look for the side that went down. Size alone cannot tell us mass.'),
    ]),
    11:('Find the missing partner','Make ten and count the difference as jumps.','workshop',[
        build_practice('Seven spaces are filled. Add counters until the ten frame is full.',10,'counter','You added three counters. Seven and three make ten.',initial=7,arrangement='tenFrame',hint='Count the empty spaces. Each needs one counter.'),
        choose_practice('How many forward jumps take you from five to nine?',[3,4,9],4,'Five to nine takes four jumps. The standing start is not a jump.',visual=line(5,9,markers=[5,9]),hint='Start on five. Count jumps to six, seven, eight and nine.'),
        build_practice('Ten beans are ready. Hide four by taking them off the tray. How many stay visible?',6,'bean','Six are visible and four are hidden. Both parts still make ten.',initial=10,hint='Remove four beans. Count only those still on the tray.'),
    ]),
    12:('Share into fair halves','Halves must be two equal parts of the same whole.','orchard',[
        choose_practice('Which picture shows two equal parts?',['A','B'],'A','A has two equal parts. B has a larger part and a smaller part, so they are not halves.',option_visuals={'A':half_circle,'B':unequal},hint='Compare the two parts in each picture. Halves have the same size.'),
        build_practice('Eight apples are shared fairly by two children. Build one child\'s share.',4,'apple','Four apples for each child makes two equal groups: four and four.',visual=count(8,'apple'),hint='Make two equal groups in your mind. One child must get the same number as the other.'),
        choose_practice('These two parts have different sizes. Are they halves?',['yes','no'],'no','Halves of the same whole must be equal. Two unequal pieces are not halves.',visual=unequal,hint='Check equality, rather than only counting the two pieces.'),
    ]),
    13:('Partners, positions and coins','Use pairing for odd/even, order for positions, and value for money.','village',[
        choose_practice('Seven socks make three pairs and one left over. Is seven odd or even?',['odd','even'],'odd','One sock has no partner, so seven is odd.',visual=count(7,'sock','pairs'),hint='An even group pairs with none left over. Look for the unpaired sock.'),
        choose_practice('Ali finishes first, Mona second and Omar third. Who is in second position?',['Ali','Mona','Omar'],'Mona','Mona is second: after Ali and before Omar.',visual=groups({'type':'text','text':'1st Ali'},{'type':'text','text':'2nd Mona'},{'type':'text','text':'3rd Omar'}),hint='Second is the middle position in this three-person order.'),
        choose_practice('One pound is one hundred piastres. Which coin is worth the most?',['25 piastres','50 piastres','1 pound'],'1 pound','One pound is one hundred piastres, more than fifty or twenty-five.',option_visuals={'25 piastres':{'type':'money','coins':[25]},'50 piastres':{'type':'money','coins':[50]},'1 pound':{'type':'money','coins':[100]}},hint='Compare the written values, rather than the number or size of coins.'),
    ]),
    14:('Double and count on','Add the same group again for doubles; start with the larger number.','orchard',[
        count_practice('Tap the three beans once each. This is our first group.',3,'bean','Our first group has three beans.'),
        build_practice('Double three means three again. Add another group of three beans.',6,'bean','Three and another three make six. Double three is six.',initial=3,hint='Keep the first three. Add the same number again.'),
        build_practice('For four plus nine, start with nine. Count on four more beans.',13,'bean','Starting at nine and adding four reaches thirteen. Nine plus four equals four plus nine.',initial=9,hint='Say ten, eleven, twelve, thirteen as you add four beans.'),
    ]),
    15:('Shapes keep their names','Notice unchanged shapes, all six cube faces and a robot turn.','harbour',[
        choose_practice('One triangle has turned upside down. Are both still triangles?',['yes','no'],'yes','Both still have three straight sides and three corners. Turning keeps the shape unchanged.',visual=groups(shape('triangle'),shape('triangle',rotation=180)),hint='Compare sides and corners, not the direction the point faces.'),
        choose_practice('These are the cube\'s flat faces shown separately. How many faces?',[3,6,8],6,'A cube has six square faces. A single view of the cube hides some of them.',visual=groups(*[{**shape('square'),'label':label} for label in ['front','back','top','bottom','left','right']]),hint='Count all six named face pictures once, including the hidden back and bottom.'),
        choose_practice('The robot faces up, then turns right without moving. Where does it face?',['up','right','down'],'right','It faces right. Turning changes facing, while staying in the same place.',visual={'type':'text','text':'Start ↑'},option_visuals={'up':{'type':'text','text':'↑'},'right':{'type':'text','text':'→'},'down':{'type':'text','text':'↓'}},hint='The robot stays on its square. Imagine a right turn from up.'),
    ]),
    16:('Read and compare columns','Use the chart labels, count differences and find the total.','village',[
        choose_practice('Read the travel chart. Which way has the most children?',['walk','bus','bike'],'walk','Walk has six blocks, the tallest column and the most children.',visual=SCHOOL,hint='Read the labels, then compare the columns from their shared baseline.'),
        build_practice('Car has three blocks; walk has six. Add blocks to the car group until it matches walk.',6,'counter','You added three blocks. Six is three more than three.',initial=3,visual=SCHOOL,hint='Count only the extra blocks needed after the first three.'),
        choose_practice('How many children are represented altogether?',[12,15,16],15,'Six plus four plus three plus two makes fifteen children altogether.',visual=SCHOOL,hint='Add the counts of all four labeled columns, not just the tallest one.'),
    ]),
    17:('One half and one whole','Connect ½ to an equal part, a fair share and a complete whole.','orchard',[
        choose_practice('Which picture has one of two equal parts coloured?',['A','B'],'A','A shows one half: one of two equal parts. B shows one of four equal parts.',option_visuals={'A':half_circle,'B':{'type':'fraction','shape':'square','parts':4,'shaded':1,'equal':True}},hint='Count the equal parts in the whole, then the coloured parts.'),
        build_practice('Fourteen counters are shared equally between two groups. Build one half.',7,'counter','Seven and seven make fourteen, so half of fourteen is seven.',visual=count(14),hint='Both groups must get the same number. Check that your share doubled makes fourteen.'),
        choose_practice('Put the two equal halves back together. What have we made?',['one half','one whole','two wholes'],'one whole','Two halves of the same thing join to make one whole.',visual={'type':'fraction','shape':'square','parts':2,'shaded':2,'equal':True},hint='The complete shape is one whole, even though a dividing line remains.'),
    ]),
    18:('Clocks and containers','Read the long hand first and compare how much containers hold.','harbour',[
        choose_practice('The long hand points to twelve. What time is shown?',["3 o'clock",'half past 3',"12 o'clock"],"3 o'clock",'Long hand on twelve means o\'clock; the short hand points to three.',visual={'type':'clock','hour':3,'minute':0},hint='Use the short hand for the hour after finding the long hand on twelve.'),
        choose_practice('Now the long hand points to six. What time is shown?',["3 o'clock",'half past 3','half past 4'],'half past 3','The hour hand is past three but not yet four. It is half past three.',visual={'type':'clock','hour':3,'minute':30},hint='Read the hour it has gone past, not the next hour.'),
        choose_practice('Each dot stands for one cup of water. Which container holds most?',['jug','bowl','mug'],'jug','The jug holds five cups, more than the bowl\'s four or the mug\'s two.',visual=groups({**count(5),'label':'jug'},{**count(4),'label':'bowl'},{**count(2),'label':'mug'}),hint='Compare the number of same-size cups, not the height of the containers.'),
    ]),
    'charts':('Find the story in a chart','Read titles, labels and keys before counting or reading the scale.','workshop',[
        choose_practice('Read the cars column in Toys in the box. How many cars?',[3,4,5],4,'The cars column contains four blocks. Each block is one toy.',visual=toys,hint='Find cars below the chart, then count only that column.'),
        choose_practice('Each picture is one earned star. Which day has the most?',['Mon','Wed','Thu'],'Wed','Wednesday has four earned stars, the most in this pictogram.',visual=stars,hint='Read the day labels and compare the equal-size pictures.'),
        choose_practice('The crows bar ends halfway between two and four. How many crows?',[2,3,4],3,'Three lies halfway between two and four. The bar represents three crows.',visual=birds,hint='The scale counts in twos. The unlabelled middle number is three.'),
    ]),
    }
    workshops={}
    for key,(title,goal,scene,tasks) in data.items():
        ident='math_charts' if key=='charts' else f'math_unit_{key:02d}'
        for i,task in enumerate(tasks,1):
            task['id']=f'explore_{i}'
            if 'choices' in task: task['choices']=stable_order(task['choices'],f'{ident}/workshop/{task["id"]}')
        workshops[ident]={'title':title,'goal':goal,'scene':scene,'tasks':tasks}
    return workshops


FRUIT=chart('Our favourite fruit',[('apple',4),('banana',2),('orange',3),('mango',1)],'pictogram','one person')
PETS=chart('Our pets',[('cat',5),('dog',3),('fish',1)],unit='one child')
SCHOOL=chart('How we came to school today',[('walk',6),('bus',4),('car',3),('bike',2)],unit='one child')
PETS_NO_FISH=chart('Pets in our class',[('cat',3),('dog',2),('fish',0)],unit='one child')

# Teacher review 5: a question shows what it talks about. Keys are
# (unit, multiple-choice number); pictures never mark the answer.
MCQ_VISUALS={
    (1,3):count(0,'dot','tenFrame'),
    (2,3):line(0,10),
    (4,1):FRUIT,(4,2):FRUIT,(4,3):PETS,(4,5):FRUIT,
    (6,1):sky('night'),
    (7,1):venn(['red','has wheels'],[('apple','left'),('car','both'),('banana','outside')]),
    (7,4):PETS,(7,5):PETS,
    (8,5):groups(shape('cube'),shape('cylinder'),shape('sphere')),
    (10,2):balance(1,3),
    (10,3):{'type':'ruler','units':6,'unit':'cube','item':'pencil'},
    (15,1):groups({**shape('triangle'),'label':'before'},{**shape('triangle',rotation=180),'label':'turned'}),
    (16,1):SCHOOL,(16,4):SCHOOL,(16,5):PETS_NO_FISH,
    (18,1):{'type':'clock','hour':3,'minute':0},
}
MCQ_OPTION_VISUALS={(3,4):shapes('square','triangle','circle')}


def cycle(labels):
    """Names in order around a circle: the last one leads back to the first."""
    return {'type':'cycle','labels':labels}


def tens(n):
    """n as full ten frames and a row of ones (an empty row for no ones)."""
    size={'width':190,'height':80}
    frames=[{**count(10,arrangement='tenFrame'),**size,'label':'one ten' if n<20 else 'ten'} for _ in range(n//10)]
    ones=n%10
    return groups(*frames,{**count(ones),**size,'label':'one' if ones==1 else 'ones'})


def colours(*names):
    """A colour pattern; None is a gap to fill."""
    return {'type':'pattern','items':[{**count(1),'color':name,'height':70} if name else {'type':'missing','text':'?'} for name in names]}


def two_colours(a,b,arrangement='row'):
    """a counters, then b more in a second colour: 6 and 4 in a ten frame."""
    return {**count(a+b,'dot',arrangement),'color':'red','split':a,'color2':'blue'}


def double(n):
    """Two equal rows of n: double n, or 2n shared into two halves."""
    return {**count(2*n,'dot','double'),'color':'red','color2':'blue'}


def pairs(n,slots=None):
    """Socks in pairs; answers given the same slots show socks one size."""
    return {**count(n,'sock','pairs'),**({'slots':slots} if slots else {})}


def clock(hour,minute):
    return {'type':'clock','hour':hour,'minute':minute}


def thing(*items,**kwargs):
    """Real objects drawn from the things atlas: a bed, a jug, a feather..."""
    return {'type':'object','items':list(items),**kwargs}


def plus(a,b,item='apple',b_label=None):
    """a + b as two groups of one size, with a plus sign between them."""
    most=max(a,b,1)
    size={'width':max(120,56*min(most,5)),'height':90 if most<=5 else 150}
    return groups({**count(a,item),**size,'label':str(a)},{'type':'text','text':'+','width':40},{**count(b,item),**size,'label':b_label or str(b)})


HALF={'type':'fraction','shape':'circle','parts':2,'shaded':1,'equal':True}
UNEQUAL={'type':'fraction','shape':'rectangle','parts':2,'shaded':1,'equal':False}
WHOLE={'type':'fraction','shape':'circle','parts':2,'shaded':2,'equal':True}
QUARTER={'type':'fraction','shape':'rectangle','parts':4,'shaded':1,'equal':True}
PENCILS=groups({'type':'ruler','units':3,'item':'pencil','label':'A'},{'type':'ruler','units':5,'item':'pencil','label':'B'})
WEEK=cycle(['Sun','Mon','Tue','Wed','Thu','Fri','Sat'])
YEAR=cycle(['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'])
HOOPS=venn(['red','has wheels'],[])
RED_CAR=venn(['red','has wheels'],[('car','both')])
POSITIONS={'type':'pattern','items':[{'type':'text','text':'1st'},{'type':'text','text':'2nd'},{'type':'missing','text':'?'}]}

# Teacher review 5 asked for a picture in every question. Keys are question
# IDs; 'visual' goes above the question and 'options' on answers by label.
# Pictures never mark the answer. Real objects (a spoon, a bed, a
# feather...) come from the things atlas, maths-things-v1.webp.
PICTURES={
    'math.u01.main.06':{'visual':groups({**count(6,'counter'),'columns':3,'width':150,'height':100,'label':'before'},{**count(6,'counter','scattered'),'columns':6,'width':400,'height':56,'label':'spread out'})},
    'math.u01.main.07':{'visual':tens(12)},
    'math.u01.choice.01':{'visual':count(5,'apple')},
    'math.u01.choice.02':{'visual':jumps(10,20,15,[1])},
    'math.u01.choice.04':{'visual':tens(13)},
    'math.u01.choice.05':{'visual':groups({**count(5,'counter','scattered'),'columns':3,'width':150,'height':100,'label':'in a pile'},{**count(5,'counter'),'width':300,'height':56,'label':'in a line'})},
    'math.u02.main.06':{'visual':plus(4,3)},
    'math.u02.main.07':{'visual':{**count(8,'car'),'removed':4}},
    'math.u02.choice.02':{'visual':{**count(6,'cube'),'removed':2}},
    'math.u02.choice.04':{'visual':jumps(0,10,8,[-1])},
    'math.u02.choice.05':{'visual':plus(5,0)},
    'math.u03.main.06':{'options':{'triangle':shape('triangle'),'tin':shape('cylinder'),'ball':shape('sphere'),'dice':shape('cube'),'square':shape('square'),'circle':shape('circle')}},
    'math.u03.main.07':{'visual':groups({**shape('square'),'label':'square'},{**shape('square',rotation=45),'label':'on its corner'})},
    'math.u03.choice.01':{'visual':count(1,'ball'),'options':shapes('sphere','circle','cylinder')},
    'math.u03.choice.02':{'options':shapes('cone','cuboid','cube')},
    'math.u03.choice.03':{'visual':shape('rectangle')},
    'math.u03.choice.05':{'visual':shape('cylinder'),'options':shapes('square','triangle','circle')},
    'math.u04.main.06':{'options':{'blue ball':shape('sphere',color='blue'),'red ball':shape('sphere',color='red'),'green car':shape('car',color='green'),'red car':shape('car',color='red')}},
    'math.u04.main.07':{'visual':chart('Pets we chose',[('cat',3),('dog',1),('fish',1)],'pictogram','one child')},
    'math.u05.main.01':{'options':{'twenty':two_colours(10,10),'eleven':two_colours(10,1),'fifteen':two_colours(10,5)}},
    'math.u05.choice.02':{'visual':line(0,20,markers=[9,12,17])},
    'math.u05.choice.03':{'visual':jumps(0,20,10,[-1])},
    'math.u05.choice.04':{'visual':count(14,'dot','scattered')},
    'math.u05.choice.05':{'visual':jumps(0,20,12,[-2])},
    'math.u06.main.01':{'options':{'night':sky('night'),'morning':sky('morning'),'evening':sky('evening')}},
    'math.u06.main.02':{'options':{'night':sky('night'),'afternoon':sky('afternoon'),'morning':sky('morning')}},
    'math.u06.main.03':{'options':{'wake up':thing('alarm clock'),'go to school':thing('school bag'),'eat dinner':thing('dinner')}},
    'math.u06.main.04':{'options':{"a night's sleep":thing('bed'),'brushing your teeth':thing('toothbrush'),'eating dinner':thing('dinner')}},
    'math.u06.main.05':{'options':{'a football match':thing('football'),'a blink':thing('open eye','closed eye'),"a night's sleep":thing('bed')}},
    'math.u06.main.07':{'visual':PENCILS},
    'math.u06.choice.02':{'options':{'morning':sky('morning'),'evening':sky('evening'),'middle of the night':sky('night')}},
    'math.u06.choice.03':{'options':{'a spoon':thing('spoon'),'a shoe':thing('shoe'),'a bed':thing('bed')}},
    'math.u06.choice.04':{'visual':PENCILS},
    'math.u06.choice.05':{'visual':PENCILS},
    'math.q01.02':{'visual':jumps(0,20,12,[1])},
    'math.q01.03':{'visual':jumps(0,10,7,[-3])},
    'math.q01.07':{'visual':line(10,20,markers=[15,18])},
    'math.q01.08':{'visual':groups({**count(0,'counter'),'width':260,'height':110,'label':'an empty bag'})},
    'math.q01.09':{'options':{'morning':sky('morning'),'night':sky('night'),'afternoon':sky('afternoon')}},
    'math.q01.10':{'visual':PENCILS},
    'math.u07.main.01':{'visual':HOOPS},
    'math.u07.main.02':{'visual':RED_CAR},
    'math.u07.main.03':{'visual':HOOPS},
    'math.u07.main.07':{'visual':RED_CAR},
    'math.u07.choice.02':{'visual':{**carroll(['less than 10','not less than 10']),'placed':{'less than 10':['3','7'],'not less than 10':['12','15']}}},
    'math.u07.choice.03':{'visual':HOOPS},
    'math.u08.main.03':{'visual':colours('red','blue','blue','red','blue','blue',None,None)},
    'math.u08.main.08':{'options':shapes('triangle','rectangle','square','circle')},
    'math.u08.choice.01':{'visual':colours('red','yellow','red','yellow',None)},
    'math.u08.choice.02':{'visual':shape('square')},
    'math.u08.choice.03':{'visual':robot({'backwards':'B','forwards':'F','sideways':'RF'},cols=3,rows=3,start=(1,1),star=(1,2))},
    'math.u09.main.03':{'visual':tens(17)},
    'math.u09.main.04':{'visual':tens(20)},
    'math.u09.main.06':{'visual':line(0,50,markers=[10,20,40])},
    'math.u09.main.07':{'visual':line(0,40,markers=[4,14,34])},
    'math.u09.main.08':{'visual':tens(16)},
    'math.u09.choice.01':{'visual':tens(13)},
    'math.u09.choice.02':{'visual':groups({**count(5),'width':190,'height':80,'label':'5'},{'type':'text','text':'+','width':40},{**count(10,arrangement='tenFrame'),'width':190,'height':80,'label':'ten more'})},
    'math.u09.choice.03':{'visual':line(0,50,markers=[10,20,30])},
    'math.u09.choice.04':{'visual':line(0,20,markers=[4,11,18])},
    'math.u10.main.01':{'visual':WEEK},
    'math.u10.main.02':{'visual':WEEK},
    'math.u10.main.03':{'visual':YEAR},
    'math.u10.main.04':{'visual':YEAR},
    'math.u10.main.07':{'visual':groups({**thing('pillow',height=150),'label':'a big pillow'},{**thing('stone',height=70),'label':'a small stone'})},
    'math.u10.main.08':{'options':{'feather':thing('feather'),'book':thing('book'),'chair':thing('chair')}},
    'math.u10.choice.01':{'visual':YEAR},
    'math.u10.choice.04':{'visual':WEEK},
    'math.u10.choice.05':{'options':{'a grape':thing('grape'),'a watermelon':thing('watermelon'),'a strawberry':thing('strawberry')}},
    'math.u11.main.01':{'options':{'2 + __ = 10':count(2,arrangement='tenFrame'),'__ + 5 = 10':count(5,arrangement='tenFrame'),'6 + __ = 10':count(6,arrangement='tenFrame')}},
    'math.u11.main.03':{'options':{'3 + 2':two_colours(3,2),'4 + 1':two_colours(4,1)}},
    'math.u11.main.07':{'visual':two_colours(6,3,'tenFrame')},
    'math.u11.choice.01':{'options':{'6 and 4':two_colours(6,4,'tenFrame'),'6 and 3':two_colours(6,3,'tenFrame'),'5 and 4':two_colours(5,4,'tenFrame')}},
    'math.u11.choice.02':{'visual':jumps(0,10,8,[2],ask='distance')},
    'math.u11.choice.03':{'visual':jumps(10,20,14,[2])},
    'math.u11.choice.04':{'visual':jumps(0,10,9,[1])},
    'math.u11.choice.05':{'visual':jumps(10,20,18,[-3])},
    'math.u12.main.05':{'visual':HALF},
    'math.u12.main.06':{'visual':HALF},
    'math.u12.choice.02':{'visual':double(2)},
    'math.u12.choice.03':{'visual':HALF},
    'math.u12.choice.04':{'visual':double(3)},
    'math.q02.01':{'visual':HOOPS},
    'math.q02.02':{'visual':colours('red','blue','red','blue',None)},
    'math.q02.03':{'visual':tens(15)},
    'math.q02.04':{'visual':line(0,40,markers=[10,20])},
    'math.q02.05':{'visual':WEEK},
    'math.q02.07':{'visual':count(8,arrangement='tenFrame')},
    'math.q02.08':{'visual':jumps(0,10,7,[3],ask='distance')},
    'math.q02.09':{'visual':double(4)},
    'math.q02.10':{'visual':HALF},
    'math.u13.main.01':{'visual':groups({**pairs(6),'width':220,'height':110,'label':'6: even'},{**pairs(7),'width':220,'height':110,'label':'7: odd'})},
    'math.u13.main.03':{'visual':pairs(10)},
    'math.u13.main.06':{'options':{'14 = 7 + __':double(7),'14 = 10 + __':two_colours(10,4)}},
    'math.u13.main.04':{'visual':{'type':'podium','places':[{'name':'Ali','place':1},{'name':'Mona','place':2},{'name':'Omar','place':3}]}},
    'math.u13.choice.02':{'options':{'9':pairs(9,12),'12':pairs(12,12),'4':pairs(4,12)}},
    'math.u13.choice.03':{'visual':POSITIONS},
    'math.u13.choice.04':{'visual':{'type':'money','coins':[25,50,100]}},
    'math.u13.choice.05':{'visual':tens(12)},
    'math.u14.main.01':{'options':{'double 2':double(2),'double 5':double(5)}},
    'math.u14.main.02':{'options':{'double 10':double(10),'double 7':double(7)}},
    'math.u14.choice.01':{'visual':double(6)},
    'math.u14.choice.02':{'visual':line(0,12,markers=[2,9])},
    'math.u14.choice.03':{'visual':plus(7,3,'cube')},
    'math.u14.choice.04':{'visual':jumps(10,20,20,[-2])},
    'math.u14.choice.05':{'visual':double(8)},
    'math.u15.main.07':{'options':shapes('cylinder','cone','pyramid','cuboid','sphere','cube')},
    'math.u15.choice.02':{'visual':shape('cone')},
    'math.u15.choice.03':{'visual':shape('sphere')},
    'math.u15.choice.04':{'visual':shape('cuboid')},
    'math.u15.choice.05':{'visual':shape('triangle')},
    'math.u16.main.07':{'options':shapes('circle','square','triangle','oval')},
    'math.u17.main.01':{'visual':HALF},
    'math.u17.main.06':{'visual':WHOLE},
    'math.u17.main.07':{'visual':double(5)},
    'math.u17.choice.02':{'visual':double(8)},
    'math.u17.choice.03':{'visual':WHOLE},
    'math.u17.choice.04':{'visual':double(9)},
    'math.u17.choice.05':{'visual':thing('string',height=90,artWidth=360)},
    'math.u18.main.04':{'visual':clock(3,0)},
    'math.u18.main.05':{'options':{'weigh flour':thing('flour'),'measure a pencil':thing('pencil'),'measure water':thing('glass of water')}},
    'math.u18.main.06':{'options':{'jug':thing('jug'),'mug':thing('mug'),'bowl':thing('bowl')}},
    'math.u18.main.08':{'visual':clock(3,30)},
    'math.u18.choice.02':{'visual':clock(5,30)},
    'math.u18.choice.03':{'visual':thing('parcel'),'options':{'a jug':thing('jug'),'a ruler':thing('ruler'),'scales':thing('scales')}},
    'math.u18.choice.04':{'visual':groups({**thing('jug',height=150),'label':'a jug'},{**thing('mug',height=80),'label':'a mug'})},
    'math.u18.choice.05':{'visual':clock(3,30)},
    'math.q03.01':{'options':{'6':pairs(6,9),'3':pairs(3,9),'9':pairs(9,9)}},
    'math.q03.02':{'visual':POSITIONS},
    'math.q03.03':{'visual':double(4)},
    'math.q03.04':{'visual':jumps(0,20,11,[6])},
    'math.q03.05':{'visual':shape('cube')},
    'math.q03.06':{'visual':groups({**shape('triangle'),'label':'before'},{**shape('triangle',rotation=180),'label':'upside down'})},
    'math.q03.08':{'visual':double(10)},  # two friends, ten sweets each
    'math.q03.10':{'visual':thing('flour'),'options':{'jug':thing('jug'),'scales':thing('scales'),'ruler':thing('ruler')}},
}
PICTURED=set()

# Teacher review 5: every Maths sticker showed the same calculator icon. Each
# word now has a small picture of its own, drawn like the question pictures.
STICKER_PICTURES={
    'count':count(3,'apple'),
    'add':two_colours(2,3),
    'side':shape('square'),
    'pictogram':count(4,'banana'),
    'zero':count(0),
    'longer':thing('pencil',height=40,artWidth=150),
    'Venn diagram':venn(['',''],[('car','both')]),
    'pattern':{'type':'pattern','items':[{**count(1),'color':c,'width':30,'height':30} for c in ['red','blue','red','blue']]},
    'tens and ones':two_colours(10,4),
    'mass':thing('watermelon'),
    'difference':line(0,10,markers=[7,10]),
    'half':HALF,
    'odd':pairs(7),
    'double':double(3),
    'face':shape('cube'),
    'total':count(7,'counter','scattered'),
    'whole':WHOLE,
    'capacity':thing('jug'),
    'count on':{**line(0,10),'from':5,'shown':[1,1,1]},
    'bar chart':count(4,'cube'),
}

# Teacher review 5: questions that asked what a word means now ask about a
# picture (the owner chose this for the definitions on 14 October 2026).
# The book's question and answer stay in each step's source for the parent.
WORD_QUESTIONS={
    'math.u02.choice.01':single('Which picture shows 2 + 3?','c',['a','b','c'],option_visuals={'a':{**count(5),'removed':3},'b':{**count(3),'slots':5},'c':two_colours(2,3)}),
    'math.u04.choice.03':single('Look at the graph. What is it made of?','blocks (squares)',['only circles','only words','blocks (squares)'],PETS),
    'math.u05.choice.01':single('How many apples are in the basket?','0',['1','0','10'],thing('basket',height=150)),
    'math.u08.choice.04':single('The triangle turned. What changed?','the way it points',['its size','the way it points','its colour'],groups({**shape('triangle'),'label':'before'},{**shape('triangle',rotation=90),'label':'turned'})),
    'math.u09.choice.05':single('Look at 18 as tens and ones. What does the 1 in 18 stand for?','one ten',['eighteen','one ten','just one'],tens(18)),
    'math.u12.choice.01':single('Which shape is cut into two halves?','c',['a','b','c'],option_visuals={'a':UNEQUAL,'b':QUARTER,'c':HALF}),
    'math.u12.choice.05':single('Which shape is cut into equal parts?','b',['a','b','c'],option_visuals={'a':UNEQUAL,'b':{'type':'fraction','shape':'square','parts':4,'shaded':1,'equal':True},'c':shape('circle')}),
    'math.u13.choice.01':single('Put these 6 socks in pairs. How many are left over?','0',['1','0','2'],pairs(6)),
    'math.u16.choice.04':single('Which part of this graph tells us what it is about?','the title',['the blocks','the colours','the title'],SCHOOL),
    'math.u16.choice.05':single('Look at the fish column. How many children chose fish?','0',['1','0','10'],PETS_NO_FISH),
    'math.u17.choice.01':single('Which picture shows ½?','a',['a','b','c'],option_visuals={'a':HALF,'b':UNEQUAL,'c':QUARTER}),
}

HALVES={'a':{'type':'fraction','shape':'circle','parts':2,'shaded':0,'equal':True},
        'b':{'type':'fraction','shape':'rectangle','parts':2,'shaded':0,'equal':False},
        'c':{'type':'fraction','shape':'square','parts':2,'shaded':0,'equal':True,'orientation':'diagonal'}}
COLOURED={'a':{'type':'fraction','shape':'circle','parts':2,'shaded':1,'equal':True},
          'b':{'type':'fraction','shape':'square','parts':4,'shaded':1,'equal':True},
          'c':{'type':'fraction','shape':'rectangle','parts':2,'shaded':1,'equal':True}}


def unit_specs():
    """Reviewed accessible adaptations; drawings and personal responses are ungraded."""
    return {
    1:[
        number('Count the apples. How many are there?',8,count(8,'apple'), 'Touch each apple once. There are 8 apples.'),
        number('Count the stars. How many are there?',13,count(13,'star'), 'Counting each star once gives 13 stars.'),
        mapping('Fill the gaps in the number track.', [('11, 12, __, 14','13'),('14, 15, __, 17','16'),('17, __, 19, 20','18')], [13,16,18],line(11,20), 'The missing numbers are 13, 16 and 18.'),
        mapping('Match each dot picture to its number.', [('A','4'),('B','6'),('C','10')],[4,6,10],groups({**count(4),'label':'A'},{**count(6),'label':'B'},{**count(10,arrangement='tenFrame'),'label':'C'}), 'The pictures show 4, 6 and 10 dots.'),
        free('With an adult, draw 9 circles on paper. Count them together.'),
        tf('Sara spreads out 6 cups. Now there are more than 6 cups.',False,'Moving the cups does not change how many there are.'),
        single('Choose the number twelve.','12',['21','12','2','20'],explanation='Twelve is ten and two, written 12.'),
        free('Count something in your room with an adult. What did you count, and how many?'),
    ],
    2:[
        mapping('Find one more and one less.', [('1 more than 6','7'),('1 less than 10','9')],[7,9],line(0,10),'One more moves forward; one less moves back.'),
        number('Start at 5 and count on 3. Where do you land?',8,jumps(0,10,5,[3]),'Three forward jumps from 5 land on 8.'),
        number('Start at 9 and count back 4. Where do you land?',5,jumps(0,10,9,[-4]),'Four backward jumps from 9 land on 5.'),
        single('Choose the addition sentence for the two groups.','4 + 3 = 7',['4 + 3 = 7','4 - 3 = 1','3 + 3 = 6'],groups({**count(4),'color':'blue'},{**count(3),'color':'orange'}),'Adding 4 blue dots and 3 orange dots makes 7.'),
        number('There are 8 cubes. Take away 3. How many remain?',5,count(8,'cube'),'Taking 3 cubes from 8 leaves 5 cubes.'),
        mapping('Match the words to the number sentence.', [('4 add 3 equals 7','4 + 3 = 7'),('7 take away 2 is 5','7 - 2 = 5')],['4 + 3 = 7','7 - 2 = 5'],explanation='Plus adds, minus takes away and equals means the same as.'),
        single('8 cars were parked. 4 drive away. Choose the correct sentence.','8 - 4 = 4',['8 + 4 = 12','8 - 4 = 4','4 - 4 = 0'],explanation='The cars leave, so take 4 away from 8.'),
        number('Mona has 7 sweets. Ali has 4. How many more does Mona have?',3,groups({**count(7),'label':'Mona'},{**count(4),'label':'Ali'}),'Match the sweets in pairs. Mona has 3 without partners.'),
    ],
    3:[
        mapping('Match each flat shape to its name.', [('A','circle'),('B','triangle'),('C','square'),('D','rectangle')],['circle','triangle','square','rectangle'],groups(*[{**shape(s),'label':chr(65+i)} for i,s in enumerate(['circle','triangle','square','rectangle'])]),'Count straight sides and corners to name the shapes.'),
        single('I have 4 corners and 4 equal sides. What am I?','square',['square','rectangle','triangle'],explanation='A square has 4 equal sides and 4 corners.',option_visuals={s:shape(s) for s in ['square','rectangle','triangle']}),
        single('I have 6 square faces and 8 corners. What am I?','cube',['cube','sphere','cylinder'],explanation='A cube has 6 square faces and 8 corners.',option_visuals={s:shape(s) for s in ['cube','sphere','cylinder']}),
        mapping('Complete the triangle facts.', [('sides','3'),('corners','3')],[0,3,4],shape('triangle'),'A triangle has 3 sides and 3 corners.'),
        multiple('Choose all the shapes that can roll.',['sphere','cube','cylinder','cuboid'],['sphere','cylinder'],explanation='Spheres and cylinders have curved parts that let them roll.',option_visuals={s:shape(s) for s in ['sphere','cube','cylinder','cuboid']}),
        mapping('Sort flat drawings and solid objects.', [('square','Flat (2D)'),('ball','Solid (3D)'),('tin','Solid (3D)'),('triangle','Flat (2D)'),('dice','Solid (3D)'),('circle','Flat (2D)')],['Flat (2D)','Solid (3D)'],explanation='Flat drawings are 2D. Objects you can hold are 3D.'),
        tf('A square turned onto its corner is still a square.',True,'Turning does not change its 4 equal sides or 4 corners.'),
        free('With an adult, draw a house using squares, rectangles and triangles. Count your triangles.'),
    ],
    4:[
        number('How many people chose apple?',4,FRUIT,'One picture represents one person. The apple row has 4.'),
        single('Which fruit is the favourite?','apple',['apple','banana','orange','mango'],FRUIT,'The apple row has the most pictures.'),
        single('Which fruit did the fewest people choose?','mango',['apple','banana','orange','mango'],FRUIT,'Mango has the fewest pictures: one.'),
        number('How many chose banana and orange together?',5,FRUIT,'Two chose banana and 3 chose orange. Together that is 5.'),
        number('How many people were asked altogether?',10,FRUIT,'Add all the rows: 4 + 2 + 3 + 1 = 10.'),
        mapping('Sort the toys by colour.', [('red car','red'),('blue ball','not red'),('red ball','red'),('green car','not red')],['red','not red'],explanation='Red objects go in red. Every other colour goes in not red.'),
        mapping('Sara, Laila and Nour chose cat. Omar chose dog. Adam chose fish. Match each pet to its total.', [('cat','3'),('dog','1'),('fish','1')],[1,3,5],explanation='Count each vote once: 3 cats, 1 dog and 1 fish.'),
        free('Ask 4 people their favourite colour with an adult. Draw one equal-size circle for each vote.'),
    ],
    5:[
        mapping('Match each number word to its number.', [('eleven','11'),('fifteen','15'),('twenty','20')],[11,15,20],explanation='These words name the numbers 11, 15 and 20.'),
        mapping('Count back and fill each gap.', [('18, 17, __','16'),('17, 16, __, 14','15'),('14, __, 12','13')],[13,15,16],line(12,18),'Counting back takes away one each time.'),
        mapping('Choose the larger number in each pair.', [('14 or 19','19'),('8 or 11','11'),('20 or 2','20')],[19,11,20],line(0,20),'The larger number is farther along the number track.'),
        mapping('Choose the smaller number in each pair.', [('13 or 10','10'),('6 or 16','6')],[10,6],line(0,20),'The smaller number comes first on the number track.'),
        number('The fruit bowl is empty. How many apples are there?',0,count(0,'apple'),'Zero means there are no apples.'),
        number('Make a guess aloud first. Then count the dots. How many are there?',12,count(12,arrangement='scattered'),'An estimate is a guess. Counting checks it: there are 12.',hint='Your guess does not have to match. Count each dot once.'),
        number('Start at 7 and count on 4. Where do you land?',11,jumps(0,20,7,[4]),'Four forward jumps from 7 land on 11.'),
        number('Start at 15 and count back 3. Where do you land?',12,jumps(0,20,15,[-3]),'Three backward jumps from 15 land on 12.'),
    ],
    6:[
        single('When do you usually eat breakfast?','morning',['morning','night','evening'],explanation='We usually eat breakfast in the morning.'),
        single('When do you usually go to sleep?','night',['afternoon','night','morning'],explanation='We usually sleep at night.'),
        ordered('Put these parts of a school day in order.',['wake up','go to school','eat dinner'],explanation='Wake up first, go to school, then eat dinner later.'),
        single('Which takes longer?','a night\'s sleep',['brushing your teeth','a night\'s sleep','eating dinner'],explanation='A night of sleep takes much longer than brushing your teeth.'),
        single('Which takes a shorter time?','a blink',['a blink','a football match','a night\'s sleep'],explanation='A blink takes a very short time.'),
        mapping('Compare the ribbons. Choose the longest and shortest.', [('longest','b'),('shortest','c')],['a','b','c'],groups({'type':'ruler','units':5,'item':'ribbon','label':'a'},{'type':'ruler','units':7,'item':'ribbon','label':'b'},{'type':'ruler','units':3,'item':'ribbon','label':'c'}),'Start at the same line. Ribbon b is longest and c shortest.'),
        tf('To compare two pencils, put their ends on the same line.',True,'Lining up the ends makes the length comparison fair.'),
        free('With an adult, draw something you do in the afternoon. Tell them about it.'),
    ],
    7:[
        single('Which object belongs in both red and has wheels?','red car',['red car','red apple','blue ball'],explanation='A red car is red and has wheels, so it fits both labels.'),
        single('Why does the red car belong in the overlap?','It is red and has wheels.',['It is red and has wheels.','It is only red.','It fits neither label.'],explanation='The overlap is for objects that fit both labels.'),
        multiple('Choose the objects that fit neither red nor has wheels.',['red car','green leaf','blue ball','red apple'],['green leaf','blue ball'],explanation='The green leaf and blue ball are not red and have no wheels.'),
        mapping('Sort the numbers into the Carroll diagram.', [(str(v),'less than 10' if v<10 else 'not less than 10') for v in [3,12,7,15,9,18,10]],['less than 10','not less than 10'],carroll(['less than 10','not less than 10']),explanation='10 is not less than 10. It belongs with 12, 15 and 18.'),
        number('How many children have a cat?',5,PETS,'Each block is one child. The cat column has 5.'),
        number('How many more cats than dogs?',2,PETS,'There are 5 cats and 3 dogs. The difference is 2.'),
        tf('An object that fits both labels belongs in the overlap.',True,'Both labels are true in the overlap.'),
        free('Find or draw an object that is not red and has no wheels. Explain why it fits neither label.'),
    ],
    8:[
        single('What comes next in the pattern?','red circle',['red circle','blue square','yellow triangle'],{'type':'pattern','items':[shape('circle',color='red'),shape('square',color='blue'),shape('circle',color='red'),shape('square',color='blue')]},'The repeating part is red circle, blue square.',option_visuals={'red circle':shape('circle',color='red'),'blue square':shape('square',color='blue'),'yellow triangle':shape('triangle',color='yellow')}),
        single('What comes next in this pattern?','triangle',['triangle','circle','square'],{'type':'pattern','items':[shape('triangle',color='yellow'),shape('triangle',color='yellow'),shape('circle',color='green')]*2},'Two triangles and a circle repeat. The next shape is a triangle.',option_visuals={s:shape(s) for s in ['triangle','circle','square']}),
        mapping('Fill the next two gaps: red, blue, blue, red, blue, blue, __, __.', [('first gap','red'),('second gap','blue')],['red','blue'],explanation='The repeating part is red, blue, blue.'),
        free('Make your own repeating pattern with two shapes on paper. Repeat the part at least twice.'),
        number('Walk 3 steps forwards and 1 backwards. How many steps from the start?',2,jumps(0,4,0,[3,-1]),'Three forwards and one backwards leaves 2 steps forwards.'),
        tf('A cube is a flat 2D shape.',False,'A cube is solid, so it is a 3D shape.',shape('cube')),
        mapping('Compare a square and a rectangle.', [('They each have 4 sides and 4 corners.','same'),('Only the square must have 4 equal sides.','different')],['same','different'],groups(shape('square'),shape('rectangle')),'Both have 4 sides. A square has all 4 sides equal.'),
        mapping('Sort the shapes by their corners.', [('circle','0 corners'),('triangle','3 corners'),('square','4 corners'),('rectangle','4 corners')],['0 corners','3 corners','4 corners'],explanation='Circle: 0 corners. Triangle: 3. Square and rectangle: 4.'),
    ],
    9:[
        number('What number do the ten and ones make?',14,groups({'type':'count','count':10,'arrangement':'tenFrame','label':'one ten'},{'type':'count','count':4,'label':'ones'}),'One ten and 4 ones make 14.'),
        number('What number do the ten and ones make?',19,groups({'type':'count','count':10,'arrangement':'tenFrame','label':'one ten'},{'type':'count','count':9,'label':'ones'}),'One ten and 9 ones make 19.'),
        mapping('Complete: 17 is __ ten and __ ones.', [('tens','1'),('ones','7')],[1,7],explanation='The 1 is one ten; the 7 is seven ones.'),
        mapping('Complete: 20 is __ tens and __ ones.', [('tens','2'),('ones','0')],[0,2],explanation='20 has 2 tens and no extra ones.'),
        ordered('Put the numbers in order, smallest first.',['9','12','15','20'],line(0,20),'Compare the tens first, then the ones.'),
        mapping('Count in tens and fill the gaps.', [('10, 20, __, 40','30'),('20, 30, 40, __','50')],[30,50],explanation='Counting in tens adds a whole ten each time.'),
        number('Count on in tens: 4, 14, __, 34. What is missing?',24,explanation='Adding ten to 14 gives 24. The ones stay 4.'),
        single('Omar wrote sixteen as 61. Choose sixteen.','16',['61','16','6'],explanation='Sixteen is one ten and six ones: 16.'),
    ],
    10:[
        number('How many days are in a week?',7,explanation='There are 7 days before the week repeats.'),
        mapping('Find the neighbouring days.', [('after Monday','Tuesday'),('before Friday','Thursday')],['Tuesday','Thursday','Saturday'],explanation='Tuesday follows Monday. Thursday comes before Friday.'),
        number('How many months are in a year?',12,explanation='A year has 12 months, from January to December.'),
        single('Which month comes after January?','February',['March','February','December'],explanation='February is the month after January.'),
        number('How many cubes long is the pencil?',6,{'type':'ruler','units':6,'unit':'cube','item':'pencil'},'Six equal cubes cover the pencil length with no gaps.'),
        single('Look at the balance. Which side is heavier, A or B?','B',['A','B'],balance(1,3,'A','B'),explanation='The heavier side goes down, so B is heavier.'),
        tf('A bigger object is always heavier.',False,'A large pillow can be lighter than a small stone.'),
        ordered('Put these in order, heaviest first.',['chair','book','feather'],explanation='A typical chair is heavier than a book, and a feather is lightest.'),
    ],
    11:[
        mapping('Fill the partners that make 10.', [('6 + __ = 10','4'),('2 + __ = 10','8'),('__ + 5 = 10','5')],[4,8,5],explanation='The partners are 6 and 4, 2 and 8, 5 and 5.'),
        number('7 + __ = 10. How many empty spaces?',3,count(7,arrangement='tenFrame'),'Seven filled spaces leave 3 empty spaces in a ten frame.'),
        mapping('Find each total.', [('3 + 2','5'),('4 + 1','5')],[4,5,6],explanation='Both addition sentences have the same total: 5.'),
        number('Use the number line: 12 + 3 = ?',15,jumps(10,20,12,[3]),'Three forward jumps from 12 land on 15.'),
        number('There are 16 cubes. Take away 4. How many remain?',12,count(16,'cube'),'Taking 4 from 16 leaves 12.'),
        number('What is the difference between 5 and 9?',4,jumps(0,10,5,[4],ask='distance'),'Count 4 jumps from 5 to 9.'),
        single('Sam says 6 + 3 = 19. Choose the sensible total.','9',['19','9','3'],explanation='Six and three are small groups. Together they make 9.'),
        number('There are 10 beans. You see 6. How many are hiding?',4,count(6,'bean'),'Six visible beans and 4 hidden beans make 10.'),
    ],
    12:[
        multiple('Choose all shapes cut into two equal parts.',['a','b','c'],['a','c'],explanation='Shapes a and c have equal parts. Shape b has unequal parts.',option_visuals=HALVES),
        number('Half of 6 is...?',3,count(6),'Sharing 6 equally between two groups gives 3 each.'),
        number('Half of 10 is...?',5,count(10),'Sharing 10 equally gives 5 in each group.'),
        number('Share 8 apples equally between 2 children. How many each?',4,count(8,'apple'),'Two equal groups of 4 make 8 apples.'),
        number('A half is one of how many equal parts?',2,explanation='A half is one of two equal parts.'),
        tf('It makes sense to ask for the bigger half.',False,'Halves of the same whole must be the same size.'),
        free('With an adult, draw a line cutting a rectangle into two equal parts. Check both parts.'),
        free('Name something at home that you can share in half. Explain how both parts can be equal.'),
    ],
    13:[
        multiple('Choose all the even numbers.',['2','5','8','11','14','17'],['2','8','14'],explanation='2, 8 and 14 make pairs with none left over.'),
        single('Is 7 odd or even?','odd',['odd','even'],count(7,'sock','pairs'),'Seven makes three pairs and one left over, so it is odd.'),
        mapping('Count in twos and fill the gaps.', [('2, 4, __, 8','6'),('4, 6, 8, __','10')],[6,10],explanation='Counting in twos adds 2 each time.'),
        single('Ali came 1st, Mona 2nd and Omar 3rd. Who came 2nd?','Mona',['Ali','Mona','Omar'],explanation='Mona is in the second position.'),
        single('Which position means the third star from the left?','3rd',['1st','2nd','3rd','4th'],count(5,'star'),'The third star from the left is in position 3rd.'),
        mapping('Fill the parts of 14.', [('14 = 10 + __','4'),('14 = 7 + __','7')],[4,7],explanation='10 and 4 make 14; 7 and 7 make 14 too.'),
        single('Which coin is worth the most?','b',['a','b','c'],groups({'type':'money','coins':[50],'label':'a'},{'type':'money','coins':[100],'label':'b'},{'type':'money','coins':[25],'label':'c'}),'One pound is 100 piastres, more than 50 or 25 piastres.'),
        number('You have 5 pairs of socks. How many socks?',10,count(10,'sock','pairs'),'Each pair has 2 socks. Five pairs have 10 socks.'),
    ],
    14:[
        mapping('Find the doubles.', [('double 2','4'),('double 5','10')],[4,10],explanation='Double means the same number added again.'),
        mapping('Find these doubles.', [('double 7','14'),('double 10','20')],[14,20],explanation='7 + 7 = 14, and 10 + 10 = 20.'),
        number('Start with the bigger number and find 3 + 8.',11,jumps(0,20,8,[3]),'Start at 8 and count on 3 to reach 11.'),
        number('Start with the bigger number and find 5 + 12.',17,jumps(0,20,12,[5]),'Start at 12 and count on 5 to reach 17.'),
        number('8 birds are in a tree. 4 more come. How many now?',12,groups(count(8,'bird'),count(4,'bird')),'Adding 4 birds to 8 gives 12 birds.'),
        number('Count back: 15 - 3 = ?',12,jumps(10,20,15,[-3]),'Count back three jumps from 15: 14, 13, 12.'),
        number('What is the difference between 13 and 17?',4,jumps(10,20,13,[4],ask='distance'),'There are 4 jumps from 13 to 17.'),
        free('Tell an adult your own number story for 6 + 4 = 10. Act it out with safe objects.'),
    ],
    15:[
        number('How many faces does a cube have?',6,shape('cube'),'A cube has 6 square faces.'),
        number('How many corners does a cube have?',8,shape('cube'),'A cube has 8 corners.'),
        single('Are these the same shape?','yes',['yes','no'],groups(shape('triangle'),shape('triangle',rotation=180)),'Both are triangles. Turning does not change the shape.'),
        number('How many flat faces does a cylinder have?',2,shape('cylinder'),'A cylinder has two flat circular faces.'),
        single('sphere, cube, cube, sphere, cube, cube... What comes next?','sphere',['sphere','cube','cone'],explanation='The repeating part is sphere, cube, cube.',option_visuals={s:shape(s) for s in ['sphere','cube','cone']}),
        free('With an adult, name something in a playground that has the shape of a circle.'),
        mapping('Sort the solid shapes by their faces.', [(s,'has a curved face' if s in ['sphere','cylinder','cone'] else 'only flat faces') for s in ['sphere','cube','cylinder','cuboid','cone','pyramid']],['has a curved face','only flat faces'],explanation='Sphere, cylinder and cone have curved faces; the other shapes have only flat faces.'),
        multiple('The robot faces up. Choose both routes that reach the star two spaces up and two right.', ['2 forwards, turn right, 2 forwards','turn right, 2 forwards, turn left, 2 forwards','2 backwards, turn right, 2 forwards'],['2 forwards, turn right, 2 forwards','turn right, 2 forwards, turn left, 2 forwards'],robot({'2 forwards, turn right, 2 forwards':['F','F','R','F','F'],'turn right, 2 forwards, turn left, 2 forwards':['R','F','F','L','F','F'],'2 backwards, turn right, 2 forwards':['B','B','R','F','F']}),explanation='Both selected routes finish two spaces up and two right of the start.'),
    ],
    16:[
        number('How many children walked?',6,SCHOOL,'Count the walk column: 6 blocks.'),
        number('How many came by bus?',4,SCHOOL,'Count the bus column: 4 blocks.'),
        single('Which way was most popular?','walk',['walk','bus','car','bike'],SCHOOL,'Walk has the tallest column and the most children.'),
        single('Which way was least popular?','bike',['walk','bus','car','bike'],SCHOOL,'Bike has the shortest column and the fewest children.'),
        number('How many more walked than came by car?',3,SCHOOL,'Six walked and 3 came by car. The difference is 3.'),
        number('How many children are in the graph altogether?',15,SCHOOL,'Add the columns: 6 + 4 + 3 + 2 = 15.'),
        mapping('Sort the flat shapes by their corners.', [('circle','has no corners'),('square','has corners'),('triangle','has corners'),('oval','has no corners')],['has corners','has no corners'],explanation='Square and triangle have corners; circle and oval have none.'),
        free('Ask an adult your own question about this graph. Use the graph to check your answer.',SCHOOL),
    ],
    17:[
        single('Choose how to write one half.','½',['½','12','2/1'],explanation='One over two means one of two equal parts.'),
        number('Half of 20 is...?',10,count(20),'Two equal groups of 10 make 20.'),
        number('Half of 14 is...?',7,count(14),'Two equal groups of 7 make 14.'),
        number('Half of 12 is...?',6,count(12),'Two equal groups of 6 make 12.'),
        multiple('Choose all shapes with one half coloured.',['a','b','c'],['a','c'],explanation='a and c have half coloured. b has only one of four equal parts coloured.',option_visuals=COLOURED),
        single('Two halves make one...','whole',['whole','half','quarter'],explanation='Putting two equal halves together makes the whole again.'),
        number('Half a team is 5 children. How many are in the whole team?',10,explanation='Five children are one half. Another five make the whole team of 10.'),
        free('With an adult, draw a cake and one line that divides it into two equal halves.'),
    ],
    18:[
        single('What time does this clock show?','4 o\'clock',['3 o\'clock','4 o\'clock','half past 4'],{'type':'clock','hour':4,'minute':0},'The long hand is on 12 and the short hand is on 4.'),
        single('What time does this clock show?','half past 7',['7 o\'clock','half past 7','half past 8'],{'type':'clock','hour':7,'minute':30},'The long hand is on 6. The short hand is between 7 and 8.'),
        free('Draw the hands for 9 o\'clock on paper with an adult. Long hand on 12, short hand on 9.'),
        single('What is the long hand called?','minute hand',['hour hand','minute hand'],explanation='The long hand shows minutes.'),
        mapping('Match each measuring job to its tool.', [('measure a pencil','ruler'),('weigh flour','scales'),('measure water','jug')],['ruler','scales','jug'],explanation='A ruler measures length, scales measure mass, and a jug measures water.'),
        ordered('Jug holds 5 cups, bowl 4 and mug 2. Put them in order, holds most first.',['jug','bowl','mug'],explanation='Compare capacity: 5 cups, then 4 cups, then 2 cups.'),
        free('Tell an adult your lunchtime. Draw it on a paper clock and check the hands together.'),
        tf('At half past, the long hand points to 6.',True,'The minute hand has travelled halfway around the clock.'),
    ]}


HINTS={
    1:'Touch each object once, then remember the last number.', 2:'Think whether things join the group or leave it.',
    3:'Count sides and corners; look for flat or curved faces.', 4:'Read the labels and count one picture for each vote.',
    5:'Find the numbers on a track. Each step changes the number by one.', 6:'Think about your day, or line up the ends before comparing.',
    7:'Ask about each label separately. Both and neither are groups too.', 8:'Say the repeating part aloud. Turning changes where you face.',
    9:'A ten is a full group of ten. Compare tens, then ones.', 10:'Check the day order; use equal units or see which side goes down.',
    11:'Use a ten frame or count the jumps between the numbers.', 12:'Share equally into two groups. The parts must match.',
    13:'Pair things up; for coins, compare their value rather than their count.', 14:'Start with the bigger number. A double adds the same number again.',
    15:'Turning leaves the shape the same. Count each face or corner once.', 16:'Read the labels. Count blocks and compare the columns.',
    17:'One half is one of two equal parts. Share the group equally.', 18:'Find the long hand first; compare how much each container holds.',
}
EXPLORATIONS={
    1: [('Count once',count(7,'apple')),('Same group, spread out',count(7,'apple','scattered')),('A full ten frame',count(10,arrangement='tenFrame'))],
    2: [('Put groups together',groups(count(2),count(3))),('A number track',line(0,10)),('An empty group',count(0))],
    3: [('Flat shapes',groups(shape('circle'),shape('triangle'),shape('square'))),('Solid shapes',groups(shape('cube'),shape('sphere'),shape('cylinder'))),('A turned square',shape('square',rotation=45))],
    4: [('Picture votes',FRUIT),('Sort by a label',groups(shape('circle',color='red'),shape('circle',color='blue'))),('Equal-size pictures',count(4,'apple'))],
    5: [('Number order',line(0,20)),('None at all',count(0)),('Guess then count',count(11,arrangement='scattered'))],
    6: [('Start at the same line',groups({'type':'ruler','units':3,'item':'pencil'},{'type':'ruler','units':5,'item':'pencil'})),('Time of day',{'type':'clock','hour':7,'minute':0}),('Compare lengths',{'type':'ruler','units':4,'item':'ribbon'})],
    7: [('Red things',shape('circle',color='red')),('Sort numbers',line(0,20)),('Read the pet graph',PETS)],
    8: [('A repeating part',{'type':'pattern','items':[shape('circle'),shape('square')]*3}),('Turn a shape',shape('triangle',rotation=180)),('Forwards and backwards',line(0,5))],
    9: [('One whole ten',count(10,arrangement='tenFrame')),('Extra ones',count(3)),('Two tens',groups(count(10,arrangement='tenFrame'),count(10,arrangement='tenFrame')))],
    10: [('Equal measuring units',{'type':'ruler','units':4,'unit':'cube','item':'pencil'}),('A week repeats',{'type':'pattern','items':[shape('circle')]*7}),('Compare sizes',groups(shape('circle'),shape('square')))],
    11: [('A ten frame',count(5,arrangement='tenFrame')),('Count the difference',line(0,10)),('Join groups',groups(count(3),count(4)))],
    12: [('Two equal parts',{'type':'fraction','shape':'circle','parts':2,'shaded':1,'equal':True}),('Unequal parts',{'type':'fraction','shape':'rectangle','parts':2,'shaded':1,'equal':False}),('Fair sharing',groups(count(3),count(3)))],
    13: [('Pairs with none left',count(6,'sock','pairs')),('One left over',count(7,'sock','pairs')),('Coin values',{'type':'money','coins':[25,50,100]})],
    14: [('The same group twice',groups(count(3),count(3))),('Count on',line(0,20)),('Count back',line(10,20))],
    15: [('Same triangle, turned',groups(shape('triangle'),shape('triangle',rotation=180))),('Flat faces',shape('cube')),('Curved faces',shape('cylinder'))],
    16: [('Graph title and labels',SCHOOL),('Count each block',count(4,'cube')),('Compare columns',chart('Two groups',[('A',5),('B',3)]))],
    17: [('One of two parts',{'type':'fraction','shape':'circle','parts':2,'shaded':1,'equal':True}),('Two halves make a whole',{'type':'fraction','shape':'square','parts':2,'shaded':2,'equal':True}),('Share fairly',groups(count(4),count(4)))],
    18: [('O\'clock',{'type':'clock','hour':3,'minute':0}),('Half past',{'type':'clock','hour':3,'minute':30}),('A measuring tool',{'type':'ruler','units':5,'item':'pencil'})],
}
HOME={
    1:'Count 7 spoons while moving each once. Spread them out and ask whether the number changed. Play a short dice-dot guessing game.',
    2:'Make a floor number line with an adult. Start on a number and count forward or back by jumps. Compare two groups by pairing objects.',
    3:'Find safe objects shaped like a cube, cuboid, sphere, cylinder or cone. Predict which roll or stack, then test and trace flat faces.',
    4:'Ask family members their favourite fruit. Put one equal-size drawing per vote in rows. Read the totals and sort toys by red/not red.',
    5:'Guess how many safe large counters are in a jar, then count to check. Record the guess and count separately; guesses are not graded.',
    6:'Line up the ends of three spoons or pencils and order their lengths. Predict which daily activity takes longer, then compare.',
    7:'Make two overlapping loops with scarves: red and has wheels. Sort toys into red only, wheels only, both and neither. Sort number cards around 10.',
    8:'Continue a two-shape or two-sound pattern, then invent one. Play robot commands in a clear space: forwards, backwards, left and right.',
    9:'Bundle ten safe large counters and add loose ones to build teen numbers. Make two bundles for 20 and practise counting whole tens.',
    10:'With an adult, measure a spoon using equal-size bricks with no gaps. Compare mass with a safe balance and talk about days and months.',
    11:'Use ten safe large counters. Hide some under a cup, count what remains and find the hidden partner. Use a number track for differences.',
    12:'Fold paper so the edges match to make halves. Share 6, 8 or 10 safe large counters equally between two plates and compare both groups.',
    13:'Pair socks to decide odd or even. Race three toy cars to name positions. Compare supervised coins by written value, not the number of coins.',
    14:'Show the same number of large counters in two groups to make doubles. Tell and act out small addition and subtraction stories.',
    15:'Feel safe solid shapes in a bag and describe flat or curved faces. Mark each cube corner once. Give robot commands along a paper grid.',
    16:'Record a short supervised toy-colour survey. Make a block graph with equal-size bricks, then ask about most, least, difference and total.',
    17:'Fold a ribbon in half with an adult. Share 12, 14, 16, 18 or 20 large counters into two equal groups. Write one half as ½.',
    18:'Make a paper clock with an adult handling the scissors. Practise o\'clock and half past. Guess how many same-size cups fill a container, then measure at the sink.',
}

WORDS = [
    ('count','Say one number for each thing, in order.'),
    ('add','Put groups together to make more.'),
    ('side','An edge of a flat shape.'),
    ('pictogram','A chart where each picture stands for one thing.'),
    ('zero','Nothing at all: the number 0.'),
    ('longer','Having greater length when the ends line up.'),
    ('Venn diagram','Sorting hoops with an overlap for things that fit both labels.'),
    ('pattern','Something that repeats in the same way.'),
    ('tens and ones','16 is one ten and six ones.'),
    ('mass','How heavy or light an object is.'),
    ('difference','How many steps from the smaller number to the bigger number.'),
    ('half','One of two equal parts.'),
    ('odd','A number that makes pairs with one left over.'),
    ('double','The same number added again.'),
    ('face','A flat or curved part of a solid shape.'),
    ('total','How many there are altogether.'),
    ('whole','The complete thing before it is cut.'),
    ('capacity','How much a container can hold.'),
]


def visual_units(value):
    """Keep the currency unit explicit in every nested coin diagram."""
    if isinstance(value,dict):
        if value.get('type')=='money': value['unit']='piastres'
        for child in value.values(): visual_units(child)
    elif isinstance(value,list):
        for child in value: visual_units(child)


def source_ref(draft,record=None):
    return {'pages':record['sourcePages'] if record else draft['sourcePages'],
        'questionId':record['id'] if record else None,'answerKeyPages':record['answerKeyPages'] if record else [],
        'answerKeyText':record['answerKeyText'] if record else '', 'sourceSha256':draft['sourceSha256']}


@functools.lru_cache(maxsize=None)
def question_text():
    return json.loads((CONTENT/'maths_question_text.json').read_text(encoding='utf-8'))


def short_explanation(text,limit=16):
    """Whole sentences up to the word limit, never a sentence cut short.

    Cutting at 16 words left "...depth as well as" (teacher review 5).
    """
    short=''
    for sentence in re.split(r'(?<=[.!?])\s+',text.strip()):
        candidate=f'{short} {sentence}'.strip()
        if short and len(candidate.split())>limit: break
        short=candidate
    return short


def playable_step(draft,record,spec,index,hint,explanation):
    options=[]; targets=[]; answer=None
    pictures=PICTURES.get(record['id'],{}) if spec['type']!='free' else {}
    assert not (pictures.get('visual') and spec.get('visual')),(record['id'],'two pictures')
    labels=[str(p[0]) for p in spec['pairs']] if spec['type']=='mapping' else spec.get('choices',[])
    assert set(pictures.get('options',{}))<=set(labels),(record['id'],'picture for a missing answer')
    option_visuals={**pictures.get('options',{}),**spec.get('optionVisuals',{})}
    visual=spec.get('visual') or pictures.get('visual')
    if pictures: PICTURED.add(record['id'])
    kind={'single':'tap-choice','set':'drag-to-basket','mapping':'match-lines','sequence':'order-sequence','free':'story'}[spec['type']]
    if spec['type']=='mapping':
        targets=[{'id':f'target_{i+1}','label':str(t),'art':'math_label'} for i,t in enumerate(spec['targets'])]
        ids={t['label']:t['id'] for t in targets}
        options=[{'id':f'item_{i+1}','label':str(label),'art':'math_label',**({'visual':option_visuals[str(label)]} if str(label) in option_visuals else {})} for i,(label,_) in enumerate(spec['pairs'])]
        answer={'type':'mapping','value':{options[i]['id']:ids[str(v)] for i,(_,v) in enumerate(spec['pairs'])}}
    elif spec['type']!='free':
        options=[{'id':f'choice_{i+1}','label':str(label),'art':'math_label',**({'visual':option_visuals[label]} if label in option_visuals else {})} for i,label in enumerate(spec['choices'])]
        ids={o['label']:o['id'] for o in options}
        answer={'type':spec['type'],'value':ids[spec['correct']] if spec['type']=='single' else [ids[v] for v in spec['correct']]}
    # Teacher review 5: a title, a hint and a reason of its own for every
    # assessed question (assets/content/maths_question_text.json).
    words=question_text()[record['id']] if answer else {}
    text=words.get('explanation') or spec.get('explanation') or explanation
    short=short_explanation(text)
    step={'id':f'{draft["id"]}.step.{index:03d}','kind':kind,'title':('Try it at home' if spec['type']=='free' else words['title']),
        'prompt':spec['prompt'],'options':options,'targets':targets,'answer':answer,
        'assessed':answer is not None,'objective':record['id'] if answer else '',
        'hint':words.get('hint') or spec.get('hint') or hint,'explanation':text,'shortExplanation':short,
        'source':source_ref(draft,record),'scene':'workshop','section':'Try at home' if spec['type']=='free' else ('Challenge' if draft['kind']=='quiz' else 'Discover'),
        'playScene':'maths','theme':draft['id'],'adapted':True}
    if visual: step['mathVisual']=visual
    if not answer:
        step['parentReview']={'en':record['answerKeyText'],'note':'Discuss with an adult; this personal or drawing response is not automatically graded.'}
    if options:
        if all(re.fullmatch(r'[A-Za-z]',o['label']) for o in options):
            # Letters name pictures labelled a, b, c: keep them in that order
            # (teacher review 5 saw b, c, a). Other answers stay shuffled.
            step['options']=sorted(options,key=lambda o:o['label'].lower())
        else:
            step['options']=stable_order(options,step['id'])
        if answer and answer['type']=='sequence' and [o['id'] for o in step['options']]==answer['value']:
            step['options']=step['options'][1:]+step['options'][:1]
    return step


def mcq_spec(record,unit):
    text=norm(record['sourceText'])
    choices=re.findall(r'\(\s+(.*?)\s+\)',text)
    prompt=text.split('(',1)[0].strip()
    correct=MCQ[unit-1][record['number']-1]
    assert correct in choices,(unit,record['number'],correct,choices)
    visual=MCQ_VISUALS.get((unit,record['number'])) or (FRUIT if unit==4 and record['number']==4 else SCHOOL if unit==16 and record['number'] in [2,3] else None)
    return single(prompt,correct,choices,visual,option_visuals=MCQ_OPTION_VISUALS.get((unit,record['number'])),explanation=f'{correct[0].upper()+correct[1:]} is the answer. {MCQ_REASONS[unit-1][record["number"]-1]}')


MCQ_REASONS=[
    ['The last count names the whole group.','Counting on one moves from 15 to 16.','A ten frame has ten spaces.','Thirteen is ten and three.','Moving a group does not change its number.'],
    ['The plus sign joins groups.','Two backward jumps from 6 leave 4.','Taking away moves toward smaller numbers.','One backward step from 8 reaches 7.','Adding nothing changes nothing.'],
    ['A football is a solid round shape.','A cereal box has rectangular faces.','A rectangle has four corners.','A circle is round with no corners.','A cylinder has a circular flat face.'],
    ['There is one equal-size picture per vote.','The longest row has the greatest count.','Each equal-size block represents a vote.','Count the three orange pictures.','Equal sizes make the comparison fair.'],
    ['Zero names an empty group.','17 is farther along the number track.','9 comes immediately before 10.','We guess before counting to check.','Count back one step from 11.'],
    ['We usually see a dark sky at night.','Dinner usually comes in the evening.','A bed is typically longer than a shoe or spoon.','A shared start line makes comparison fair.','Shorter is the opposite of longer.'],
    ['The overlap fits both sorting rules.','10 is equal to 10, not less.','Neither fits either label.','One equal-size block represents one child.','The tallest column contains most blocks.'],
    ['Red and yellow repeat in pairs.','A square has four straight sides.','Your back faces the backward direction.','Turning changes the direction you face.','3D shapes also have depth.'],
    ['13 contains one complete ten and three extras.','Adding one ten to 5 gives 15.','The next bundle adds ten.','Each number is larger than the previous one.','The tens digit names a whole group of ten.'],
    ['The months run from January through December.','More mass makes that side lower.','Touching units cover the whole length.','The week cycles back to Sunday.','A typical watermelon has more mass than a grape or strawberry.'],
    ['6 + 4 fills all ten spaces.','Two jumps lead from 8 to 10.','Adding two to 14 reaches 16.','One more than 9 completes ten.','Three backward jumps from 18 reach 15.'],
    ['Fair halves have matching size.','Two and two make four.','Each equal part is half the pizza.','Three for each person makes six altogether.','Fractions describe equal parts.'],
    ['Every object has a partner.','Nine pairs with one left over.','Third follows second.','Pounds and piastres are money units in Egypt.','Ten and two make twelve.'],
    ['6 + 6 gives twelve.','Starting with the larger number needs fewer jumps.','Swapping the groups does not change the total.','Two backward jumps from twenty reach eighteen.','8 + 8 gives sixteen.'],
    ['Its sides and corners stay the same.','A cone meets at one pointed corner.','A sphere is curved all around.','A cuboid has six flat faces.','A triangle has three straight sides.'],
    ['More blocks make a taller column.','Count the three car blocks.','Four bus blocks and two bike blocks make six.','The title tells us what the graph is about.','No blocks means nobody chose that group.'],
    ['The two parts must be equal.','Eight and eight make sixteen.','Together the two parts rebuild the whole.','Nine and nine make eighteen.','Matching the ends shows the midpoint.'],
    ['The minute hand is at twelve for o\'clock.','The hour hand is halfway to six.','Scales measure mass.','Capacity means how much the container holds.','Thirty is half of sixty minutes.'],
]


def quiz_specs(n):
    return {
    1:[number('How many dots?',9,count(9),'Count each dot once: there are 9.'),number('1 more than 12 is...?',13,explanation='One forward step from 12 reaches 13.'),number('7 take away 3 is...?',4,explanation='Taking three away from seven leaves four.'),single('Name a flat shape with 3 sides.','triangle',['triangle','square','circle'],explanation='A triangle has three straight sides.',option_visuals=shapes('triangle','square','circle')),single('Name a solid shape like a football.','sphere',['sphere','cylinder','circle'],count(1,'ball'),explanation='A football is solid and round like a sphere.',option_visuals=shapes('sphere','cylinder','circle')),single('The longest pictogram row shows the...','most',['most','least','first'],FRUIT,explanation='The longest row has the most equal-size pictures.'),single('Choose the larger number.','18',['18','15'],explanation='18 comes after 15 on the number track.'),number('How many sweets are in an empty bag?',0,explanation='An empty bag contains zero sweets.'),single('When do you usually sleep?','night',['morning','night','afternoon'],explanation='We usually sleep at night.'),single('What should you line up to compare two pencils?','the ends',['the ends','the middles','the colours'],explanation='Start both pencils at the same line.')],
    2:[single('What belongs where two Venn hoops overlap?','things that fit both labels',['things that fit both labels','things that fit neither label','only red things'],explanation='The overlap satisfies both sorting rules.'),single('red, blue, red, blue... What comes next?','red',['red','blue','green'],explanation='The repeated part is red, blue.'),mapping('15 has how many tens and ones?',[('tens','1'),('ones','5')],[1,5],explanation='15 is one whole ten and five ones.'),number('Count in tens: 10, 20, ...?',30,explanation='One more ten after 20 is 30.'),number('Omar plays outside every day for one week. How many days is that?',7,explanation='One week has seven days, from Sunday to Saturday.'),single('On a balance, does the heavier side go up or down?','down',['up','down'],balance(3,1),explanation='More mass makes that side go down.'),number('8 + __ = 10. Find the missing partner.',2,explanation='Eight and two make ten.'),number('What is the difference between 7 and 10?',3,explanation='Three forward jumps lead from seven to ten.'),number('Half of 8 is...?',4,explanation='Share eight equally into two groups of four.'),tf('Two halves of the same whole can have different sizes.',False,'Halves of the same whole are always equal.')],
    3:[single('Choose the even number.','6',['3','6','9'],explanation='Six makes three pairs with none left over.'),single('Which position comes after 2nd?','3rd',['1st','3rd','4th'],explanation='Third follows second.'),number('Double 4 is...?',8,explanation='Four and another four make eight.'),number('6 + 11 = ?',17,explanation='Start at eleven and count on six to reach seventeen.'),number('A dice is a cube. How many faces does a dice have?',6,explanation='A dice is a cube, and a cube has six square faces.'),single('A triangle turns upside down. Is it still a triangle?','yes',['yes','no'],explanation='It still has three straight sides and three corners.'),single('Which graph column shows the most?','the tallest',['the tallest','the shortest','the first'],PETS,explanation='The tallest column has the greatest count.'),number('Share 20 sweets fairly between 2 friends. How many does each friend get?',10,explanation='Two equal groups of ten make twenty, so each friend gets ten.'),single('What time does this clock show?','2 o\'clock',['2 o\'clock','12 o\'clock','half past 2'],{'type':'clock','hour':2,'minute':0},'The minute hand is on twelve; the hour hand is on two.'),single('What do we use to weigh flour?','scales',['scales','ruler','jug'],explanation='Scales measure mass, so use them to weigh flour.')]
    }[n]


def chart_specs():
    toys=chart('Toys in the box',[('cars',4),('balls',2),('dolls',3),('blocks',1)],unit='one toy')
    stars=chart('Stars earned this week',[('Sun',2),('Mon',3),('Tue',1),('Wed',4),('Thu',2)],'pictogram','one star earned')
    birds=chart('Birds we saw from the balcony',[('pigeons',6),('sparrows',8),('crows',3)],'bar','one bird',axisMax=10,tickStep=2)
    return [number('How many cars are in the box?',4,toys,'Count four car blocks.'),single('Which toy is there most of?','cars',['cars','balls','dolls','blocks'],toys,'The cars column has the most blocks.'),number('How many toys altogether?',10,toys,'Add 4 + 2 + 3 + 1 to make 10 toys.'),single('Which day has the most stars?','Wed',['Sun','Mon','Tue','Wed','Thu'],stars,'Wednesday has four stars, the largest count.'),number('How many stars on Monday and Tuesday together?',4,stars,'Monday has three and Tuesday one: four altogether.'),number('How many more stars on Wednesday than Sunday?',2,stars,'Four minus two gives a difference of two.'),number('How many sparrows were seen?',8,birds,'The sparrows bar reaches eight on the scale.'),single('Which bird was seen the fewest times?','crows',['pigeons','sparrows','crows'],birds,'Crows have the shortest bar and the smallest count.'),number('How many pigeons and crows altogether?',9,birds,'Six pigeons and three crows make nine birds.')]


def build():
    specs=unit_specs()
    workshops=guided_workshops()
    # Egyptian Arabic for the parent report, one entry per activity; a missing
    # entry stops the build instead of falling back to a generic sentence.
    arabic=json.loads((CONTENT/'maths_parent_ar.json').read_text(encoding='utf-8'))
    for file in sorted(CONTENT.glob('math_*.json')):
        if file.name in ['math_support.json']: continue
        draft=json.loads(file.read_text(encoding='utf-8'))
        draft['contentVersion']=2
        dump(file,draft)
        ident=draft['id']; quiz=draft['kind']=='quiz'; records=draft['sourceQuestions']
        if ident.startswith('math_unit_'):
            unit=int(ident[-2:]); adapted=specs[unit]+[WORD_QUESTIONS.get(r['id']) or mcq_spec(r,unit) for r in records[8:]]
            hint=HINTS[unit]; home=HOME[unit]
        elif ident.startswith('math_quiz_'):
            unit=(int(ident[-2:])-1)*6+1; adapted=quiz_specs(int(ident[-2:])); hint='Think about the objects, number track or equal groups before choosing.'; home='Revisit the home games for this term. Talk about how each answer was found.'
        else:
            unit=16; adapted=chart_specs(); hint='Read the title and labels first. Count the marks or read the scale.'; home='Build a toy survey chart together. Ask about the most, least, total and difference.'
        assert len(adapted)==len(records)
        steps=[]
        if not quiz:
            workshop=workshops[ident]
            options=[{'id':task['id'],'label':task['prompt'],'art':'math_label'} for task in workshop['tasks']]
            steps.append({'id':f'{ident}.step.001','kind':'explore','title':workshop['title'],
                'prompt':'Help Owl count the apples.' if ident=='math_unit_01' else 'Let us explore together!',
                'options':options,'targets':[],'answer':None,'assessed':False,'objective':'',
                'hint':WORKSHOP_START_HINTS.get(ident) or (COUNT_TAP_HINT if workshop['tasks'][0]['mode']=='count' else workshop['tasks'][0]['hint']),'explanation':workshop['goal'],'shortExplanation':'Make, count or compare the objects. Explain what changed.',
                'source':source_ref(draft),'scene':'workshop','section':'Explore','playScene':'maths','theme':ident,
                'minTouches':len(options),'mathWorkshop':workshop,
                'parentReview':{'en':'Guided practice is ungraded. Completion records the child doing the activities, not a book-question score.'}})
        for record,spec in zip(records,adapted):
            steps.append(playable_step(draft,record,spec,len(steps)+1,hint,'Look carefully at the groups and explain how you found your answer.'))
        # One home activity per goal, written for its question (teacher
        # review 5: every goal had the same "Discuss this question" text).
        goals=[{'objective':s['objective'],'text':question_text()[s['objective']]['home'],
            'textAr':arabic['goal'][f"{ident}/{s['objective']}"],'safety':SAFETY,'safetyAr':arabic['safety'][SAFETY],'pages':s['source']['pages'],'safetyPages':[2],'adapted':True} for s in steps if s['assessed']]
        word,meaning=WORDS[unit-1] if ident.startswith('math_unit_') else ('bar chart','A chart where the end of each bar shows a number.') if ident=='math_charts' else ('count on','Start with a number and add forward jumps.')
        book={'schemaVersion':1,'contentVersion':2,'id':ident,'subject':'maths','title':draft['title'],'quiz':quiz,
            'sourceSha256':draft['sourceSha256'],'sourcePages':draft['sourcePages'],'steps':steps,
            'stickers':[{'id':f'{ident}.sticker','word':word,'art':'math_label','picture':STICKER_PICTURES[word],'meaning':meaning,
                'meaningSource':'adapted_from_big_idea','sourcePages':draft['sourcePages']}],
            'homeActivities':[{'text':home,'textAr':arabic['home'][ident],'safety':SAFETY,'safetyAr':arabic['safety'][SAFETY],'pages':draft['sourcePages'],'safetyPages':[2],'adapted':True}],
            'goalActivities':goals,'parentNote':{'en':'Drawing and personal answers are discussed with an adult and are not automatically graded. Estimate first; a guess is not a scored answer.',
                'ar':'الرسم والإجابات الشخصية بنتناقش فيها مع شخص كبير ومش بنقيّمها تلقائيًا. التوقع الأول مش إجابة عليها درجات.'}}
        if quiz: book['practiceUnitId']=f'math_unit_{(int(ident[-2:])-1)*6+1:02d}'
        visual_units(book)
        dump(CONTENT/'playable'/f'{ident}.json',book)
    # A picture written for a question that no longer exists is a mistake.
    assert PICTURED==set(PICTURES),sorted(set(PICTURES)-PICTURED)
    islands=[]
    for term in range(1,4):
        levels=[{'id':f'math_unit_{n:02d}','title':META[n-1][0],'ar':META[n-1][1]} for n in range((term-1)*6+1,term*6+1)]
        levels.append({'id':f'math_quiz_{term:02d}','title':f'Big Challenge: Term {term}','ar':f'تحدي الفصل الدراسي {term}','quiz':True})
        islands.append({'title':f'Maths Island: Term {term}','ar':f'جزيرة الرياضيات: الفصل {term}',
            'color':['FF3E9B5A','FFE88A2E','FF4A9FE0'][term-1],'levels':levels})
    islands.append({'title':'Chart Skills Island','ar':'جزيرة مهارات الرسوم','color':'FF5B4BA8',
        'levels':[{'id':'math_charts','title':'Chart Skills','ar':'مهارات قراءة الرسوم'}]})
    rules=[('Keep sessions short: two or three sittings of fifteen minutes.', 'خلي الجلسة قصيرة: حوالي ربع ساعة في كل مرة.'),('Play with objects before answering on screen.', 'خلّي الطفل يلعب بالحاجات الأول، وبعدها يجاوب.'),('Ask for a guess before counting. Praise the thinking.', 'اسأله يتوقع العدد قبل العدّ، وامدح طريقته في التفكير.'),(SAFETY,SAFETY_AR)]
    dump(CONTENT/'maths_catalog.json',{'schemaVersion':1,'contentVersion':2,'subject':'maths','title':'Maths','ar':'الرياضيات',
        'welcome':'Welcome to Maths Island! Start by helping Owl count each apple once in Term 1.', 'sourcePages':[2,3],
        'islands':islands,'parentRules':[{'en':en,'ar':ar,'sourcePage':2} for en,ar in rules]})
    support=CONTENT/'math_support.json'
    if support.exists():
        data=json.loads(support.read_text(encoding='utf-8'))
        data['contentVersion']=2
        dump(support,data)


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source-pdf',type=Path,help='Re-extract reviewed source drafts from the supplied 83-page parent companion.')
    args=parser.parse_args()
    if args.source_pdf: extract_source(args.source_pdf)
    build()
    print('Built 18 Maths units, 3 term challenges and Chart Skills from 273 source questions.')
