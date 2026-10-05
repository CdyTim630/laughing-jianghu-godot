extends SceneTree

func _initialize() -> void:
 call_deferred("check_pages")

func check_pages() -> void:
 var ui = load("res://scenes/main.tscn").instantiate()
 root.add_child(ui)
 root.size = Vector2i(1440,900)
 await process_frame
 ui.begin_setup()
 await process_frame
 await process_frame
 if not DisplayServer.get_name() == "headless":
  await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://docs/setup-preview.png")
 print("SETUP minimum: ",ui.page.get_child(1).get_combined_minimum_size())
 ui.swap_slots(0,3)
 ui.select_character(3)
 assert(ui.model.order == [3,1,2,0])
 assert(ui.selected_fighter == 3)
 ui.model.start_tournament()
 ui.model.select_arena(0)
 ui.arena.sample_support()
 for step in range(40):
  ui.model.advance(0.5)
  ui.arena.sample_support()
 assert(ui.arena.support_history.size() > 10)
 var samples: int = ui.arena.support_history.size()
 ui.arena.sample_support()
 assert(ui.arena.support_history.size() == samples)
 ui.update_hud()
 await process_frame
 await process_frame
 if not DisplayServer.get_name() == "headless":
  await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://docs/battle-preview.png")
 print("BATTLE minimum: ",ui.page.get_child(1).get_combined_minimum_size())
 ui.model.elapsed = 22.0
 ui.model.state = "cast"
 ui.model.cast_used = 1
 ui.model.dialog_time = 5.0
 ui.on_state()
 await process_frame
 ui.model.comment(3,0)
 ui.update_hud()
 print("PASS: setup swaps, preview, battle HUD and broadcast flow")
 ui.queue_free()
 await process_frame
 quit()
