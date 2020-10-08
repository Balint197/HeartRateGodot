extends KinematicBody2D

var explosion = preload("res://games/topdown_shooter/explosion.tscn")


#var speed = 300
var velocity = Vector2()

func start(pos, dir, speed):
	rotation = dir
	position = pos
	velocity = Vector2(speed, 0).rotated(rotation)

func _physics_process(delta):
	var collision = move_and_collide(velocity * delta)
	if collision:
		#velocity = velocity.bounce(collision.normal)
		if collision.collider.has_method("hit"):
			collision.collider.hit()
		if collision.collider.is_in_group("obstacle"):
			var explosion_instance = explosion.instance()
			explosion_instance.position = get_global_position()
			get_tree().get_root().add_child(explosion_instance)
			queue_free()

