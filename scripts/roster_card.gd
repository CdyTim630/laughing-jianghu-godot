extends PanelContainer
## Native Godot drag & drop; arrows provide the equivalent keyboard action.
var slot: int = 0
var on_swap: Callable

func _get_drag_data(_at: Vector2) -> Variant:
 var preview := Label.new()
 preview.text = "交換對戰位置 %d" % (slot+1)
 preview.add_theme_font_size_override("font_size",26)
 set_drag_preview(preview)
 return {"roster_slot":slot}

func _can_drop_data(_at: Vector2, data: Variant) -> bool:
 return data is Dictionary and data.has("roster_slot") and int(data.roster_slot) != slot

func _drop_data(_at: Vector2, data: Variant) -> void:
 on_swap.call(int(data.roster_slot),slot)
