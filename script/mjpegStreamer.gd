extends TextureRect

var streaming = true

var host_ip = "roverpi.local"
var port = 1984
var path = "/api/stream.mjpeg?src=mjpeg0"

var tcp_client: StreamPeerTCP = StreamPeerTCP.new()
var buffer = PackedByteArray() # Data buffer for incremental reading

var tex = ImageTexture.new()

var lastSize = 1000000

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

func decode(data: PackedByteArray) -> String:
	var output = ""
	for symbol in data:
		if utf8dict.has(symbol):
			output += utf8dict[symbol]
		else:
			output += "_"
	return output

# Connect to the MJPEG stream server
func connect_to_host(ip: String, port: int) -> bool:
	print("connect")
	tcp_client.set_no_delay(true)
	var err = await tcp_client.connect_to_host(ip, port)
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

	print("Connected to ", ip, ":", port)
	return true

# Send an HTTP GET request to start the MJPEG stream.
func request_mjpeg_stream(path: String, host: String):
	print("req")
	var request = "GET " + path + " HTTP/1.1\r\n"
	request += "Host: " + host + "\r\n"
	request += "Accept: multipart/x-mixed-replace\r\n"
	request += "Connection: keep-alive\r\n\r\n"
	
	var data = request.to_utf8_buffer()
	tcp_client.set_no_delay(true)
	var bytes_sent = tcp_client.put_data(data)
	tcp_client.poll()
	print("error ",bytes_sent)



func fill_buffer():
	var bytes = tcp_client.get_available_bytes()
	print("available bytes: ",bytes)
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
						if buffer[i+3] == 103:
							if buffer[i+4] == 116:
								if buffer[i+5] == 104:
									found = true
								else: offset = i+1
							else: offset = i+1
						else: offset = i+1
					else: offset = i+1
				else: offset = i+1
			print("gefunden")
			var stringsize = decode(buffer.slice(i+8, i+14))
			lastSize = int(stringsize)
			print("content size: ",lastSize)
			buffer = buffer.slice(i, i+15+lastSize)
			var image = Image.new()
			var error = image.load_jpg_from_buffer(buffer)
			if error == 0:
				print("setting image")
				tex.set_image(image)
				self.set_texture(tex.create_from_image(image))
				buffer.clear()

func _process(delta):
	pass
	# In a real application you would probably call process_stream() in _process
	# or in a separate thread, to continuously handle incoming data.

func _physics_process(delta: float) -> void:
	if streaming:
		fill_buffer()
	#process_stream()

func _ready():
	if streaming:
		print("stream")
		if await connect_to_host(host_ip, port):
			request_mjpeg_stream(path, host_ip)
	await get_tree().create_timer(5).timeout
	# Change these values to match your MJPEG stream server's IP, port, and path.


func _on_streaming_toggled(toggled_on: bool) -> void:
	streaming = toggled_on
