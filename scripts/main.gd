extends Control
## UI composition, player input and presentation. Rules live in game_model.gd.
const Model = preload("res://scripts/game_model.gd")
const ArenaView = preload("res://scripts/arena.gd")
const AudioService = preload("res://scripts/audio_manager.gd")
const SupportChart = preload("res://scripts/support_chart.gd")
const CardDrag = preload("res://scripts/roster_card.gd")
const INK := Color("151f23")
const PANEL := Color("222d30")
const PAPER := Color("eee2c8")
const GOLD := Color("c9a66a")
const RED := Color("d65b42")
const MUTED := Color("a6aaa3")
var model: TournamentModel
var audio: JianghuAudio
var page: Control
var overlay: Control
var current_page: String = "menu"
var paused: bool = false
var speed: float = 1.0
var ui_timer: float = 0.0
var arena: JianghuArena
var hp_labels: Array[Label] = []
var hp_bars: Array[ProgressBar] = []
var music_buttons: Array[Button] = []
var ledger_labels: Array[Label] = []
var clock_label: Label
var phase_label: Label
var music_label: Label
var target_label: Label
var cast_label: Label
var arena_label: Label
var suspicion_label: Label
var suspicion_bar: ProgressBar
var prediction_label: Label
var log_label: Label
var dialog_clock: Label
var mute_button: Button
var phase_bar: ProgressBar
var regular_font: FontVariation
var bold_font: FontVariation
var music_texture: Texture2D
var selected_fighter: int = 0
var character_preview: VBoxContainer
var short_names: Array[String] = ["少俠","劍聖","公子","蒙面客"]

func _ready() -> void:
 var skin := Theme.new()
 regular_font = FontVariation.new()
 regular_font.base_font = load("res://assets/fonts/NotoSansTC.ttf")
 regular_font.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"):500}
 bold_font = FontVariation.new()
 bold_font.base_font = regular_font.base_font
 bold_font.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"):750}
 skin.default_font = regular_font
 skin.default_font_size = 20
 skin.set_color("font_color","Label",PAPER)
 skin.set_color("font_color","Button",PAPER)
 skin.set_color("font_disabled_color","Button",Color("717c7d"))
 skin.set_constant("outline_size","Button",0)
 skin.set_stylebox("normal","Button",button_box(Color("2a373a"),Color("56625d"),1,7))
 skin.set_stylebox("hover","Button",button_box(Color("3e4942"),GOLD,2,7))
 skin.set_stylebox("pressed","Button",button_box(Color("784333"),RED,2,7))
 skin.set_stylebox("disabled","Button",button_box(Color("20292d"),Color("37423f"),1,7))
 skin.set_stylebox("focus","Button",button_box(Color(0,0,0,0),GOLD,3,7))
 theme = skin
 model = Model.new()
 model.state_changed.connect(on_state)
 model.changed.connect(update_hud)
 model.battle_event.connect(on_event)
 audio = AudioService.new()
 add_child(audio)
 page = Control.new()
 page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(page)
 overlay = Control.new()
 overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(overlay)
 music_texture = load("res://assets/art/fighters.png")
 show_menu()

func box(fill: Color, border: Color = Color.TRANSPARENT, width: int = 0, radius: int = 0) -> StyleBoxFlat:
 var b := StyleBoxFlat.new()
 b.bg_color = fill
 b.border_color = border
 b.set_border_width_all(width)
 b.set_corner_radius_all(radius)
 b.content_margin_left = 16
 b.content_margin_right = 16
 b.content_margin_top = 12
 b.content_margin_bottom = 12
 return b

