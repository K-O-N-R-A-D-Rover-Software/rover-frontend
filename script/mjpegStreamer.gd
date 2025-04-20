extends TextureRect

var streaming = true

var host_ip = "192.168.178.105"
var port = 1984
var path = "/api/stream.mjpeg?src=mjpeg1"

var tcp_client: StreamPeerTCP = StreamPeerTCP.new()
var buffer = PackedByteArray() # Data buffer for incremental reading

# Connect to the MJPEG stream server
func connect_to_host(ip: String, port: int) -> bool:
	print("connect")
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
	process_stream()


# Reading from the stream and splitting out JPEG images
# (This is a very simplified parser. A real implementation would need to
# handle partial data, boundaries split across multiple reads, etc.)
func process_stream():
	# Keep reading data available on the socket.
	while tcp_client.get_status() == StreamPeerTCP.STATUS_CONNECTED and tcp_client.get_available_bytes() > 0:
		var chunk = tcp_client.get_data(tcp_client.get_available_bytes())
		if chunk.size() > 0:
			buffer.append_array(chunk)
	
	# Now process the buffer to look for headers and JPEG frame boundaries.
	# Typically, after the initial HTTP response header, frames come separated by
	# boundaries like "--myboundary". You need to locate these boundaries.
	# A very basic approach might be to convert the buffer to a string and split it:
	
	var data_str = buffer.get_string_from_utf8()
	# Check if we have read the HTTP response header (ends with "\r\n\r\n")
	if data_str.find("\r\n\r\n") != -1:
		# Only process after the header if you haven't already done so.
		var header_end = data_str.find("\r\n\r\n") + 4
		var stream_data = data_str.substr(header_end, data_str.length() - header_end)
		# Suppose the boundary marker is known (for example, "--myboundary").
		var boundary = "--myboundary"
		# Split the multipart data by the boundary:
		var parts = stream_data.split(boundary)
		for part in parts:
			# Each part will start with its own HTTP-like header followed by the JPEG data.
			if part.strip_edges() == "":
				continue
			# Separate header from body:
			var header_end_index = part.find("\r\n\r\n")
			if header_end_index != -1:
				var part_header = part.substr(0, header_end_index).strip_edges()
				var jpeg_data_str = part.substr(header_end_index + 4, part.length() - header_end_index - 4)
				# Convert the JPEG data string back to a byte array.
				var jpeg_data = jpeg_data_str.to_utf8()  # Note: this may not work correctly as JPEG is binary.
				
				# A more proper solution is to work directly on the raw byte array to locate 
				# the header boundaries rather than converting to/from strings.
				# Once you have jpeg_data, you can convert it to an Image.
				var image = Image.new()
				var err = image.load_jpg_from_buffer(jpeg_data)
				if err == OK:
					print("Loaded a JPEG frame!")
					texture = image
					# Now you can use the image, e.g. update a texture.
					# ...
				else:
					print("Failed to load JPEG from frame.")
		# After processing, clear the buffer (or remove the processed part).
		buffer = PackedByteArray()
	
	# If your data is incomplete, you'll need to wait for more data to arrive.
	
	
func _process(delta):
	# In a real application you would probably call process_stream() in _process
	# or in a separate thread, to continuously handle incoming data.
	process_stream()


func _ready():
	if streaming:
		print("stream")
		if await connect_to_host(host_ip, port):
			request_mjpeg_stream(path, host_ip)
	# Change these values to match your MJPEG stream server's IP, port, and path.
