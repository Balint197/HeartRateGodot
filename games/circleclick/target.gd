extends Sprite

signal clicked


func _on_click_area_input_event(_viewport, event, _shape_idx):
	if (event is InputEventMouseButton && event.pressed):
		emit_signal("clicked")
		position = Vector2(rand_range(0,1100), rand_range(0,700))
