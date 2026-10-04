import math,wave,struct
from pathlib import Path
out=Path(__file__).resolve().parents[1]/'assets/audio'
rate=22050

def save(name,buf):
 peak=max(abs(x) for x in buf) or 1
 with wave.open(str(out/(name+'.wav')),'wb') as w:
  w.setnchannels(1);w.setsampwidth(2);w.setframerate(rate)
  w.writeframes(b''.join(struct.pack('<h',int(max(-1,min(1,x/peak*.65))*32767)) for x in buf))

def music(name,notes,beat,style):
 length=len(notes)*beat; buf=[0.0]*int(length*rate)
 for j,note in enumerate(notes):
  freq=440*2**((note-69)/12)
  for i in range(int(beat*.88*rate)):
   t=i/rate; k=int(j*beat*rate)+i
   env=(1-math.exp(-t*90))*math.exp(-t*(7 if style=='calm' else 4))
   tone=math.sin(2*math.pi*freq*t)
   if style=='comic': tone+=.35*math.sin(4*math.pi*freq*t)+.2*math.sin(6*math.pi*freq*t)
   elif style=='heroic': tone+=.3*math.sin(4*math.pi*freq*t)+.12*math.sin(8*math.pi*freq*t)
   buf[k]+=tone*env*.32
  # Plucked bass, low drum, and tiny high percussion follow the same tempo.
  bass=440*2**(((notes[(j//4)*4]-24)-69)/12)
  for i in range(int(beat*rate)):
   t=i/rate;k=int(j*beat*rate)+i
   buf[k]+=.10*math.sin(2*math.pi*bass*t)*math.exp(-t*5)
   if style=='heroic' and j%2==0:
    buf[k]+=.20*math.sin(2*math.pi*(60*t+18*(1-math.exp(-t*20))))*math.exp(-t*24)
   if style=='comic' and j%2:
    buf[k]+=.03*math.sin(2*math.pi*3500*t)*math.exp(-t*60)
 save(name,buf)
base=[62,69,74,76,74,69,67,69,62,67,69,74,76,74,69,67,64,69,74,76,79,76,74,69,67,64,62,64,67,69,64,62]
music('heroic',base,.375,'heroic')
music('comic',[74,62,76,64,79,67,76,64,74,62,69,81,67,79,64,76]*2,.25,'comic')
music('calm',[62,64,67,69,74,69,67,64,62,67,69,74,76,74,69,67],.75,'calm')
for name,freq,dur in [('hit',130,.15),('click',650,.09),('coin',1100,.25),('alarm',420,.6)]:
 buf=[]
 for i in range(int(rate*dur)):
  t=i/rate;buf.append(math.sin(2*math.pi*(freq*t+freq*.4*t*t))*math.exp(-t*12))
 save(name,buf)
