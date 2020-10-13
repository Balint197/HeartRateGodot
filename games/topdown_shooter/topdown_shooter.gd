extends "res://HeartRate/HeartRateScript.gd"

export var health = 100

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

export (String, 
			"Simple timer", 
			"Classic adaptive difficulty") var basic_game

export (String, 
			"Heart adaptive difficulty", 
			"Heart And Classic Adaptive") var HR_game


export (int) var ClassicAdaptiveEnemies = 5

func _ready():
	match Globals.gameType:
		"basic_game":
			GameType = basic_game
		"HR_game":
			GameType = HR_game

	match GameType:
		"Simple timer":
			spawnTimer.start()
		"Heart adaptive difficulty":
			# TODO add heartratespawner
			pass
		"Classic adaptive difficulty":
			spawnTimer.start()

	initFile(folder_location)
	
	# add first row to CSV
	var titleRow = ["Data_number","HR","RMMSD","SDNN","pNN50","pNN20","SI"]
	results_arr.append(titleRow)
	results_file.open(folder_location.plus_file(results_filename), results_file.WRITE)
	results_file.store_csv_line(results_arr[0],";")
	results_file.close()


func _on_HR_Timer_timeout():
	updateRR() 	# from IBI file (logfile unused)
	
	HR = HR_func() 
	RMSSD = RMSSD_func()
	SDNN = SDNN_func()
	pNN50 = pNNX_func(50)
	pNN20 = pNNX_func(20)
	SI = SI_func()# Baevsky’s stress index square root (Kubios, normal)
	
	# writing results to array
	results_arr.append([1,HR,RMSSD,SDNN,pNN50,pNN20,SI])

	logResults()
	
	dataRating(RMSSD_borders, RMSSD)
	dataRating(SDNN_borders, SDNN)
	dataRating(PNN50_borders, pNN50)
	dataRating(PNN20_borders, pNN20)
	dataRating(SI_borders, SI)
	


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

func _on_hit_player():
	health -= 1
	print(health)

