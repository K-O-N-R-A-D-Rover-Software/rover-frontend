extends Node

var peer = PacketPeerUDP.new()

@export var joystick1: VirtualJoystick
@export var joystick2: VirtualJoystick
var ml
var mr
var a
var l
var connected

func _ready():
	#peer.set_dest_address("127.0.0.1", 5000)
	#peer.set_dest_address("10.42.0.1", 5000)
	%StatusColor.color = Color.DARK_RED
	peer.set_dest_address("192.168.178.105", 5000)
	sendToPi(1,"handshake")
	connected = false

func _process(delta:float):
	if peer.get_available_packet_count() > 0:
		print("Connected: %s" % peer.get_packet().get_string_from_utf8())
	
func _physics_process(delta: float):
	pass
	
func _input(event: InputEvent) -> void:
	a = round(joystick1.output.angle() * 1000)/1000
	l = round(joystick1.output.length() * 1000)/1000
	mr = clamp( ( sin(-a) -cos(-a) ) * l, -1, 1)
	ml = clamp( ( sin(a-PI) -cos(a-PI) ) * l, -1, 1)
	$VBoxContainer/HBoxContainer2/ProgressBar.value = ml
	$VBoxContainer/HBoxContainer2/ProgressBar2.value = mr
	$VBoxContainer/HBoxContainer3/ProgressBar3.value = -ml
	$VBoxContainer/HBoxContainer3/ProgressBar4.value = -mr

func _on_button_pressed() -> void:
	while true:
		await get_tree().create_timer(.1).timeout
		$VBoxContainer/StatusColor/Video.getFrame()
	print("frame")

func _on_v_slider_value_changed(value: float) -> void:
	sendToPi(1,str(value))

func _on_v_slider_2_value_changed(value: float) -> void:
	sendToPi(2,str(value))

func sendToPi(port: int, data: String):
	peer.put_packet((str(port) + "#" + data).to_utf8_buffer())
	print((str(port) + "#" + data).to_utf8_buffer())

func _on_v_slider1_value_changed(value: float) -> void:
	sendToPi(1, str(value))
