extends Control


onready var currentHR = 0
onready var currentRR = 0

func _on_Timer_timeout():
	# updateHR() # from logfile
	updateRR() # from IBI
	pass
	
func updateHR():
	
	var csv_array = []
	var csv_file = File.new();
	
	csv_file.open("C:/Users/hajna/HeartRateLogs/heartrateCSV.csv", csv_file.READ)
	
	while not csv_file.eof_reached():
		var csv_row = []
		var csv_line = csv_file.get_line()
		for element in csv_line.split(","):
			csv_row.append(element);
			# If you know the data will always be floats, use the following instead of the above.
			#csv_row.append(float(element))
		csv_array.append(csv_row);
	# Then you can access the array like this:
	# (Assuming there is something at that position)
	#print ("Example value at X=3 Y=2 : ", csv_array[3][2]);
	# To get the size of the data (assuming every row has the same size), you just do this:
	var csv_size_column = csv_array.size();		# number of rows
	var _csv_size_row = csv_array[0].size();		#number of columns
	var csv_lastRow = csv_size_column-2;
	
	currentHR = str(csv_array[csv_lastRow][2])
	
	$HR_label.text = currentHR
	
func updateRR():
	var RR_array = []
	var IBI_file = File.new()
	
	IBI_file.open("C:/Users/hajna/HeartRateLogs/IBI.txt", IBI_file.READ)
	
	while not IBI_file.eof_reached():
		var IBI_line = IBI_file.get_line()
		RR_array.append(IBI_line)
	
	var IBI_size = RR_array.size()
	var IBI_lastRow = IBI_size-1 # last IBI value

	currentRR = str(RR_array[IBI_lastRow])
	$RR_label.text = currentRR