func button_box(fill: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
 var b := box(fill,border,width,radius)
 b.content_margin_top=5
 b.content_margin_bottom=5
 b.content_margin_left=10
 b.content_margin_right=10
 return b

func label(text_value: String, font_size: int = 20, color: Color = PAPER) -> Label:
 var l := Label.new()
 l.text = text_value
 l.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 if font_size>=24: l.add_theme_font_override("font",bold_font)
 l.add_theme_font_size_override("font_size",font_size)
 l.add_theme_color_override("font_color",color)
 l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 l.mouse_filter = Control.MOUSE_FILTER_IGNORE
 return l

func button(text_value: String, action: Callable, accent: bool = false) -> Button:
 var b := Button.new()
 b.text = text_value
 b.custom_minimum_size.y = 43
 b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 if accent:
  b.add_theme_stylebox_override("normal",button_box(Color("a94632"),RED,1,7))
 b.pressed.connect(func() -> void:
  audio.sfx("click")
  action.call())
 return b

func icon(name_value: String, side: int = 24) -> TextureRect:
 var t:=TextureRect.new()
 t.texture=load("res://assets/icons/%s.svg" % name_value)
 t.custom_minimum_size=Vector2(side,side)
 t.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 t.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 t.mouse_filter=Control.MOUSE_FILTER_IGNORE
 t.size_flags_horizontal=Control.SIZE_SHRINK_CENTER
 t.size_flags_vertical=Control.SIZE_SHRINK_CENTER
 return t

func icon_button(icon_name: String, text_value: String, action: Callable, accent: bool = false) -> Button:
 var b:=button(text_value,action,accent)
 b.icon=load("res://assets/icons/%s.svg" % icon_name)
 b.add_theme_constant_override("icon_max_width",24)
 return b

func vbox(separation: int = 12) -> VBoxContainer:
 var v := VBoxContainer.new()
 v.add_theme_constant_override("separation",separation)
 return v

func hbox(separation: int = 14) -> HBoxContainer:
 var h := HBoxContainer.new()
 h.add_theme_constant_override("separation",separation)
 return h

func panel(fill: Color = PANEL, border: Color = Color("45514a")) -> PanelContainer:
 var p := PanelContainer.new()
 p.add_theme_stylebox_override("panel",box(fill,border,1,10))
 return p

func spacer() -> Control:
 var s := Control.new()
 s.size_flags_vertical = Control.SIZE_EXPAND_FILL
 s.mouse_filter = Control.MOUSE_FILTER_IGNORE
 return s

func clear_children(node: Node) -> void:
 for child in node.get_children():
  node.remove_child(child)
  child.queue_free()

func clear_page() -> void:
 clear_children(page)
 clear_children(overlay)
 hp_labels.clear()
 hp_bars.clear()
 music_buttons.clear()
 ledger_labels.clear()
 arena = null
 dialog_clock = null

func scaffold(title: String, subtitle: String) -> VBoxContainer:
 var background := ColorRect.new()
 background.color = INK
 background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 background.mouse_filter = Control.MOUSE_FILTER_IGNORE
 page.add_child(background)
 var margin := MarginContainer.new()
 margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for side in ["left","right"]: margin.add_theme_constant_override("margin_"+side,28)
 for side in ["top","bottom"]: margin.add_theme_constant_override("margin_"+side,20)
 page.add_child(margin)
 var root := vbox(14)
 margin.add_child(root)
 var header := hbox()
 root.add_child(header)
 var titles := vbox(0)
 titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 header.add_child(titles)
 titles.add_child(label(title,28,GOLD))
 if not subtitle.is_empty(): titles.add_child(label(subtitle,16,MUTED))
 mute_button = icon_button("volume","",toggle_mute)
 mute_button.custom_minimum_size.x = 50
 mute_button.size_flags_horizontal = Control.SIZE_SHRINK_END
 header.add_child(mute_button)
 update_mute()
 var help_button := icon_button("help","",show_help)
 help_button.custom_minimum_size.x = 50
 help_button.size_flags_horizontal = Control.SIZE_SHRINK_END
 header.add_child(help_button)
 if current_page == "battle":
  var pause_button := icon_button("pause","",toggle_pause)
  pause_button.custom_minimum_size.x = 50
  pause_button.size_flags_horizontal = Control.SIZE_SHRINK_END
  header.add_child(pause_button)
 return root

func show_menu() -> void:
 current_page = "menu"
 paused = false
 clear_page()
 var bg := TextureRect.new()
 bg.texture = load("res://assets/art/cover.png")
 bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
 bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
 page.add_child(bg)
 var veil := ColorRect.new()
 veil.color = Color(.03,.045,.05,.32)
 veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
 page.add_child(veil)
 var margin := MarginContainer.new()
 margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 margin.add_theme_constant_override("margin_left",80)
 margin.add_theme_constant_override("margin_top",60)
 margin.add_theme_constant_override("margin_right",80)
 margin.add_theme_constant_override("margin_bottom",45)
 page.add_child(margin)
 var row := hbox()
 margin.add_child(row)
 var left := vbox(16)
 left.custom_minimum_size.x = 600
 row.add_child(left)
 left.add_child(label("一場正經武林大會，一位不正經主持人。",20,GOLD))
 left.add_child(spacer())
 left.add_child(label("笑嗷江糊",86,PAPER))
 left.add_child(label("不 講 武 德 大 會",31,RED))
 left.add_child(label("換首歌，帶歪江湖。",29,PAPER))
 
 var gap := Control.new()
 gap.custom_minimum_size.y = 25
 left.add_child(gap)
 var start := icon_button("play","開始",begin_setup,true)
 start.custom_minimum_size = Vector2(350,64)
 start.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
 start.add_theme_font_size_override("font_size",26)
 left.add_child(start)
 var learn := icon_button("help","怎麼玩",show_help)
 learn.custom_minimum_size.x = 350
 learn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
 left.add_child(learn)
 left.add_child(spacer())
 left.add_child(label("單人  ·  5–8 分鐘  ·  虛構銅錢",16,MUTED))
 start.grab_focus()

func begin_setup() -> void:
 if not audio.enabled: audio.start()
 model.reset()
 paused = false
 speed = 1.0

func portrait(id: int, height: int = 175) -> TextureRect:
 var atlas := AtlasTexture.new()
 atlas.atlas = music_texture
 var quarter: float = float(music_texture.get_width())/4.0
 atlas.region = Rect2(id*quarter,0,quarter,music_texture.get_height())
 var t := TextureRect.new()
 t.texture = atlas
 t.custom_minimum_size.y = height
 t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 t.mouse_filter = Control.MOUSE_FILTER_IGNORE
 return t

func show_setup() -> void:
 current_page = "setup"
 clear_page()
 var root := scaffold("安排對戰", "拖曳交換  ·  兩場準決賽 → 冠軍賽")
 var body := hbox(18)
 body.size_flags_vertical = Control.SIZE_EXPAND_FILL
 root.add_child(body)
 var schedule := vbox(12)
 schedule.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 schedule.size_flags_stretch_ratio = 3
 body.add_child(schedule)
 var tree := panel(Color("313b32"),GOLD)
 schedule.add_child(tree)
 var rounds := vbox(8)
 tree.add_child(rounds)
 var champion := label("冠軍",26,GOLD)
 champion.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 rounds.add_child(champion)
 var final_line := label("┌───────────────┴───────────────┐",24,GOLD)
 final_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 rounds.add_child(final_line)
 var matches := hbox(20)
 rounds.add_child(matches)
 for n in range(2):
  var match_box := vbox(4)
  match_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  matches.add_child(match_box)
  var title := label("準決賽 %d" % (n+1),20,GOLD)
  title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  match_box.add_child(title)
  var pairing := label("%s  vs  %s" % [short_names[model.order[n*2]],short_names[model.order[n*2+1]]],18)
  pairing.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  match_box.add_child(pairing)
  var branches := label("┌────────┴────────┐",22,GOLD)
  branches.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  match_box.add_child(branches)
 var cards := hbox(12)
 cards.size_flags_vertical = Control.SIZE_EXPAND_FILL
 schedule.add_child(cards)
 var preview_panel := panel(Color("1b2729"),GOLD)
 preview_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 preview_panel.size_flags_stretch_ratio = 1
 body.add_child(preview_panel)
 character_preview = vbox(10)
 preview_panel.add_child(character_preview)
 update_character_preview()
 for slot in range(4):
  var id: int = model.order[slot]
  var card := PanelContainer.new()
  card.set_script(CardDrag)
  card.slot = slot
  card.on_swap = swap_slots
  card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  card.add_theme_stylebox_override("panel",box(PAPER,Color(model.FIGHTERS[id].color),3,8))
  cards.add_child(card)
  var content := vbox(7)
  content.mouse_filter = Control.MOUSE_FILTER_IGNORE
  card.add_child(content)
  var place := hbox(5)
  content.add_child(place)
  var prev := button("←",swap_slots.bind(slot,(slot+3)%4))
  var next := button("→",swap_slots.bind(slot,(slot+1)%4))
  place.add_child(prev)
  var num := label("%d" % (slot+1),19,INK)
  num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  num.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  place.add_child(num)
  place.add_child(next)
  content.add_child(portrait(id,145))
  content.add_child(label(model.FIGHTERS[id].name,22,INK))
  
  content.add_child(label("%s" % model.FIGHTERS[id].trait,17,Color("806139")))
  var hint := label(["♪ 熱血 +3","♪ 反應 ±1","轉播 ±2","♪ 徵兆 ±2"][id],20,INK)
  hint.tooltip_text = model.FIGHTERS[id].hint
  hint.mouse_filter = Control.MOUSE_FILTER_PASS
  content.add_child(hint)
  content.add_child(button("角色詳情",select_character.bind(id)))
  content.add_child(spacer())
  content.add_child(label("×%.1f   ·   投注 %d" % [model.FIGHTERS[id].odds,model.FIGHTERS[id].stake],17,Color("615e50")))
  var gain: int = model.projected_profit(id)
  content.add_child(label("%+d 銅錢" % gain,30,Color("a04130") if gain<0 else Color("56734f")))
 var bottom := hbox()
 root.add_child(bottom)
 bottom.add_child(button("返回",show_menu))
 var start := button("開賽  →",model.start_tournament,true)
 bottom.add_child(start)
 start.grab_focus()
 

func select_character(id: int) -> void:
 selected_fighter = id
 update_character_preview()

func update_character_preview() -> void:
 if not is_instance_valid(character_preview): return
 clear_children(character_preview)
 var fighter: Dictionary = model.FIGHTERS[selected_fighter]
 character_preview.add_child(label("角色展示",22,GOLD))
 character_preview.add_child(portrait(selected_fighter,245))
 character_preview.add_child(label(fighter.name,28))
 character_preview.add_child(label(fighter.brief,19,MUTED))
 character_preview.add_child(label("性格 · %s" % fighter.trait,21,GOLD))
 character_preview.add_child(label(fighter.hint,19))
 character_preview.add_child(spacer())
 character_preview.add_child(label("鎖定賠率 ×%.1f\n奪冠收益 %+d 銅錢" % [fighter.odds,model.projected_profit(selected_fighter)],22,GOLD))

func swap_slots(a: int, b: int) -> void:
 if model.state != "setup": return
 var new_order: Array = model.order.duplicate()
 var tmp: int = new_order[a]
 new_order[a] = new_order[b]
 new_order[b] = tmp
 model.set_order(new_order)
 show_setup()

func on_state() -> void:
 if model.state == "setup": show_setup()
 elif model.state in ["battle","cast","midfield","arena_select"]:
  if current_page != "battle": show_battle()
  clear_children(overlay)
  dialog_clock = null
  if model.state == "arena_select" or model.state == "midfield": arena_dialog()
  elif model.state == "cast": cast_dialog()
  else: audio.music(model.music_index)
  update_hud()
 elif model.state == "match_result": show_match_result()
 elif model.state == "ending": show_ending()

func show_battle() -> void:
 current_page = "battle"
 clear_page()
 var root := scaffold(model.match_title(),"")
 var body := hbox(16)
 body.size_flags_vertical = Control.SIZE_EXPAND_FILL
 root.add_child(body)
 var left := vbox(9)
 left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 body.add_child(left)
 var support_charts: Array[Control] = []
 var hp_row := hbox(18)
 left.add_child(hp_row)
 for side in range(2):
  if side == 1:
   var booth := panel(Color("313b32"),GOLD)
   booth.custom_minimum_size.x = 240
   hp_row.add_child(booth)
   var booth_box := vbox(4)
   booth.add_child(booth_box)
   booth_box.add_child(label("轉播台",24,GOLD))
   prediction_label = label("",17)
   booth_box.add_child(prediction_label)
   cast_label = label("",16,MUTED)
   booth_box.add_child(cast_label)
  var id: int=model.pair[side]
  var p := panel(Color("263334"),Color(model.FIGHTERS[id].color))
  p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  hp_row.add_child(p)
  var row := hbox(10)
  p.add_child(row)
  var face:=portrait(id,48)
  face.custom_minimum_size.x=48
  row.add_child(face)
  var v := vbox(4)
  v.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  row.add_child(v)
  var l := label("",22)
  hp_labels.append(l)
  v.add_child(l)
  var bar := make_bar(Color(model.FIGHTERS[id].color),100)
  bar.custom_minimum_size.y=12
  hp_bars.append(bar)
  v.add_child(bar)
  var chart := SupportChart.new()
  chart.side = side
  chart.custom_minimum_size = Vector2(0,76)
  v.add_child(chart)
  support_charts.append(chart)
 arena = ArenaView.new()
 arena.model = model
 arena.custom_minimum_size.y = 340
 arena.size_flags_vertical = Control.SIZE_EXPAND_FILL
 left.add_child(arena)
 for chart in support_charts: chart.arena = arena
 var timing := hbox(12)
 left.add_child(timing)
 clock_label = label("",20,GOLD)
 clock_label.custom_minimum_size.x=170
 timing.add_child(clock_label)
 phase_label = label("",20,PAPER)
 phase_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 timing.add_child(phase_label)
 phase_bar = make_bar(GOLD,3)
 phase_bar.custom_minimum_size.x = 170
 timing.add_child(phase_bar)
 var controls := hbox(10)
 left.add_child(controls)
 var music_panel := panel()
 music_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 music_panel.size_flags_stretch_ratio=2
 controls.add_child(music_panel)
 var music_box := vbox(5)
 music_panel.add_child(music_box)
 var music_title := hbox(8)
 music_box.add_child(music_title)
 music_title.add_child(icon("music",24))
 music_title.add_child(label("切歌",22,GOLD))
 target_label = label("",17,MUTED)
 target_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 target_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
 music_title.add_child(target_label)
 var buttons := hbox(6)
 music_box.add_child(buttons)
 for index in range(3):
  var b := icon_button(["fire","comic","calm"][index],["熱血","滑稽","舒緩"][index],use_music.bind(index))
  b.add_theme_font_size_override("font_size",18)
  music_buttons.append(b)
  buttons.add_child(b)
 music_label = label("",16,PAPER)
 music_box.add_child(music_label)
 var attack_panel := panel()
 attack_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 attack_panel.size_flags_stretch_ratio = 2
 controls.add_child(attack_panel)
 var attack_box := vbox(8)
 attack_panel.add_child(attack_box)
 attack_box.add_child(label("攻擊狀態",22,GOLD))
 timing.reparent(attack_box)
 clock_label.custom_minimum_size.x = 0
 phase_bar.custom_minimum_size.x = 70
 attack_box.add_child(label("蓄勢 1.6s → 出招 0.6s → 收招 0.8s",16,MUTED))
 var arena_panel := panel()
 arena_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 controls.add_child(arena_panel)
 var arena_box := vbox(8)
 arena_panel.add_child(arena_box)
 arena_box.add_child(icon("arena",30))
 arena_label = label("",19,GOLD)
 arena_box.add_child(arena_label)
 arena_box.add_child(label("45 秒換場",16,MUTED))
 var ticker := panel(Color("182428"),Color("384941"))
 left.add_child(ticker)
 log_label = label("",18,PAPER)
 log_label.custom_minimum_size.y = 30
 ticker.add_child(log_label)
 var right := panel(Color("1b2729"),GOLD)
 right.custom_minimum_size.x = 235
 body.add_child(right)
 var ledger := vbox(12)
 right.add_child(ledger)
 var account_title:=hbox(8)
 ledger.add_child(account_title)
 account_title.add_child(icon("coin",30))
 account_title.add_child(label("冠軍收益",25,GOLD))
 for id in range(4):
  var row:=hbox(8)
  ledger.add_child(row)
  var face:=portrait(id,50)
  face.custom_minimum_size.x=42
  row.add_child(face)
  var l := label("",19)
  l.tooltip_text="鎖定賠率 ×%.1f / 投注 %d" % [model.FIGHTERS[id].odds,model.FIGHTERS[id].stake]
  l.mouse_filter=Control.MOUSE_FILTER_PASS
  ledger_labels.append(l)
  row.add_child(l)
 ledger.add_child(spacer())
 var risk_title:=hbox(8)
 ledger.add_child(risk_title)
 risk_title.add_child(icon("eye",30))
 suspicion_label = label("",24,RED)
 risk_title.add_child(suspicion_label)
 suspicion_bar = make_bar(RED,100)
 suspicion_bar.custom_minimum_size.y=14
 ledger.add_child(suspicion_bar)
 var risk_note:=label("100 = 穿幫",17,MUTED)
 risk_note.tooltip_text="切歌 +8 / 偏心轉播 +10 / 換場 +12\n10 秒內連續操作額外 +6。穿幫退注並賠償 200。"
 risk_note.mouse_filter=Control.MOUSE_FILTER_PASS
 ledger.add_child(risk_note)
 var fast := button("×1",toggle_speed)
 fast.name = "SpeedButton"
 fast.tooltip_text="快轉戰鬥；決策仍有 5 秒。"
 ledger.add_child(fast)
 update_hud()

func make_bar(color: Color, max_value: float) -> ProgressBar:
 var b := ProgressBar.new()
 b.max_value = max_value
 b.show_percentage = false
 b.custom_minimum_size.y = 9
 b.add_theme_stylebox_override("background",box(Color("111a1e"),Color.TRANSPARENT,0,4))
 b.add_theme_stylebox_override("fill",box(color,Color.TRANSPARENT,0,4))
 for style_name in ["background","fill"]:
  var style: StyleBoxFlat=b.get_theme_stylebox(style_name)
  style.content_margin_top=0
  style.content_margin_bottom=0
  style.content_margin_left=0
  style.content_margin_right=0
 b.mouse_filter = Control.MOUSE_FILTER_IGNORE
 return b

func update_hud() -> void:
 if current_page != "battle" or hp_labels.size()!=2: return
 for side in range(2):
  hp_labels[side].text = "%s   %d" % [model.FIGHTERS[model.pair[side]].name,model.hp[side]]
  hp_bars[side].value = model.hp[side]
 var alive: Array = model.alive_ids()
 for id in range(4):
  ledger_labels[id].text = "%s ×%.1f\n收益 %+d" % [short_names[id],model.FIGHTERS[id].odds,model.projected_profit(id)]
  ledger_labels[id].modulate = Color.WHITE if id in alive else Color(.4,.4,.4,1)
 clock_label.text = "%s  %02d:%02d" % ["下半" if model.midfield_done else "上半",int(model.elapsed)/60,int(model.elapsed)%60]
 phase_label.text = "%s → %s %.1fs" % [short_names[model.pair[model.attacker_side()]],["蓄勢","出招","收招"][model.attack_phase()],maxf(0.0,[1.6,2.2,3.0][model.attack_phase()]-fmod(model.elapsed,3.0))]
 phase_bar.value = fmod(model.elapsed,3.0)
 suspicion_bar.value = model.suspicion
 suspicion_label.text = "%d / 100" % model.suspicion
 suspicion_label.modulate=Color(1,.65,.3) if model.suspicion>=80 else Color.WHITE
 var target: int = model.music_target()
 var defense: bool = model.attack_phase()==1
 target_label.text = "%s · %s" % [short_names[model.pair[target]],"防禦" if defense else "攻擊"]
 for i in range(3):
  music_buttons[i].text="%s %+d" % [["熱血","滑稽","舒緩"][i],model.music_effect(i)]
  music_buttons[i].modulate=GOLD if i==model.music_index else Color.WHITE
  music_buttons[i].disabled = paused or model.state!="battle" or model.cooldown>0 or i==model.music_index
  music_buttons[i].tooltip_text = "[%d] %s %+d / 懷疑 +8%s" % [i+1,"防禦" if defense else "攻擊",model.music_effect(i),"，連動另 +6" if model.tournament_time-model.last_operation<10 else ""]
 music_label.text = "%s  ·  %s" % [["熱血","滑稽","舒緩"][model.music_index],"%d 秒" % ceili(model.cooldown) if model.cooldown>0 else "可切換 +8"]
 if model.pair.has(3): music_label.text += "  ·  鴨 %+d" % model.masked_sign
 cast_label.text = "轉播中 · 選擇台詞" if model.state == "cast" else "下次轉播 %ds" % ceili(maxf(0.0,(22.0 if model.cast_used == 0 else 67.0)-model.elapsed)) if model.cast_used < 2 else "本場轉播結束"
 arena_label.text = ["石板","油滑","回音"][model.arena_index]
 prediction_label.text = "%s %d%% · %s %d%%" % [short_names[model.pair[0]],roundi(model.prediction()*100),short_names[model.pair[1]],roundi((1.0-model.prediction())*100)]
 log_label.text = model.logs[0] if not model.logs.is_empty() else "等他出招，再換歌。"
 if dialog_clock != null and is_instance_valid(dialog_clock):
  dialog_clock.text = "%d 秒" % ceili(model.dialog_time)

func popup(title: String, subtitle: String, width: int = 920) -> VBoxContainer:
 clear_children(overlay)
 var veil := ColorRect.new()
 veil.color = Color(0.035,.05,.05,.83)
 veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 overlay.add_child(veil)
 var center := CenterContainer.new()
 center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 overlay.add_child(center)
 var p := panel(Color("233033"),GOLD)
 p.custom_minimum_size.x = width
 center.add_child(p)
 var v := vbox(14)
 p.add_child(v)
 v.add_child(label(title,32,GOLD))
 if not subtitle.is_empty(): v.add_child(label(subtitle,19,PAPER))
 return v

func arena_dialog() -> void:
 var midfield: bool = model.state=="midfield"
 var v := popup("換場" if midfield else "選擇場地","懷疑 +12  ·  換一個場地" if midfield else "首次免費")
 if midfield:
  dialog_clock = label("",20,RED)
  v.add_child(dialog_clock)
 var row := hbox()
 v.add_child(row)
 var first_button: Button
 for i in range(3):
  var p := panel(Color("1d292c"))
  p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  p.custom_minimum_size.x = 278
  row.add_child(p)
  var col := vbox(10)
  p.add_child(col)
  col.add_child(icon(["stone","oil","echo"][i],100))
  col.add_child(label(["石板","油滑","回音"][i],28,GOLD))
  col.add_child(label(["傷害不變","傷害 −1","轉播更強 ±1"][i],22,PAPER))
  var b := button("已用" if midfield and i==model.first_arena else "選擇",choose_arena.bind(i),true)
  b.disabled = midfield and i==model.first_arena
  col.add_child(b)
  if not b.disabled and first_button == null: first_button=b
 
 if first_button: first_button.grab_focus()
 update_hud()

func choose_arena(index: int) -> void:
 model.select_arena(index)

func cast_dialog() -> void:
 var v := popup("轉播 %d / 2" % model.cast_used,"替誰帶風向？  ·  懷疑 +10")
 dialog_clock = label("",20,RED)
 v.add_child(dialog_clock)
 var row := hbox()
 v.add_child(row)
 var first_button: Button
 for side in range(2):
  var p := panel(Color("1b272a"),Color(model.FIGHTERS[model.pair[side]].color))
  p.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  p.custom_minimum_size.x = 428
  row.add_child(p)
  var col := vbox(9)
  p.add_child(col)
  col.add_child(portrait(model.pair[side],120))
  col.add_child(label(model.FIGHTERS[model.pair[side]].name,24,GOLD))
  for kind in range(3):
   var words: String = ["稱讚","提醒","嘲諷"][kind]
   var b := button("%s   攻擊 %+d" % [words,model.cast_effect(kind,side)],model.comment.bind(kind,side))
   b.add_theme_font_size_override("font_size",18)
   col.add_child(b)
   if first_button == null: first_button=b
 v.add_child(button("中立  ·  懷疑 +0",model.comment.bind(3,0)))
 
 if first_button: first_button.grab_focus()
 update_hud()

func use_music(index: int) -> void:
 if paused: return
 if model.switch_music(index): audio.music(index)

func show_match_result() -> void:
 current_page = "match_result"
 clear_page()
 var root := scaffold("%s / 比賽結果" % model.match_title(),"")
 root.add_child(spacer())
 var p := panel(PAPER,GOLD)
 root.add_child(p)
 var row := hbox(30)
 p.add_child(row)
 var art := portrait(model.match_winner,300)
 art.custom_minimum_size.x = 290
 row.add_child(art)
 var text := vbox(14)
 text.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 row.add_child(text)
 text.add_child(label("勝者 / %s" % model.FIGHTERS[model.match_winner].name,40,INK))
 text.add_child(label("「%s」" % model.FIGHTERS[model.match_winner].quote,26,Color("8a4a32")))
 text.add_child(label("%s  %d HP     vs     %s  %d HP" % [model.FIGHTERS[model.pair[0]].name,model.hp[0],model.FIGHTERS[model.pair[1]].name,model.hp[1]],22,INK))
 text.add_child(label("懷疑 %d / 100" % model.suspicion,22,Color("8a4a32")))
 if model.match_index < 2:
  text.add_child(label("晉級路線：%s" % "、".join(model.winners.map(func(id: int) -> String: return str(model.FIGHTERS[id].name))),20,INK))
 else: text.add_child(label("冠軍出爐！",22,INK))
 root.add_child(spacer())
 var go := button("結算  →" if model.match_index==2 else "下一場  →",model.continue_tournament,true)
 root.add_child(go)
 go.grab_focus()
 audio.sfx("coin")

func show_ending() -> void:
 current_page = "ending"
 paused=false
 clear_page()
 var root := scaffold("大會落幕", "")
 root.add_child(spacer())
 var p := panel(PAPER,RED if model.exposed else GOLD)
 root.add_child(p)
 var row := hbox(28)
 p.add_child(row)
 if model.champion>=0:
  var art := portrait(model.champion,280)
  art.custom_minimum_size.x = 260
  row.add_child(art)
 var text := vbox(14)
 text.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 row.add_child(text)
 text.add_child(label(model.ending_title(),42,Color("a94631") if model.exposed else INK))
 text.add_child(label("%+d 銅錢" % model.profit,34,Color("a94631") if model.profit<0 else Color("526b49")))
 if model.exposed:
  text.add_child(label("穿幫！退款，賠償 200。",23,INK))
 else:
  var c: Dictionary = model.FIGHTERS[model.champion]
  text.add_child(label("冠軍：%s\n總投注 1000 − 賠付 %.1f × %d = %+d" % [c.name,c.odds,c.stake,model.profit],23,INK))
  text.add_child(label("「%s」" % c.quote,24,Color("8a4b33")))
 text.add_child(label("懷疑 %d / 100    ·    操作 %d 次" % [model.suspicion,model.operations],18,Color("6a6859")))
 var history := panel()
 root.add_child(history)
 history.add_child(label(model.logs[0] if not model.logs.is_empty() else "江湖，下次見。",18,MUTED))
 root.add_child(spacer())
 var actions := hbox()
 root.add_child(actions)
 actions.add_child(button("返回",show_menu))
 var replay := button("再辦一場大會   →",begin_setup,true)
 actions.add_child(replay)
 replay.grab_focus()
 audio.sfx("alarm" if model.exposed else "coin")

func toggle_speed() -> void:
 speed = 2.0 if speed==1.0 else 1.0
 var buttons: Array[Node] = page.find_children("SpeedButton","Button",true,false)
 if not buttons.is_empty(): buttons[0].text = "×%d" % int(speed)

func toggle_mute() -> void:
 audio.toggle_mute()
 update_mute()

func update_mute() -> void:
 if is_instance_valid(mute_button):
  mute_button.modulate=Color(.5,.5,.5) if audio.muted else Color.WHITE
  mute_button.tooltip_text="音效關 [M]" if audio.muted else "音效開 [M]"

func show_help() -> void:
 paused = true
 var v := popup("三步帶歪江湖", "少露餡，多賺錢。",1020)
 var row:=hbox(16)
 v.add_child(row)
 var symbols: Array = ["cards","music","coin"]
 var titles: Array = ["排對戰","動手腳","收銅錢"]
 var tips: Array = ["拖曳四位選手\n排出兩場準決賽","切歌 / 轉播 / 換場\n選手自動打","冠軍決定收益\n懷疑 100 就穿幫"]
 for n in range(3):
  var p:=panel(Color("1b272a"))
  p.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  p.custom_minimum_size.x=315
  row.add_child(p)
  var c:=vbox(12)
  p.add_child(c)
  c.add_child(icon(symbols[n],90))
  c.add_child(label("%d  %s" % [n+1,titles[n]],28,GOLD))
  c.add_child(label(tips[n],22,PAPER))
 var timing:=hbox(15)
 v.add_child(timing)
 for n in range(3):
  var c:=vbox(6)
  c.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  timing.add_child(c)
  c.add_child(icon(["sword","shield","sword"][n],35))
  c.add_child(label(["蓄勢 → 攻擊","出招 → 防禦","收招 → 對手攻擊"][n],20,GOLD))
 v.add_child(label("切歌 +8  ·  轉播 +10  ·  換場 +12  ·  連動 +6",18,MUTED))
 v.add_child(label("滑鼠操作  ·  1 / 2 / 3 切歌  ·  Space 暫停  ·  M 靜音",17,MUTED))
 v.add_child(button("懂了",close_help,true))

func close_help() -> void:
 paused=false
 clear_children(overlay)
 if current_page=="battle":
  if model.state in ["arena_select","midfield"]: arena_dialog()
  elif model.state=="cast": cast_dialog()

func toggle_pause() -> void:
 if current_page!="battle": return
 if paused:
  close_help()
  return
 paused=true
 var v := popup("導播休息中", "戰鬥與決策倒數都已暫停。")
 v.add_child(button("繼續大會",close_help,true))
 v.add_child(button("結束這局，返回主選單",show_menu))

func on_event(kind: String, side: int, amount: int) -> void:
 if is_instance_valid(arena): arena.react(kind,side,amount)
 if kind=="hit": audio.sfx("hit")
 elif kind=="exposed": audio.sfx("alarm")

func _process(delta: float) -> void:
 if current_page=="battle" and not paused:
  model.advance(delta*speed if model.state=="battle" else delta)
 ui_timer += delta
 if ui_timer>=0.1:
  ui_timer=0
  if current_page=="battle": update_hud()

func _unhandled_key_input(event: InputEvent) -> void:
 if not event is InputEventKey or not event.pressed or event.echo: return
 if event.keycode==KEY_M: toggle_mute()
 elif event.keycode==KEY_SPACE: toggle_pause()
 elif event.keycode==KEY_ESCAPE:
  if paused: close_help()
  elif current_page=="battle": toggle_pause()
  else: show_menu()
 elif current_page=="battle" and not paused:
  if event.keycode==KEY_1: use_music(0)
  elif event.keycode==KEY_2: use_music(1)
  elif event.keycode==KEY_3: use_music(2)
