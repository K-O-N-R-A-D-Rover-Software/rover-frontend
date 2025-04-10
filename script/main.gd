extends Node

var peer = PacketPeerUDP.new()

func _ready():
	peer.set_dest_address("0.0.0.0", 5000)

func _on_timer_timeout() -> void:
	pass


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
	
