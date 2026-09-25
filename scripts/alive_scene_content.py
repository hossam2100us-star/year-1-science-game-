"""Build distinct illustrated scene questions from Unit 1 and its answer key."""
from copy import deepcopy

def add_alive_scenes(book):
    g=book['garden']
    g.update(id='garden',asset='garden-v2.png',difficulty=1)
    g['ui'].update(explained="Let's learn this together.",difficulty='1 - First discoveries',difficultyAr='١ - أول اكتشافاتي',menu='Choose an adventure',menuAr='اختار مغامرة',back='My adventures',titleAr='الجنينة')
    data=[
      ('home','home-hunt-v1.png','Home detectives','محققين في البيت',2,[
        ('grandmother','Grandmother','الجدة',True,'Think about a person growing and needing food.','Grandmother is alive. People grow, need food and water, and breathe.','u01.main.01',[.045,.135,.222,.646]),
        ('fish','Fish','السمكة',True,'Does a fish need food and grow?','The fish is alive. It grows and needs food.',None,[.285,.270,.110,.170]),
        ('fly','Fly','الذبابة',True,'Think about growing, needing food and making new living things.','The fly is alive. It grows, needs food and can make new living things.','u01.main.08',[.438,.065,.055,.110]),
        ('mug','Mug','الكوباية',False,'Does a mug grow or need food?','The mug is not alive. It does not grow or need food.','u01.main.01',[.320,.571,.099,.170]),
        ('doll','Doll','العروسة اللعبة',False,'It looks like a person. But does it grow or need food?','The doll is not alive. Looking like a person does not make it alive.','u01.main.08',[.550,.551,.165,.293]),
        ('kettle','Kettle','الغلاية',False,'Does a kettle grow or make new kettles?','A kettle is not alive. It does not grow, does not need food, and cannot make new kettles.','u01.main.03',[.798,.213,.099,.175]),
        ('clock','Clock','الساعة',False,'The hands move. Is moving enough?','The clock is not alive. Its hands move, but moving is not enough.','u01.main.05',[.741,.003,.102,.207]),
      ]),
      ('river','river-hunt-v1.png','River explorers','مستكشفين النهر',3,[
        ('lizard','Lizard','السحلية',True,'Think about growing and needing food.','The lizard is alive. It grows, needs food and breathes.','u01.main.01',[.035,.250,.266,.192]),
        ('worm','Worm','الدودة',True,'Think about growing, needing food and making new living things.','The worm is alive. It grows and needs food.','u01.main.08',[.354,.732,.104,.120]),
        ('dandelion','Dandelion','الهندباء',True,'It does not walk. But does it grow and make seeds?','The dandelion is alive. It grows, needs water and makes seeds.','u01.main.04',[.016,.461,.265,.433]),
        ('stone','Stone','الحجر',False,'Does a stone need food or make babies?','The stone is not alive. It does not need food or make babies.',None,[.528,.584,.131,.134]),
        ('river','River','النهر',False,'The water moves. Does moving mean it is alive?','The river moves, but it is not alive. Moving is not enough.','u01.main.05',[.344,.315,.376,.246]),
        ('spoon','Wooden spoon','المعلقة الخشب',False,'Think about the spoon itself. Is it growing?','The wooden spoon is not alive.',None,[.675,.655,.325,.224]),
        ('egg','Egg with a growing chick','بيضة فيها كتكوت بينمو',True,'Think about the chick growing inside this egg.','This egg is alive: there is a chick growing inside it.',None,[.831,.392,.096,.132]),
      ])
    ]
    book['aliveScenes']=[]
    for sceneId,asset,title,titleAr,difficulty,rows in data:
        scene=deepcopy(g)
        scene.update(id=sceneId,asset=asset,difficulty=difficulty,bounds={},items=[])
        scene['ui'].update(title=title,titleAr=titleAr,
          difficulty=('2 - Look closely' if difficulty==2 else '3 - Think it through'),
          difficultyAr=('٢ - بص كويس' if difficulty==2 else '٣ - فكر في الدليل'),
          tutorial=('Tap grandmother.' if difficulty==2 else 'Find something to investigate.'),
          tutorialAr=('ابدأ بلمس الجدة' if difficulty==2 else 'دور على حاجة وافحصها'),
          hunt='Find another thing.',huntAr='دور على حاجة تانية',
          finished='You explored this whole scene!',finishedAr='اكتشفت كل الحاجات في المشهد!')
        for i,n,ar,alive,hint,explanation,objective,bounds in rows:
            item=dict(id=i,name=n,nameAr=ar,alive=alive,hint=hint,explanation=explanation,
                      objective=objective,sourcePages=[4,5],answerKeyPages=[35] if objective else [],
                      sourceSha256=book['sourceSha256'],
                      sourceSection='sourceQuestions' if objective else 'introductionText')
            if i=='egg':
                item['question']='There is a chick growing inside this egg. Is this egg alive?'
            scene['items'].append(item)
            scene['bounds'][i]=bounds
        book['aliveScenes'].append(scene)
