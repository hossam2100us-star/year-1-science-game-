"""Add a source-cited, scene-based first garden; does not replace full-unit scores."""
def add_garden(book):
 items=[
 ("cat","Cat","القطة",True,"Does a cat eat and grow?","The cat is alive. It eats, breathes and grows.","u01.main.07"),
 ("tree","Tree","الشجرة",True,"Does a tree drink water and grow taller?","The tree is alive. It drinks water, grows taller and makes seeds.","u01.main.01"),
 ("car","Car","العربية",False,"A car moves. But does it grow or need food?","A car moves, but it does not grow, eat or make babies. It is not alive.","u01.main.05"),
 ("plant","Plant","النبات",True,"Think about the plant getting taller and drinking water.","The plant is alive. It grows and drinks water.","u01.choice.05"),
 ("chair","Wooden chair","الكرسي الخشب",False,"Is the chair itself growing?","A wooden chair was once part of a living tree, but the chair itself is not alive.","u01.main.01"),
 ("bird","Bird","العصفور",True,"Does the bird eat, breathe and grow?","The bird is alive. It eats, breathes and grows.","u01.main.02"),
 ("cloud","Cloud","السحابة",False,"The cloud moves. Is moving enough?","A cloud moves but is not alive.","u01.main.08")]
 book["garden"]={
 "version":1,"sourcePages":[4,5],"sourceSha256":book["sourceSha256"],
 "ui":{"title":"Garden explorers","hunt":"Find another thing.","huntAr":"المس حاجة في الجنينة",
 "question":"Is the {name} alive?","questionAr":"حية ولا مش حية؟",
 "alive":"Alive","aliveAr":"حية","notAlive":"Not alive","notAliveAr":"مش حية",
 "retry":"Hmm, let's look again!","praise":"You looked carefully!","next":"Find another","nextAr":"دور على حاجة تانية",
 "finished":"You explored the whole garden!","finishedAr":"اكتشفت كل اللي في الجنينة!",
 "replay":"Play again","replayAr":"العب تاني","back":"My island","backAr":"ارجع للجزيرة",
 "count":"Found","drag":"Tap a basket, or drag the picture into it.","dragAr":"اختار سلة، أو اسحب الصورة ليها",
 "voiceUnavailable":"Voice is unavailable here. Follow the hand to explore.",
 "tutorial":"Tap the cat.","tutorialAr":"ابدأ بلمس القطة",
 "saved":"Your discoveries are saved.","saveError":"Could not save yet. Tap to try again.",
 "sourceLabel":"Alive or Not Alive?","goodName":"Great exploring, {name}!"},
 "items":[{"id":i,"name":n,"nameAr":a,"alive":v,"hint":h,"explanation":e,"objective":q,
 "sourcePages":[4,5],"answerKeyPages":[35]} for i,n,a,v,h,e,q in items]}

 from alive_scene_content import add_alive_scenes
 add_alive_scenes(book)
