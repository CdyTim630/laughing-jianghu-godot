class_name TournamentModel
extends RefCounted
## v1 balance: equal base damage; personality and timed interventions decide the edge.
## Pure simulation: independent from rendering and audio, reproducible by seed.
signal state_changed
signal changed
signal battle_event(kind: String, side: int, amount: int)
signal log_added(message: String)

const FIGHTERS: Array = [
 {"name":"熱血少俠", "brief":"替師門爭光，先喊再說。", "trait":"衝動", "attack":6, "odds":2.2, "stake":500, "hint":"熱血／前段 +3；滑稽／中段 −2", "quote":"我的師門沒有教過這段副歌！", "color":"d4563c"},
 {"name":"冷面劍聖", "brief":"看破紅塵，沒看破音控。", "trait":"沉著", "attack":6, "odds":3.0, "stake":300, "hint":"音樂干預幅度最多 ±1", "quote":"劍可斷水，斷不了主辦方的音響。", "color":"8dabbc"},
 {"name":"金扇公子", "brief":"參賽靠實力，資格靠家裡。", "trait":"愛面子", "attack":6, "odds":4.5, "stake":150, "hint":"誇獎 +2；嘲諷 −2（下次攻擊）", "quote":"這不是賄賂，是品牌合作。", "color":"d4b16b"},
 {"name":"神祕蒙面客", "brief":"來歷成謎，面具很像鴨子。", "trait":"古怪", "attack":6, "odds":9.0, "stake":50, "hint":"音樂反應 ±2；操作前可見徵兆", "quote":"嘎。……我是說，承讓。", "color":"ada49b"}
]
const ARENAS: Array = [
 {"name":"祖師廣場", "effect":"石板安穩，傷害無修正。", "gag":"祖師爺看得見，主辦方假裝沒看見。"},
 {"name":"油滑擂台", "effect":"所有攻擊傷害 −1（至少 1）。", "gag":"場務說這是保養，選手說這是拋光。"},
 {"name":"回音山谷", "effect":"非零轉播效果的幅度 +1。", "gag":"你的偏心，有三倍的回音。"}
]
const MUSIC: Array = ["熱血戰歌", "滑稽小調", "舒緩古曲"]
const PHASE_NAMES: Array = ["攻擊前段", "攻擊中段", "攻擊後段"]
const CAST_LINES: Array = ["「此人一出手，連祖師都想按讚！」", "「這招的破綻，在你左手邊！」", "「這種腳步，像在排隊買雞排。」", "「雙方都很努力，請公平較量。」"]

var state: String = "setup"
var order: Array = [0,1,2,3]
var match_index: int = 0
var pair: Array = [0,1]
var winners: Array = []
var hp: Array = [100,100]
var attack_mod: Array = [0,0]
var defense_mod: Array = [0,0]
var elapsed: float = 0.0
var tournament_time: float = 0.0
var suspicion: int = 0
var last_operation: float = -100.0
var cooldown: float = 0.0
var music_index: int = 0
var arena_index: int = 0
var first_arena: int = 0
var last_strike: int = -1
var cast_used: int = 0
var midfield_done: bool = false
var dialog_time: float = 0.0
var champion: int = -1
var profit: int = 0
var exposed: bool = false
var logs: Array[String] = []
var rng := RandomNumberGenerator.new()
var run_seed: int = 0
var masked_sign: int = 2
var match_winner: int = -1
var operations: int = 0

func reset(seed_value: int = 0) -> void:
 run_seed = seed_value if seed_value != 0 else int(Time.get_unix_time_from_system())
 rng.seed = run_seed
 state = "setup"
 order = [0,1,2,3]
 match_index = 0
 winners.clear()
 suspicion = 0
 tournament_time = 0.0
 last_operation = -100.0
 champion = -1
 profit = 0
 exposed = false
 operations = 0
 logs.clear()
 state_changed.emit()
 changed.emit()

func announce(message: String) -> void:
 logs.push_front(message)
 if logs.size() > 80: logs.pop_back()
 log_added.emit(message)

func set_order(new_order: Array) -> bool:
 if state != "setup" or new_order.size() != 4: return false
 var seen: Array = []
 for id in new_order:
  if not id is int or id < 0 or id > 3 or id in seen: return false
  seen.append(id)
 order = new_order.duplicate()
 changed.emit()
 return true

