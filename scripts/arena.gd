class_name JianghuArena
extends Control

var sprite_sheet: Texture2D
var sprites: Array[AtlasTexture] = []
var model: TournamentModel
var font: Font
var clock: float = 0.0
var effects: Array = []
var pulse: float = 0.0
var music_gag: float = 0.0
var gag_side: int = 0
const PAPER := Color("ecdfc2")
const INK := Color("222b2d")
const GOLD := Color("c9a365")

func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 clip_contents = true
 var face := FontVariation.new()
 face.base_font = load("res://assets/fonts/NotoSansTC.ttf")
 face.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"):600}
 font = face
 sprite_sheet = load("res://assets/art/battle-sprites-v2.png")
 # Four isolated quadrants; retain the transparent padding around weapons.
 var w: float=sprite_sheet.get_width()
 var h: float=sprite_sheet.get_height()
 var regions: Array[Rect2] = [Rect2(0,0,w*.52,h*.5),Rect2(w*.52,0,w*.48,h*.5),Rect2(0,h*.5,w*.5,h*.5),Rect2(w*.5,h*.5,w*.5,h*.5)]
 for id in range(4):
  var atlas := AtlasTexture.new()
  atlas.atlas=sprite_sheet
  atlas.region=regions[id]
  sprites.append(atlas)

func _process(delta: float) -> void:
 clock += delta
 pulse = maxf(0,pulse-delta)
 music_gag = maxf(0,music_gag-delta)
 for e in effects: e.life -= delta
 effects = effects.filter(func(e: Dictionary) -> bool: return float(e.life)>0.0)
 queue_redraw()

func react(kind: String, side: int, amount: int) -> void:
 if kind == "hit":
  pulse = 0.12
  effects.append({"side":side,"amount":amount,"life":1.1})
 elif kind == "music":
  music_gag = 3.0
  gag_side = side

func _draw() -> void:
 if model == null: return
 var w: float = size.x
 var h: float = size.y
 var ground: float = h*0.85
 var arena: int = model.arena_index
 var bg: Color = [Color("dbc9a2"),Color("bda781"),Color("c5c6b1")][arena]
 draw_rect(Rect2(Vector2.ZERO,size),bg)
 # Layered, angular ink mountains with paper-like negative space.
 for layer in range(3):
  var pts := PackedVector2Array([Vector2(0,ground)])
  for n in range(14):
   var x: float = float(n)/13.0*w
   var y: float = ground-65.0-layer*35.0-absf(sin(n*1.7+layer*2.2))*70.0
   pts.append(Vector2(x,y))
  pts.append(Vector2(w,ground))
  draw_colored_polygon(pts,Color(0.19,0.26,0.27,0.09+layer*.02))
 draw_circle(Vector2(w*.77,h*.26),h*.15,Color(1,0.94,0.76,0.55))
 for n in range(80):
  var x: float = fmod(float(n*173+49),maxf(w,1))
  var y: float = fmod(float(n*61+19),maxf(h,1))
  draw_line(Vector2(x,y),Vector2(x+9,y-2),Color(0.1,0.1,0.1,0.035),1)
 if arena == 0:
  for x in [w*.1,w*.9]:
   draw_rect(Rect2(x-12,ground-140,24,140),Color("555e55"))
   draw_line(Vector2(x-45,ground-140),Vector2(x+45,ground-140),INK,12)
   draw_line(Vector2(x-65,ground-144),Vector2(x+65,ground-144),INK,5)
 elif arena == 1:
  for n in range(5): paint_oval(Vector2(w*(.1+n*.2),ground+20),Vector2(50,8),Color(0.31,.36,.30,.25))
 else:
  draw_line(Vector2(25,ground-50),Vector2(90,ground-210),Color("647d76"),18)
  draw_line(Vector2(w-30,ground-40),Vector2(w-90,ground-230),Color("647d76"),20)
 draw_rect(Rect2(0,ground,w,h-ground),Color("333c38"))
 draw_line(Vector2(0,ground),Vector2(w,ground),GOLD,4)
 # A distant audience, keeping the centre stage clear.
 for n in range(28):
  var cx: float=n*w/27.0
  var cy: float=ground-22+sin(n*2.4)*6
  draw_circle(Vector2(cx,cy),7,Color("636958"))
  draw_line(Vector2(cx-6,cy+8),Vector2(cx+7,cy+8),Color("636958"),12)
 for n in range(10):
  var x: float = n*w/9
  draw_line(Vector2(x,ground),Vector2(x-35,h),Color(1,1,1,.06),2)
 var attack: int = model.attacker_side()
 var local: float = fmod(model.elapsed,3.0)
 for side in range(2):
  var x: float = w*(.29 if side==0 else .71)
  var lunge: float = sin(clampf((local-1.45)/.9,0,1)*PI)*w*.12 if side==attack and model.state=="battle" else 0.0
  x += lunge*(1 if side==0 else -1)
  fighter(side,Vector2(x,ground-7),1 if side==0 else -1,local,side==attack)
  if side==attack and model.state=="battle" and local<1.6:
   draw_arc(Vector2(x,ground-4),45,-PI*.9,-PI*.9+clampf(local/1.6,0,1)*TAU,36,Color("a54e33"),3)
 if model.state=="battle" and local>=1.6 and local<2.4:
  var center := Vector2(w*.5,ground-h*.33)
  var ink_color := Color(model.FIGHTERS[model.pair[attack]].color)
  var sweep: float=clampf((local-1.6)/.8,0,1)
  for line in range(6):
   var y: float=center.y-24+line*9
   var start: float=w*(.30 if attack==0 else .70)
   var end: float=w*(.70 if attack==0 else .30)
   draw_line(Vector2(start,y),Vector2(lerpf(start,end,sweep),y-15),Color(ink_color,0.35-line*.035),3)
  draw_arc(center,66,PI*.12+ sweep,PI*.85+sweep,24,Color(1,.92,.67,.75),5)
 if model.state == "battle":
  var phase: int = model.attack_phase()
  var tag: String = ["蓄勢", "出招！", "收招"][phase]
  draw_string(font,Vector2(w*.5-36,h*.22),tag,HORIZONTAL_ALIGNMENT_LEFT,-1,29,Color("753a2e"))
 for e in effects:
  var y: float = ground-h*.58-(1.1-float(e.life))*65
  var x: float = w*(.28 if int(e.side)==0 else .72)
  draw_string(font,Vector2(x-15,y),"−%d" % int(e.amount),HORIZONTAL_ALIGNMENT_LEFT,-1,45,Color(.85,.18,.1,minf(1,float(e.life)*2)))
 if music_gag > 0:
  var x: float = w*(.28 if gag_side==0 else .72)
  for n in range(3):
   var pos := Vector2(x-65+n*65,ground-h*.72+sin(clock*5+n)*10)
   draw_string(font,pos,"♪",HORIZONTAL_ALIGNMENT_LEFT,-1,30,Color("b95137"))
 if pulse>0: draw_rect(Rect2(Vector2.ZERO,size),Color(1,.9,.65,pulse*.7))
 draw_string(font,Vector2(22,37),model.ARENAS[arena].name,HORIZONTAL_ALIGNMENT_LEFT,-1,22,INK)
 draw_circle(Vector2(w-75,28),5,Color("bf4636"))
 draw_string(font,Vector2(w-63,34),"LIVE",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("9c4838"))

