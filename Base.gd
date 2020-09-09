extends Control

onready var currentHR = 0
onready var currentRR = 0
onready var RR_array = []
onready var usedRR_arr = []

onready var latest_file
onready var filePos = 0

export (int, 1, 9999) var RR_use_amount = 5
export (String) var folder_location = "C:/Users/hajna/HeartRateLogs"

func _ready():
	initFile(folder_location)

func _on_Timer_timeout():
	updateRR() 	# from IBI file (logfile unused)
	
	# https://en.wikipedia.org/wiki/Heart_rate_variability#Analysis
	# https://imotions.com/blog/heart-rate-variability/
	
	# TIME domain
	HR()
	RMSSD() 
	# SDNN() # add maybe?
	# Baevsky’s stress index
	
	# FREQUENCY domain measurements -> measure of sympathetic nervous system activity
	# frequencies [Hz]:  # TODO export?
		# HF: 0.15 - 0.4
		# LF: 0.04 - 0.15
		# VLF: 0 - 0.04

	# TODO detect trends, graph, separate timer, run less often?

	pass

func _on_Button_button_down():
	RMSSD()

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
		print("Latest file: " + latest_file)
	else:
		print("An error occurred when trying to access the path.")

func updateRR():

	var IBI_file = File.new()
	IBI_file.open(folder_location.plus_file(latest_file), IBI_file.READ)
	IBI_file.seek(filePos)

	while not IBI_file.eof_reached():
		var IBI_line = IBI_file.get_line()
		if IBI_line != "":	# needed for last line (\n in HeartRate program)
			RR_array.append(IBI_line)

	filePos = IBI_file.get_position()

	var IBI_size = RR_array.size()

	usedRR_arr = RR_array.slice(IBI_size - RR_use_amount, IBI_size) # takes last "RR_use_amount" values of IBI file

	print_debug(usedRR_arr)

	currentRR = str(RR_array[IBI_size - 1])
	$RR_label.text = currentRR
	IBI_file.close()

func HR():
	currentHR = 0.0
	for RR in usedRR_arr:
		currentHR += int(RR)
	currentHR = 60 / (currentHR / RR_use_amount) * 1000
	print(str(currentHR))
	
	$HR_label.text = str(int(currentHR))

func RMSSD():
	var RMSSD = 0
	
	for i in range(RR_use_amount-1):	# -1 because N elements, but N-1 places between elements
		RMSSD += pow(int(usedRR_arr[i]) - int(usedRR_arr[i + 1]), 2)
	
	RMSSD = sqrt(RMSSD)
	$RMSSD_label.text = str(RMSSD)

