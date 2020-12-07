extends Node


# export (int, 1, 9999) var RR_use_amount = 10 # using RR_use_time instead
onready var RR_use_amount = 0
export (int, 1, 999999999) var RR_use_time = 30000

onready var RR_use_amount_short = 0
export (int, 1, 999999999) var RR_use_time_short = 5000

# !!! modify values here, export is broken (gives null sometimes)
# unused
#export (Dictionary) var HR_borders = {
#	0: 0,
#	1: 50,
#	2: 100,
#	3: 150
#}
#
#export (Dictionary) var RMSSD_borders = {
#	0: 0,
#	1: 50,
#	2: 100,
#	3: 150
#}
#
#export (Dictionary) var SDNN_borders = {
#	0: 0,
#	1: 50,
#	2: 100,
#	3: 150
#}
#
#export (Dictionary) var PNN50_borders = {
#	0: 0,
#	1: 50,
#	2: 100,
#	3: 150
#}
#
#export (Dictionary) var PNN20_borders = {
#	0: 0,
#	1: 50,
#	2: 100,
#	3: 150
#}
#
#export (Dictionary) var SI_borders = {
#	0: 0,
#	1: 50,
#	2: 100,
#	3: 150
#}

### INIT VARS ###

onready var currentRR = 0
onready var RR_average = 0
onready var RR_average_short = 0
onready var HR = 0
onready var RMSSD = 0
onready var SDNN = 0
onready var SDNN_short = 0
onready var pNN50: float = 0
onready var pNN20: float = 0
onready var SI = 0

onready var RR_arr = []
onready var RR_used_arr = []
onready var RR_used_arr_short = []
onready var results_arr = []

onready var latest_file
onready var filePos = 0
onready var IBI_size = 0

onready var time = str(OS.get_datetime().year) + ". " + str(OS.get_datetime().month) \
	+ ". " + str(OS.get_datetime().day) + ". " + str(OS.get_datetime().hour) \
	+ "-"  + str(OS.get_datetime().minute) + "-" + str(OS.get_datetime().second)

export (String) var folder_location = "C:/Users/hajna/HeartRateLogs"
export (String) var save_file_name = "HeartRateAnalysisLog_" 

onready var results_file = File.new()
onready var results_filename = save_file_name + Globals.gameType + "_" + time + ".csv"



func initFile(path):
	var latest_date = 0
	var date_modified
	var dir = Directory.new()
	if dir.open(path) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if !dir.current_is_dir() && file_name.get_extension() == "txt": # IBI only?
#				print("Found file: " + file_name)
#				print("File extension: " + file_name.get_extension())

				var file = File.new()
				date_modified = file.get_modified_time(path.plus_file(file_name))
#				print("File last modified: " + str(date_modified) + "\n")
				
				if date_modified > latest_date:
					latest_date = date_modified
					latest_file = file_name

			file_name = dir.get_next()
		#print("Latest file: " + latest_file + "\n")
	else:
		print("An error occurred when trying to access the path.")

func updateRR():
	var IBI_file = File.new()

	# testing if the file is being written by HeartRate program
	var fileOpenError = IBI_file.open(folder_location.plus_file(latest_file), IBI_file.READ)
	if fileOpenError != OK:
		print("File open error: ", fileOpenError)
	if fileOpenError == OK:
		IBI_file.seek(filePos)

		while not IBI_file.eof_reached():
			var IBI_line = IBI_file.get_line()
			if IBI_line != "":	# needed for last line (\n in HeartRate program)
				RR_arr.append(int(IBI_line))

		filePos = IBI_file.get_position()

		IBI_size = RR_arr.size()
		IBI_file.close()


	RR_use_amount = 0
	var last_RR_sum = 0
	while last_RR_sum < RR_use_time && RR_use_amount < IBI_size:
		last_RR_sum += RR_arr[IBI_size - 1 - RR_use_amount]
		RR_use_amount += 1

	RR_used_arr = RR_arr.slice(IBI_size - RR_use_amount, IBI_size) # takes last "RR_use_amount" values of IBI file

	
	RR_use_amount_short = 0
	last_RR_sum = 0
	while last_RR_sum < RR_use_time_short && RR_use_amount_short < IBI_size:
		last_RR_sum += RR_arr[IBI_size - 1 - RR_use_amount_short]
		RR_use_amount_short += 1

	RR_used_arr_short = RR_arr.slice(IBI_size - RR_use_amount_short, IBI_size) # takes last "RR_use_amount_short" values of IBI file

	RR_average = 0
	for i in range(RR_use_amount):
		RR_average += RR_used_arr[i]
	RR_average = RR_average / RR_use_amount
	
	RR_average_short = 0
	for i in range(RR_use_amount_short):
		RR_average_short += RR_used_arr_short[i]
	RR_average_short = RR_average_short / RR_use_amount_short

	currentRR = str(RR_arr[IBI_size - 1])

