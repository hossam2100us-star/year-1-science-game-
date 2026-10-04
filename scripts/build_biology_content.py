"""Build reviewed, source-cited Biology gameplay from the supplied curriculum."""
from pathlib import Path
import json, re
ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/"assets/content"
OUT=SOURCE/"playable"
OUT.mkdir(parents=True,exist_ok=True)
def read(name): return json.loads((SOURCE/f"{name}.json").read_text(encoding="utf-8-sig"))
SOURCE_HASH=read("manifest")["sourceSha256"]
all_books={k:read(k) for k in ["unit_01","unit_02","unit_03","quiz_01"]}
def slug(s): return re.sub(r"[^a-z0-9]+","_",s.lower()).strip("_")
def option(label, art=None): return {"id":slug(label),"label":label,"art":art or slug(label)}
def opts(values): return [option(*v) if isinstance(v,tuple) else option(v) for v in values]
def new_book(id):
 b=all_books[id]
 return {"schemaVersion":1,"contentVersion":1,"id":id,"title":b.get("title","Biology Big Challenge"),
 "sourceSha256":SOURCE_HASH,"sourcePages":b.get("sourcePages",[11]),"quiz":id.startswith("quiz"),
 "steps":[],"stickers":[],"homeActivities":[]}
def source(book,qid=None):
 b=all_books[book["id"]]
 q=next((q for q in b["sourceQuestions"] if q["id"]==qid),None)
 return {"pages":q["sourcePages"] if q else b.get("sourcePages",[11]),
 "questionId":qid,"answerKeyPages":q["answerKeyPages"] if q else [],
 "answerKeyText":q["answerKeyText"] if q else "", "sourceSha256":SOURCE_HASH}
def add(b,kind,title,prompt,values=(),answer=None,qid=None,assessed=False,
 hint="",explanation="",scene="garden",targets=(),section="Explore",**extra):
 s={"id":b["id"]+".step."+str(len(b["steps"])+1).zfill(3),"kind":kind,"title":title,
 "prompt":prompt,"options":opts(values),"targets":opts(targets),"answer":answer,
 "assessed":assessed,"objective":qid or "", "hint":hint,"explanation":explanation,
 "scene":scene,"section":section,"source":source(b,qid),**extra}
 b["steps"].append(s);return s
def choice(b,title,prompt,values,correct,qid=None,assessed=False,**kw):
 return add(b,"tap-choice",title,prompt,values,{"type":"single","value":slug(correct)},qid,assessed,**kw)
def multi(b,title,prompt,values,correct,qid=None,assessed=False,**kw):
 return add(b,"tap-choice",title,prompt,values,{"type":"set","value":[slug(v) for v in correct]},qid,assessed,**kw)
def sort_one(b,title,item,target,targets,qid=None,assessed=False,**kw):
 return add(b,"drag-to-basket",title,f"Move the {item.lower()} to its place. You can drag, or tap it and tap a place.",
 [item],{"type":"mapping","value":{slug(item):slug(target)}},qid,assessed,targets=targets,**kw)
def match(b,title,prompt,left,right,qid=None,assessed=False,**kw):
 return add(b,"match-lines",title,prompt,left,{"type":"mapping","value":{slug(a):slug(c) for a,c in zip(left,right)}},
 qid,assessed,targets=right[::-1],**kw)
def order(b,title,prompt,values,correct,qid=None,assessed=False,**kw):
 return add(b,"order-sequence",title,prompt,values,{"type":"sequence","value":[slug(v) for v in correct]},
 qid,assessed,**kw)
