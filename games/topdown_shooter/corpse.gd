extends Sprite

func _ready():
	$bloodParticles.emitting = true
	$bodyParticles.emitting = true


func _on_Timer_timeout():
	queue_free()
