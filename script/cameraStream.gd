#extends TextureRect
#
#var image = Image.new()
#
#var index = 0
#
#var streaming = false
#
#var http_request
#
#func _ready():
	## Create an HTTP request node and connect its completion signal.
	#http_request = HTTPRequest.new()
	#add_child(http_request)
	#http_request.request_completed.connect(self._http_request_completed)
	#
#func _physics_process(delta: float) -> void:
	#if streaming:
		#getFrame()
		#
#func getFrame():
	#var error
	#match index:
		#0:
			#error = http_request.request("http://roverpi.local:1984/api/frame.jpeg?src=mjpeg2")
		#1:
			#error = http_request.request("http://roverpi.local:1984/api/frame.jpeg?src=mjpeg1")
	#error = http_request.request("https://fastly.picsum.photos/id/316/200/200.jpg?hmac=f0i62VkjVy8OPLP77Xf7mdZa3UBNlTOXFm9WpDMOiiA")
	#if error != OK:
		#push_error("An error occurred in the HTTP request.")
	#elif error == OK:
		#print("ok")
#
#
#func _http_request_completed(result, response_code, headers, body):
	#if result != HTTPRequest.RESULT_SUCCESS:
		#push_error("Image couldn't be downloaded. Try a different image.")
	#var error = image.load_jpg_from_buffer(body)
	#if error != OK:
		#push_error("Couldn't load the image.")
	#texture = ImageTexture.create_from_image(image)
	#print(result)
#
#
#func _on_streaming_toggled(toggled_on: bool) -> void:
	#streaming = toggled_on
