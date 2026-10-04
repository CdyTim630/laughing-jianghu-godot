extends Control
## UI composition, player input and presentation. Rules live in game_model.gd.
const Model = preload("res://scripts/game_model.gd")
const ArenaView = preload("res://scripts/arena.gd")
const AudioService = preload("res://scripts/audio_manager.gd")
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
 titles.add_child(label(subtitle,16,MUTED))
 mute_button = button("音效 開",toggle_mute)
 mute_button.custom_minimum_size.x = 110
 mute_button.size_flags_horizontal = Control.SIZE_SHRINK_END
 header.add_child(mute_button)
 update_mute()
 var help_button := button("玩法",show_help)
 help_button.custom_minimum_size.x = 85
 help_button.size_flags_horizontal = Control.SIZE_SHRINK_END
 header.add_child(help_button)
 if current_page == "battle":
  var pause_button := button("暫停",toggle_pause)
  pause_button.custom_minimum_size.x = 90
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
 left.add_child(label("選手負責熱血，你負責音控。\n換一首歌，帶歪一個江湖。",25,PAPER))
 left.add_child(label("三場對決 · 三種干預 · 一筆不能見光的帳",18,GOLD))
 var gap := Control.new()
 gap.custom_minimum_size.y = 25
 left.add_child(gap)
 var start := button("入席開盤   →",begin_setup,true)
 start.custom_minimum_size = Vector2(350,64)
 start.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
 start.add_theme_font_size_override("font_size",26)
 left.add_child(start)
 var learn := button("先看主持人手冊",show_help)
 learn.custom_minimum_size.x = 350
 learn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
 left.add_child(learn)
 left.add_child(spacer())
 left.add_child(label("單人策略喜劇  /  約 5–8 分鐘  /  虛構銅錢，無真實投注",16,MUTED))
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
 var root := scaffold("主持人入席 / 安排對戰", "拖曳卡片交換位置，或使用左右箭頭。投注已鎖定；三場比賽後僅結算一次。")
 var banner := panel(Color("313b32"),GOLD)
 var notice := label("目標：把冠軍導向最賺錢的結果，並讓懷疑值保持在 100 以下。",23,GOLD)
 banner.add_child(notice)
 root.add_child(banner)
 var cards := hbox(18)
 cards.size_flags_vertical = Control.SIZE_EXPAND_FILL
 root.add_child(cards)
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
  var num := label("位置 %d" % (slot+1),19,INK)
  num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  num.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  place.add_child(num)
  place.add_child(next)
  content.add_child(portrait(id,205))
  content.add_child(label(model.FIGHTERS[id].name,28,INK))
  content.add_child(label(model.FIGHTERS[id].brief,18,Color("5b594c")))
  content.add_child(label("性格／%s" % model.FIGHTERS[id].trait,17,Color("806139")))
  content.add_child(label(model.FIGHTERS[id].hint,17,INK))
  content.add_child(spacer())
  content.add_child(label("鎖定賠率  ×%.1f  ／ 投注 %d" % [model.FIGHTERS[id].odds,model.FIGHTERS[id].stake],17,Color("615e50")))
  var gain: int = model.projected_profit(id)
  content.add_child(label("若奪冠，收益 %+d 銅錢" % gain,22,Color("a04130") if gain<0 else Color("56734f")))
 var bracket := hbox(18)
 root.add_child(bracket)
 for n in range(2):
  var p := panel()
  p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  bracket.add_child(p)
  p.add_child(label("準決賽%s    %s  vs  %s" % ["一" if n==0 else "二",model.FIGHTERS[model.order[n*2]].name,model.FIGHTERS[model.order[n*2+1]].name],22,GOLD))
 var bottom := hbox()
 root.add_child(bottom)
 bottom.add_child(button("返回主選單",show_menu))
 var start := button("賽程確認，開啟第一場   →",model.start_tournament,true)
 bottom.add_child(start)
 start.grab_focus()
 root.add_child(label("1000 總投注 − 冠軍賠率 × 該選手投注額 = 最終收益。賠率不隨戰局變更。",16,MUTED))

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
 var root := scaffold("笑嗷江糊 / %s" % model.match_title(),"你只操控導播席。選手自動戰鬥；音樂、轉播、場地由你干預。")
 var body := hbox(18)
 body.size_flags_vertical = Control.SIZE_EXPAND_FILL
 root.add_child(body)
 var left := vbox(10)
 left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 body.add_child(left)
 var hp_row := hbox(18)
 left.add_child(hp_row)
 for side in range(2):
  var p := panel(Color("263334"),Color(model.FIGHTERS[model.pair[side]].color))
  p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  hp_row.add_child(p)
  var v := vbox(3)
  p.add_child(v)
  var l := label("",21)
  hp_labels.append(l)
  v.add_child(l)
  var bar := make_bar(Color(model.FIGHTERS[model.pair[side]].color),100)
  hp_bars.append(bar)
  v.add_child(bar)
 arena = ArenaView.new()
 arena.model = model
 arena.custom_minimum_size.y = 270
 arena.size_flags_vertical = Control.SIZE_EXPAND_FILL
 left.add_child(arena)
 var row := hbox()
 left.add_child(row)
 clock_label = label("",20,GOLD)
 clock_label.custom_minimum_size.x = 280
 row.add_child(clock_label)
 phase_label = label("",18,PAPER)
 phase_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 row.add_child(phase_label)
 phase_bar = make_bar(GOLD,3)
 phase_bar.custom_minimum_size.x = 190
 row.add_child(phase_bar)
 var controls := hbox(12)
 left.add_child(controls)
 var music_panel := panel()
 music_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 controls.add_child(music_panel)
 var music_box := vbox(5)
 music_panel.add_child(music_box)
 music_box.add_child(label("01  音樂干預",23,GOLD))
 target_label = label("",16,MUTED)
 music_box.add_child(target_label)
 var buttons := hbox(5)
 music_box.add_child(buttons)
 for index in range(3):
  var b := button(["1 熱血","2 滑稽","3 舒緩"][index],use_music.bind(index))
  b.add_theme_font_size_override("font_size",17)
  music_buttons.append(b)
  buttons.add_child(b)
 music_label = label("",16,PAPER)
 music_box.add_child(music_label)
 var cast_panel := panel()
 cast_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 controls.add_child(cast_panel)
 var cast_box := vbox(8)
 cast_panel.add_child(cast_box)
 cast_box.add_child(label("02  轉播帶風向",23,GOLD))
 cast_label = label("",17,PAPER)
 cast_box.add_child(cast_label)
 cast_box.add_child(label("誇獎 / 提示 / 嘲諷 / 中立\n到時間會彈出，5 秒內決策。",16,MUTED))
 var arena_panel := panel()
 arena_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 controls.add_child(arena_panel)
 var arena_box := vbox(8)
 arena_panel.add_child(arena_box)
 arena_box.add_child(label("03  場地黑箱",23,GOLD))
 arena_label = label("",17,PAPER)
 arena_box.add_child(arena_label)
 arena_box.add_child(label("第 45 秒中場換場。\n上下半場必須不同。",16,MUTED))
 var ticker := panel(Color("182428"),Color("384941"))
 left.add_child(ticker)
 log_label = label("",17,PAPER)
 log_label.custom_minimum_size.y = 61
 ticker.add_child(log_label)
 var right := panel(Color("1b2729"),GOLD)
 right.custom_minimum_size.x = 300
 body.add_child(right)
 var ledger := vbox(7)
 right.add_child(ledger)
 ledger.add_child(label("不能見光的帳本",25,GOLD))
 ledger.add_child(label("收款  1000 枚\n賠率已鎖定，冠軍結算一次",17,MUTED))
 for id in range(4):
  var l := label("",17)
  ledger_labels.append(l)
  ledger.add_child(l)
 ledger.add_child(label("收益＝1000 − 冠軍賠付",16,MUTED))
 ledger.add_child(spacer())
 prediction_label = label("",17,GOLD)
 ledger.add_child(prediction_label)
 ledger.add_child(label("局勢預測只反映場上優勢，\n不更改投注或結算賠率。",15,MUTED))
 ledger.add_child(spacer())
 suspicion_label = label("",22,RED)
 ledger.add_child(suspicion_label)
 suspicion_bar = make_bar(RED,100)
 ledger.add_child(suspicion_bar)
 ledger.add_child(label("切歌 +8 · 偏心轉播 +10\n換場 +12 · 10 秒內連動額外 +6\n100：揭穿、退注、賠償 200",14,MUTED))
 var fast := button("快轉 ×1",toggle_speed)
 fast.name = "SpeedButton"
 ledger.add_child(fast)
 root.add_child(label("1 / 2 / 3 切歌     Space 暫停     M 靜音     Tab 選擇按鈕，Enter 確認",15,MUTED))
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
  hp_labels[side].text = "%s    %d / 100" % [model.FIGHTERS[model.pair[side]].name,model.hp[side]]
  hp_bars[side].value = model.hp[side]
 var alive: Array = model.alive_ids()
 for id in range(4):
  ledger_labels[id].text = "%s\n×%.1f  ／  若奪冠 %+d" % [model.FIGHTERS[id].name,model.FIGHTERS[id].odds,model.projected_profit(id)]
  ledger_labels[id].modulate = Color.WHITE if id in alive else Color(.4,.4,.4,1)
 clock_label.text = "%s  /  %02d:%02d" % ["下半場" if model.midfield_done else "上半場",int(model.elapsed)/60,int(model.elapsed)%60]
 phase_label.text = "%s → %s" % [model.FIGHTERS[model.pair[model.attacker_side()]].name,model.PHASE_NAMES[model.attack_phase()]]
 phase_bar.value = fmod(model.elapsed,3.0)
 suspicion_bar.value = model.suspicion
 suspicion_label.text = "懷疑 %d / 100  %s" % [model.suspicion,"紅色警戒" if model.suspicion>=80 else ("有人起疑" if model.suspicion>=60 else "風平浪靜")]
 var target: int = model.music_target()
 var defense: bool = model.attack_phase()==1
 target_label.text = "→ %s／%s" % [model.FIGHTERS[model.pair[target]].name,"防禦" if defense else "下次攻擊"]
 for i in range(3):
  music_buttons[i].disabled = paused or model.state!="battle" or model.cooldown>0 or i==model.music_index
  music_buttons[i].tooltip_text = "%s → %s %+d；懷疑 +8%s" % [model.MUSIC[i],"防禦" if defense else "攻擊",model.music_effect(i),"，連續操作另 +6" if model.tournament_time-model.last_operation<10 else ""]
 music_label.text = "♪ %s  %s" % [model.MUSIC[model.music_index],"冷卻 %d 秒" % ceili(model.cooldown) if model.cooldown>0 else "可切歌 · +8 懷疑"]
 if model.pair.has(3): music_label.text += "\n蒙面徵兆：%s" % ("順拍 +2" if model.masked_sign>0 else "走音 −2")
 cast_label.text = "已用 %d / 2 次\n%s" % [model.cast_used,"下一次：第 %d 秒" % (22 if model.cast_used==0 else 67) if model.cast_used<2 else "轉播已結束"]
 arena_label.text = "%s\n%s" % [model.ARENAS[model.arena_index].name,model.ARENAS[model.arena_index].effect]
 prediction_label.text = "本場優勢預測\n%s  %d%%" % [model.FIGHTERS[model.pair[0]].name,roundi(model.prediction()*100)]
 log_label.text = "\n".join(model.logs.slice(0,2)) if not model.logs.is_empty() else "導播就緒。觀察攻擊階段，在正確時機切歌。"
 if dialog_clock != null and is_instance_valid(dialog_clock):
  dialog_clock.text = "剩餘 %d 秒（暫停戰鬥）" % ceili(model.dialog_time)

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
 v.add_child(label(subtitle,19,PAPER))
 return v