def story(b,scene):
 raw=all_books[b["id"]]["introductionText"]
 if b["id"]=="unit_02":
  text=raw.split("Say It Like This — give every part a job\n")[1].split("\nWatch Out For")[0]
  chunks=re.split(r"(?=(?:Roots|Stem|Leaf|Flower) —)", " ".join(text.split()))
 else:
  text=raw.split("Read aloud\n",1)[1].split("\nWatch Out For" if b["id"]=="unit_01" else "\nThe words to practise")[0]
  text=" ".join(text.replace('"',"").split())
  sentences=re.split(r"(?<=[.!?]) ",text);chunks=[];chunk=""
  for sentence in sentences:
   if len((chunk+" "+sentence).split())>35 and chunk: chunks.append(chunk);chunk=""
   chunk=(chunk+" "+sentence).strip()
  if chunk:chunks.append(chunk)
 for chunk in chunks:
  if len(chunk.strip())>3:
   add(b,"story","The Big Idea",chunk.strip(),["Car","Tree"] if scene=="garden" else ["Plant"] if scene=="plant" else ["Eyes","Ears","Nose","Tongue","Skin"],scene=scene,section="Big Idea")
living_hint="Does it grow? Does it need food? Can it make babies?"
living_explain="Living things grow, feed, breathe and make babies. Moving is not enough."
b1=new_book("unit_01")
add(b1,"explore","The house garden","Look around! Tap at least three different things to hear their names.",
 ["Tree","Cat","Car","Chair","Plant","Mug","Cloud","Bird"],minTouches=3)
story(b1,"garden")
alive=["giraffe","tree","human","plant","lizard","cat","worm","fly","mint plant"]
dead=["car","chair","mug","doll","cloud","wooden chair","bread"]
for item in ["giraffe","car","tree","chair","human","mug","plant","lizard","cat","worm","doll","fly","cloud","wooden chair","egg with a growing chick"]:
 target="Alive" if item in alive or item.startswith("egg") else "Not alive"
 explain=("This egg has a baby chick growing inside." if item.startswith("egg") else
  "A wooden chair was once part of a living tree, but the chair itself is not alive." if item=="wooden chair" else
  "A cloud moves but is not alive." if item=="cloud" else living_explain)
 sort_one(b1,"Alive Sorter",item,target,["Alive","Not alive"],hint=living_hint,explanation=explain)
for item,answer in [("Cat","Yes"),("Plant","Yes"),("Kettle","No")]:
 for question in ["Does it grow?","Does it need food?","Can it make babies?"]:
  choice(b1,"The Three Questions",f"Look at the {item.lower()}. {question}",["Yes","No"],answer,
   hint=living_hint,explanation=("A kettle does not grow, does not need food, and cannot make new kettles." if item=="Kettle" else living_explain),focus=item)
# All source question objectives are covered through scene missions.
kw=dict(assessed=True,section="Challenge",hint=living_hint,explanation=living_explain)
multi(b1,"Garden rescue","Find all the living things in this place.",["Giraffe","Car","Tree","Chair","Human","Mug","Plant","Lizard"],
 ["Giraffe","Tree","Human","Plant","Lizard"],"u01.main.01",**kw)
match(b1,"Care for the bird","Match each moment with what the bird does.",["Around the cage","When hungry","Air through its beak","Baby becomes bigger"],
 ["Moves","Eats","Breathes","Grown"],"u01.main.02",**kw)
choice(b1,"Kitchen detective","Look at the kettle. Choose its basket.",["Alive","Not alive"],"Not alive","u01.main.03",focus="Kettle",**kw)
multi(b1,"Dandelion detective","Find two signs of life for the dandelion.",["Grows","Makes seeds","Made in a factory"],
 ["Grows","Makes seeds"],"u01.main.04",focus="Plant",**kw)
choice(b1,"Moving things","The car is moving. Is moving enough to mean something is alive?",["Yes","No"],"No","u01.main.05",focus="Car",**kw)
add(b1,"free-pair","My room collection","Choose one living thing and one non-living thing for your own little scene.",
 ["Person","Plant","Cat","Chair","Toy","Book"],qid="u01.main.06",allowedGroups=[["person","plant","cat"],["chair","toy","book"]],section="Challenge",explanation="You made your own collection!")
