extends Particles2D

var impact1 = preload("res://sound/impact1.wav")
var impact2 = preload("res://sound/impact2.wav")
var impact3 = preload("res://sound/impact3.wav")
var impact4 = preload("res://sound/impact4.wav")
var impact5 = preload("res://sound/impact5.wav")

var impact_array = [impact1, impact2, impact3, impact4, impact5]

func _ready():
	randomize()
	var impact_number = rand_range(0, impact_array.size())
	$AudioStreamPlayer2D.stream = impact_array[impact_number]
	$AudioStreamPlayer2D.play()

	emitting = true

func _on_AnimationPlayer_animation_finished(_explode):
	queue_free()

