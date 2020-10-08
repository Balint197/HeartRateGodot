extends KinematicBody2D

export var speed = 300
export var bullet_speed = 1000
export var fire_rate = 0.2
export var bulletspray = 50
var velocity = Vector2()

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
		velocity = Vector2(-speed/3, 0).rotated(rotation)
	if Input.is_action_pressed('ui_up'):
		velocity = Vector2(speed, 0).rotated(rotation)
	if Input.is_action_pressed('ui_right'):
		velocity += Vector2(0, speed/3).rotated(rotation)
	if Input.is_action_pressed('ui_left'):
		velocity += Vector2(0, -speed/3).rotated(rotation)
	if Input.is_action_just_pressed('fire') && can_fire:
		shoot()

func shoot():
	var bullet = Bullet.instance()
	bullet.start($Muzzle.global_position, rotation, bullet_speed)
#	bullet.position = get_global_position()
#	bullet.rotation_degrees = rotation_degrees
#	bullet.apply_impulse(Vector2(), Vector2(bullet_speed, rand_range(-bulletspray,bulletspray)).rotated(rotation))
	get_tree().get_root().add_child(bullet)
	can_fire = false
	firetimer.start()
	get_tree().get_root().get_node("topdown_shooter").get_node("Camera2D").shake(0.1, 30, 5)

func _physics_process(delta):
	get_input()
	var dir = get_global_mouse_position() - global_position
	if dir.length() > 5:
		rotation = dir.angle()
		velocity = move_and_slide(velocity)


func _on_firetimer_timeout():
	can_fire = true
	
