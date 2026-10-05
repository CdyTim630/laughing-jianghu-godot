extends SceneTree

func _initialize() -> void:
 call_deferred("check_pages")

func capture(ui: Control, filename: String) -> void:
 await process_frame
 await process_frame
 assert(ui.page.get_child(1).get_combined_minimum_size().y <= 900)
 if DisplayServer.get_name() != "headless":
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://docs/"+filename)

func check_pages() -> void:
 var ui = load("res://scenes/main.tscn").instantiate()
 root.add_child(ui)
 root.size = Vector2i(1600,900)
 await process_frame
 ui.begin_setup()
 ui.paused = true
 await capture(ui,"setup-preview.png")
 ui.swap_slots(0,3)
 ui.select_character(3)
 assert(ui.model.order == [3,1,2,0])
 assert(ui.selected_fighter == 3)
 ui.model.start_tournament()
 await capture(ui,"arena-select-preview.png")
 ui.model.select_arena(0)
 ui.arena.sample_support()
 for step in range(40):
  ui.model.advance(0.5)
  ui.arena.sample_support()
 assert(ui.arena.support_history.size() > 10)
 var samples: int = ui.arena.support_history.size()
 ui.arena.sample_support()
 assert(ui.arena.support_history.size() == samples)
 assert(ui.arena.backgrounds.size() == 3)
 assert(ui.arena.backgrounds[0] != ui.arena.backgrounds[1])
 assert(ui.arena.backgrounds[1] != ui.arena.backgrounds[2])
 for texture in ui.arena.backgrounds:
  assert(texture.get_width() == 1672 and texture.get_height() == 941)
 ui.arena.effects.clear()
 ui.arena.react("hit",1,6)
 ui.model.elapsed = 19.85
 ui.update_hud()
 await capture(ui,"battle-preview.png")
 # All three backgrounds and every fighter are rendered, not just the default pair.
 ui.arena.effects.clear()
 ui.model.pair = [0,2]
 ui.model.arena_index = 1
 ui.model.elapsed = 18.4
 ui.model.logs.assign(["少俠與公子 · 竹林上半場"])
 ui.show_battle()
 ui.update_hud()
 await capture(ui,"battle-oil-preview.png")
 ui.model.pair = [1,3]
 ui.model.arena_index = 2
 ui.model.logs.assign(["劍聖與蒙面客 · 回音上半場"])
 ui.show_battle()
 ui.update_hud()
 await capture(ui,"battle-echo-preview.png")
 # Aspect changes must preserve the logical layout and all three operation panels.
 for viewport in [Vector2i(960,540),Vector2i(1280,720),Vector2i(1920,1080)]:
  root.size = viewport
  await process_frame
  await process_frame
  assert(ui.arena.size.y >= 390)
  for b in ui.music_buttons:
   assert(b.get_global_rect().end.x <= ui.size.x+1)
   assert(b.get_global_rect().end.y <= ui.size.y+1)
 root.size = Vector2i(1600,900)
 ui.model.elapsed = 22.0
 ui.model.state = "cast"
 ui.model.cast_used = 1
 ui.model.dialog_time = 5.0
 ui.on_state()
 await capture(ui,"cast-preview.png")
 ui.model.comment(3,0)
 ui.update_hud()
 ui.model.state = "midfield"
 ui.model.elapsed = 45.0
 ui.model.first_arena = 2
 ui.on_state()
 await capture(ui,"midfield-preview.png")
 ui.choose_arena(1)
 assert(ui.model.arena_index == 1)
 assert(ui.model.state == "battle")
 ui.show_help()
 await capture(ui,"help-preview.png")
 ui.close_help()
 ui.toggle_pause()
 await capture(ui,"pause-preview.png")
 print("PASS: roster swaps, three background assets, all fighter pairs, support history, viewport scaling, broadcast and midfield flow")
 ui.audio.enabled = false
 if ui.audio.fade: ui.audio.fade.kill()
 for child in ui.audio.get_children():
  if child is AudioStreamPlayer:
   child.stop()
   child.stream = null
 await create_timer(0.1).timeout
 ui.queue_free()
 await process_frame
 await process_frame
 quit()
