extends "res://HeartRate/HeartRateScript.gd"

export var health = 10
export var pixelizeAmount = 0.05

onready var player = $player
onready var nav_2d = $Navigation2D
onready var enemy_scene = preload("res://games/topdown_shooter/enemy.tscn")
onready var enemies_node = get_node("enemies")
onready var spawnTimer = $spawnTimer
onready var levelChangeTimer = $level_Timer
onready var currentLevel = 0
onready var pixelize = $Pixelize

var canGetHurt = true

# possible modes, scene start test
export (String, 
			"Simple timer", 				# spawn enemy on timer, timer triggers more often with time
			"Simple adaptive difficulty", 	# max number of allowed enemies, spawn instantly if under max, increase max enemies with time, maybe score based
			"Level progression",			# preset levels and progression between them
			"Heart adaptive difficulty", 	# using HR data, fuzzy logic
			"Heart And Simple Adaptive") var GameType 	#  combine fuzzy with score based (2)

# assign task 1 and 2 to possible mode
export (String, 
			"Simple timer", 
			"Simple adaptive difficulty",
			"Level progression") var basic_game

export (String, 
			"Heart adaptive difficulty", 
			"Heart And Simple Adaptive") var HR_game

# vars for "Simple timer":
export (float) var spawnTimeDecrease = 0.05
export (int) var spawnTimeInitial = 5

# vars for "Simple adaptive difficulty":
export (int) var SimpleAdaptiveEnemies = 5

# vars for "Level progression":
export (int) var levelChangeTime = 30

# set difficulty levels, value is timer wait time
export (Dictionary) var levels = {
	0: 9999,	# no enemies spawned
	1: 10,
	2: 5,
	3: 3,
	4: 2,
	5: 1
}

export (Dictionary) var levelProgression = {
	0: 0,
	1: 2, 
	2: 5, 
	3: 2, 
	4: 5, 
	5: 1, 
	6: 4, 
	7: 5
}

func _ready():
	match Globals.gameType:
		"basic_game":
			GameType = basic_game
		"HR_game":
			GameType = HR_game

	match GameType:
		"Simple timer":
			spawnTimer.wait_time = spawnTimeInitial
			spawnTimer.start()
		"Simple adaptive difficulty":
			spawnTimer.start()
		"Level progression":
			levelChangeTimer.wait_time = levelChangeTime
			levelChangeTimer.start()
			spawnTimer.start()
		"Heart adaptive difficulty":
			# TODO add heartratespawner
			pass
		"Heart And Simple Adaptive":
			pass
			
	$HP_bar.max_value = health

	initFile(folder_location)
	
	# add first row to CSV
	var titleRow = ["Data_number","HR","RMMSD","SDNN","pNN50","pNN20","SI"]
	results_arr.append(titleRow)
	results_file.open(folder_location.plus_file(results_filename), results_file.WRITE)
	results_file.store_csv_line(results_arr[0],";")
	results_file.close()

func _process(delta):
	$HP_bar.value = lerp($HP_bar.value, health, 0.3)

func _on_HR_Timer_timeout():
	updateRR()
	
	HR = HR_func() 
	RMSSD = RMSSD_func()
	SDNN = SDNN_func()
	pNN50 = pNNX_func(50)
	pNN20 = pNNX_func(20)
	SI = SI_func()# Baevsky’s stress index square root (Kubios, normal)
	
	# writing results to array
	results_arr.append([1,HR,RMSSD,SDNN,pNN50,pNN20,SI])

	logResults()
	
	# @TODO add others
	if Globals.gameType == basic_game:
		adjust_border(Globals.minSDNN, SDNN, "min")
		adjust_border(Globals.maxSDNN, SDNN, "max")

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
		spawnTimer.wait_time -= spawnTimeDecrease
	if GameType == "Simple adaptive difficulty" && $enemies.get_child_count() < SimpleAdaptiveEnemies:
		spawnEnemy()
		# TODO increase number of allowed enemies over time / score 


func _on_ai_Timer_timeout(): # gives enemies pathfinding
	for enemy_instance in $enemies.get_children():
		var new_path = nav_2d.get_simple_path(enemy_instance.global_position, player.global_position)
		enemy_instance.path = new_path

func _on_hit_player():
	if canGetHurt:
		health -= 1
		#$HP_bar.value = health
		
		$player/HitAnimationPlayer.play("hit")
		for i in range(4):
			$player/HitAnimationPlayer.queue("hit")
		$Camera2D.shake(0.2, 30, 15)
		canGetHurt = false
		$hit_timer.start()


		$pixelizeAnimationPlayer.play("pixelize")
#		pixelize.material.set_shader_param("size_x", pixelizeAmount)
#		pixelize.material.set_shader_param("size_y", pixelizeAmount)
		
		if health == 0:
			game_end()

func game_end():


# warning-ignore:return_value_discarded
	get_tree().change_scene("res://HeartRate/menu.tscn")

func set_difficulty(level: int): 	# @TODO speed, level length?
	spawnTimer.wait_time = levels[level]


func _on_level_Timer_timeout():
	currentLevel += 1
	set_difficulty(levelProgression[currentLevel])

func set_HR_difficulty():
	
	
	pass


func _on_hit_timer_timeout():
	canGetHurt = true
