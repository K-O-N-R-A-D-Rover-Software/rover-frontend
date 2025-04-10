extends TextureRect

var image = Image.new()

var index = 0

func _ready():
	pass
	# Create an HTTP request node and connect its completion signal.
		
func getFrame():
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(self._http_request_completed)
	var error
	match index:
		0:
			error = http_request.request("http://raspi.local:1984/api/stream.mjpeg?src=1")
			index = 0
		1:
			error = http_request.request("http://roverpi.local:1984/api/frame.jpeg?src=2")
			index = 0
#	var error = http_request.request("https://fastly.picsum.photos/id/316/200/200.jpg?hmac=f0i62VkjVy8OPLP77Xf7mdZa3UBNlTOXFm9WpDMOiiA")
	if error != OK:
		push_error("An error occurred in the HTTP request.")
	elif error == OK:
		print("ok")


func _http_request_completed(result, response_code, headers, body):
	if result != HTTPRequest.RESULT_SUCCESS:
		push_error("Image couldn't be downloaded. Try a different image.")
	var error = image.load_jpg_from_buffer(body)
	if error != OK:
		push_error("Couldn't load the image.")
	texture = ImageTexture.create_from_image(image)
	print(result)
