class_name JianghuArena
extends Control

const BACKGROUND_PATHS := ["res://assets/art/arena-stone.png","res://assets/art/arena-oil.png","res://assets/art/arena-echo.png"]
var backgrounds: Array[Texture2D] = []
var sprite_sheet: Texture2D
var sprites: Array[AtlasTexture] = []
var model: TournamentModel
var font: Font
var clock: float = 0.0
var effects: Array = []
var pulse: float = 0.0
var music_gag: float = 0.0
var gag_side: int = 0
# Sample simulation time, so pause and decision windows do not invent history.
var support_history: Array[Vector2] = []
var history_match: int = -1
var last_support_sample: float = -1.0
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
 for path in BACKGROUND_PATHS: backgrounds.append(load(path))
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
 sample_support()
 clock += delta
 pulse = maxf(0,pulse-delta)
 music_gag = maxf(0,music_gag-delta)
 for e in effects: e.life -= delta
 effects = effects.filter(func(e: Dictionary) -> bool: return float(e.life)>0.0)
 queue_redraw()

func sample_support() -> void:
 if model == null: return
 if history_match != model.match_index or model.elapsed < last_support_sample:
  support_history.clear()
  history_match = model.match_index
  last_support_sample = -1.0
 if support_history.is_empty() or model.elapsed-last_support_sample >= 0.5:
  support_history.append(Vector2(model.elapsed,model.prediction()))
  last_support_sample = model.elapsed
  # Retain only samples within the last 30 simulation seconds.
  while not support_history.is_empty() and support_history[0].x < model.elapsed-30.0:
   support_history.pop_front()

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
 var ground: float = h*0.755
 var location: int = model.arena_index
 if backgrounds.size() == 3:
  var background: Texture2D = backgrounds[location]
  # A panoramic crop keeps architecture proportions and the stone stage visible.
  var source_h: float = minf(background.get_height(),background.get_width()*h/maxf(1,w))
  var source_w: float = minf(background.get_width(),background.get_height()*w/maxf(1,h))
  var source_y: float = (background.get_height()-source_h)*0.42
  var source_x: float = (background.get_width()-source_w)*0.5
  draw_texture_rect_region(background,Rect2(Vector2.ZERO,size),Rect2(source_x,source_y,source_w,source_h))
 else:
  draw_rect(Rect2(Vector2.ZERO,size),PAPER)
 # A soft floor wash separates actors from detailed scenery without hiding the art.
 draw_rect(Rect2(0,h*.59,w,h*.41),Color(1,.96,.86,.12))
 # Audience pennants bounce with each side's support, at the far arena rail.
 for side in range(2):
  var support: float = model.prediction() if side == 0 else 1.0-model.prediction()
  var color := Color(model.FIGHTERS[model.pair[side]].color)
  for n in range(6):
   var x: float = w*(.045+n*.045) if side == 0 else w*(.955-n*.045)
   var y: float = h*.38-absf(sin(clock*5+n))*maxf(0,support-.45)*38
   draw_line(Vector2(x,y+16),Vector2(x,y-9),Color("574a39"),2)
   draw_colored_polygon(PackedVector2Array([Vector2(x,y-9),Vector2(x+19,y-6),Vector2(x,y+2)]),Color(color,.8))
 var attack: int = model.attacker_side()
 var local: float = fmod(model.elapsed,3.0)
 var active: bool = model.state == "battle"
 for side in range(2):
  var x: float = w*(.25 if side == 0 else .75)
  var lunge: float = sin(clampf((local-1.45)/.9,0,1)*PI)*w*.09 if side == attack and active else 0.0
  x += lunge*(1 if side == 0 else -1)
  if side == attack and active and local < 1.6:
   paint_oval(Vector2(x,ground+1),Vector2(h*.23,h*.035),Color(1,.8,.22,.18))
   draw_arc(Vector2(x,ground-4),h*.18,-PI*.9,-PI*.9+clampf(local/1.6,0,1)*TAU,48,Color("e28c36"),4,true)
  fighter(side,Vector2(x,ground-7),1 if side == 0 else -1,local,side == attack)
 if active and local >= 1.6 and local < 2.4:
  var center := Vector2(w*.5,ground-h*.23)
  var ink_color := Color(model.FIGHTERS[model.pair[attack]].color)
  var sweep: float = clampf((local-1.6)/.8,0,1)
  for line in range(5):
   var y: float = center.y-20+line*10
   var start: float = w*(.35 if attack == 0 else .65)
   var end: float = w*(.65 if attack == 0 else .35)
   draw_line(Vector2(start,y),Vector2(lerpf(start,end,sweep),y-15),Color(ink_color,.4-line*.04),4,true)
  draw_arc(center,h*.16,PI*.12+sweep,PI*.85+sweep,36,Color(1,.95,.7,.8),6,true)
 if active:
  var phase: int = model.attack_phase()
  var tag: String = ["蓄勢", "出招！", "收招"][phase]
  var tint: Color = Color("b74830") if phase == 1 else Color("204747")
  var seal := Rect2(w*.5-77,h*.30,154,54)
  draw_style_box(seal_style(tint),seal)
  draw_string(font,Vector2(w*.5-70,h*.30+38),tag,HORIZONTAL_ALIGNMENT_CENTER,140,30,PAPER)
 for e in effects:
  var alpha: float = minf(1,float(e.life)*3)
  var y: float = ground-h*.45-(1.1-float(e.life))*75
  var x: float = w*(.25 if int(e.side) == 0 else .75)
  var text: String = "−%d" % int(e.amount)
  draw_string_outline(font,Vector2(x-38,y),text,HORIZONTAL_ALIGNMENT_LEFT,-1,58,7,Color(1,.98,.84,alpha))
  draw_string(font,Vector2(x-38,y),text,HORIZONTAL_ALIGNMENT_LEFT,-1,58,Color(.82,.17,.1,alpha))
 if music_gag > 0:
  var x: float = w*(.25 if gag_side == 0 else .75)
  for n in range(3):
   var pos := Vector2(x-80+n*70,ground-h*.50+sin(clock*5+n)*12)
   draw_string_outline(font,pos,"♪",HORIZONTAL_ALIGNMENT_LEFT,-1,42,4,PAPER)
   draw_string(font,pos,"♪",HORIZONTAL_ALIGNMENT_LEFT,-1,42,Color("b74830"))
  var caption: String = ["燃起來了！","怎麼跳起來了？","心如止水…"][model.music_index]
  draw_style_box(seal_style(Color("284e46")),Rect2(w*.5-145,h*.68,290,44))
  draw_string(font,Vector2(w*.5-137,h*.68+32),caption,HORIZONTAL_ALIGNMENT_CENTER,274,23,PAPER)
 if pulse > 0:
  # Restrained flash, never a camera movement or gameplay interruption.
  draw_rect(Rect2(Vector2.ZERO,size),Color(1,.94,.72,pulse*.35))

func seal_style(fill: Color) -> StyleBoxFlat:
 var style := StyleBoxFlat.new()
 style.bg_color = Color(fill,.94)
 style.border_color = Color("e7c78f")
 style.set_border_width_all(1)
 style.set_corner_radius_all(9)
 return style


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
 var angle: float = sin(clock*11)*.10 if dancing else sin(phase*TAU/3)*.025
 if striking: angle=sin((phase-1.6)/.7*PI)*.1
 var bob: float=absf(sin(clock*4))*4
 if dancing: bob=absf(sin(clock*11))*12
 var hurt: bool=false
 for e in effects:
  if int(e.side)==side and float(e.life)>.84: hurt=true
 if hurt:
  at.x-=direction*18
  angle=-.11
 var sprite_h: float=size.y*.48
 var sprite_w: float=sprite_h*sprites[id].get_width()/sprites[id].get_height()
 paint_oval(at+Vector2(0,5),Vector2(sprite_w*.30,12),Color(0,0,0,.22))
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
   draw_line(impact+Vector2.from_angle(a)*22,impact+Vector2.from_angle(a)*56,Color("fff2b3"),3)
