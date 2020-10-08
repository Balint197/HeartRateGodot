extends KinematicBody2D

export var speed = 300
export var bullet_speed = 1000
export var fire_rate = 0.2
export var bulletspray = 50

#var bullet_scene = load("res://games/topdown_shooter/bullet.tscn")
var bullet_scene = preload("res://games/topdown_shooter/bullet_kine.tscn")

var can_fire = true
onready var firetimer = $firetimer

func _ready():
	firetimer.wait_time = fire_rate 

func _process(_delta):
	look_at(get_global_mouse_position())
	
	if Input.is_action_just_pressed("fire") && can_fire:
		var bullet = bullet_scene.instance()
		bullet.position = get_global_position()
		bullet.rotation_degrees = rotation_degrees
#		bullet.apply_impulse(Vector2(), Vector2(bullet_speed, rand_range(-bulletspray,bulletspray)).rotated(rotation))
		get_tree().get_root().add_child(bullet)
		can_fire = false
		firetimer.start()
		get_tree().get_root().get_node("topdown_shooter").get_node("Camera2D").shake(0.1, 30, 5)

func _physics_process(_delta):
	var direction = Vector2()
	if Input.is_action_pressed("ui_up"):
		direction += Vector2(0, -1)
	if Input.is_action_pressed("ui_down"):
		direction += Vector2(0, 1)
	if Input.is_action_pressed("ui_left"):
		direction += Vector2(-1, 0)
	if Input.is_action_pressed("ui_right"):
		direction += Vector2(1, 0)
	direction = direction.normalized()
	
	var movevector = move_and_slide(direction * speed)

func _on_firetimer_timeout():
	can_fire = true


func shoot():
	var b = bullet_scene.instance()
	b.start($Muzzle.global_position, rotation, bullet_speed)
	get_parent().add_child(b)
