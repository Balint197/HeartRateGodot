extends Control


onready var HR = 0

func _on_Timer_timeout():
	updateHR()

func updateHR():
	
	var csv_array = []
	var csv_file = File.new();
	
	
	#csv_file.open("C:\Users\hajna\heartrateCSV.csv", csv_file.READ)
	csv_file.open("res://heartrateCSV.csv", csv_file.READ)
	
	
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
	var csv_size_column = csv_array.size();
	var csv_size_row = csv_array[0].size();
	
	
	
	
	$Label.text = str(csv_array[10][2])
