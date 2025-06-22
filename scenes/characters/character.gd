extends CharacterBody2D

@onready var sprite : AnimatedSprite2D = $Sprite

var tilemap      : TileMapLayer
var current_tile : Vector2i
var pixels_per_sec := 128.0
var path : Array[Vector2i] = []
var last_dir := "s"                # remember facing (default south)

func init(_map: TileMapLayer, start_tile: Vector2i) -> void:
	tilemap = _map
	current_tile = start_tile
	global_position = tilemap.map_to_local(start_tile)

func set_target(target_tile: Vector2i) -> void:
	path.clear()
	var t = current_tile
	while t != target_tile:
		t += Vector2i(signi(target_tile.x - t.x), signi(target_tile.y - t.y))
		path.append(t)

func _physics_process(delta: float) -> void:
	if path.is_empty():
		# idle in last direction
		_play_if_changed("idle_" + last_dir)
		return

	var target = path[0]
	var target_pos = tilemap.map_to_local(target)
	var step = pixels_per_sec * delta
	var move_vec = target_pos - global_position

	if move_vec.length() <= step:
		global_position = target_pos
		current_tile = target
		path.pop_front()
	else:
		global_position += move_vec.normalized() * step

	# choose animation for movement direction
	_update_walk_animation(move_vec)

func _update_walk_animation(move_vec: Vector2) -> void:
	var angle := move_vec.angle()
	var dir := ""

	if angle >= -PI/8 and angle < PI/8:
		dir = "e"
	elif angle >= PI/8 and angle < 3*PI/8:
		dir = "se"
	elif angle >= 3*PI/8 and angle < 5*PI/8:
		dir = "s"
	elif angle >= 5*PI/8 and angle < 7*PI/8:
		dir = "sw"
	elif angle >= 7*PI/8 or angle < -7*PI/8:
		dir = "w"
	elif angle >= -7*PI/8 and angle < -5*PI/8:
		dir = "nw"
	elif angle >= -5*PI/8 and angle < -3*PI/8:
		dir = "n"
	elif angle >= -3*PI/8 and angle < -PI/8:
		dir = "ne"

	last_dir = dir
	_play_if_changed("walk_" + dir)

func _play_if_changed(anim: String) -> void:
	if sprite.animation != anim:
		sprite.play(anim)
