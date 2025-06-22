extends Node2D

@onready var tilemap  : TileMapLayer = get_parent()           as TileMapLayer
@onready var network  : Node         = $"../Network"
@onready var chatbox  : Control      = $"../ChatBox"
const CHARACTER_SCENE = preload("res://scenes/characters/character.tscn")

var players : Dictionary = {}   # uuid → Character node

# -------------------------------------------------------------

func _ready() -> void:
	if chatbox:
		print("✅ ChatBox found")
	else:
		push_error("❌ ChatBox NOT found in scene tree!")
		return

	network.connect("snapshot_received",        _on_snapshot)
	network.connect("chat_message_received",    _on_chat_recv)
	chatbox.connect("chat_submitted",           _on_chat_send)

# -------------------------------------------------------------
func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT \
	and event.pressed:
		var tile := tilemap.local_to_map(get_global_mouse_position())
		network.send_move_to(network.player_id, tile.x, tile.y)

# -------------------------------------------------------------
func _on_snapshot(chars: Dictionary) -> void:
	# Remove missing
	for id in players.keys():
		if not chars.has(id):
			players[id].queue_free()
			players.erase(id)

	# Add/update
	for id in chars:
		var dest := Vector2i(chars[id]["x"], chars[id]["y"])
		if players.has(id):
			var c := players[id] as CharacterBody2D      # returns null if wrong type
			if c.current_tile != dest:
				c.set_target(dest)
		else:
			var n := CHARACTER_SCENE.instantiate()
			add_child(n)
			n.init(tilemap, dest)
			players[id] = n

# -------------------------------------------------------------
func _on_chat_send(text: String) -> void:
	network.send_chat(text)
	chatbox.append_message("Me", text)   # local echo

func _on_chat_recv(from_id: String, text: String) -> void:
	chatbox.append_message(from_id, text)