multi(b1,"Watch the cat","Find two things the cat does that show it is alive.",["Eats and drinks","Breathes","Made in a factory"],
 ["Eats and drinks","Breathes"],"u01.main.07",focus="Cat",**kw)
for item in ["Cloud","Worm","Bread","Mint plant","Doll","Fly"]:
 sort_one(b1,"Garden and kitchen",item,"Alive" if item.lower() in alive else "Not alive",["Alive","Not alive"],"u01.main.08",**kw)
choice(b1,"Garden search","Tap the living thing.",["Car","Tree","Chair"],"Tree","u01.choice.01",**kw)
choice(b1,"Care basket","Bring what living things need with food.",["Water","Toys","Paper"],"Water","u01.choice.02",**kw)
choice(b1,"Factory visitor","Which picture is not a sign of being alive?",["Growing","Eating","Made in a factory"],"Made in a factory","u01.choice.03",**kw)
choice(b1,"Baby bird","Choose what happens to a baby bird over time.",["Stays the same size","Grows bigger","Gets smaller"],"Grows bigger","u01.choice.04",focus="Bird",**kw)
choice(b1,"Balcony plant","Choose a basket for the plant.",["Alive","Not alive"],"Alive","u01.choice.05",focus="Plant",**kw)

b2=new_book("unit_02")
add(b2,"explore","The little greenhouse","Touch the plant parts. Listen to their names.",["Roots","Stem","Leaf","Flower"],scene="plant",minTouches=4)
story(b2,"plant")
parts=["Roots","Stem","Leaf","Flower"]
jobs={"Roots":"They drink water from the soil and hold the plant down so the wind cannot blow it away.",
 "Stem":"It holds the plant up and carries the water all the way to the leaves.",
 "Leaf":"Leaves catch the sunlight and use it to make the plant's food.",
 "Flower":"The flower makes the seeds that grow into new plants."}
for part in parts:
 add(b2,"label-diagram","Build a Plant",f"Put the {part.lower()} on the plant.",[part],
 {"type":"mapping","value":{slug(part):slug(part)}},targets=parts,scene="plant",diagram="plant",
 hint="Look at the shape and position of each part.",explanation=jobs[part])
bean_frames=[{"label":"Day 1","art":"bean_1","caption":"Nothing yet."},
 {"label":"Day 4","art":"bean_4","caption":"A small white root pushes downwards."},
 {"label":"Day 7","art":"bean_7","caption":"A shoot pushes upwards."},
 {"label":"Day 8","art":"bean_8","caption":"The first tiny green leaves open."}]
add(b2,"predict-then-reveal","Grow a Bean","What do you think will come out first?",["Root","Leaf"],
 {"type":"single","value":"root"},scene="plant",frames=bean_frames,action="Water and watch",experiment="bean",
 explanation="The root comes first. Then a shoot grows upwards, and the first green leaves open.",hint="")
light_frames=[{"label":"Day 1","art":"light_start","caption":"Two young beans. Water both exactly the same."},
 {"label":"Day 9","art":"light_result","caption":"The plant in the light is green, short and strong. The plant in the dark is pale yellow, long, thin and floppy."}]
add(b2,"predict-then-reveal","Light Test","Both plants get the same water. What do you think the plant in the dark cupboard will look like?",
 ["Green and strong","Pale and floppy"],{"type":"single","value":"pale_and_floppy"},scene="plant",
 sceneLabels=["Sunny window","Dark cupboard"],frames=light_frames,action="Water both and watch",experiment="light",
 explanation="Plants need light. The roots drink the water. The leaves make the food from sunlight.")
foods={"Carrot":"Root","Radish":"Root","Celery":"Stem","Sugar cane":"Stem","Lettuce":"Leaf","Mint":"Leaf","Parsley":"Leaf",
 "Cauliflower":"Flower","Broccoli":"Flower","Beans":"Seed","Rice":"Seed","Lentils":"Seed","Peas":"Seed"}
