"""Original quiet illustrative instrument tones; no recordings or third-party audio."""
import math,random,struct,wave
from pathlib import Path
random.seed(9)
for name,freq in [('triangle',1200),('maracas',0),('trumpet',440),('sitar',220),('drum',110),('stone',0),('feather',0)]:
 out=[];rate=22050
 for i in range(rate):
  t=i/rate;fade=min(1,t/.035)*min(1,(1-t)/.09)
  if name in ['maracas','stone','feather']:
   pulse=max(0,math.sin(t*math.pi*14))**8
   y=(random.random()*2-1)*pulse*(.08 if name=='feather' else .45)
  elif name=='drum':y=math.sin(2*math.pi*(freq*t-20*t*t))*math.exp(-6*t)
  elif name=='triangle':y=(math.sin(2*math.pi*freq*t)+.3*math.sin(2*math.pi*freq*2.7*t))*math.exp(-3*t)
  else:y=sum(math.sin(2*math.pi*freq*n*t)/n**1.6 for n in range(1,6))*math.exp(-t*(4 if name=='sitar' else 1))
  out.append(struct.pack('<h',round(max(-1,min(1,y))*.25*fade*32767)))
 with wave.open(str(Path('assets/audio')/(name+'.wav')),'wb') as w:
  w.setparams((1,2,rate,0,'NONE','not compressed'));w.writeframes(b''.join(out))
