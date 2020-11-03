extends "res://HeartRate/HeartRateScript.gd"

export var health = 4
export var pixelizeAmount = 0.05
export var HR_initial_difficulty: float = 0.5 

onready var player = $player
onready var nav_2d = $Navigation2D
onready var enemy_scene = preload("res://games/topdown_shooter/enemy.tscn")
onready var enemies_node = get_node("enemies")
onready var spawnTimer = $spawnTimer
onready var levelChangeTimer = $level_Timer
onready var currentLevel = 0
onready var pixelize = $Pixelize
onready var blur = $Blur
onready var dataNumber = 0
onready var targetValue = 0 # TODO make array? TODO do others...
onready var HRrange = 0 # TODO calculations currently based on 50%+ difficulty
onready var HPtween = $HP_bar/HPtween

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
export (float) var simpleSpawnTimeDecrease = 0.05
export (float) var HRSpawnTimeChange = 1 # scaled by how big the difference is, modify based on RR_use_time
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
	randomize()
	
	match Globals.gameType:
		"basic_game":
			GameType = basic_game
		"HR_game":
			GameType = HR_game

	match GameType:
		"Simple timer":
			spawnTimer.wait_time = spawnTimeInitial
		"Simple adaptive difficulty":
			spawnTimer.wait_time = spawnTimeInitial
		"Level progression":
			levelChangeTimer.wait_time = levelChangeTime
			levelChangeTimer.start()
		"Heart adaptive difficulty":
# 			custom value testing
#			targetValue = 50 
#			HRrange = 133 - targetValue
#			spawnTimer.wait_time = 3
			targetValue = (Globals.minSDNN + Globals.maxSDNN) * (1 - HR_initial_difficulty)
			HRrange = targetValue - Globals.minSDNN
			spawnTimer.wait_time = (spawnTimeInitial + Globals.easy_game_level) * HR_initial_difficulty
			# print("targetValue: ", targetValue, "\nHRrange: ", HRrange, "\nspawnTimer: ", spawnTimer.wait_time)

		"Heart And Simple Adaptive":
			pass
	spawnTimer.start()

	$HP_bar.max_value = health
	initFile(folder_location)
	
	# add first row to CSV
	var titleRow = ["spawnTimer_wait_time","HR","RMMSD","SDNN","pNN50","pNN20","SI"]
	results_arr.append(titleRow)
	results_file.open(folder_location.plus_file(results_filename), results_file.WRITE)
	results_file.store_csv_line(results_arr[0],";")
	results_file.close()

func _process(_delta):
	blur.rect_position = player.get_global_position() - blur.rect_pivot_offset
	blur.rect_rotation = player.rotation_degrees

func _on_HR_Timer_timeout():
	updateRR()
	
	HR = HR_func() 
	RMSSD = RMSSD_func()
	SDNN = SDNN_func()
	pNN50 = pNNX_func(50)
	pNN20 = pNNX_func(20)
	SI = SI_func()# Baevsky’s stress index square root (Kubios, normal)
	
	# writing results to array
#	results_arr.append([dataNumber,HR,RMSSD,SDNN,pNN50,pNN20,SI]) # datanumber version
	dataNumber += 1

	results_arr.append([spawnTimer.wait_time,HR,RMSSD,SDNN,pNN50,pNN20,SI])

	logResults()
	adjustMinMax()

	dataRating(HR_borders, HR)
	dataRating(RMSSD_borders, RMSSD)
	dataRating(SDNN_borders, SDNN)
	dataRating(PNN50_borders, pNN50)
	dataRating(PNN20_borders, pNN20)
	dataRating(SI_borders, SI)

	if health < $HP_bar.max_value:
		health += 0.1

	HPtween.interpolate_property($HP_bar, "value", $HP_bar.value, health, 1, Tween.TRANS_EXPO, Tween.EASE_OUT)
	HPtween.start()

func spawnEnemy():
	var enemy = enemy_scene.instance()
	$spawnPath/spawnPoint.offset = randi()
	enemy.position = $spawnPath/spawnPoint.position
	enemies_node.add_child(enemy)

func _on_spawnTimer_timeout():
	if GameType == "Simple timer":
		spawnEnemy()
#		if spawnTimer.wait_time >= 0.5:
#			spawnTimer.wait_time -= simpleSpawnTimeDecrease
	if GameType == "Simple adaptive difficulty" && $enemies.get_child_count() < SimpleAdaptiveEnemies:
		spawnEnemy()
		# TODO increase number of allowed enemies over time / score 
	if GameType == "Heart adaptive difficulty":
		spawnEnemy()
		adjustSpawn()