func arena_dialog() -> void:
 var midfield: bool = model.state=="midfield"
 var v := popup("中場 / 換個地方打" if midfield else "%s / 選擇上半場場地" % model.match_title(),"上下半場需使用不同場地。中場換場：懷疑 +12；首次選場免費。")
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
  col.add_child(label(["Ⅰ 石板","Ⅱ 油滑","Ⅲ 回音"][i],28,GOLD))
  col.add_child(label(model.ARENAS[i].name,24))
  col.add_child(label(model.ARENAS[i].effect,19,MUTED))
  var b := button("本場已用" if midfield and i==model.first_arena else "選擇此場地",choose_arena.bind(i),true)
  b.disabled = midfield and i==model.first_arena
  col.add_child(b)
  if not b.disabled and first_button == null: first_button=b
 if midfield: v.add_child(label("逾時自動選擇下一個不同場地。懷疑值會照常增加。",16,MUTED))
 if first_button: first_button.grab_focus()
 update_hud()

func choose_arena(index: int) -> void:
 model.select_arena(index)

func cast_dialog() -> void:
 var v := popup("轉播窗口 %d / 2" % model.cast_used,"先看效果再帶風向。偏心台詞：懷疑 +10；中立不增加。回音山谷加強非零效果。")
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
  col.add_child(label("對 %s 說：" % model.FIGHTERS[model.pair[side]].name,24,GOLD))
  for kind in range(3):
   var words: String = ["誇獎：祖師都想按讚","提示：破綻在左邊","嘲諷：像排隊買雞排"][kind]
   var b := button("%s  /  攻擊 %+d" % [words,model.cast_effect(kind,side)],model.comment.bind(kind,side))
   b.add_theme_font_size_override("font_size",18)
   col.add_child(b)
   if first_button == null: first_button=b
 v.add_child(button("中立轉播：「雙方都很努力，請公平較量。」  懷疑 +0",model.comment.bind(3,0)))
 v.add_child(label("所有效果只影響下次攻擊；逾時採中立台詞。",16,MUTED))
 if first_button: first_button.grab_focus()
 update_hud()

