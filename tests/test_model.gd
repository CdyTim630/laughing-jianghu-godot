extends SceneTree
const Model = preload("res://scripts/game_model.gd")
var checks: int = 0

func check(condition: bool, message: String) -> void:
 checks += 1
 if not condition:
  push_error("FAILED: "+message)
  quit(1)
  assert(condition,message)

func fresh(seed_value: int = 123) -> TournamentModel:
 var m: TournamentModel = Model.new()
 m.reset(seed_value)
 m.start_tournament()
 m.select_arena(0)
 return m

func _init() -> void:
 # Tournament invariant, reproducibility, locked payouts, valid bracket.
 var a: TournamentModel = Model.new()
 a.reset(123)
 check(not a.set_order([0,0,2,3]),"Reject duplicate roster slots")
 check(a.set_order([3,1,0,2]),"Allow a permutation")
 check(a.projected_profit(0)==-100 and a.projected_profit(1)==100 and a.projected_profit(2)==325 and a.projected_profit(3)==550,"Locked champion payout table")
 # No-op switches do not change suspicion, effect is consumed once, cooldown enforced.
 var m: TournamentModel = fresh()
 check(not m.switch_music(0) and m.suspicion==0,"Same BGM is a no-op")
 check(m.switch_music(1) and m.suspicion==8,"BGM modifies battle and suspicion")
 check(not m.switch_music(2) and m.suspicion==8,"Cooldown refuses another switch")
 check(m.attack_mod[0]==-2,"Windup affects attack")
 m.resolve_attack(0)
 check(m.hp[1]==96 and m.attack_mod[0]==0,"BGM consumed on first attack")
 m.resolve_attack(0)
 check(m.hp[1]==90,"No endless stacking")
 m= fresh()
 m.elapsed=1.8
 m.switch_music(2)
 check(m.defense_mod[1]==1,"Swordmaster clamps defensive music to +1")
 m.resolve_attack(0)
 check(m.hp[1]==95 and m.defense_mod[1]==0,"Defensive effect reduces damage once")
 m=fresh()
 m.elapsed=2.4
 m.switch_music(1)
 check(m.attack_mod[1]==-1,"Recovery targets upcoming attacker")
 # Mid-strike input affects the current hit, and commentary composes with BGM.
 m=fresh();m.elapsed=1.8;m.switch_music(2);m.advance(.5)
 check(m.hp[1]==95 and m.defense_mod[1]==0,"Middle phase music affects current strike before damage resolves")
 m=fresh();m.state="cast";m.comment(1,0);m.switch_music(1)
 check(m.attack_mod[0]==0,"BGM and commentary compose instead of silently overwriting")
 m=Model.new();m.reset(123);m.advance(100)
 check(m.state=="setup" and m.elapsed==0,"Simulation does not advance before a match")
 # Commentary all categories, echoed amplification, one-shot effect.
 m=fresh()
 m.pair=[2,3]
 m.state="cast"
 check(m.cast_effect(0,0)==2 and m.cast_effect(2,0)==-2,"Gold fan personality")
 m.arena_index=2
 check(m.cast_effect(0,0)==3 and m.cast_effect(2,0)==-3 and m.cast_effect(3,0)==0,"Echo amplifies nonzero commentary")
 check(m.comment(0,0) and m.suspicion==10 and m.attack_mod[0]==3,"Commentary applies to next attack")
 check(not m.comment(0,0),"No extra commentary outside a window")
 # Midfield requires a different arena and only changes active arena modifier.
 m=fresh()
 m.state="midfield"
 check(not m.select_arena(0),"Cannot reuse first arena")
 check(m.select_arena(1) and m.suspicion==12,"Midfield applies arena and suspicion")
 m.resolve_attack(0)
 check(m.hp[1]==95,"Oil lowers base damage by one")
 # Combo detection, threshold exposure and correct refunds.
 m=fresh()
 m.suspicion=85
 m.last_operation=m.tournament_time
 m.switch_music(1)
 check(m.suspicion==99 and not m.exposed,"Combo adds 6")
 m.state="cast"
 m.comment(1,0)
 check(m.exposed and m.state=="ending" and m.profit==-200,"100 immediately exposes and refunds")
 m=fresh()
 m.state="cast"
 m.dialog_time=.05
 m.advance(.1)
 check(m.state=="battle" and m.suspicion==0,"Cast timeout defaults neutral")
 m.state="midfield"
 m.dialog_time=.05
 m.advance(.1)
 check(m.state=="battle" and m.arena_index==1 and m.suspicion==12,"Midfield timeout picks different arena")
 # Play all three matches over many seeds and ordering permutations.
 var histories: Array = []
 for seed_value in range(1,13):
  m=Model.new()
  m.reset(seed_value)
  m.set_order([3,1,0,2] if seed_value%2 else [0,1,2,3])
  m.start_tournament()
  var steps: int=0
  while m.state!="ending" and steps<3000:
   steps+=1
   match m.state:
    "arena_select": m.select_arena(0)
    "match_result": m.continue_tournament()
    _: m.advance(.25)
  check(m.state=="ending" and m.winners.size()==3 and m.match_index==2,"All 3 matches complete, seed %d" % seed_value)
  check(m.champion in [m.winners[0],m.winners[1]],"Champion was a semifinal winner")
  check(m.profit==m.projected_profit(m.champion) and m.suspicion<100,"Final settlement is correct")
  histories.append(m.winners.duplicate())
 # Replay same seed and choices for exactly the same results.
 m=Model.new(); m.reset(1);m.set_order([3,1,0,2]);m.start_tournament()
 for step in range(3000):
  if m.state=="ending": break
  if m.state=="arena_select":m.select_arena(0)
  elif m.state=="match_result":m.continue_tournament()
  else:m.advance(.25)
 check(m.winners==histories[0],"Identical seed reproduces tournament")
 # Each ending threshold and tie branch.
 for id in range(4):
  m=Model.new();m.reset(123);m.start_tournament();m.select_arena(0)
  m.match_index=2;m.match_winner=id;m.state="match_result";m.continue_tournament()
  check(m.champion==id and m.profit==m.projected_profit(id),"Payout ending %d" % id)
 m=fresh();m.hp=[25,25];m.finish_match()
 check(m.match_winner in m.pair,"Seeded tie breaker")
 print("PASS: %d gameplay checks (12 complete tournaments, 4 settlements, effects, timeouts, exposure)." % checks)
 quit(0)
