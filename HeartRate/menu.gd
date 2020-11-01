extends Control

func _ready():
	match Globals.tasksdone:
		0:	# nothing done
			$ItemList/restButton.disabled = false
		1:  # rest done
			$ItemList/restCheckButton.pressed = true
			$ItemList/task1Button.disabled = false
		2:  # game1 done
			$ItemList/restCheckButton.pressed = true
			$ItemList/task1CheckButton.pressed = true
			$ItemList/task2Button.disabled = false
		3:  # all done
			$ItemList/restCheckButton.pressed = true
			$ItemList/task1CheckButton.pressed = true
			$ItemList/task2CheckButton.pressed = true
			$endLabel.visible = true
			$endLabel/Button.disabled = false


func _on_restButton_pressed():
	Globals.gameType = "rest"
	Globals.tasksdone += 1
	get_tree().change_scene("res://HeartRate/rest_measure.tscn")


func _on_task1Button_pressed():
	Globals.gameType = "basic_game"
	Globals.tasksdone += 1
	get_tree().change_scene("res://games/topdown_shooter/topdown_shooter.tscn")

func _on_task2Button_pressed():
	Globals.gameType = "HR_game"
	Globals.tasksdone += 1
	get_tree().change_scene("res://games/topdown_shooter/topdown_shooter.tscn")

func _on_Button_pressed():
	get_tree().quit()