func use_music(index: int) -> void:
 if paused: return
 if model.switch_music(index): audio.music(index)

func show_match_result() -> void:
 current_page = "match_result"
 clear_page()
 var root := scaffold("%s / 比賽結果" % model.match_title(),"本場結束。血量下場重置，懷疑值持續累積。")
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
 text.add_child(label("觀眾懷疑：%d / 100" % model.suspicion,22,Color("8a4a32")))
 if model.match_index < 2:
  text.add_child(label("晉級路線：%s" % "、".join(model.winners.map(func(id: int) -> String: return str(model.FIGHTERS[id].name))),20,INK))
 else: text.add_child(label("冠軍已出爐。準備公開一份不太公開的帳本。",22,INK))
 root.add_child(spacer())
 var go := button("查看最終帳本   →" if model.match_index==2 else "繼續下一場   →",model.continue_tournament,true)
 root.add_child(go)
 go.grab_focus()
 audio.sfx("coin")

func show_ending() -> void:
 current_page = "ending"
 paused=false
 clear_page()
 var root := scaffold("大會落幕 / 主辦方結算", "虛構銅錢的荒謬江湖；每一次黑箱都有代價。")
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
 text.add_child(label("最終收益   %+d 銅錢" % model.profit,34,Color("a94631") if model.profit<0 else Color("526b49")))
 if model.exposed:
  text.add_child(label("總投注 1000 − 全額退款 1000 − 補償 200 = −200\n觀眾衝上導播席，你的副歌終於被迫停止。",23,INK))
 else:
  var c: Dictionary = model.FIGHTERS[model.champion]
  text.add_child(label("冠軍：%s\n總投注 1000 − 賠付 %.1f × %d = %+d" % [c.name,c.odds,c.stake,model.profit],23,INK))
  text.add_child(label("「%s」" % c.quote,24,Color("8a4b33")))
 text.add_child(label("懷疑 %d / 100    ·    黑箱操作 %d 次    ·    局種子 %d" % [model.suspicion,model.operations,model.run_seed],18,Color("6a6859")))
 var history := panel()
 root.add_child(history)
 history.add_child(label("最後的江湖傳聞\n"+"\n".join(model.logs.slice(0,4)),18,MUTED))
 root.add_child(spacer())
 var actions := hbox()
 root.add_child(actions)
 actions.add_child(button("返回主選單",show_menu))
 var replay := button("再辦一場大會   →",begin_setup,true)
 actions.add_child(replay)
 replay.grab_focus()
 audio.sfx("alarm" if model.exposed else "coin")

