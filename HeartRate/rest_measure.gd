extends "res://HeartRate/HeartRateScript.gd"

func _on_Button_pressed():
	$Timer.start()
	$Button.text = "Felmérés folyamatban..."
	$Button.disabled = true

func _on_Timer_timeout():
	$ProgressBar.value += 1
	if $ProgressBar.value == $ProgressBar.max_value:
		initFile(folder_location)
		# add first row to CSV
		var titleRow = ["Data_number","HR","RMMSD","SDNN","pNN50","pNN20","SI"]
		results_arr.append(titleRow)
		results_file.open(folder_location.plus_file(results_filename), results_file.WRITE)
		results_file.store_csv_line(results_arr[0],";")
		results_file.close()

		updateRR()

		### TIME domain ###
		HR = HR_func() 
		RMSSD = RMSSD_func()
		SDNN = SDNN_func()
		pNN50 = pNNX_func(50)
		pNN20 = pNNX_func(20)
		SI = SI_func()# Baevsky’s stress index square root (Kubios, normal)

		# writing results to array
		results_arr.append([1,HR,RMSSD,SDNN,pNN50,pNN20,SI])

		logResults()

		$Timer.stop()
		get_tree().change_scene("res://HeartRate/menu.tscn")
