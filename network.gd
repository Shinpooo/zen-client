extends Node

var client := WebSocketPeer.new()

var connected := false
signal snapshot_received(snapshot: Dictionary)
var player_id := ""
func _ready():
	randomize()
	var err = client.connect_to_url("ws://127.0.0.1:8080")
	if err != OK:
		print("❌ Failed to start WebSocket connection:", err)
	else:
		print("🔌 Attempting to connect...")

func _process(_delta):
	client.poll()

	if not connected and client.get_ready_state() == WebSocketPeer.STATE_OPEN:
		connected = true
		print("✅ Connected to WebSocket server!")
		var uuid = generate_uuid()
		send_join_game(uuid)

	elif client.get_ready_state() == WebSocketPeer.STATE_CLOSED and connected:
		print("🔌 WebSocket disconnected.")
		connected = false

	while client.get_available_packet_count() > 0:
		var packet = client.get_packet().get_string_from_utf8()
		print("📨 Received from server:", packet)

		var result = JSON.parse_string(packet)
		if result is Dictionary:
			emit_signal("snapshot_received", result)
		else:
			print("⚠️ Could not parse snapshot:", result)

func send_join_game(uuid: String):
	player_id = uuid
	if not connected:
		print("⚠️ Not connected yet, can't send JoinGame")
		return

	var msg = {
		"type": "JoinGame",
		"id": uuid
	}
	var json = JSON.stringify(msg)
	var err = client.send_text(json)

	if err != OK:
		print("❌ Failed to send packet:", err)
	else:
		print("🚀 Sent JoinGame with ID:", uuid)

func generate_uuid() -> String:
	var hex := "0123456789abcdef"
	var uuid := ""

	for i in 32:
		uuid += hex[randi() % hex.length()]

	uuid = "%s-%s-%s-%s-%s" % [
		uuid.substr(0, 8),
		uuid.substr(8, 4),
		uuid.substr(12, 4),
		uuid.substr(16, 4),
		uuid.substr(20, 12)
	]

	return uuid


func send_move_to(id: String, x: int, y: int) -> void:
	if not connected:
		print("⚠️ Not connected, cannot send MoveTo")
		return

	var msg = {
		"type": "MoveTo",
		"id": id,
		"x": x,
		"y": y
	}
	var json = JSON.stringify(msg)
	var err = client.send_text(json)

	if err != OK:
		print("❌ Failed to send MoveTo packet:", err)
	else:
		print("➡️ Sent MoveTo to ({x}, {y}) for ID: {id}")