func _on_ai_Timer_timeout(): # gives enemies pathfinding
	for enemy_instance in $enemies.get_children():
		var new_path = nav_2d.get_simple_path(enemy_instance.global_position, player.global_position)
		enemy_instance.path = new_path

func _on_hit_player():
	if canGetHurt:
		health -= 1
		HPtween.interpolate_property($HP_bar, "value", $HP_bar.value, health, 1, Tween.TRANS_EXPO, Tween.EASE_OUT)
		HPtween.start()

		$player/HitAnimationPlayer.play("hit")
		for _i in range(4):
			$player/HitAnimationPlayer.queue("hit")
		$Camera2D.shake(0.2, 30, 15)
		canGetHurt = false
		$hit_timer.start()

		$pixelizeAnimationPlayer.play("pixelize")

		$player.hurtSound()

		for enemy in enemies_node.get_children():
			enemy.knockBack()

		if health <= 0:
			game_end()

func game_end():
	if GameType == "Simple timer":
		Globals.easy_game_level = spawnTimer.wait_time

		print("HR: ", Globals.minHR, "-", Globals.maxHR)
		print("RMSSD: ", Globals.minRMSSD, "-", Globals.maxRMSSD)
		print("SDNN: ", Globals.minSDNN, "-", Globals.maxSDNN)
		print("PNN50: ", Globals.minPNN50, "-", Globals.maxPNN50)
		print("PNN20: ", Globals.minPNN20, "-", Globals.maxPNN20)
		print("SI: ", Globals.minSI, "-", Globals.maxSI)

	get_tree().change_scene("res://HeartRate/menu.tscn")

func set_difficulty(level: int): 	# @TODO speed, level length?
	spawnTimer.wait_time = levels[level]

func _on_level_Timer_timeout():
	currentLevel += 1
	set_difficulty(levelProgression[currentLevel])

func _on_hit_timer_timeout():
	canGetHurt = true

func adjustMinMax():
	if Globals.gameType == "basic_game":
		Globals.minHR = adjust_border(Globals.minHR, HR, "min")
		Globals.maxHR = adjust_border(Globals.maxHR, HR, "max")
		Globals.minRMSSD = adjust_border(Globals.minRMSSD, RMSSD, "min")
		Globals.maxRMSSD = adjust_border(Globals.maxRMSSD, RMSSD, "max")
		Globals.minSDNN = adjust_border(Globals.minSDNN, SDNN, "min")
		Globals.maxSDNN = adjust_border(Globals.maxSDNN, SDNN, "max")
		Globals.minPNN50 = adjust_border(Globals.minPNN50, pNN50, "min")
		Globals.maxPNN50 = adjust_border(Globals.maxPNN50, pNN50, "max")
		Globals.minPNN20 = adjust_border(Globals.minPNN20, pNN20, "min")
		Globals.maxPNN20 = adjust_border(Globals.maxPNN20, pNN20, "max")
		Globals.minSI = adjust_border(Globals.minSI, SI, "min")
		Globals.maxSI = adjust_border(Globals.maxSI, SI, "max")

func adjustSpawn(): # TODO add others, weighted based on previous measure
	if SDNN > targetValue:		# low stress -> increase difficulty (decrease time)
		var HRdifference = (SDNN - targetValue) / HRrange # ~+- 0-1, % of difference from desired
		if spawnTimer.wait_time - (HRSpawnTimeChange * HRdifference) >= 2:
			spawnTimer.wait_time -= HRSpawnTimeChange * HRdifference
		else:
			spawnTimer.wait_time = 2

	if SDNN < targetValue:		# high stress -> decrease difficulty (increase time)
		var HRdifference = (targetValue - SDNN) / HRrange # ~+- 0-1, % of difference from desired
		if spawnTimer.wait_time + (HRSpawnTimeChange * HRdifference) <= 8:
			spawnTimer.wait_time += HRSpawnTimeChange * HRdifference
		else:
			spawnTimer.wait_time = 8

func _on_gameLength_timer_timeout():
	game_end()

func _on_change_difficulty_timer_timeout():
	if GameType == "Simple timer" && spawnTimer.wait_time >= 1.5:
		spawnTimer.wait_time -= simpleSpawnTimeDecrease