func toggle_speed() -> void:
 speed = 2.0 if speed==1.0 else 1.0
 var buttons: Array[Node] = page.find_children("SpeedButton","Button",true,false)
 if not buttons.is_empty(): buttons[0].text = "快轉 ×%d" % int(speed)

func toggle_mute() -> void:
 audio.toggle_mute()
 update_mute()

func update_mute() -> void:
 if is_instance_valid(mute_button): mute_button.text = "音效 關" if audio.muted else "音效 開"

func show_help() -> void:
 paused = true
 var v := popup("主持人手冊 / 三步帶歪江湖", "讓最有利的選手奪冠，同時維持懷疑 < 100。",1080)
 v.add_child(label("① 排賽程：拖曳四張卡，決定兩場準決賽。莊家收益看「投注 × 賠率」，並非只看高賠率。\n\n② 干預比賽：選手每 3 秒輪流攻擊。前段切歌改攻擊，中段改防禦，後段改下一位攻擊者。\n　 熱血提振、滑稽干擾、舒緩在中段加防禦。劍聖反應小，蒙面客有可見徵兆。\n　 第 22／67 秒可轉播；第 45 秒換不同場地。各窗口最多暫停 5 秒。\n\n③ 收錢與收場：三場結束，依冠軍計算 1000 − 賠率 × 投注。懷疑到 100 立即揭穿。",22,PAPER))
 v.add_child(label("切歌 +8 ／ 偏心轉播 +10 ／ 中場換場 +12 ／ 10 秒內連續操作額外 +6。\n相同曲目、冷卻中的無效操作、中立轉播都不加懷疑。音樂與轉播修正只生效一次。",19,GOLD))
 v.add_child(label("操作：滑鼠點擊；Tab 切換焦點、Enter 確認；1／2／3 切歌；Space 暫停；M 靜音。\n主選單點擊入席後啟用音訊。快轉 ×2 只加速戰鬥，決策窗口仍保留 5 秒。",18,MUTED))
 v.add_child(button("明白了，回導播席",close_help,true))

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
