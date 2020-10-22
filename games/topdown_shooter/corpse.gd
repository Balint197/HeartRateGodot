extends Sprite

func _ready():
	$bloodParticles.emitting = true

func _on_AnimationPlayer_animation_finished(_anim_name):
	queue_free()
