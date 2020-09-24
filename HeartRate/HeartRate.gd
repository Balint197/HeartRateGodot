extends Control

# export (int, 1, 9999) var RR_use_amount = 10 # using RR_use_time instead
onready var RR_use_amount = 0
export (int, 1, 999999999) var RR_use_time = 30000 # TODO? -> = 0: all used

# !!! modify values here, export is broken (gives null sometimes)
export (Dictionary) var RMSSD_borders = {
	RMSSD_verylow = 0,
	RMSSD_low     = 50,
	RMSSD_mid     = 100,
	RMSSD_high    = 150
}

export (Dictionary) var SDNN_borders = {
	SDNN_verylow = 0,
	SDNN_low     = 10,
	SDNN_mid     = 20,
	SDNN_high    = 30
}

export (Dictionary) var PNN50_borders = {
	pNN50_verylow = 0,
	pNN50_low     = 10,
	pNN50_mid     = 20,
	pNN50_high    = 30
}

export (Dictionary) var PNN20_borders = {
	pNN20_verylow = 0,
	pNN20_low     = 10,
	pNN20_mid     = 20,
	pNN20_high    = 30
}

export (Dictionary) var SI_borders = {
	SI_verylow = 0,
	SI_low     = 10,
	SI_mid     = 20,
	SI_high    = 30
}

### INIT VARS ###

onready var currentRR = 0
onready var RR_average = 0
onready var HR = 0
onready var RMSSD = 0
onready var SDNN = 0
onready var pNN50: float = 0
onready var pNN20: float = 0
onready var SI = 0

onready var RR_arr = []
onready var RR_used_arr = []
onready var results_arr = []

onready var latest_file
onready var filePos = 0

onready var time = str(OS.get_datetime().year) + ". " + str(OS.get_datetime().month) \
	+ ". " + str(OS.get_datetime().day) + ". " + str(OS.get_datetime().hour) \
	+ "-"  + str(OS.get_datetime().minute) + "-" + str(OS.get_datetime().second)

onready var results_file = File.new()
onready var results_filename = "HeartRateAnalysisLog_" + time + ".csv"

export (String) var folder_location = "C:/Users/hajna/HeartRateLogs"

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
	SI = SI_func()# Baevsky’s stress index @TODO!!! - nem ua. mint Kubios
		# non-sqrt: small load: 1.5x-2x increase, big: 5-10x
	$analysis_container/SI_label.text = ("SI: " + str(SI))
	
	### FREQUENCY domain ### -> measure of sympathetic nervous system activity
	# frequencies [Hz]:  # TODO FFT PythonScript (bug)
		# HF: 0.15 - 0.4
		# LF: 0.04 - 0.15
		# VLF: 0 - 0.04


	# TODO detect trends, graph, separate timer, run less often?
	
	
	# writing results to array
	results_arr.append([1,HR,RMSSD,SDNN,pNN50,pNN20,SI])
	
	logResults()
	#drawCharts()
	
	dataRating(RMSSD_borders, 250)
	dataRating(SDNN_borders, 5)
	dataRating(PNN50_borders, 5)
	dataRating(PNN20_borders, 5)
	dataRating(SI_borders, 5)


func initFile(path):
	var latest_date = 0
	var date_modified
	var dir = Directory.new()
	if dir.open(path) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if !dir.current_is_dir() && file_name.get_extension() == "txt": # IBI only?
				print("Found file: " + file_name)
				print("File extension: " + file_name.get_extension())

				var file = File.new()
				date_modified = file.get_modified_time(path.plus_file(file_name))
				print("File last modified: " + str(date_modified) + "\n")
				
				if date_modified > latest_date:
					latest_date = date_modified
					latest_file = file_name

			file_name = dir.get_next()
		print("Latest file: " + latest_file + "\n")
	else:
		print("An error occurred when trying to access the path.")

func updateRR():

	var IBI_file = File.new()
	IBI_file.open(folder_location.plus_file(latest_file), IBI_file.READ)
	IBI_file.seek(filePos)

	while not IBI_file.eof_reached():
		var IBI_line = IBI_file.get_line()
		if IBI_line != "":	# needed for last line (\n in HeartRate program)
			RR_arr.append(int(IBI_line))

	filePos = IBI_file.get_position()

	var IBI_size = RR_arr.size()

	RR_use_amount = 0

	var last_RR_sum = 0
	while last_RR_sum < RR_use_time && RR_use_amount < IBI_size:
		last_RR_sum += RR_arr[IBI_size - 1 - RR_use_amount]
		RR_use_amount += 1

	RR_used_arr = RR_arr.slice(IBI_size - RR_use_amount, IBI_size) # takes last "RR_use_amount" values of IBI file

	print_debug(RR_used_arr)

	RR_average = 0
	for i in range(RR_use_amount):
		RR_average += RR_used_arr[i]
	RR_average = RR_average / RR_use_amount

	currentRR = str(RR_arr[IBI_size - 1])
	IBI_file.close()

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
	
func SI_func():
	var Mo = 0 		# RR median -> should be mode in original paper?
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

	print(str(SI_array.max()[0]))
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
	# TODO read last N values from CSV, or based on time -> easyCharts plot bug...

	#$LineChart2.source = "C:/Users/hajna/HeartRateLogs/heartRateLog_2020. 9. 16. 0-15-34.csv"
	$LineChart2.plot()

func logResults():	# CSV (for plotting and review)
	
	results_file.open(folder_location.plus_file(results_filename), results_file.READ_WRITE)
	results_file.seek_end()
	results_file.store_csv_line(results_arr[results_arr.size()-1],";")
	results_file.close()

func _on_test_button_button_down():
	#drawCharts()
	fft([1.0, 1.0, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0])

func fft(x):
	
#	var N = x.size()
#	if N >= 1: return x
#	var even = fft(x[0%2])
#	var odd  = fft(x[1%2])
#	T = [exp(-2j*PI*k/N) * odd[k] for k in range(N//2)]


#def fft(x):
#
#    N = len(x)
#    if N <= 1: return x
#    even = fft(x[0::2])
#    odd =  fft(x[1::2])
#    T= [exp(-2j*pi*k/N)*odd[k] for k in range(N//2)]
#    return [even[k] + T[k] for k in range(N//2)] + \
#           [even[k] - T[k] for k in range(N//2)]
#
#print( ' '.join("%5.3f" % abs(f) 
#                for f in fft([1.0, 1.0, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0])) )
				
	pass

func dataRating(analysis_dictionary: Dictionary, data):
	
	var lastGood
	var i = 0

	for key in analysis_dictionary.keys():
		if analysis_dictionary[key] < data:
			lastGood = key
			i += 1
			if analysis_dictionary.size() == i:
				print(lastGood)
				return
		else:
			print(lastGood)
			return