for food,part in foods.items():
 sort_one(b2,"Fridge Sort",food,part,["Root","Stem","Leaf","Flower","Seed"],scene="kitchen",
  hint="Think about the plant part we eat.",explanation=f"We eat the {part.lower()} of {food.lower()}.")
kw=dict(assessed=True,section="Challenge",scene="plant",hint="Think about the plant parts and the greenhouse experiments.")
match(b2,"Plant helpers","Give each job to the right plant part.",["Drinks water","Holds the plant up","Catches sunlight","Makes seeds"],parts,
 "u02.main.01",explanation="Roots drink water. The stem holds the plant up. Leaves catch sunlight. The flower makes seeds.",**kw)
choice(b2,"Bean detective","Choose the part that came out first.",["Root","Leaf"],"Root","u02.main.02",
 explanation="The root comes first — the seed needs a drink before it can grow upwards.",**kw)
multi(b2,"Healthy plant","Bring two things to keep the plant healthy.",["Water","Light","Toys","Paper"],["Water","Light"],
 "u02.main.03",explanation="A plant needs water and light to stay healthy.",**kw)
multi(b2,"Cupboard detective","Choose the three clues for the plant after nine days in the dark.",
 ["Green","Pale yellow","Thick stem","Thin floppy stem","Healthy","Not healthy"],["Pale yellow","Thin floppy stem","Not healthy"],
 "u02.main.04",explanation="The dark-cupboard plant is pale yellow, with a thin floppy stem, and is not healthy.",**kw)
for prompt,correct in [("Seeds need water to start growing.","True"),("A plant is not a living thing.","False"),("Leaves make food for the plant.","True")]:
 s=choice(b2,"Plant signals",prompt,["True","False"],correct,"u02.main.05",
  explanation="Seeds need water. A plant is a living thing. Leaves make the plant's food.",**kw);s["kind"]="true-false"
add(b2,"free-plant","My own plant","Build your own plant picture. Touch each part to add it.",parts,
 qid="u02.main.06",scene="plant",section="Challenge",minTouches=4,explanation="You made a plant with roots, stem, leaf and flower.")
choice(b2,"Remember to water","Choose what happens after two weeks without water.",["Green and strong","Dry and drooping"],"Dry and drooping",
 "u02.main.07",explanation="It would dry out: the leaves would droop and go brown, and in the end the plant would die.",**kw)
for food,part in [("Carrot","Root"),("Lettuce","Leaf")]:
 sort_one(b2,"Our vegetable basket",food,part,["Root","Leaf"],"u02.main.08",
 explanation="We eat the root of a carrot and the leaves of lettuce.",**kw)
for n,prompt,values,correct,explain in [
 (1,"Find the part that holds the plant up.",["Root","Stem","Flower"],"Stem",jobs["Stem"]),
 (2,"Bring what leaves use to make food.",["Sunlight","Soil","Wind"],"Sunlight","Leaves make the plant's food using sunlight."),
 (3,"Find where the seeds are made.",["Leaf","Flower","Root"],"Flower",jobs["Flower"]),
 (4,"Choose the plant part we eat in a carrot.",["Root","Stem","Flower"],"Root","We eat the root of a carrot."),
 (5,"Choose the plant from the dark cupboard.",["Green and strong","Pale and floppy"],"Pale and floppy","A plant kept with no light looks pale and floppy.")]:
 choice(b2,"Greenhouse mission",prompt,values,correct,f"u02.choice.{n:02}",explanation=explain,**kw)

