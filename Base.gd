extends Control

onready var currentHR = 0
onready var currentRR = 0
onready var usedRR_arr = []

export var RR_use_amount = 5 # TODO only for RR currently, add to HR

func _on_Timer_timeout():
	updateHR() 	# from logfile 
				# can also calculate custom HR from RR
	updateRR() 	# from IBI file
	
	# https://en.wikipedia.org/wiki/Heart_rate_variability#Analysis
	# https://imotions.com/blog/heart-rate-variability/
	
	RMSSD() # TODO detect trend? separate timer, run less often?
	# SDNN() # add maybe?
	
	# frequency domain measurements -> measure of sympathetic nervous system activity
	# frequencies [Hz]:  # TODO export?
		# HF: 0.15 - 0.4
		# LF: 0.04 - 0.15
		# VLF: 0.0033 - 0.04

func updateHR():
	
	var csv_array = []
	var csv_file = File.new();
	
	csv_file.open("C:/Users/hajna/HeartRateLogs/heartrateCSV.csv", csv_file.READ)
	
	while not csv_file.eof_reached():
		var csv_row = []
		var csv_line = csv_file.get_line()
		if csv_line != "":	# needed for last line (\n in HeartRate program)
			for element in csv_line.split(","):
				csv_row.append(element);
			csv_array.append(csv_row);

	var csv_size_column = csv_array.size();		# number of rows
	var _csv_size_row = csv_array[0].size();	# number of columns
	var csv_lastRow = csv_size_column-1;
	
	currentHR = str(csv_array[csv_lastRow][2])	
	$HR_label.text = currentHR
	
func updateRR():
	var RR_array = []
	var IBI_file = File.new()

	# TODO get_modified_time -> use the latest reading, timestamp
	# TODO put file open outside updateRR()  if possible?
	IBI_file.open("C:/Users/hajna/HeartRateLogs/IBI.txt", IBI_file.READ)
	
	# TODO save byte position of last read, only read data after that
	while not IBI_file.eof_reached():
		var IBI_line = IBI_file.get_line()
		if IBI_line != "":	# needed for last line (\n in HeartRate program)
			RR_array.append(IBI_line)
	
	# TODO szures?
	
	var IBI_size = RR_array.size()
	var IBI_lastRow = IBI_size-1 # last IBI value in file

	usedRR_arr = RR_array.slice(IBI_size-RR_use_amount, IBI_size) # takes last N values of IBI file
	print_debug(usedRR_arr)

	currentRR = str(RR_array[IBI_lastRow])
	$RR_label.text = currentRR

func RMSSD():
	var RMSSD = 0
	
	for i in range(RR_use_amount-1):	# -1 because N elements, but N-1 places between elements
		RMSSD += pow(int(usedRR_arr[i]) - int(usedRR_arr[i + 1]), 2)
	
	RMSSD = sqrt(RMSSD)
	$RMSSD_label.text = str(RMSSD)

func _on_Button_button_down():
	RMSSD()
