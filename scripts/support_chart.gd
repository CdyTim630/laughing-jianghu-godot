extends Control
## One fighter's recent support, styled to match their health panel.
var arena: JianghuArena
var side: int = 0
const PAPER := Color("eee2c8")
const MUTED := Color("a6aaa3")

func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 clip_contents = true

func _process(_delta: float) -> void:
 queue_redraw()

func _draw() -> void:
 if not is_instance_valid(arena) or arena.model == null: return
 var model := arena.model
 var font := get_theme_default_font()
 var color := Color(model.FIGHTERS[model.pair[side]].color)
 var value: float = model.prediction() if side == 0 else 1.0-model.prediction()
 draw_string(font,Vector2(0,18),"支持度 %d%%" % roundi(value*100),HORIZONTAL_ALIGNMENT_LEFT,-1,18,color)
 draw_string(font,Vector2(maxf(0,size.x-76),18),"最近 30 秒",HORIZONTAL_ALIGNMENT_LEFT,-1,13,MUTED)
 var plot := Rect2(25,27,maxf(1,size.x-30),maxf(10,size.y-31))
 var spread: float = absf(value-0.5)
 for sample in arena.support_history: spread = maxf(spread,absf(sample.y-0.5))
 spread = minf(0.5,maxf(0.04,spread+0.02))
 var low: float = 0.5-spread
 var high: float = 0.5+spread
 draw_string(font,Vector2(0,plot.position.y+8),"%d" % roundi(high*100),HORIZONTAL_ALIGNMENT_LEFT,-1,10,MUTED)
 draw_string(font,Vector2(0,plot.end.y),"%d" % roundi(low*100),HORIZONTAL_ALIGNMENT_LEFT,-1,10,MUTED)
 for level in [0.0,0.5,1.0]:
  var y: float = plot.end.y-level*plot.size.y
  draw_line(Vector2(plot.position.x,y),Vector2(plot.end.x,y),Color(PAPER,0.12),1)
 draw_line(plot.position,Vector2(plot.position.x,plot.end.y),Color(PAPER,0.25),1)
 var points := PackedVector2Array()
 # Fixed 30-second scale. New matches start at the right and fill leftwards.
 var start_time: float = model.elapsed-30.0
 for sample in arena.support_history:
  if sample.x < start_time: continue
  var support: float = sample.y if side == 0 else 1.0-sample.y
  points.append(Vector2(plot.position.x+(sample.x-start_time)/30.0*plot.size.x,plot.end.y-(support-low)/(high-low)*plot.size.y))
 points.append(Vector2(plot.end.x,plot.end.y-(value-low)/(high-low)*plot.size.y))
 if points.size() > 1:
  # Draw one simple strip per interval. A sample can share the current
  # timestamp, so a single filled polygon may contain duplicate vertices.
  for i in range(1,points.size()):
   var left := points[i-1]
   var right := points[i]
   if right.x-left.x <= 0.001: continue
   draw_colored_polygon(PackedVector2Array([Vector2(left.x,plot.end.y),left,right,Vector2(right.x,plot.end.y)]),Color(color,0.09))
  draw_polyline(points,color,2.5,true)
 draw_circle(points[points.size()-1],2.5,color)
