extends KinematicBody2D

export var speed = 300
export var bullet_speed = 1000
export var fire_rate = 0.2
export var bulletspray = 50
var velocity = Vector2()

var hurt1 = preload("res://sound/hurt1.wav")
var hurt2 = preload("res://sound/hurt2.wav")
var hurt3 = preload("res://sound/hurt3.wav")
var hurt4 = preload("res://sound/hurt4.wav")
var hurt5 = preload("res://sound/hurt5.wav")

var hurt_array = [hurt1, hurt2, hurt3, hurt4, hurt5]

var damage1 = preload("res://sound/damage1.wav")
var damage2 = preload("res://sound/damage2.wav")
var damage3 = preload("res://sound/damage3.wav")
var damage4 = preload("res://sound/damage4.wav")
var damage5 = preload("res://sound/damage5.wav")
var damage6 = preload("res://sound/damage6.wav")

var damage_array = [damage1, damage2, damage3, damage4, damage5, damage6]

onready var Muzzle = $spr_human/gunHand/gun/Muzzle/
onready var flash = $spr_human/gunHand/gun/Muzzle/flash

#var Bullet = preload("res://games/topdown_shooter/bullet.tscn")
var Bullet = preload("res://games/topdown_shooter/bullet_kine.tscn")

var can_fire = true
onready var firetimer = $firetimer

func _ready():
	firetimer.wait_time = fire_rate 

func _process(_delta):
	look_at(get_global_mouse_position())

func get_input():
	velocity = Vector2()
	if Input.is_action_pressed('ui_down'):
		velocity = Vector2(-speed/2, 0).rotated(rotation)
	if Input.is_action_pressed('ui_up'):
		velocity = Vector2(speed, 0).rotated(rotation)
	if Input.is_action_pressed('ui_right'):
		velocity += Vector2(0, speed/2).rotated(rotation)
	if Input.is_action_pressed('ui_left'):
		velocity += Vector2(0, -speed/2).rotated(rotation)
	if Input.is_action_just_pressed('fire') && can_fire:
		shoot()

func shoot():
	var bullet = Bullet.instance()
	bullet.start(Muzzle.global_position, rotation, bullet_speed, bulletspray)
	get_tree().get_root().add_child(bullet)
	can_fire = false
	firetimer.start()
	get_tree().get_root().get_node("topdown_shooter").get_node("Camera2D").shake(0.1, 30, 20)
	flash.emitting = true

	$AnimationPlayer.play("reload")
	
func _physics_process(_delta):
	get_input()
	var dir = get_global_mouse_position() - global_position
	if dir.length() > 5:
		rotation = dir.angle()
		velocity = move_and_slide(velocity)

	if $AnimationPlayer.current_animation != "reload" && velocity != Vector2(0,0):
		$AnimationPlayer.play("walk")

	if velocity != Vector2(0,0):
		$WalkAnimationPlayer.play("walk")

func _on_firetimer_timeout():
	can_fire = true

func hurtSound():
	randomize()
	var hurt_number = rand_range(0, hurt_array.size())
	$hurtSFX.stream = hurt_array[hurt_number]
	$hurtSFX.play()
	
	var damage_number = rand_range(0, damage_array.size())
	$hitSFX.stream = damage_array[damage_number]
	$hitSFX.play()
	
	$hurtbuzzSFX.play()