b3=new_book("unit_03")
add(b3,"explore","Meet the explorer","Touch the explorer's body parts and listen.",["Head","Hand","Foot","Eyes","Ears"],scene="body",minTouches=3)
story(b3,"body")
bodygroups=[["Head","Neck","Chin"],["Shoulder","Arm","Elbow"],["Wrist","Hand","Fingers"],["Leg","Knee","Ankle","Foot"],["Eyebrow","Eyelash","Eyelid"]]
eye_jobs={"Eyebrow":"The eyebrow keeps sweat out.","Eyelash":"The eyelash keeps dust out.","Eyelid":"The eyelid is the door that blinks."}
for group in bodygroups:
 for part in group:
  add(b3,"label-diagram","Label Me",f"Put the {part.lower()} label in the right place.",[part],
   {"type":"mapping","value":{slug(part):slug(part)}},targets=group,scene="eye" if group==bodygroups[-1] else "body",
   diagram="eye" if group==bodygroups[-1] else "body",hint="Look at where the line points.",
   explanation=eye_jobs.get(part,f"This is the {part.lower()}."))
senses=["Sight","Hearing","Smell","Taste","Touch"];organs=["Eyes","Ears","Nose","Tongue","Skin"]
for sense,organ in zip(senses,organs):
 sort_one(b3,"Five Senses Match",sense,organ,organs,scene="body",hint="Which part helps you find out?",
  explanation=f"{sense}: {organ.lower()}.")
situations=[("The bread is burning.","Smell","Bread"),("The lemon is sour.","Taste","Lemon"),
 ("The traffic outside.","Hearing","Car"),("The tea is too hot.","Touch","Mug"),("The traffic light turned green.","Sight","Traffic light")]
for text,sense,art in situations:
 choice(b3,"Which sense is telling you?",text,senses,sense,scene="body",focus=art,
  hint="Think about how you found that out.",explanation=f"The sense is {sense.lower()}.")
multi(b3,"Watermelon discovery","Find the four senses for a slice of watermelon.",senses,["Sight","Smell","Touch","Taste"],
 scene="body",focus="Watermelon",hint="The book names four senses together.",explanation="Sight, smell, touch and taste all together!")
table=[{"name":"David","value":6},{"name":"Zara","value":9},{"name":"Jack","value":5}]
for prompt,correct in [("Whose handful has the most marbles?","Zara"),("Whose handful has the fewest marbles?","Jack")]:
 choice(b3,"Biggest Hand",prompt,["David","Zara","Jack"],correct,scene="table",table=table,
 hint="Look at the number of marbles.",explanation="Zara has 9, the most. Jack has 5, the fewest. David has 6.")
kw=dict(assessed=True,section="Challenge",scene="body",hint="Think about the five senses and the explorer's body.")
match(b3,"Explorer's senses","Connect every sense to its body part.",senses,organs,"u03.main.01",
 explanation="Sight: eyes. Hearing: ears. Smell: nose. Taste: tongue. Touch: skin.",**kw)
for prompt,values,correct in [
 ("Choose how many senses we have.",["Three","Five","Ten"],"Five"),
 ("Find what is on the tongue.",["Taste buds","Eyelashes","Fingers"],"Taste buds"),
 ("Find the part you hold to make the apple harder to taste.",["Nose","Hand","Ear"],"Nose"),
 ("Choose the taste that goes with sour and salty.",["Sweet","Loud","Bright"],"Sweet")]:
 choice(b3,"Sense detective",prompt,values,correct,"u03.main.02",
  explanation="There are five senses. Taste buds are on the tongue. Smell and taste work together. We taste sweet, sour and salty foods.",**kw)
multi(b3,"Eye protectors","Find all three parts around the eye.",["Eyebrow","Eyelash","Eyelid","Wrist"],["Eyebrow","Eyelash","Eyelid"],
 "u03.main.03",explanation="The three parts are eyebrow, eyelash and eyelid.",**kw)
for prompt,correct in [("Find the biggest handful.","Zara"),("Find the smallest handful.","Jack")]:
 choice(b3,"Marble challenge",prompt,["David","Zara","Jack"],correct,"u03.main.04",table=table,
 explanation="Zara has the biggest handful: 9. Jack has the smallest: 5.",**kw)