func start_tournament() -> void:
 if state != "setup": return
 match_index = 0
 prepare_match()

func prepare_match() -> void:
 if match_index < 2:
  pair = [order[match_index * 2], order[match_index * 2 + 1]]
 else:
  pair = [winners[0],winners[1]]
 hp = [100,100]
 attack_mod = [0,0]
 defense_mod = [0,0]
 elapsed = 0.0
 cooldown = 0.0
 music_index = 0
 cast_used = 0
 midfield_done = false
 last_strike = -1
 masked_sign = 2 if rng.randf() > 0.5 else -2
 state = "arena_select"
 state_changed.emit()
 changed.emit()

func select_arena(index: int) -> bool:
 if index < 0 or index >= ARENAS.size(): return false
 if state == "arena_select":
  arena_index = index
  first_arena = index
  state = "battle"
  announce("%s：%s vs %s。上半場／%s" % [match_title(),FIGHTERS[pair[0]].name,FIGHTERS[pair[1]].name,ARENAS[index].name])
 elif state == "midfield":
  if index == first_arena: return false
  arena_index = index
  midfield_done = true
  state = "battle"
  if not raise_suspicion(12): return true
  announce("下半場／%s。%s" % [ARENAS[index].name,ARENAS[index].gag])
 else: return false
 state_changed.emit()
 changed.emit()
 return true

func match_title() -> String:
 return ["準決賽一", "準決賽二", "冠軍決賽"][match_index]

func attacker_side() -> int:
 return int(floor(elapsed / 3.0)) % 2

func attack_phase() -> int:
 var local: float = fmod(elapsed,3.0)
 if local < 1.6: return 0
 if local < 2.2: return 1
 return 2

func music_target() -> int:
 return attacker_side() if attack_phase() == 0 else 1 - attacker_side()

func music_effect(index: int) -> int:
 var side: int = music_target()
 var id: int = pair[side]
 var phase: int = attack_phase()
 var effect: int = 0
 if id == 3: return masked_sign
 match index:
  0: effect = 3 if id == 0 and phase == 0 else 1
  1: effect = -2
  2: effect = 2 if phase == 1 else -1
 if id == 1: effect = clampi(effect,-1,1)
 return effect

func switch_music(index: int) -> bool:
 if state != "battle" or index < 0 or index > 2 or cooldown > 0.0 or index == music_index: return false
 var target: int = music_target()
 var effect: int = music_effect(index)
 var defending: bool = attack_phase() == 1
 if defending: defense_mod[target] = effect
 else: attack_mod[target] = clampi(int(attack_mod[target])+effect,-5,5)
 music_index = index
 cooldown = 15.0
 operations += 1
 announce("♪ %s → %s／%s %+d（只生效一次）" % [MUSIC[index],FIGHTERS[pair[target]].name,"防禦" if defending else "下次攻擊",effect])
 if index == 1: announce(["少俠的熱血，突然變成廣播體操。","劍聖的袖子很冷靜，腳卻開始打拍子。","公子以為自己在走秀，順手比了個讚。","蒙面客跟著節奏嘎了一聲。有人下注烤鴨。"][pair[target]])
 if pair[target] == 3: masked_sign = 2 if rng.randf() > 0.5 else -2
 battle_event.emit("music",target,effect)
 if not raise_suspicion(8): return true
 changed.emit()
 return true

func cast_effect(kind: int, side: int) -> int:
 if kind == 3: return 0
 var id: int = pair[side]
 var effect: int = 2 if kind == 1 or id == 2 else 1
 if kind == 2: effect = -effect
 if arena_index == 2: effect += 1 if effect > 0 else -1
 return effect

func comment(kind: int, side: int) -> bool:
 if state != "cast" or kind < 0 or kind > 3 or side < 0 or side > 1: return false
 var effect: int = cast_effect(kind,side)
 attack_mod[side] = clampi(int(attack_mod[side])+effect,-5,5)
 announce("轉播：%s → %s／下次攻擊 %+d" % [CAST_LINES[kind],FIGHTERS[pair[side]].name,effect])
 state = "battle"
 if effect != 0:
  operations += 1
  if not raise_suspicion(10): return true
 state_changed.emit()
 changed.emit()
 return true

