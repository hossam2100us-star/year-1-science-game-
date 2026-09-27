"""Source-linked compact Materials, Physics and Earth/Space adventures."""
import json,re
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
SRC=ROOT/'assets/content'
def read(id):return json.loads((SRC/f'{id}.json').read_text(encoding='utf-8-sig'))
def slug(s):return re.sub('[^a-z0-9]+','_',s.lower()).strip('_')
def opt(v):
 if isinstance(v,tuple):
  label,art=v
 else:label,art=v,slug(v)
 return dict(id=slug(label),label=label,art=art)
def options(v):return [opt(x) for x in v]
books=[]
def book(id):
 raw=read(id)
 b=dict(schemaVersion=1,contentVersion=1,id=id,title=raw.get('title',id),quiz=id.startswith('quiz'),sourceSha256=raw['sourceSha256'],sourcePages=raw['sourcePages'],steps=[],stickers=[],homeActivities=[])
 books.append(b);return b
def source(b,qid=None):
 raw=read(b['id']);q=next((q for q in raw['sourceQuestions'] if q['id']==qid),None)
 return dict(pages=q['sourcePages'] if q else raw['sourcePages'],questionId=qid,answerKeyPages=q['answerKeyPages'] if q else [],answerKeyText=q['answerKeyText'] if q else '',sourceSha256=raw['sourceSha256'])
def add(b,title,prompt,values,answer=None,q=None,kind='tap-choice',targets=(),**kw):
 qid=(f"u{b['id'][-2:]}.main.{q:02}" if isinstance(q,int) else q)
 s=dict(id=f"{b['id']}.step.{len(b['steps'])+1:03}",kind=kind,title=title,prompt=prompt,options=options(values),targets=options(targets),answer=answer,assessed=answer is not None,objective=qid or '',hint=kw.pop('hint','Look carefully, listen again, and try your discovery.'),explanation=kw.pop('explanation',source(b,qid)['answerKeyText'] or prompt),source=source(b,qid),scene='workshop',section='Challenge' if answer else 'Explore',playScene='science',theme=b['id'],**kw)
 # Stable mixing keeps matching positions from giving the answer away.
 s['options']=s['options'][::2]+s['options'][1::2]
 b['steps'].append(s);return s
def single(b,title,prompt,values,correct,q,**kw):return add(b,title,prompt,values,dict(type='single',value=slug(correct)),q,**kw)
def multi(b,title,prompt,values,correct,q,**kw):return add(b,title,prompt,values,dict(type='set',value=[slug(x) for x in correct]),q,**kw)
def match(b,title,prompt,pairs,q,**kw):
 vals=list(pairs);rights=[]
 for x in pairs.values():
  if x not in rights:rights.append(x)
 return add(b,title,prompt,vals,dict(type='mapping',value={opt(k)['id']:opt(v)['id'] for k,v in pairs.items()}),q,kind='match-lines',targets=rights[::-1],**kw)
def explore(b,title,prompt,values,**kw):return add(b,title,prompt,values,kind='explore',minTouches=len(values),**kw)
def lab(b,title,prompt,mode,values=(),q=None,**kw):return add(b,title,prompt,values,q=q,kind='free-plant',lab=mode,**kw)
def checks(b,rows):
 # Five distinct source goals share one board but keep their own evidence.
 prefix='u'+b['id'][-2:]+'.choice.'
 pairs={question:answer for question,answer in rows}
 s=match(b,'Discovery badges','Match each discovery to its answer.',pairs,prefix+'01')
 s['extraObjectives']=[prefix+f'{n:02}' for n in range(2,6)]
 s['relatedSources']=[source(b,q) for q in s['extraObjectives']]
 s['objectiveItems']={prefix+f'{i+1:02}':[opt(question)['id']] for i,(question,_) in enumerate(rows)}
 s['explanation']=' '.join(source(b,prefix+f'{i:02}')['answerKeyText']+'.' for i in range(1,6))
 return s
