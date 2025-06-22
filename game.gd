extends Node2D

@onready var tilemap = get_parent() as TileMapLayer
@onready var network = $"../Network"
const CHARACTER_SCENE = preload("res://scenes/characters/character.tscn")  # Replace with your actual path
var players := {}

func _ready():
	# Call every frame from Network, or pull manually
	# get_parent().get_node("Network").connect("snapshot_received", _on_snapshot_received)
	network.connect("snapshot_received", _on_snapshot_received)



func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var world_pos = get_global_mouse_position()  # ← Correct for Godot 4
		var tile_pos = tilemap.local_to_map(world_pos)
		print("🖱️ Tile clicked at world position:", world_pos, " -> tile:", tile_pos)

		# Send movement request
		if network.player_id != "":
			network.send_move_to(network.player_id, tile_pos.x, tile_pos.y)

func _on_snapshot_received(snapshot: Dictionary) -> void:
	# Despawn players that are no longer in the snapshot
	for id in players.keys():
		if not snapshot.has(id):
			print("👋 Player left:", id)
			players[id].queue_free()
			players.erase(id)
			
	for id in snapshot.keys():
		var data      : Dictionary = snapshot[id]
		var tile_dest : Vector2i   = Vector2i(data["x"], data["y"])

		if players.has(id):
			var char: Node = players[id]
			if char.current_tile != tile_dest:
				char.set_target(tile_dest)
		else:
			var inst: Node = CHARACTER_SCENE.instantiate()
			add_child(inst)
			inst.init(tilemap, tile_dest)
			players[id] = inst
