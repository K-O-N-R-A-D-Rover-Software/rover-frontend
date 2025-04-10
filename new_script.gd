extends Node
# Main scene.

# Create the two peers.
var p1 := WebRTCPeerConnection.new()
var ch1 := p1.create_data_channel("chat", { "id": 1, "negotiated": true })

func _ready() -> void:
	print(p1.create_data_channel("chat", { "id": 1, "negotiated": true }))
	# Connect P1 session created to itself to set local description.
	p1.session_description_created.connect(p1.set_local_description)
	# Connect P1 session and ICE created to p2 set remote description and candidates.

	# Let P1 create the offer.
	p1.create_offer()

	# Wait a second and send message from P1.
	await get_tree().create_timer(1).timeout
	ch1.put_packet("Hi from P1".to_utf8_buffer())

	# Wait a second and send message from P2.
	await get_tree().create_timer(1).timeout


func _process(delta: float) -> void:
	p1.poll()
	if ch1.get_ready_state() == ch1.STATE_OPEN and ch1.get_available_packet_count() > 0:
		print("P1 received: ", ch1.get_packet().get_string_from_utf8())
