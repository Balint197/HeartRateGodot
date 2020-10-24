extends Sprite

var splash1 = preload("res://sound/splash1.wav")
var splash2 = preload("res://sound/splash2.wav")
var splash3 = preload("res://sound/splash3.wav")
var splash4 = preload("res://sound/splash4.wav")
var splash5 = preload("res://sound/splash5.wav")
var splash6 = preload("res://sound/splash6.wav")
var splash7 = preload("res://sound/splash7.wav")

var splash_array = [splash1, splash2, splash3, splash4, splash5, splash6, splash7]

var body_impact1 = preload("res://sound/body_impact1.wav")
var body_impact2 = preload("res://sound/body_impact2.wav")

var body_impact_array = [body_impact1, body_impact2]

func _ready():
	randomize()
	var splash_number = rand_range(0, splash_array.size())
	$AudioStreamPlayer2D.stream = splash_array[splash_number]
	$AudioStreamPlayer2D.play()
	
	var impact_number = rand_range(0, body_impact_array.size())
	$impactAudioStreamPlayer2D.stream = body_impact_array[impact_number]
	$impactAudioStreamPlayer2D.play()
	
	$bloodParticles.emitting = true
	$bodyParticles.emitting = true


func _on_Timer_timeout():
	queue_free()
