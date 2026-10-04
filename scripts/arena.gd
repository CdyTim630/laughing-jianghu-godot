class_name JianghuArena
extends Control

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
 var ground: float = h*0.79
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
 for n in range(10):
  var x: float = n*w/9
  draw_line(Vector2(x,ground),Vector2(x-35,h),Color(1,1,1,.06),2)
 var attack: int = model.attacker_side()
 var local: float = fmod(model.elapsed,3.0)
 for side in range(2):
  var x: float = w*(.28 if side==0 else .72)
  var lunge: float = sin(clampf((local-1.45)/.9,0,1)*PI)*60.0 if side==attack and model.state=="battle" else 0.0
  x += lunge*(1 if side==0 else -1)
  fighter(side,Vector2(x,ground-10),1 if side==0 else -1,local,side==attack)
 if model.state == "battle":
  var phase: int = model.attack_phase()
  var tag: String = ["蓄勢", "出招！", "收招"][phase]
  draw_string(font,Vector2(w*.5-35,ground-110),tag,HORIZONTAL_ALIGNMENT_LEFT,-1,25,Color("753a2e"))
 for e in effects:
  var y: float = ground-200-(1.1-float(e.life))*65
  var x: float = w*(.28 if int(e.side)==0 else .72)
  draw_string(font,Vector2(x-15,y),"−%d" % int(e.amount),HORIZONTAL_ALIGNMENT_LEFT,-1,32,Color(.85,.18,.1,minf(1,float(e.life)*2)))
 if music_gag > 0:
  var x: float = w*(.28 if gag_side==0 else .72)
  for n in range(3):
   var pos := Vector2(x-65+n*65,ground-245+sin(clock*5+n)*10)
   draw_string(font,pos,"♪",HORIZONTAL_ALIGNMENT_LEFT,-1,30,Color("b95137"))
 if pulse>0: draw_rect(Rect2(Vector2.ZERO,size),Color(1,.9,.65,pulse*.7))
 draw_string(font,Vector2(22,37),model.ARENAS[arena].name,HORIZONTAL_ALIGNMENT_LEFT,-1,22,INK)
 draw_string(font,Vector2(22,62),"江湖直播  ·  導播席操作中",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color(.2,.23,.21,.6))

func paint_oval(pos: Vector2, radius: Vector2, color: Color) -> void:
 var points := PackedVector2Array()
 for n in range(24):
  var a: float = n*TAU/24
  points.append(pos+Vector2(cos(a)*radius.x,sin(a)*radius.y))
 draw_colored_polygon(points,color)

func fighter(side: int, at: Vector2, direction: int, phase: float, attacking: bool) -> void:
 var id: int = model.pair[side]
 var tint: Color = Color(model.FIGHTERS[id].color)
 var dancing: bool = music_gag>0 and model.music_index==1 and side==gag_side
 var angle: float = sin(clock*10)*.13 if dancing else (sin(phase*2)*.025)
 var scale_value: float = minf(size.y/360.0,1.25)
 paint_oval(at+Vector2(0,5),Vector2(55,10),Color(0,0,0,.2))
 draw_set_transform(at,angle,Vector2(scale_value*direction,scale_value))
 var legs: float = sin(clock*12)*18 if dancing else 0
 draw_line(Vector2(-15,-35),Vector2(-28+legs,0),INK,15)
 draw_line(Vector2(17,-35),Vector2(32-legs,0),INK,15)
 # Ink-outlined flared robes.
 var robe := PackedVector2Array([Vector2(-30,-125),Vector2(27,-127),Vector2(47,-40),Vector2(12,-22),Vector2(-8,-30),Vector2(-47,-36)])
 draw_colored_polygon(robe,INK)
 draw_set_transform(at,angle,Vector2(scale_value*direction*.9,scale_value*.94))
 draw_colored_polygon(robe,tint.darkened(.16))
 draw_line(Vector2(-18,-116),Vector2(25,-42),tint.lightened(.2),4)
 draw_line(Vector2(-30,-69),Vector2(35,-69),Color("d3b176"),7)
 draw_set_transform(at,angle,Vector2(scale_value*direction,scale_value))
 var arm: Vector2 = Vector2(64,-108) if attacking and phase>=1.6 and phase<2.2 else Vector2(43,-78)
 if dancing: arm = Vector2(55,-148+sin(clock*10)*20)
 draw_line(Vector2(19,-108),arm,tint,19)
 draw_line(Vector2(-22,-108),Vector2(-49,-78-sin(clock*4)*4),tint,18)
 draw_circle(arm,9,Color("e5bb87"))
 draw_circle(Vector2(-49,-78),8,Color("e5bb87"))
 # Each fighter has an immediately recognizable silhouette and prop.
 if id == 2:
  var fan := PackedVector2Array([arm,arm+Vector2(48,-8),arm+Vector2(34,-45),arm+Vector2(5,-54),arm+Vector2(-25,-32)])
  draw_colored_polygon(fan,Color("f0d395"))
  for n in range(5): draw_line(arm,fan[n],INK,2)
 elif id == 0 or id == 1:
  draw_line(arm,arm+Vector2(82,-38),Color("efe9dc"),8)
  draw_line(arm+Vector2(8,12),arm+Vector2(-8,-13),GOLD,7)
 draw_circle(Vector2(0,-149),31,INK)
 draw_circle(Vector2(1,-146),26,Color("eac597") if id!=3 else Color("ebe3cb"))
 if id==3:
  draw_arc(Vector2(0,-149),31,PI,TAU,24,Color("555450"),14)
  draw_circle(Vector2(14,-151),4,INK)
  draw_circle(Vector2(-8,-151),4,INK)
  draw_colored_polygon(PackedVector2Array([Vector2(-6,-139),Vector2(36,-139),Vector2(13,-126)]),Color("d7a13d"))
 else:
  draw_arc(Vector2(-2,-153),26,PI,TAU+.2,20,Color("e3ded0") if id==1 else Color("272a29"),14)
  draw_line(Vector2(8,-153),Vector2(20,-157),INK,4)
  draw_circle(Vector2(15,-150),2,INK)
  draw_line(Vector2(9,-134),Vector2(22,-135),INK,2)
  if id==1: draw_colored_polygon(PackedVector2Array([Vector2(3,-127),Vector2(23,-128),Vector2(13,-97)]),Color("ddd8cb"))
  if id==0:
   draw_line(Vector2(-22,-161),Vector2(24,-161),Color("c34a32"),7)
   draw_line(Vector2(-22,-161),Vector2(-57,-147+sin(clock*6)*8),Color("c34a32"),6)
  if id==2: draw_circle(Vector2(0,-187),10,GOLD)
 draw_set_transform(Vector2.ZERO)
