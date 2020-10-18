extends KinematicBody2D

signal hit_player

export var speed = 200
export var damageDistance = 50

var texture_0_0 = preload("res://sprites/enemies/0_0.png")
var texture_0_1 = preload("res://sprites/enemies/0_1.png")
#var texture_1_0 = preload("res://sprites/enemies/1_0.png")
#var texture_1_1 = preload("res://sprites/enemies/1_1.png")
var texture_2_0 = preload("res://sprites/enemies/2_0.png")
var texture_2_1 = preload("res://sprites/enemies/2_1.png")
var texture_3_0 = preload("res://sprites/enemies/3_0.png")
var texture_3_1 = preload("res://sprites/enemies/3_1.png")
var texture_4_0 = preload("res://sprites/enemies/4_0.png")
var texture_4_1 = preload("res://sprites/enemies/4_1.png")
var texture_5_0 = preload("res://sprites/enemies/5_0.png")
var texture_5_1 = preload("res://sprites/enemies/5_1.png")
var texture_6_0 = preload("res://sprites/enemies/6_0.png")
var texture_6_1 = preload("res://sprites/enemies/6_1.png")
var texture_7_0 = preload("res://sprites/enemies/7_0.png")
var texture_7_1 = preload("res://sprites/enemies/7_1.png")
var texture_8_0 = preload("res://sprites/enemies/8_0.png")
var texture_8_1 = preload("res://sprites/enemies/8_1.png")



var texture_array_0 = [texture_0_0, texture_2_0, texture_3_0, texture_4_0, texture_5_0, texture_6_0, texture_7_0, texture_8_0]
var texture_array_1 = [texture_0_1, texture_2_1, texture_3_1, texture_4_1, texture_5_1, texture_6_1, texture_7_1, texture_8_1]

onready var control_node = get_tree().get_root().get_node("topdown_shooter")
onready var player = get_tree().get_root().get_node("topdown_shooter").get_node("player")
onready var corpse = preload("res://games/topdown_shooter/corpse.tscn")

var path: = PoolVector2Array() setget set_path

func _ready():
	connect("hit_player", control_node, "_on_hit_player")
	set_process(false)
	
	randomize()
	var sprite_number = rand_range(0, texture_array_0.size())
	$spr_enemy.texture = texture_array_0[sprite_number]
	$spr_enemy/hands.texture = texture_array_1[sprite_number]

func _physics_process(delta):
	var move_distance = speed * delta
	move_along_path(move_distance)
	if path.size() != 0:
		look_at(path[0])
	if player.get_global_position().distance_to(get_global_position()) < damageDistance:
		emit_signal("hit_player")

func move_along_path(distance: float):
	var start_point = position
	for _i in range(path.size()):
		var distance_to_next = start_point.distance_to(path[0])
		if distance <= distance_to_next and distance >= 0.0:
#			position = start_point.linear_interpolate(path[0], distance / distance_to_next) 
			var idealposition = start_point.linear_interpolate(path[0], distance / distance_to_next) 
			var _collided = move_and_slide((idealposition - get_global_position()) * 70)
			break
		elif distance < 0.0:
			position = path[0]
			set_process(false)
			break
		distance -= distance_to_next
		start_point = path[0]
		path.remove(0)

func set_path(value : PoolVector2Array):
	path = value
	if value.size() == 0:
		return
	set_process(true)

func hit():
	var corpse_instance = corpse.instance()
	corpse_instance.position = get_global_position()
	get_tree().get_root().get_node("topdown_shooter").add_child(corpse_instance)
	queue_free()