choice(b3,"Visit the optometrist","Help the optometrist find the body part to look after.",["Teeth","Hair","Eyes"],"Eyes",
 "u03.main.05",explanation="An optometrist looks after your eyes.",**kw)
match(b3,"My sense stories","Match each scene to a sense.",["See birds","Hear music","Soft cat","Sweet honey","Smell flowers"],
 senses[:2]+["Touch","Taste","Smell"],"u03.main.06",
 explanation="We see with eyes, hear with ears, touch with skin, taste with the tongue and smell with the nose.",**kw)
multi(b3,"Apple discovery","Choose the two senses that work together when eating an apple.",senses,["Taste","Smell"],
 "u03.main.07",focus="Apple",explanation="Taste and smell work together. If you hold your nose you can hardly taste the apple at all.",**kw)
add(b3,"free-measure","Our shoe sizes","Choose two shoe-size numbers, then compare them.",qid="u03.main.08",
 scene="table",section="Challenge",explanation="Compare the two numbers. The bigger number is the bigger shoe size.")
for n,prompt,values,correct,explanation in [
 (1,"Find the part that helps you hear.",["Eyes","Ears","Nose"],"Ears","You hear with your ears."),
 (2,"Put taste buds on the right body part.",["Tongue","Skin","Ear"],"Tongue","Taste buds are on your tongue."),
 (3,"Count the senses.",["Three","Five","Ten"],"Five","We have five senses."),
 (4,"What do eyelashes help keep out?",["Dust","Sound","Food"],"Dust","Eyelashes keep dust out."),
 (5,"Find the part between your wrist and shoulder.",["Knee","Elbow","Ankle"],"Elbow","The elbow is between your wrist and shoulder.")]:
 choice(b3,"Explorer mission",prompt,values,correct,f"u03.choice.{n:02}",explanation=explanation,**kw)

quiz=new_book("quiz_01")
kw=dict(assessed=True,section="Big Challenge",hint="Think back to the Biology Island games.")
multi(quiz,"Garden team","Find every living thing in this place.",["Table","Cat","Tree","Spoon","Baby","Rock"],
 ["Cat","Tree","Baby"],"quiz01.01",explanation="The cat, tree and baby are living things.",**kw)
multi(quiz,"Signs of life","Find two things all living things do.",["Grow","Breathe","Made in a factory"],
 ["Grow","Breathe"],"quiz01.02",explanation="Living things grow and breathe.",**kw)
choice(quiz,"Water delivery","Give the water to the plant part that drinks from the soil.",parts,"Roots","quiz01.03",
 scene="plant",explanation="The roots drink water from the soil.",**kw)
multi(quiz,"Healthy greenhouse","Bring the two things the plant needs.",["Water","Light","Toys","Paper"],["Water","Light"],
 "quiz01.04",scene="plant",explanation="A plant needs water and light to stay healthy.",**kw)
choice(quiz,"Dark cupboard","Choose the colour of the leaves after the dark cupboard.",["Green","Pale yellow"],"Pale yellow",
 "quiz01.05",scene="plant",explanation="The leaves are pale yellow.",**kw)
multi(quiz,"Sense collection","Collect the five senses.",senses+["Growing"],senses,"quiz01.06",
 scene="body",explanation="The five senses are sight, hearing, smell, taste and touch.",**kw)
choice(quiz,"Tasting helper","Find the part we use to taste.",["Tongue","Nose","Ears"],"Tongue","quiz01.07",
 scene="body",explanation="We taste with the tongue.",**kw)
s=choice(quiz,"Moving car","A car is alive because it moves.",["True","False"],"False","quiz01.08",
 focus="Car",explanation="Moving is not enough; a car does not grow, eat or make babies.",**kw);s["kind"]="true-false"