func HR_func():
	var HR_calc = 0.0
	for RR in RR_used_arr:
		HR_calc += RR
	HR_calc = 60 / (HR_calc / RR_use_amount) * 1000
	
	return HR_calc

func RMSSD_func():
	var RMSSD_calc = 0
	
	for i in range(RR_use_amount-1):	# -1 because N elements, but N-1 places between elements
		RMSSD_calc += pow(RR_used_arr[i] - RR_used_arr[i + 1], 2)
	
	RMSSD_calc = sqrt(RMSSD_calc / (RR_use_amount-1))
	
	return RMSSD_calc

func pNNX_func(x):
	var NNX: int = 0

	for i in range(RR_use_amount-1):
		if abs(RR_used_arr[i] - RR_used_arr[i + 1]) > x: 
			NNX += 1
	var pNNX = float(NNX) / float(RR_use_amount-1) * 100
	
	return pNNX
	
func SDNN_func():
	var SDNN_calc = 0
	
	for i in range(RR_use_amount):
		SDNN_calc += pow(RR_used_arr[i] - RR_average,2)
	SDNN_calc = sqrt(SDNN_calc / RR_use_amount)

	return SDNN_calc
	
func SDNN_short_func():
	var SDNN_calc = 0
	
	for i in range(RR_use_amount_short):
		SDNN_calc += pow(RR_used_arr_short[i] - RR_average_short,2)
	SDNN_calc = sqrt(SDNN_calc / RR_use_amount_short)

	return SDNN_calc
	
func SI_func():
	var Mo = 0 		# RR median -> should be mode in original paper
	var AMo = 0		# amplitude of the modal value
	var MxDMn = (float(RR_used_arr.max()) - float(RR_used_arr.min()))/1000 # variability width

	# sorting array
	var RR_arr_sorted = RR_used_arr
	RR_arr_sorted.sort()

	var SI_array = []
	var SI_array_index = -1
	var steppedValue = 0
	var prevValue = 0

	for i in range (RR_use_amount):
		steppedValue = stepify(RR_arr_sorted[i], 50) # round current value

		if steppedValue != prevValue: 	# start new element in array
			SI_array.append([0, steppedValue])
			SI_array_index += 1

		SI_array[SI_array_index][0] += 1 # value belongs in current array
		prevValue = steppedValue

	AMo = float(100 * SI_array.max()[0]) / float(RR_use_amount)
	
	
	# Mo with mode 
	Mo = float(SI_array.max()[1]) / 1000

	# Mo with median (Kubios)
#	if RR_use_amount % 2 != 0: 			# odd RR_use_amount
#		Mo = float(RR_arr_sorted[RR_use_amount/2])
#	else:								# even RR_use_amount -> mean
#		Mo = (float(RR_arr_sorted[RR_use_amount/2]) + float(RR_arr_sorted[(RR_use_amount/2)-1])) / 2
#	Mo = float(Mo/1000)
	
	var SI_calc = sqrt(float(AMo) / (float(2 * Mo) * MxDMn))
	
	return SI_calc

func drawCharts():
	# TODO read last N values from CSV, or based on time -> easyCharts realtime plot bug...

	#$LineChart2.source = "C:/Users/hajna/HeartRateLogs/heartRateLog_2020. 9. 16. 0-15-34.csv"
	$LineChart2.plot()

func logResults():	# CSV (for plotting and review)
	
	results_file.open(folder_location.plus_file(results_filename), results_file.READ_WRITE)
	results_file.seek_end()
	results_file.store_csv_line(results_arr[results_arr.size()-1],";")
	results_file.close()

func _on_test_button_button_down():
	#drawCharts()
	pass

func dataRating(analysis_dictionary: Dictionary, data):
	# adjusting borders

	if data > analysis_dictionary[analysis_dictionary.size()-1]:
		analysis_dictionary[analysis_dictionary.size()-1] = data


	# classifying new value
	var lastGood
	var i = 0

	for key in analysis_dictionary.keys():
		if analysis_dictionary[key] < data:
			lastGood = key
			i += 1
			if analysis_dictionary.size() == i:
				#print(lastGood)
				return
		else:
			#print(lastGood)
			return

func adjust_border(current_value: float, new_value: float, compare: String):
	match compare:
		"max":
			if current_value < new_value:
				current_value = new_value
		"min":
			if current_value > new_value:
				current_value = new_value
	return current_value
