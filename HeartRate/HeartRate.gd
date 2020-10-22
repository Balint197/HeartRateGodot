extends "res://HeartRate/HeartRateScript.gd"


func _ready():
	initFile(folder_location)
	
	# add first row to CSV
	var titleRow = ["Data_number","HR","RMMSD","SDNN","pNN50","pNN20","SI"]
	results_arr.append(titleRow)
	results_file.open(folder_location.plus_file(results_filename), results_file.WRITE)
	results_file.store_csv_line(results_arr[0],";")
	results_file.close()

	#$LineChart.source = folder_location.plus_file(results_filename)
	#$LineChart2.source = "C:/Users/hajna/HeartRateLogs/heartRateLog_2020. 9. 16. 0-15-34.csv"
	
#	$LineChart.plot()
	#$LineChart2.plot()
	
	# print("Folder location: " + folder_location.plus_file(results_filename))

func _on_Timer_timeout():
	updateRR() 	# from IBI file (logfile unused)
	$RR_label.text = ("Last RR: " + currentRR)
	# https://en.wikipedia.org/wiki/Heart_rate_variability#Analysis
	# https://imotions.com/blog/heart-rate-variability/

	### TIME domain ###
	HR = HR_func() 
	$HR_label.text = ("Heart rate: " + str(int(HR)))
	RMSSD = RMSSD_func()
	$analysis_container/RMSSD_label.text = ("RMSSD: " + str(RMSSD))
	SDNN = SDNN_func()
	$analysis_container/SDNN_label.text = ("SDNN: " + str(SDNN))
	pNN50 = pNNX_func(50)
	$analysis_container/PNN50_label.text = ("pNN50: " + str(pNN50))
	pNN20 = pNNX_func(20)
	$analysis_container/PNN20_label.text = ("pNN20: " + str(pNN20))
	SI = SI_func()# Baevsky’s stress index square root (Kubios, normal)
	$analysis_container/SI_label.text = ("SI: " + str(SI))

	# writing results to array
	results_arr.append([1,HR,RMSSD,SDNN,pNN50,pNN20,SI])

	logResults()
	#drawCharts()

	dataRating(HR_borders, HR)
	dataRating(RMSSD_borders, RMSSD)
	dataRating(SDNN_borders, SDNN)
	dataRating(PNN50_borders, pNN50)
	dataRating(PNN20_borders, pNN20)
	dataRating(SI_borders, SI)


