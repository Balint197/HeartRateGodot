extends "res://HeartRate/HeartRateScript.gd"

export var health = 4
export var pixelizeAmount = 0.05
export var HR_initial_difficulty: float = 0.5 
export var spawnTimeMin = 2
export var spawnTimeMax = 8

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
onready var SDNNrange = 0 # TODO calculations currently based on 50%+ difficulty
onready var targetValue_short = 0 # TODO make array? TODO do others...
onready var SDNNrange_short = 0 # TODO calculations currently based on 50%+ difficulty
onready var HPtween = $HP_bar/HPtween
onready var timerSet = 0.0

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
export (float) var HRSpawnTimeChange_short = 1
export (int) var spawnTimeInitial = 5

# vars for "Simple adaptive difficulty":
export (int) var AdaptiveEnemies = 5

# vars for "Level progression":
export (int) var levelChangeTime = 30

# set difficulty levels, value is timer wait time
# unused
#export (Dictionary) var levels = {
#	0: 9999,	# no enemies spawned
#	1: 10,
#	2: 5,
#	3: 3,
#	4: 2,
#	5: 1
#}
#
#export (Dictionary) var levelProgression = {
#	0: 0,
#	1: 2, 
#	2: 5, 
#	3: 2, 
#	4: 5, 
#	5: 1, 
#	6: 4, 
#	7: 5
#}

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
#			SDNNrange = 133 - targetValue
#			spawnTimer.wait_time = 3
			targetValue = (Globals.minSDNN + Globals.maxSDNN) * (1 - HR_initial_difficulty)
			SDNNrange = targetValue - Globals.minSDNN
			print("targetValue: ", targetValue, "\nSDNNrange: ", SDNNrange)
			targetValue_short = (Globals.minSDNN_short + Globals.maxSDNN_short) * (1 - HR_initial_difficulty)
			SDNNrange_short = targetValue_short - Globals.minSDNN_short
			print("targetValue_short: ", targetValue_short, "\nSDNNrange_short: ", SDNNrange_short)

			spawnTimer.wait_time = spawnTimeInitial #(spawnTimeInitial + Globals.easy_game_level) * (1 - HR_initial_difficulty)
		"Heart And Simple Adaptive":
# 			custom value testing
#			targetValue = 50 
#			targetValue_short = 50 
#			SDNNrange = 133 - targetValue
#			SDNNrange_short = 133 - targetValue_short
#			spawnTimer.wait_time = 3
			targetValue = (Globals.minSDNN + Globals.maxSDNN) * (1 - HR_initial_difficulty)
			SDNNrange = targetValue - Globals.minSDNN
			print("targetValue: ", targetValue, "\nSDNNrange: ", SDNNrange)
			targetValue_short = (Globals.minSDNN_short + Globals.maxSDNN_short) * (1 - HR_initial_difficulty)
			SDNNrange_short = targetValue_short - Globals.minSDNN_short
			print("targetValue_short: ", targetValue_short, "\nSDNNrange_short: ", SDNNrange_short)

			spawnTimer.wait_time = spawnTimeInitial #(spawnTimeInitial + Globals.easy_game_level) * (1 - HR_initial_difficulty)

	spawnTimer.start()

	$HP_bar.max_value = health
	initFile(folder_location)
	
	# add first row to CSV
	var titleRow = ["spawnTimer_wait_time","HR","RMMSD","SDNN", "SDNN_short","pNN50","pNN20","SI"]
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
	SDNN_short = SDNN_short_func()
	pNN50 = pNNX_func(50)
	pNN20 = pNNX_func(20)
	SI = SI_func() # Baevsky’s stress index square root (Kubios, normal)
	
	# writing results to array
#	results_arr.append([dataNumber,HR,RMSSD,SDNN,pNN50,pNN20,SI]) # datanumber version
	dataNumber += 1

	results_arr.append([spawnTimer.wait_time,HR,RMSSD,SDNN,SDNN_short,pNN50,pNN20,SI])

	logResults()
	adjustMinMax()

