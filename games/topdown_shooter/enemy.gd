extends KinematicBody2D

export var speed = 200

onready var nav_2d: Navigation2D = $Navigation2D
onready var player = get_tree().get_root().get_node("topdown_shooter").get_node("player")

var path: = PoolVector2Array() setget set_path

func _ready():
	set_process(false)

func _process(delta):
	var move_distance = speed * delta
	move_along_path(move_distance)

func move_along_path(distance: float):
	var start_point = position
	for i in range(path.size()):
		var distance_to_next = start_point.distance_to(path[0])
		if distance <= distance_to_next and distance >= 0.0:
			position = start_point.linear_interpolate(path[0], distance / distance_to_next)
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


func _on_Timer_timeout():
	var new_path = nav_2d.get_simple_path(global_position, player.global_position)
	path = new_path
