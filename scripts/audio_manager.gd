class_name JianghuAudio
extends Node

var tracks: Array[AudioStream] = []
var players: Array[AudioStreamPlayer] = []
var active: int = 0
var fade: Tween
var enabled: bool = false
var muted: bool = false
var effects: Dictionary = {}

func _ready() -> void:
 for bus_name in ["Music","SFX"]:
  if AudioServer.get_bus_index(bus_name)<0:
   AudioServer.add_bus()
   var idx: int=AudioServer.bus_count-1
   AudioServer.set_bus_name(idx,bus_name)
   AudioServer.set_bus_send(idx,"Master")
   AudioServer.set_bus_volume_db(idx,-10.0 if bus_name=="Music" else -6.0)
 for name in ["heroic","comic","calm"]:
  var track: AudioStreamWAV = load("res://assets/audio/%s.wav" % name)
  track.loop_mode = AudioStreamWAV.LOOP_FORWARD
  track.loop_end = int(track.get_length()*track.mix_rate)
  tracks.append(track)
 for i in range(2):
  var player := AudioStreamPlayer.new()
  player.bus = &"Music"
  add_child(player)
  players.append(player)
 for name in ["hit","click","coin","alarm"]:
  effects[name] = load("res://assets/audio/%s.wav" % name)

func start() -> void:
 enabled = true
 music(0,true)

func music(index: int, force: bool = false) -> void:
 if not enabled: return
 if not force and players[active].stream == tracks[index]: return
 if fade: fade.kill()
 var old: int = active
 active = 1-active
 players[active].stop()
 players[active].stream = tracks[index]
 players[active].volume_db = -40
 players[active].play()
 fade = create_tween().set_parallel(true)
 fade.tween_property(players[active],"volume_db",0.0,0.35)
 fade.tween_property(players[old],"volume_db",-40.0,0.35)
 fade.chain().tween_callback(players[old].stop)

func sfx(which: String) -> void:
 if not enabled: return
 var player := AudioStreamPlayer.new()
 player.stream = effects[which]
 player.bus = &"SFX"
 add_child(player)
 player.finished.connect(player.queue_free)
 player.play()

func toggle_mute() -> void:
 muted = not muted
 AudioServer.set_bus_mute(0,muted)

func set_music_volume(value: float) -> void:
 AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"Music"),linear_to_db(maxf(value,0.001))-5.0)
