extends "res://HeartRate/HeartRate.gd"

func _on_Button_pressed():
	$Timer.start()
	$Button.text = "Felmérés folyamatban..."
	$Button.disabled = true

func _on_Timer_timeout():
	$ProgressBar.value += 1
	if $ProgressBar.value == $ProgressBar.max_value:
		print("kesz")
		$Timer.stop()
