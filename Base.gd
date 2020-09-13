extends Control

onready var HR = 0
onready var currentRR = 0
onready var RR_average = 0

onready var RMSSD = 0
onready var SDNN = 0
onready var pNN50: float = 0
onready var pNN20: float = 0
onready var SI = 0

onready var RR_array = []
onready var usedRR_arr = []

onready var latest_file
onready var filePos = 0

export (int, 1, 9999) var RR_use_amount = 5 # TODO? -> = 0: all used
export (String) var folder_location = "C:/Users/hajna/HeartRateLogs"

func _ready():
	initFile(folder_location)

func _on_Timer_timeout():
	updateRR() 	# from IBI file (logfile unused)
	$RR_label.text = ("Last RR: " + currentRR)
	# https://en.wikipedia.org/wiki/Heart_rate_variability#Analysis
	# https://imotions.com/blog/heart-rate-variability/
	
	# TODO uniform time instead of same number of RR values?
	
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
	# frequencies [Hz]:  # TODO export?
		# HF: 0.15 - 0.4
		# LF: 0.04 - 0.15
		# VLF: 0 - 0.04

	# TODO detect trends, graph, separate timer, run less often?

	pass

func _on_Button_button_down():
	pass

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
			RR_array.append(int(IBI_line))

	filePos = IBI_file.get_position()

	var IBI_size = RR_array.size()

	usedRR_arr = RR_array.slice(IBI_size - RR_use_amount, IBI_size) # takes last "RR_use_amount" values of IBI file

	print_debug(usedRR_arr)

	RR_average = 0
	for i in range(RR_use_amount):
		RR_average += usedRR_arr[i]
	RR_average = RR_average / RR_use_amount

	currentRR = str(RR_array[IBI_size - 1])
	IBI_file.close()

func HR_func():
	var HR_calc = 0.0
	for RR in usedRR_arr:
		HR_calc += RR
	HR_calc = 60 / (HR_calc / RR_use_amount) * 1000
		
	return HR_calc

func RMSSD_func():
	var RMSSD_calc = 0
	
	for i in range(RR_use_amount-1):	# -1 because N elements, but N-1 places between elements
		RMSSD_calc += pow(usedRR_arr[i] - usedRR_arr[i + 1], 2)
	
	RMSSD_calc = sqrt(RMSSD_calc / (RR_use_amount-1))
	
	return RMSSD_calc

func pNNX_func(x):
	var NNX: int = 0

	for i in range(RR_use_amount-1):
		if abs(usedRR_arr[i] - usedRR_arr[i + 1]) > x: 
			NNX += 1
	var pNNX = float(NNX) / float(RR_use_amount-1) * 100
	
	return pNNX
	
func SDNN_func():
	var SDNN_calc = 0
	
	for i in range(RR_use_amount):
		SDNN_calc += pow(usedRR_arr[i] - RR_average,2)
	SDNN_calc = sqrt(SDNN_calc / RR_use_amount)

	return SDNN_calc
	
func SI_func():
	var SI_calc = 0 # Stress Index
	var AMo = 0		# amplitude of the modal value
	var Mo = 0 		# RR median -> should be mode in original paper?
	var MxDMn = (float(usedRR_arr.max()) - float(usedRR_arr.min())) # variability width

	var RR_array_sorted = usedRR_arr
	RR_array_sorted.sort()

	if RR_use_amount % 2 != 0: 			# odd RR_use_amount
		Mo = float(RR_array_sorted[RR_use_amount/2])
	else:								# even RR_use_amount -> mean
		Mo = (float(RR_array_sorted[RR_use_amount/2]) + float(RR_array_sorted[(RR_use_amount/2)-1])) / 2

	var SI_array = []
	var SI_array_index = -1
	var steppedValue = 0
	var prevValue = 0

	for i in range (RR_use_amount):
		steppedValue = stepify(RR_array_sorted[i], 50) # ...or using format strings

		if steppedValue != prevValue: 	# start new element in array
			SI_array.append(int(0))
			SI_array_index += 1

		SI_array[SI_array_index] += 1 # increment array
		prevValue = steppedValue

	AMo = float(100 * SI_array.max()) / float(RR_use_amount)

	SI_calc = sqrt(float(AMo) / float(2 * Mo) * MxDMn)
# Stress index (SI) = AMo / 2Mo x MxDMn. Where AMo is the amplitude of the modal
# value and represents the percentage in comparison to all other RR intervals. 
# Mo (in the formula 2Mo) is the modal value for the duration of a RR interval 
# that has been measured the most often. MxDMn is the variability width, or in 
# other words the difference between the maximum and minimum measured RR interval. 

	return SI_calc