order(quiz,"Arm trail","Build a path from the shoulder down to the fingers.",["Hand","Elbow","Shoulder","Fingers","Arm","Wrist"],
 ["Shoulder","Arm","Elbow","Wrist","Hand","Fingers"],"quiz01.09",scene="body",
 explanation="Shoulder, arm, elbow, wrist, hand, fingers.",**kw)
choice(quiz,"Eye doctor","Choose the optometrist's job.",["Checks eyes and gives glasses","Looks after teeth","Cuts hair"],
 "Checks eyes and gives glasses","quiz01.10",scene="body",
 explanation="An optometrist checks that eyes see clearly and gives people glasses.",**kw)
quiz["bands"]=all_books["quiz_01"]["scoreBands"]
# Word meanings are exact Word List entries; missing entries remain explicitly marked.
word_text=read("word_list")["sourceText"]
aliases={"roots":"root"}
excerpts={"food":("The roots drink the water. The leaves make the food from sunlight.",6),
 "sight":("You see with your eyes.",8),"hearing":("You hear with your ears.",8),
 "smell":("You smell with your nose.",8),"taste":("You taste with your tongue.",8),
 "touch":("And you touch with your skin.",8)}
keywords={b1["id"]:["alive","not alive","living thing","grow","breathe","food"],
 b2["id"]:["roots","stem","leaf","flower","petal","seed","grow","healthy"],
 b3["id"]:["senses","sight","hearing","smell","taste","touch","taste buds","optometrist","measure"]}
for b in [b1,b2,b3]:
 for word in keywords[b["id"]]:
  key=aliases.get(word,word);line=next((line for line in word_text.splitlines() if line.startswith(key+" ")),None)
  meaning=line[len(key)+1:] if line else excerpts.get(word,("",0))[0]
  b["stickers"].append({"id":slug(word),"word":word,"meaning":meaning,
   "meaningSource":"word_list" if line else "unit_excerpt" if meaning else "not_defined_in_book",
   "pages":[33,34] if line else [excerpts[word][1]] if meaning else b["sourcePages"]})
 intro=all_books[b["id"]]["introductionText"]
 home=intro.split("Try It at Home\n")[1].split("\nMore examples")[0]
 # Keep the exact home activity paragraphs, excluding diagram labels.
 if b["id"]=="unit_01":home=home.split("\nALIVE NOT ALIVE")[0]
 if b["id"]=="unit_02":home=home.split("\nDay 1 Day 4")[0]
 if b["id"]=="unit_03":home=home.split("\nhead\near")[0]
 safety=read("parent_guide")["sourceText"].split("Safety, every time\n")[1]
 b["homeActivities"]=[{"text":home,"safety":safety,"pages":b["sourcePages"],"safetyPages":[2]}]
for step in b2["steps"]:
 if step.get("experiment")=="bean":
  step["playUi"]={"predictAr":"تفتكر إيه هيطلع الأول؟ اختار وبعدين اسقي.",
   "predicted":"You predicted","water":"Water and watch","watch":"Watch it grow...",
   "continue":"Keep exploring","saveError":"الحفظ ماكملش. جرّب تاني."}
from garden_content import add_garden
add_garden(b1)
from refresh_ourselves import refresh_ourselves, refresh_quiz
refresh_ourselves(b3)
refresh_quiz(quiz)
from child_feedback import apply_child_feedback
for b in [b1,b2,b3,quiz]:
 apply_child_feedback(b)
 from refine_latest_teacher_review import refine_latest_teacher_review
 # Unit 02 here is the legacy seed; its final compaction applies the review.
 if b['id'] != 'unit_02' or b['contentVersion'] >= 4:
  refine_latest_teacher_review(b)
 (OUT/f'{b["id"]}.json').write_text(json.dumps(b,ensure_ascii=False,indent=2),encoding="utf-8")
 print(b["id"],len(b["steps"]),"steps")
