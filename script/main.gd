extends Node

var peer = PacketPeerUDP.new()

@export var joystick1: VirtualJoystick
@export var joystick2: VirtualJoystick
var ml
var mr
var a
var l
var x
var y
var connected = false
var connecting = false
var timer
var lastPing = -1
var lastCommand = "ping"
var packet

func _ready():
	#peer.set_dest_address("127.0.0.1", 5000)
	#peer.set_dest_address("10.42.0.1", 5000)
	if not connected: %StatusColor.color = Color.DARK_RED
	peer.set_dest_address("192.168.36.202", 5000)
	sendToPi("handshake")
	handleConnection()

func handleConnection():
	while connecting:
		match connected:
			true:
				if peer.get_available_packet_count() > 0:
					for i in peer.get_available_packet_count():
						packet = peer.get_packet().get_string_from_utf8().split("#")
						match packet[0]:
							"ping":
								print("ping recieved")
								lastPing = 0
							"mess":
								print("messwert")
								%SensorData.set_data(packet[1],packet[2],packet[3],packet[4])
			false:
				%StatusColor.color = Color.DARK_RED
				sendToPi("handshake")
				sendToPi("ping")
				if peer.get_packet().get_string_from_utf8() == "ping":
					%StatusColor.color = Color.WEB_GREEN
					connected = true
					lastPing = 0
		await get_tree().create_timer(.2).timeout

func _process(delta:float):
	pass
	
func _physics_process(delta: float):
	#tickrate = 20/s
	sendToPi(lastCommand)
	lastPing += 50
	if lastPing > 4000:
		connected = false
	%LastPingLabel.text = "Ping: "+str(lastPing)+"ms"

func sendToPi(data: String):
	if data != lastCommand:
		peer.put_packet(data.to_utf8_buffer())
		print(data)
	if data != "ping" and data != "handshake":
		lastCommand = data

func _greifer_auf() -> void:
	sendToPi("greifer#-1")

func _greifer_zu() -> void:
	sendToPi("greifer#1")

func _greifer_stop() -> void:
	sendToPi("greifer#0")

func _on_connection_toggle(toggled_on: bool) -> void:
	connecting = toggled_on
	if connecting:
		handleConnection()


func _on_joystick_2_input(event: InputEvent) -> void:
	x = joystick2.output.x
	y = -joystick2.output.y
	# vorne links, vorne rechts, hinten links, hinten rechts
	
	sendToPi("arm#"+str(x)+"#"+str(y))

func _on_joystick1_input(event: InputEvent) -> void:
	a = joystick1.output.angle()
	l = joystick1.output.length()
	mr = clamp( ( sin(-a) -cos(-a) ) * l, -1, 1)
	ml = clamp( ( sin(a-PI) -cos(a-PI) ) * l, -1, 1)
	var m1 = 0
	var m2 = 0
	var m3 = 0
	var m4 = 0
	if %VorneLinks.active:
		m1 = ml
	if %VorneRechts.active:
		m2 = mr
	if %HintenLinks.active:
		m3 = ml
	if %HintenRechts.active:
		m4 = mr
	%VorneLinks.new_value(m1)
	%VorneRechts.new_value(m2)
	%HintenLinks.new_value(m3)
	%HintenRechts.new_value(m4)
	setDrivingMotors(m1,m2,m3,m4)

func setDrivingMotors(m1:float, m2:float,m3:float,m4:float):
	# vorne links, vorne rechts, hinten links, hinten rechts
	sendToPi("motors#"+str(m1)+"#"+str(m2)+"#"+str(m3)+"#"+str(m4))

func _on_stop_button_down() -> void:
	sendToPi("stop")
	pass # Replace with function body.


func _on_distance_reset() -> void:
	sendToPi("distreset")
