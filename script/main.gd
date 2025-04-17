extends Node

var peer = PacketPeerUDP.new()

@export var joystick1: VirtualJoystick
@export var joystick2: VirtualJoystick

func _ready():
	#peer.set_dest_address("127.0.0.1", 5000)
	peer.set_dest_address("10.42.0.1", 5000)

func _process(delta:float):
	if peer.get_available_packet_count() > 0:
		print("Connected: %s" % peer.get_packet().get_string_from_utf8())
	var vek = (Input.get_vector("ui_down", "ui_up","ui_left", "ui_right", 0)*100).round()/100
	print(joystick2.output.angle())


func _on_button_pressed() -> void:
	while true:
		await get_tree().create_timer(.1).timeout
		$VBoxContainer/TextureRect.getFrame()
	print("frame")

func _on_v_slider_value_changed(value: float) -> void:
	sendToPi(1,value)

func _on_v_slider_2_value_changed(value: float) -> void:
	sendToPi(2,value)

func sendToPi(port: int, data: float):
	print(port, " ", data)
	peer.put_packet((str(port) + ":" + str(data).pad_decimals(2)).to_utf8_buffer())

func _on_v_slider1_value_changed(value: float) -> void:
	sendToPi(1, value)