b=book('unit_04')
explore(b,'Maker’s workshop','Touch each material and listen to its properties.',[('Metal','spoon'),('Wood','chair'),('Plastic','bottle'),('Glass','window'),('Fabric','shirt'),('Paper','paper'),('Clay','pot')],senseDescriptions={'metal':'Metal is usually hard, shiny and cold to touch.','wood':'Wood is hard and can be rough or smooth.','plastic':'Plastic is light and waterproof.','glass':'Glass is hard, smooth and see-through.','fabric':'Fabric is soft and bendy.','paper':'Paper is light, thin and soaks up water.','clay':'Clay is soft when wet and hard when dry.'},safety='Glass objects are for looking at and talking about, not for testing. Use a plastic cup when you want to talk about "see-through".')
match(b,'Object or material?','Give each idea its name.',{('Things: a spoon and a chair','chair'):'Objects',('What things are made from: metal and wood','spoon'):'Materials'},1)
match(b,'Stock the workshop','Move each object to its material.',{('Window','window'):'Glass',('T-shirt','shirt'):'Fabric',('Nail','nail'):'Metal',('Newspaper','paper'):'Paper'},2)
multi(b,'Metal detective','Choose all the properties of most metals.',['Furry','Hard','Fluffy','Shiny','Cold to touch'],['Hard','Shiny','Cold to touch'],3,focus='spoon')
match(b,'Glass inspector','Sort these discoveries about glass.',{'Glass can break':'True','Glass is soft':'False','Glass can be see-through':'True','All glass is red':'False'},4,focus='window')
lab(b,'Rain laboratory','Predict for each cover, then pour the water.', 'waterproof',[('Plastic','bottle'),('Cotton cloth','shirt'),('Tissue','tissue'),('Foil','foil')],results={'plastic':'dry','cotton_cloth':'wet','tissue':'wet','foil':'dry'},labUi={'choices':{'dry':'Keeps water out','wet':'Lets water through'},'action':'Pour water','result':'Look inside the cup'},explanation='Plastic and foil keep water out. Cloth and tissue let water through.')
multi(b,'Pack for the rain','Choose every waterproof material.',[('Plastic','bottle'),('Cotton cloth','shirt'),('Paper','paper'),('Tissue paper','tissue'),('Aluminium foil','foil')],['Plastic','Aluminium foil'],5)
lab(b,'Shape studio','Choose an object, then try a shape-changing action.','shape',[('Dough','dough'),('Rubber band','rubber_band'),('Sponge','sponge'),('Metal spoon','spoon'),('Paper straw','paper_straw'),('Stone','stone')],labUi={'actions':['Twist','Stretch','Squash','Bend']},explanation='Some materials change shape. A rubber band stretches; a sponge or dough can be squashed; a stone or metal spoon cannot be squashed.')
match(b,'Squash station','Sort these objects by what happens when you squash them.',{('Sponge','sponge'):'Can squash',('Dough','dough'):'Can squash',('Stone','stone'):'Cannot squash',('Metal spoon','spoon'):'Cannot squash'},6)
single(b,'A window that works','Why choose glass for a window?',['We can see through it','It is soft like a pillow','It soaks up water'],'We can see through it',7,focus='window')
multi(b,'Inside a pencil','Find the two materials in this wooden writing pencil.',[('Wood','chair'),'Graphite',('Fabric','shirt'),('Glass','window')],['Wood','Graphite'],8,focus='pencil')
lab(b,'Silly umbrella','Try paper and plastic in the rain. Which one would you choose?', 'waterproof',[('Paper','paper'),('Plastic','bottle')],results={'paper':'wet','plastic':'dry'},labUi={'choices':{'dry':'Keeps water out','wet':'Lets water through'},'action':'Start the rain','result':'Under the umbrella'},focus='umbrella',explanation='Paper soaks up water. Plastic is waterproof.')
checks(b,[(('A see-through window','window'),'Glass'),(('Keeps rain out','umbrella'),'Plastic'),(('Most metal feels','spoon'),'Cold and hard'),(('An object you can stretch','rubber_band'),'Rubber band'),(('A potter shapes this','pot'),'Clay')])
b=book('unit_05')
explore(b,'Movement playground','Touch each movement to hear its name.',[('Push','push'),('Pull','pull'),('Roll','ball'),('Fly','bird'),('Swim','fish'),('Hop','kangaroo'),('Slither','snake'),('Crawl','baby')])
lab(b,'Push and pull playground','Move the slider away and towards you. Watch the drawer move.','force',labUi={'left':'Pull towards you','right':'Push away from you'},explanation='A push moves an object away. A pull brings it towards you.')
match(b,'Which way?','Connect the movement to its force.',{'Away from you':'Push','Towards you':'Pull'},1)
match(b,'Forces around us','Give each action its force.',{('Ring a doorbell','doorbell'):'Push',('Open a drawer','drawer'):'Pull',('Move a swing','swing'):'Both',('Move a trolley','trolley'):'Both'},2)
lab(b,'Float or sink tank','Predict for each object, then drop it into the tank.','tank',[('Balloon','balloon'),('Stone','stone'),('Metal nail','nail'),('Cork','cork'),('Plastic pot','plastic_pot'),('Glass marble','glass_marble')],results={'balloon':'float','stone':'sink','metal_nail':'sink','cork':'float','plastic_pot':'float','glass_marble':'sink'},labUi={'choices':{'float':'Float','sink':'Sink'},'action':'Drop into water','result':'Watch the tank'})
match(b,'Tank keeper','Send each object to its place in the tank.',{('Balloon','balloon'):'Float',('Stone','stone'):'Sink',('Metal nail','nail'):'Sink',('Cork','cork'):'Float',('Plastic pot','plastic_pot'):'Float',('Glass marble','glass_marble'):'Sink'},3,board='tank')
match(b,'Animal moves','Match each animal to its movement.',{('Snake','snake'):'Slither',('Bird','bird'):'Fly',('Fish','fish'):'Swim',('Kangaroo','kangaroo'):'Hop',('Baby','baby'):'Crawl'},4)
lab(b,'Sailboat breeze','Hold the wind button to move the sailboat.','sailboat',labUi={'action':'Hold to blow'},explanation='Moving air pushes the sailboat.')
single(b,'What moved the boat?','The air moved the sailboat. Was it a push or a pull?',['Pull','Push'],'Push',5,focus='sailboat')
match(b,'Home helper','Choose a force for each job.',{('Open a drawer','drawer'):'Pull',('Ring a doorbell','doorbell'):'Push'},6)
match(b,'My four moves','Make two pushes and two pulls.',{('Press a switch','switch'):'Push',('Kick a ball','ball'):'Push',('Open a fridge','fridge'):'Pull',('Close a zip','zip'):'Pull'},7)
lab(b,'Orange surprise','Predict, then test the orange with and without its peel.','tank',[('With peel','orange'),('Without peel','peeled_orange')],q=8,results={'with_peel':'float','without_peel':'sink'},labUi={'choices':{'float':'Float','sink':'Sink'},'action':'Test the orange','result':'Look at the orange'},explanation='The orange floats with its peel and sinks without it. Tiny air pockets in the peel help it float.')
checks(b,[(('A push sends it','push'),'Away'),(('Sinks in water','coin'),'Metal coin'),(('How a snake moves','snake'),'Slithering'),(('Send the ball further','ball'),'Bigger push'),(('Ring a doorbell','doorbell'),'Push')])
b=book('unit_06')
explore(b,'Band room','Explore the instruments. Listen to the action for each one.',[('Triangle','triangle'),('Maracas','maracas'),('Trumpet','trumpet'),('Sitar','sitar'),('Drum','drum')],senseDescriptions={'triangle':'Hit the triangle.','maracas':'Shake the maracas.','trumpet':'Blow the trumpet.','sitar':'Pluck the sitar.','drum':'Beat the drum.'},band=True)
single(b,'Sound catcher','Which body part catches the sounds?',[('Eyes','eyes'),('Ears','ears'),('Nose','nose')],'Ears',1)
match(b,'Conduct the band','Give each instrument its playing action.',{('Triangle','triangle'):'Hit',('Maracas','maracas'):'Shake',('Trumpet','trumpet'):'Blow',('Sitar','sitar'):'Pluck',('Drum','drum'):'Beat'},2,band=True)
lab(b,'Sound boxes','Predict which box sounds louder, then shake each box.','sound-box',[('Stone box','stone'),('Feather box','feather')],results={'stone_box':'loud','feather_box':'quiet'},labUi={'choices':{'loud':'Loud','quiet':'Quiet'},'action':'Shake the box','result':'Compare the sounds'},explanation='The hard, heavy stone makes a louder sound than the soft, light feather.')
single(b,'Box detective','Which box makes the louder sound?',[('Feather box','feather'),('Stone box','stone')],'Stone box',3)
lab(b,'Sound walk','Move away from the drum. Listen and watch the sound fade.','distance',labUi={'near':'Near the drum','far':'Far away'},explanation='Sound gets quieter and fainter as you move away.')
single(b,'Farther away','As you walk away from the drum, what happens?',['Quieter and fainter','Louder and louder'],'Quieter and fainter',4,focus='drum')
match(b,'Drum explorers','Read the bars. Match the furthest listener and their number of steps.',{'Furthest listener':'Maris','Maris took':'23 steps'},5,table=[{'name':n,'value':v} for n,v in [('Annay',20),('Zara',14),('Maris',23),('David',8)]])
single(b,'Tapping sticks','How can you make the sticks sound louder?',['Tap harder','Tap more gently'],'Tap harder',6,focus='sticks')
add(b,'Quiet to loud','Touch these sounds in order, quietest first.',[('Thunder','thunder'),('Whisper','whisper'),('Door slamming','door'),('Cat walking','cat')],dict(type='sequence',value=['cat_walking','whisper','door_slamming','thunder']),7,kind='order-sequence')
single(b,'Feel a hum','Gently touch your throat and hum. What do you feel?',['Buzzing or shaking','A bright light','Water flowing'],'Buzzing or shaking',8,focus='hum')
checks(b,[(('Play a drum','drum'),'Beating'),(('Walk away from sound','drum'),'Fainter'),(('Louder shaken box','stone'),'Stone'),(('Something making a sound','music'),'Source of sound'),(('Instrument you blow','trumpet'),'Trumpet')])
b=book('unit_07')
safety='Electricity is very useful, but it is dangerous. We never put our fingers, or anything else, into a socket. Only grown-ups plug things in. We never touch electrical things with wet hands.'
# Retain the source's exact Unicode hyphen and line joining.
safety=read('unit_07')['introductionText'].split('"',2)[1].replace('\n',' ')
explore(b,'Safe science workshop','Listen to all three safety rules before exploring.',[('Keep away from sockets','safe'),('Grown-ups plug things in','adult'),('Keep hands dry','dry_hands')],safety=safety,senseDescriptions={'keep_away_from_sockets':'We never put our fingers, or anything else, into a socket.','grown_ups_plug_things_in':'Only grown-ups plug things in.','keep_hands_dry':'We never touch electrical things with wet hands.'})
multi(b,'Power the room','Choose everything that needs electricity.',[('Television','tv'),('Book','paper'),('Vacuum cleaner','vacuum'),('Lantern','lantern'),('Lamp','lamp'),('Chair','chair'),('Dishwasher','dishwasher')],['Television','Vacuum cleaner','Lamp','Dishwasher'],1)
match(b,'Then and now','Find the old tool for each electric helper.',{('Lamp','lamp'):('Lantern','lantern'),('Vacuum cleaner','vacuum'):('Broom','broom')},2)
lab(b,'Magnet hunt','Predict for each material, then move the magnet to test it.','magnet',[('Iron nail','nail'),('Steel key','key'),('Aluminium foil','foil'),('Plastic button','button'),('Gold ring','ring')],results={'iron_nail':'pull','steel_key':'pull','aluminium_foil':'stay','plastic_button':'stay','gold_ring':'stay'},labUi={'choices':{'pull':'Magnet pulls it','stay':'Stays still'},'action':'Move the magnet','result':'Watch carefully'},explanation='A magnet attracts iron and steel, not all metals. It does not attract aluminium, gold or plastic.')
match(b,'Magnet discoveries','Sort each statement.',{'A magnet attracts all metals':'No','A magnet does not attract all metals':'Yes','A magnet attracts iron and steel':'Yes'},3,focus='magnet')
multi(b,'Magnet collection','Collect only the objects the magnet pulls.',[('Steel key','key'),('Plastic button','button'),('Iron nail','nail'),('Sock','sock'),('Steel coat hanger','hanger'),('Leaf','leaf'),('Aluminium foil','foil')],['Steel key','Iron nail','Steel coat hanger'],4,focus='magnet')
single(b,'Inside the torch','What powers this torch without a wall socket?',[('Battery','battery'),('Paper','paper'),('Stone','stone')],'Battery',5,focus='torch')
match(b,'Safety promise','Finish every safety promise.',{'Sockets':'Keep fingers and objects out','Plugging in':'Only grown-ups','Hands near electrical things':'Keep dry'},6,safety=safety)
match(b,'Plug, battery or neither?','Sort the helpers by their power.',{('Fridge','fridge'):'Plug',('Wall clock','clock'):'Battery',('Bicycle','bicycle'):'Neither',('Torch','torch'):'Battery',('Book','paper'):'Neither',('Air conditioner','aircon'):'Plug'},7)
multi(b,'Hidden magnets','Find two places magnets can be used.',[('Fridge door seal','fridge'),('Cupboard door catch','cupboard'),('Paper tissue','tissue'),('Wooden chair','chair')],['Fridge door seal','Cupboard door catch'],8)
checks(b,[(('The magnet pulls','magnet'),'Steel key'),(('Light before electricity','lantern'),'Lantern'),(('Power for a torch','torch'),'Battery'),(('Magnetic metals','key'),'Iron and steel'),(('Finger in a socket','safe'),'Never safe')])
b=book('unit_08')
explore(b,'Water world','Explore the water places and listen.',[('Pond','pond'),('Stream','stream'),('River','river'),('Lake','lake'),('Ocean','ocean')],senseDescriptions={'pond':'Small and still. Frogs live here.','stream':'A small ribbon of moving water.','river':'Big moving water travelling to the sea.','lake':'Big still water with land all around.','ocean':'The biggest water of all, and salty.'})
single(b,'Our blue home','What covers most of Earth?',[('Water','ocean'),('Sand','sand'),('Grass','leaf')],'Water',1,focus='earth')
match(b,'Find the water place','Match each clue to a place.',{'Biggest and saltiest':('Ocean','ocean'),'Small and still, with frogs':('Pond','pond'),'Big moving water':('River','river'),'Big and still, land all around':('Lake','lake')},2)
match(b,'Animal homes','Help each animal reach its water home.',{('Whale','whale'):('Ocean','ocean'),('Crocodile','crocodile'):('River','river'),('Frog','frog'):('Pond','pond')},3,board='water')
multi(b,'Rock collection','Collect everything made from rock.',[('Diamond','diamond'),('Plastic bottle','bottle'),('Coal','coal'),('T-shirt','shirt'),('Chair','chair'),('Stone wall','brick')],['Diamond','Coal','Stone wall'],4)
lab(b,'Soil microscope','Move the magnifier and find the tiny things in soil.','soil',[('Small stones','stone'),('Sand','sand'),('Dead leaf','dead_leaf'),('Worm','worm'),('Tiny insect','insect')],safety='Wash hands afterwards.',explanation='Soil is a mixture of small stones, sand, dead leaves and little living creatures.')
multi(b,'A spoonful of soil','Choose three things you could find in soil.',[('Small stones','stone'),('Dead leaves','dead_leaf'),('Worms','worm'),('Television','tv'),('Trumpet','trumpet')],['Small stones','Dead leaves','Worms'],5,focus='soil')
single(b,'Little geologist','What does a geologist study?',[('Stars','star'),('Rocks','stone'),('Animals','cat')],'Rocks',6)
add(b,'The book’s water family','Put the book’s water family in order, smallest first.',[('Ocean','ocean'),('Pond','pond'),('Lake','lake'),('Stream','stream'),('River','river')],dict(type='sequence',value=['pond','stream','river','lake','ocean']),7,kind='order-sequence')
multi(b,'Rock outside','Find two things made from rock.',[('Stone wall','brick'),('Marble floor','stone'),('Plastic bottle','bottle'),('Cotton shirt','shirt')],['Stone wall','Marble floor'],8)
lab(b,'My rock museum','Sort the rocks into two groups using your own rule. Both choices are welcome.','rock-sort',[('Large smooth stone','stone'),('Small rough stone','stone'),('Dark stone','coal'),('Light stone','stone')],labUi={'groups':['My first group','My second group']})
lab(b,'Clean the beach','Collect the litter so animals do not swallow it.','cleanup',[('Plastic bag','bag'),('Bottle','bottle'),('Paper','paper')],explanation='Litter can harm animals. Keep their homes clean.')
checks(b,[(('Most of Earth','earth'),'Water'),(('Salty water','ocean'),'Ocean'),(('Soil is','soil'),'A mixture'),(('Coal comes from','coal'),'Rock'),(('A geologist studies','stone'),'Rocks')])
b=book('unit_09')
safety=read('unit_09')['introductionText'].split('Safety\n"',1)[1].split('"',1)[0]
explore(b,'Space explorers','Explore our three neighbours. Listen to the Sun safety rule.',[('Earth','earth'),('Sun','sun'),('Moon','moon')],safety=safety,senseDescriptions={'earth':'Earth is a round planet, mostly covered in water.','sun':'The Sun is a star. It gives us heat and light.','moon':'The Moon has no light of its own.'})
lab(b,'Day and night','Turn Earth and watch your place move into day and night.','day-night',safety=safety,labUi={'action':'Turn Earth'},explanation='The side facing the Sun has day. The other side has night.')
match(b,'Earth explorer','Sort the Earth discoveries.',{'Earth is flat':'False','Earth is a planet':'True','Earth is mostly water':'True','Humans can live on Earth':'True','Our heat and light come from the Moon':'False'},1,focus='earth')
single(b,'Star or planet?','What is the Sun?',[('Planet','earth'),('Star','star'),('Moon','moon')],'Star',2,focus='sun')
multi(b,'Gifts from the Sun','Choose the two gifts from the Sun.',['Light','Heat','Sound','Air','Water'],['Light','Heat'],3,focus='sun')
match(b,'First steps on the Moon','Complete the mission record.',{'First person':'Neil Armstrong','Year':'1969'},4,focus='astronaut')
match(b,'Dress the astronaut','Match each part of the suit to its job.',{('Visor','visor'):'Protect eyes',('Oxygen pack','oxygen'):'Breathe',('Gloves','gloves'):'Protect hands',('Boots','boots'):'Protect feet'},5,board='astronaut',focus='astronaut')
single(b,'Sun safety','What is our rule?',['Never look straight at the Sun','Look straight at the Sun'],'Never look straight at the Sun',6,safety=safety)
lab(b,'Paint our planet','Colour the water blue and the land green.','earth-paint',q=7,labUi={'water':'Blue water','land':'Green land'},explanation='Earth is round and mostly blue because of its water.')
multi(b,'Everyday sunshine','Choose two things the Sun does for us.',[('Gives daylight','sun'),('Helps plants grow','leaf'),('Makes music','music'),('Gives the Moon its own light','moon')],['Gives daylight','Helps plants grow'],8)
lab(b,'My star picture','Touch stars to join them into your own shape. Give it a name.','stars',labUi={'name':'Name my star picture','finish':'Save my star picture'})
checks(b,[(('Earth is a','earth'),'Planet'),(('The Sun is a','sun'),'Star'),(('Earth looks mostly','earth'),'Blue'),(('Missing on the Moon','oxygen'),'Air'),(('Studies the stars','star'),'Astronomer')])
# Each quiz remains exactly ten source objectives, never split into extra points.
q=book('quiz_02')
match(q,'Chair detective','Match the object and its material.',{'Object':('Chair','chair'),'Material':'Wood'},'quiz02.01',focus='chair')
multi(q,'Material collection','Choose four materials.',['Wood','Metal','Plastic','Glass',('Chair','chair'),('Spoon','spoon')],['Wood','Metal','Plastic','Glass'],'quiz02.02')
single(q,'See through','Choose a see-through material.',['Wood','Glass','Metal'],'Glass','quiz02.03',focus='window')
single(q,'Rain cover','Which cover keeps water out?',[('Paper','paper'),('Plastic','bottle'),('Cotton cloth','shirt')],'Plastic','quiz02.04',focus='umbrella')
single(q,'Metal clues','Most metals are...',['Soft and fluffy','Hard and shiny'],'Hard and shiny','quiz02.05',focus='spoon')
multi(q,'Shape actions','Choose the four ways to change shape.',['Twist','Stretch','Squash','Bend','Listen','See'],['Twist','Stretch','Squash','Bend'],'quiz02.06')
single(q,'Stretch it','Which one stretches?',[('Rubber band','rubber_band'),('Brick','brick')],'Rubber band','quiz02.07')
single(q,'Potter’s studio','Choose the potter’s material.',['Clay','Glass','Metal'],'Clay','quiz02.08',focus='pot')
single(q,'Glass claim','All glass is red. True or false?',['True','False'],'False','quiz02.09',focus='window')
multi(q,'Kitchen collection','Choose two metal kitchen objects.',[('Metal spoon','spoon'),('Metal pan','pan'),('Cotton towel','shirt'),('Paper tissue','tissue')],['Metal spoon','Metal pan'],'quiz02.10')
q=book('quiz_03')
single(q,'Open the drawer','Which force opens the drawer?',['Push','Pull'],'Pull','quiz03.01',focus='drawer')
single(q,'Ring the bell','Which force rings a doorbell?',['Pull','Push'],'Push','quiz03.02',focus='doorbell')
multi(q,'Floating cargo','Choose everything that floats.',[('Stone','stone'),('Cork','cork'),('Coin','coin'),('Closed plastic bottle','bottle'),('Metal spoon','spoon')],['Cork','Closed plastic bottle'],'quiz03.03',board='tank')
single(q,'Sound maker','What do we call something that makes sound?',['Source of sound','Sink of sound'],'Source of sound','quiz03.04',focus='drum')
single(q,'Sound walk','Farther from the drum, the sound becomes...',['Louder','Fainter and quieter'],'Fainter and quieter','quiz03.05',focus='drum')
single(q,'Play the trumpet','Choose the action.',['Pluck','Blow','Shake'],'Blow','quiz03.06',focus='trumpet')
single(q,'Hear it','Which part hears?',[('Ears','ears'),('Nose','nose'),('Eyes','eyes')],'Ears','quiz03.07')
multi(q,'Magnetic metals','Choose the two metals a magnet attracts.',['Iron','Steel','Aluminium','Gold'],['Iron','Steel'],'quiz03.08',focus='magnet')
single(q,'Magnet claim','A magnet attracts every metal. True or false?',['True','False'],'False','quiz03.09',focus='foil')
single(q,'Battery helper','Choose a helper powered by a battery.',[('Torch','torch'),('Wooden chair','chair'),('Broom','broom')],'Torch','quiz03.10')
q=book('quiz_04')
single(q,'Blue Earth','Most of Earth is covered in...',[('Water','ocean'),('Sand','sand'),('Grass','leaf')],'Water','quiz04.01',focus='earth')
single(q,'Water explorer','Choose the biggest and saltiest.',[('Pond','pond'),('Lake','lake'),('Ocean','ocean')],'Ocean','quiz04.02')
multi(q,'Soil discoveries','Choose two things found in soil.',[('Small stones','stone'),('Dead leaves','dead_leaf'),('Torch','torch'),('Trumpet','trumpet')],['Small stones','Dead leaves'],'quiz04.03',focus='soil')
single(q,'Rock scientist','Who studies rocks?',['Geologist','Astronomer','Optometrist'],'Geologist','quiz04.04',focus='stone')
single(q,'Shape of Earth','Choose the shape of Earth.',[('Plate','plate'),('Ball','ball'),('Box','box')],'Ball','quiz04.05',focus='earth')
single(q,'Our Sun','The Sun is a...',[('Star','star'),('Planet','earth'),('Moon','moon')],'Star','quiz04.06',focus='sun')
multi(q,'Sun gifts','Choose the two gifts.',['Heat','Light','Sound','Water'],['Heat','Light'],'quiz04.07',focus='sun')
single(q,'Moon claim','Our heat and light come from the Moon. True or false?',['True','False'],'False','quiz04.08',focus='moon')
match(q,'Moon mission','Complete the first Moon walk record.',{'Person':'Neil Armstrong','Year':'1969'},'quiz04.09',focus='astronaut')
single(q,'Air for the astronaut','Why carry an oxygen pack?',['There is no air on the Moon','To make music','To keep water out'],'There is no air on the Moon','quiz04.10',focus='astronaut')
for b in books:
 for step in b['steps']:
  if step['title']=='Drum explorers':
   step['targets']=options(['Zara','8 steps','Annay','23 steps','David','14 steps','Maris','20 steps'])
  if step['title'] in ['First steps on the Moon','Moon mission']:
   step['targets']=options(['1968','Neil Armstrong','1970','Geologist','1969','Astronomer'])
 raw=read(b['id']);intro=raw.get('introductionText','')
 if intro:
  words={
   'unit_04':['object','material','property','texture','waterproof','transparent','twist','stretch','squash','bend'],
   'unit_05':['force','push','pull','float','sink','predict'],
   'unit_06':['sound','source of sound','loud','quiet','fainter','ears','hit','shake','blow','pluck'],
   'unit_07':['electricity','appliance','battery','switch','magnet','attract','iron','steel','magnetic'],
   'unit_08':['ocean','lake','river','stream','pond','rock','soil','geologist','litter'],
   'unit_09':['Earth','planet','Sun','star','Moon','heat','light','astronaut','astronomy'],
  }[b['id']]
  # Use exact entries only; never manufacture dictionary definitions.
  dictionary=read('word_list')['sourceText'].splitlines()
  for word in dict.fromkeys(words):
   line=next((x for x in dictionary if x.startswith(word+' ')),None)
   b['stickers'].append(dict(id=slug(word),word=word,meaning=line[len(word)+1:] if line else '',meaningSource='word_list' if line else 'not_defined_in_book',pages=[33,34]))
  if 'Try It at Home\n' in intro:
   home=intro.split('Try It at Home\n')[1].split('More examples')[0]
   b['homeActivities']=[dict(text=home,safety=read('parent_guide')['sourceText'].split('Safety, every time\n')[1],pages=b['sourcePages'],safetyPages=[2])]
 (SRC/'playable'/f"{b['id']}.json").write_text(json.dumps(b,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
 print(b['id'],len(b['steps']))

