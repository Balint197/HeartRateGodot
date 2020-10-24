extends RigidBody2D

var explosion = preload("res://games/topdown_shooter/explosion.tscn")

func _on_bullet_body_entered(body):
	if body.is_in_group("obstacle"):
		var explosion_instance = explosion.instance()
		explosion_instance.position = get_global_position()
		get_tree().get_root().get_node("topdown_shooter").add_child(explosion_instance)
		queue_free()
	if body.is_in_group("enemy"):
		var explosion_instance = explosion.instance()
		explosion_instance.position = get_global_position()
		get_tree().get_root().get_node("topdown_shooter").add_child(explosion_instance)
		queue_free()
		body.die()

func _on_VisibilityNotifier2D_screen_exited():
	queue_free()