func paint_oval(pos: Vector2, radius: Vector2, color: Color) -> void:
 var points := PackedVector2Array()
 for n in range(24):
  var a: float = n*TAU/24
  points.append(pos+Vector2(cos(a)*radius.x,sin(a)*radius.y))
 draw_colored_polygon(points,color)

func fighter(side: int, at: Vector2, direction: int, phase: float, attacking: bool) -> void:
 var id: int = model.pair[side]
 if sprites.size()<4: return
 var dancing: bool = music_gag>0 and model.music_index==1 and side==gag_side
 var striking: bool=attacking and phase>=1.6 and phase<2.3 and model.state=="battle"
 var angle: float = sin(clock*11)*.16 if dancing else sin(phase*TAU/3)*.025
 if striking: angle=sin((phase-1.6)/.7*PI)*.1
 var bob: float=absf(sin(clock*4))*3
 if dancing: bob=absf(sin(clock*11))*18
 var hurt: bool=false
 for e in effects:
  if int(e.side)==side and float(e.life)>.84: hurt=true
 if hurt:
  at.x-=direction*10
  angle=-.11
 var sprite_h: float=size.y*.80
 var sprite_w: float=sprite_h*sprites[id].get_width()/sprites[id].get_height()
 paint_oval(at+Vector2(0,5),Vector2(sprite_w*.4,11),Color(0,0,0,.22))
 var squash: float=1.0+sin(clock*4)*.014
 draw_set_transform(at+Vector2(0,-bob),angle*direction,Vector2(direction/squash,squash))
 var rect:=Rect2(-sprite_w*.5,-sprite_h,sprite_w,sprite_h)
 if striking:
  draw_texture_rect(sprites[id],Rect2(rect.position-Vector2(23,0),rect.size),false,Color(1,1,1,.12))
 draw_texture_rect(sprites[id],rect,false,Color(1,.78,.66) if hurt else Color.WHITE)
 draw_set_transform(Vector2.ZERO)
 if hurt:
  var impact:=at+Vector2(direction*-sprite_w*.15,-sprite_h*.43)
  for n in range(10):
   var a: float=n*TAU/10+clock
   draw_line(impact+Vector2.from_angle(a)*18,impact+Vector2.from_angle(a)*42,Color("fff2b3"),3)
