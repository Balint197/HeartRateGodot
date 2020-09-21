extends AnimatedSprite



func _on_explosion_animation_finished():
	queue_free()