#	dataRating(HR_borders, HR)
#	dataRating(RMSSD_borders, RMSSD)
#	dataRating(SDNN_borders, SDNN)
#	dataRating(PNN50_borders, pNN50)
#	dataRating(PNN20_borders, pNN20)
#	dataRating(SI_borders, SI)

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
	if GameType == "Simple adaptive difficulty" && $enemies.get_child_count() < AdaptiveEnemies:
		spawnEnemy()
		# TODO increase number of allowed enemies over time / score 
	if GameType == "Heart adaptive difficulty":
		spawnEnemy()
		spawnTimer.wait_time = timerSet
	if GameType == "Heart And Simple Adaptive" && $enemies.get_child_count() < AdaptiveEnemies:
		spawnEnemy()
		spawnTimer.wait_time = timerSet

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

# for levels, unused
#func set_difficulty(level: int): 	# @TODO speed, level length?
#	spawnTimer.wait_time = levels[level]

#func _on_level_Timer_timeout():
#	currentLevel += 1
#	set_difficulty(levelProgression[currentLevel])

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

func adjustSpawn():
	var HRdifference
	var HRdifference_short

#	if SDNN > targetValue:		# low stress -> increase difficulty -> decrease time
#		HRdifference = (SDNN - targetValue) / SDNNrange # 0-1, % of difference from desired
#		timerSet += spawnTimer.wait_time - (HRSpawnTimeChange * HRdifference)
#
#	if SDNN_short > targetValue_short:		# low stress -> increase difficulty (decrease time)
#		HRdifference_short = (SDNN_short - targetValue_short) / SDNNrange_short # 0-1, % of difference from desired
#		timerSet += spawnTimer.wait_time - (HRSpawnTimeChange_short * HRdifference_short)
#
#	if SDNN < targetValue:		# high stress -> decrease difficulty (increase time)
#		HRdifference = (targetValue - SDNN) / SDNNrange # 0-1, % of difference from desired
#		timerSet += spawnTimer.wait_time + (HRSpawnTimeChange * HRdifference)
#
#	if SDNN < targetValue_short:		# high stress -> decrease difficulty (increase time)
#		HRdifference_short = (targetValue_short - SDNN_short) / SDNNrange_short # 0-1, % of difference from desired
#		timerSet += spawnTimer.wait_time + (HRSpawnTimeChange_short * HRdifference_short)

	HRdifference = (SDNN - targetValue) / SDNNrange # ~ 0 - 1 if SDNN > targetValue; 0 - -1 if SDNN < targetValue
	HRdifference_short = (SDNN_short - targetValue_short) / SDNNrange_short # ~ 0 - 1 if SDNN > targetValue; 0 - -1 if SDNN < targetValue
	timerSet = spawnTimer.wait_time - (HRSpawnTimeChange * HRdifference) - (HRSpawnTimeChange_short * HRdifference_short)

	if timerSet < spawnTimeMin:
		timerSet = spawnTimeMin
	elif timerSet > spawnTimeMax:
		timerSet = spawnTimeMax

	var percent = ((HRdifference * HRSpawnTimeChange) + (HRdifference_short * HRSpawnTimeChange_short))/(HRdifference + HRdifference_short)

	if percent > 1: percent = 1
	if percent < -1: percent = -1

	print(percent)
	
	player.speed = player.defaultSpeed - (player.speedChange * percent)
	blur.material.set_shader_param("amount", 3 - (2 * percent))

func _on_gameLength_timer_timeout():
	game_end()

func _on_change_difficulty_timer_timeout():
	if GameType == "Simple timer" && spawnTimer.wait_time >= 1.5:
		spawnTimer.wait_time -= simpleSpawnTimeDecrease


func _on_spawnAdjustTimer_timeout():
	if GameType == "Heart adaptive difficulty" || GameType == "Heart And Simple Adaptive":
		adjustSpawn()
