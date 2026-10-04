extends SceneTree
const Model=preload("res://scripts/game_model.gd")
func _init() -> void:
 var reached: Array = [false,false,false,false]
 for wanted in range(4):
  for seed_value in range(1,121):
   var m: TournamentModel=Model.new();m.reset(seed_value);m.set_order([0,1,2,3]);m.start_tournament()
   for step in range(6000):
    if m.state=="ending":break
    if m.state=="arena_select":m.select_arena(2)
    elif m.state=="midfield":m.select_arena(0)
    elif m.state=="match_result":m.continue_tournament()
    elif m.state=="cast":
     var side: int=m.pair.find(wanted)
     if side>=0 and m.suspicion<72 and int(m.hp[side])-int(m.hp[1-side])<5:m.comment(1,side)
     else:m.comment(3,0)
    elif m.state=="battle":
     var side: int=m.pair.find(wanted)
     if side>=0 and m.cooldown<=0 and m.suspicion<70 and int(m.hp[side])-int(m.hp[1-side])<5:
      var target: int=m.music_target()
      var best: int=-1
      var best_effect: int=0
      for i in range(3):
       if i==m.music_index:continue
       var effect: int=m.music_effect(i)*(1 if target==side else -1)
       if effect>best_effect:best_effect=effect;best=i
      if best>=0:m.switch_music(best)
     m.advance(.1)
   if m.champion==wanted and not m.exposed:
    reached[wanted]=true
    print("Reachable champion %s: seed %d, suspicion %d, profit %d" % [m.FIGHTERS[wanted].name,seed_value,m.suspicion,m.profit]);break
 print("Reachability: ",reached)
 quit(0 if not reached.has(false) else 1)
