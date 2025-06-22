@tool

extends Node

var client := WebSocketPeer.new()
var connected := false
var player_id : String = ""

signal snapshot_received(characters: Dictionary)
signal chat_message_received(from_id: String, text: String)

# -------------------------------------------------------------------
func _ready() -> void:
	randomize()
	var err := client.connect_to_url("wss://zen-server.fly.dev")
	if err != OK:
		push_error("❌ WebSocket connect failed: %s" % err)
	else:
		print("🔌 Connecting…")

# -------------------------------------------------------------------
func _process(_delta: float) -> void:
	client.poll()

	if not connected and client.get_ready_state() == WebSocketPeer.STATE_OPEN:
		connected = true
		print("✅ Connected!")
		player_id = generate_uuid()
		_send_join_game(player_id)

	if connected and client.get_ready_state() == WebSocketPeer.STATE_CLOSED:
		print("🔌 Disconnected.")
		connected = false

	while client.get_available_packet_count() > 0:
		var raw := client.get_packet().get_string_from_utf8()
		print("📥 RAW from server:", raw)                        # << NEW

		var msg: Variant = JSON.parse_string(raw)
		if typeof(msg) != TYPE_DICTIONARY or not msg.has("type"):
			continue

		print("📖 Parsed type:", msg["type"])                    # << NEW

		match msg["type"]:
			"CharactersSnapshot":
				emit_signal("snapshot_received", msg["characters"])
			"ChatBroadcast":
				emit_signal("chat_message_received", msg["id"], msg["text"])

# -------------------------------------------------------------------
func send_move_to(id: String, x: int, y: int) -> void:
	if connected:
		_send_json({ "type": "MoveTo", "id": id, "x": x, "y": y })

func send_chat(text: String) -> void:
	if connected:
		_send_json({ "type": "Chat", "id": player_id, "text": text })

# -------------------------------------------------------------------
func _send_join_game(uuid: String) -> void:
	_send_json({ "type": "JoinGame", "id": uuid })

func _send_json(payload: Dictionary) -> void:
	var err := client.send_text(JSON.stringify(payload))
	if err != OK:
		push_error("❌ send failed: %s" % err)

# -------------------------------------------------------------------
func generate_uuid() -> String:
	var hex := "0123456789abcdef"
	var uuid := ""
	for i in 32: uuid += hex[randi() % hex.length()]
	return "%s-%s-%s-%s-%s" % [ uuid.substr(0,8), uuid.substr(8,4),
								uuid.substr(12,4), uuid.substr(16,4),
								uuid.substr(20,12) ]