func raise_suspicion(amount: int) -> bool:
 var combo: bool = tournament_time - last_operation < 10.0
 suspicion = mini(100,suspicion+amount+(6 if combo else 0))
 last_operation = tournament_time
 if combo: announce("觀眾：怎麼這麼巧？連續操作額外懷疑 +6。")
 if suspicion >= 100:
  exposed = true
  profit = -200
  state = "ending"
  announce("黑箱被揭穿！投注全額退回，主辦方另付 200 枚銅錢。")
  battle_event.emit("exposed",0,0)
  state_changed.emit()
  changed.emit()
  return false
 return true

func advance(delta: float) -> void:
 if state == "cast" or state == "midfield":
  dialog_time -= delta
  if dialog_time <= 0:
   if state == "cast": comment(3,0)
   else: select_arena((first_arena+1)%3)
  changed.emit()
  return
 if state != "battle": return
 # Small slices ensure attack and decision milestones can't be skipped on low FPS.
 var left: float = minf(delta,1.0)
 while left > 0.00001 and state == "battle":
  var step: float = minf(left,0.05)
  left -= step
  elapsed = minf(elapsed+step,90.0)
  tournament_time += step
  cooldown = maxf(0.0,cooldown-step)
  var cycle: int = int(floor(elapsed/3.0))
  if fmod(elapsed,3.0) >= 2.2 and last_strike != cycle:
   last_strike = cycle
   resolve_attack(cycle%2)
   if state != "battle": break
  if cast_used == 0 and elapsed >= 22.0:
   cast_used = 1
   state = "cast"
   dialog_time = 5.0
   state_changed.emit()
  elif not midfield_done and elapsed >= 45.0:
   state = "midfield"
   dialog_time = 5.0
   state_changed.emit()
  elif cast_used == 1 and elapsed >= 67.0:
   cast_used = 2
   state = "cast"
   dialog_time = 5.0
   state_changed.emit()
  elif elapsed >= 90.0: finish_match()
 changed.emit()

func resolve_attack(side: int) -> void:
 var other: int = 1-side
 var damage: int = maxi(1,int(FIGHTERS[pair[side]].attack)+int(attack_mod[side])-int(defense_mod[other])-(1 if arena_index == 1 else 0))
 hp[other] = maxi(0,int(hp[other])-damage)
 attack_mod[side] = 0
 defense_mod[other] = 0
 battle_event.emit("hit",other,damage)
 if int(hp[other]) <= 0: finish_match()

func finish_match() -> void:
 var win_side: int
 if int(hp[0]) == int(hp[1]):
  win_side = rng.randi_range(0,1)
  announce("平手！裁判依本局種子抽籤判勝。")
 else: win_side = 0 if int(hp[0]) > int(hp[1]) else 1
 match_winner = pair[win_side]
 winners.append(match_winner)
 state = "match_result"
 announce("%s 勝出！「%s」" % [FIGHTERS[match_winner].name,FIGHTERS[match_winner].quote])
 state_changed.emit()
 changed.emit()

func continue_tournament() -> void:
 if state != "match_result": return
 if match_index == 2:
  champion = match_winner
  profit = projected_profit(champion)
  state = "ending"
  state_changed.emit()
  changed.emit()
 else:
  match_index += 1
  prepare_match()

func projected_profit(id: int) -> int:
 return 1000-int(round(float(FIGHTERS[id].odds)*float(FIGHTERS[id].stake)))

func alive_ids() -> Array:
 var alive: Array = order.duplicate()
 for n in range(mini(winners.size(),2)):
  var a: int = order[n*2]
  var b: int = order[n*2+1]
  alive.erase(b if winners[n] == a else a)
 return alive

func prediction() -> float:
 var a: float = float(hp[0])+float(FIGHTERS[pair[0]].attack)*4.0+float(attack_mod[0])*3.0
 var b: float = float(hp[1])+float(FIGHTERS[pair[1]].attack)*4.0+float(attack_mod[1])*3.0
 return clampf(a/maxf(a+b,1),0.05,0.95)

func ending_title() -> String:
 if exposed: return "不講武德，被抓現行"
 if profit >= 300: return "江湖金牌操盤手"
 if profit >= 0: return "平安落幕，小賺收工"
 return "武林很熱血，帳本很冷"
