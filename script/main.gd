extends Node

var peer = PacketPeerUDP.new()

@export var joystick1: VirtualJoystick
@export var joystick2: VirtualJoystick
var ml
var mr
var a
var l
var connected = true
var streaming = false

func _ready():
	#peer.set_dest_address("127.0.0.1", 5000)
	#peer.set_dest_address("10.42.0.1", 5000)
	%StatusColor.color = Color.DARK_RED
	peer.set_dest_address("192.168.178.105", 5000)
	while not connected:
		sendToPi("handshake")
		await get_tree().create_timer(.1).timeout
		if peer.get_available_packet_count() > 0:
			print(peer.get_packet().get_string_from_utf8())
			%StatusColor.color = Color.WEB_GREEN
			connected = true

func _process(delta:float):
	pass
	
func _physics_process(delta: float):
	if peer.get_available_packet_count() > 0:
		print("Connected: %s" % peer.get_packet().get_string_from_utf8())
	
func _input(event: InputEvent) -> void:
	a = joystick1.output.angle()
	l = joystick1.output.length()
	mr = clamp( ( sin(-a) -cos(-a) ) * l, -1, 1)
	ml = clamp( ( sin(a-PI) -cos(a-PI) ) * l, -1, 1)
	$VBoxContainer/HBoxContainer2/ProgressBar.value = ml
	$VBoxContainer/HBoxContainer2/ProgressBar2.value = mr
	$VBoxContainer/HBoxContainer3/ProgressBar3.value = -ml
	$VBoxContainer/HBoxContainer3/ProgressBar4.value = -mr
	# vorne links, vorne rechts, hinten links, hinten rechts
	sendToPi("motors#"+str(ml)+"#"+str(mr)+"#"+str(ml)+"#"+str(mr))
	

func _on_v_slider_value_changed(value: float) -> void:
	sendToPi(str(value))

func _on_v_slider_2_value_changed(value: float) -> void:
	sendToPi(str(value))

func sendToPi(data: String):
	peer.put_packet(data.to_utf8_buffer())
	print(data.to_utf8_buffer().get_string_from_utf8())

func _on_v_slider1_value_changed(value: float) -> void:
	sendToPi(str(value))


func _on_streaming_toggled(toggled_on: bool) -> void:
	streaming = toggled_on
	while streaming:
		await get_tree().create_timer(.1).timeout
		%Video.getFrame()
		print("frame")	


func _greifer_auf() -> void:
	sendToPi("greifer#-1")


func _greifer_zu() -> void:
	sendToPi("greifer#1")


func _greifer_stop() -> void:
	sendToPi("greifer#0")
