extends RichTextLabel

func set_data(temperature, pressure, humidity, distance):
	text = str(temperature)+"°C\n"+str(pressure)+"hPa\n"+str(humidity)+"%\n"+str(distance)+"m"
