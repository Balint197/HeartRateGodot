extends Node2D

onready var player = $player
onready var nav_2d = $Navigation2D
onready var enemy_scene = preload("res://games/topdown_shooter/enemy.tscn")
onready var enemies_node = get_node("enemies")
onready var spawnTimer = $spawnTimer

export (String, 
			"Simple timer", 
			"Classic adaptive difficulty", 
			"Heart adaptive difficulty", 
			"Heart And Classic Adaptive") var GameType
export (int) var ClassicAdaptiveEnemies = 5

func _ready():
	if GameType == "Simple timer":
		spawnTimer.start()
	if GameType == "Heart adaptive difficulty":
		# TODO add heartratespawner
		pass
	if GameType == "Classic adaptive difficulty":
		spawnTimer.start()


func spawnEnemy():
	var enemy = enemy_scene.instance()
	$spawnPath/spawnPoint.offset = randi()
	enemy.position = $spawnPath/spawnPoint.position
	enemies_node.add_child(enemy)


func _on_spawnTimer_timeout():
	if GameType == "Simple Timer":
		spawnEnemy()
	if GameType == "Classic adaptive difficulty" && $enemies.get_child_count() < ClassicAdaptiveEnemies:
		spawnEnemy()
		# TODO increase number of allowed enemies over time / score 


func _on_ai_Timer_timeout(): # gives enemies pathfinding
	for enemy_instance in $enemies.get_children():
		var new_path = nav_2d.get_simple_path(enemy_instance.global_position, player.global_position)
		enemy_instance.path = new_path
