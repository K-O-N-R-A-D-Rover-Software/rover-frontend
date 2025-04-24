extends TextureRect

var streaming = false

var thread: Thread

var port = 1984
var streamnumber = 0
var path = "/api/stream.mjpeg?src=mjpeg"
var host = "roverpi.local"

var tcp_client: StreamPeerTCP = StreamPeerTCP.new()
var buffer = PackedByteArray() # Data buffer for incremental reading

var tex = ImageTexture.new()

var lastSize = 500000

var utf8dict = {
	32: " ",
	45: "-",
	48: "0",
	49: "1",
	50: "2",
	51: "3",
	52: "4",
	53: "5",
	54: "6",
	55: "7",
	56: "8",
	57: "9",
	
	58: ":",
	
	65: "A",
	66: "B",
	67: "C",
	68: "D",
	69: "E",
	70: "F",
	71: "G",
	72: "H",
	73: "I",
	74: "J",
	75: "K",
	76: "L",
	77: "M",
	78: "N",
	79: "O",
	80: "P",
	81: "Q",
	82: "R",
	83: "S",
	84: "T",
	85: "U",
	86: "V",
	87: "W",
	88: "X",
	89: "Y",
	90: "Z",

	97: "a",
	98: "b",
	99: "c",
	100: "d",
	101: "e",
	102: "f",
	103: "g",
	104: "h",
	105: "i",
	106: "j",
	107: "k",
	108: "l",
	109: "m",
	110: "n",
	111: "o",
	112: "p",
	113: "q",
	114: "r",
	115: "s",
	116: "t",
	117: "u",
	118: "v",
	119: "w",
	120: "x",
	121: "y",
	122: "z",
}

func _ready():
	if streaming:
		print("stream")
		if await connect_to_host():
			request_mjpeg_stream()
	# Change these values to match your MJPEG stream server's IP, port, and path.

func decode(data: PackedByteArray) -> String:
	var output = ""
	for symbol in data:
		if utf8dict.has(symbol):
			output += utf8dict[symbol]
		else:
			output += "_"
	return output

# Connect to the MJPEG stream server
func connect_to_host() -> bool:
	print("connecting")
	tcp_client = StreamPeerTCP.new()
	tcp_client.set_no_delay(true)
	var err = await tcp_client.connect_to_host(host, 1984)
	print(err)
	print(tcp_client.get_status())
	print(tcp_client.get_connected_host())
	if err != OK:
		push_error("Failed to start connection: error " + str(err))
		return false

	# Wait until the connection is fully established.
	while tcp_client.get_status() == StreamPeerTCP.STATUS_CONNECTING:
		print(tcp_client.get_status())
		tcp_client.poll()
		await get_tree().create_timer(.1).timeout

	if tcp_client.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		push_error("Not connected")
		return false

	print("Connected to ", host, ":")
	return true

# Send an HTTP GET request to start the MJPEG stream.
func request_mjpeg_stream():
	print("req")
	var request = "GET " + path + str(streamnumber) + " HTTP/1.1\r\n"
	request += "Host: " + host + "\r\n"
	request += "Accept: multipart/x-mixed-replace\r\n"
	request += "Connection: keep-alive\r\n\r\n"
	
	var data = request.to_utf8_buffer()
	tcp_client.set_no_delay(true)
	var error = tcp_client.put_data(data)
	tcp_client.poll()
	print("request error ",error)
	thread = Thread.new()
	thread.start(stream.bind())


func stream():
	print("stream")
	while streaming:
		var bytes = tcp_client.get_available_bytes()
		var chunk = tcp_client.get_data(bytes)
		tcp_client.poll()
		if chunk.size() > 0:
			#print("chunk ", chunk)
			buffer.append_array(chunk[1])
			print("buffer length: ",buffer.size())
			if buffer.size() > lastSize+20000:
				var offset = 0
				var found = false
				var i = 0
				while !found and offset < buffer.size():
					i = buffer.find(76, offset)
					if buffer[i+1] == 101:
						if buffer[i+2] == 110:
										found = true
						else: offset = i+1
					else: offset = i+1
					
				var stringsize = decode(buffer.slice(i+8, i+14))
				lastSize = int(stringsize)
				print("content size: ",lastSize)
				buffer = buffer.slice(i, i+15+lastSize)
				var image = Image.new()
				var error = image.load_jpg_from_buffer(buffer)
				if error == 0:
					tex.set_image(image)
					self.set_texture(tex.create_from_image(image))
					buffer.clear()
		await get_tree().create_timer(.032).timeout
	return


func _on_streaming_toggled(toggled_on: bool) -> void:
	streaming = toggled_on

func _on_camera_changed() -> void:
	streaming = false
	if thread and thread.is_started():
		thread.wait_to_finish()
	streamnumber = (streamnumber+1)%3
	print(streamnumber)
	await get_tree().create_timer(.5).timeout
	streaming = true
	if await connect_to_host():
		request_mjpeg_stream()
