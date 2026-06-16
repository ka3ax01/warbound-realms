class_name BattleBackground
extends Node2D

const GRASS_TILE := preload("res://assets/art/tiles/ground/grass_tile_01.svg")
const DIRT_TILE := preload("res://assets/art/tiles/ground/dirt_tile_01.svg")
const ROAD_TILE := preload("res://assets/art/tiles/roads/road_tile_01.svg")
const TREE_TEXTURE := preload("res://assets/art/decor/trees/trees_4.png")
const ROCK_TEXTURE := preload("res://assets/art/decor/rocks/rocks_4.png")
const ISO_TILE_WIDTH := 128.0
const ISO_TILE_HEIGHT := 64.0

@export var structures_root_path: NodePath

var _structures_root: Node2D
var _map_size := Vector2(1280, 720)
var _road_points: Array[Vector2] = []
var _iso_origin := Vector2.ZERO


func _ready() -> void:
	_structures_root = get_node_or_null(structures_root_path) as Node2D
	_sync_iso_origin()
	_build_background()
	EventBus.level_loaded.connect(_on_level_loaded)


func _build_background() -> void:
	_sync_iso_origin()
	_clear_children()
	_road_points.clear()
	queue_redraw()
	_build_ground_tiles()
	_build_paths()
	_add_border_details()


func _build_ground_tiles() -> void:
	var bounds := _get_iso_grid_bounds()
	for x in range(bounds.position.x, bounds.end.x):
		for y in range(bounds.position.y, bounds.end.y):
			var sprite := Sprite2D.new()
			var tile_position := _iso_to_screen(Vector2(x, y))
			sprite.texture = _pick_ground_tile(x, y)
			sprite.position = tile_position
			sprite.scale = Vector2.ONE
			sprite.z_index = -10
			sprite.modulate = _pick_ground_modulate(x, y)
			if _is_inside_background_bounds(tile_position, 96.0):
				add_child(sprite)


func _build_paths() -> void:
	if _structures_root == null:
		return

	var drawn_pairs := {}
	for structure: Structure in _structures_root.get_children():
		for neighbor: Structure in structure.neighbors:
			var key := _make_pair_key(structure.structure_id, neighbor.structure_id)
			if drawn_pairs.has(key):
				continue
			drawn_pairs[key] = true
			_stamp_path(structure.global_position, neighbor.global_position)


func _stamp_path(from_point: Vector2, to_point: Vector2) -> void:
	var direction: Vector2 = to_point - from_point
	var distance: float = direction.length()
	if distance <= 0.0:
		return

	var step: float = 56.0
	var count: int = maxi(1, int(ceil(distance / step)))
	var placed_points := {}
	for index in range(count + 1):
		var t: float = float(index) / float(count)
		var point := _snap_to_iso_cell(from_point.lerp(to_point, t))
		var point_key := "%0.1f:%0.1f" % [point.x, point.y]
		if placed_points.has(point_key):
			continue
		placed_points[point_key] = true
		_road_points.append(point)

		var base := Sprite2D.new()
		base.texture = DIRT_TILE
		base.position = point
		base.scale = Vector2(1.0, 1.0)
		base.z_index = -9
		base.modulate = Color(0.42, 0.30, 0.16, 0.30)
		add_child(base)

		var sprite := Sprite2D.new()
		sprite.texture = ROAD_TILE
		sprite.position = point
		sprite.scale = Vector2.ONE
		sprite.z_index = -8
		sprite.modulate = Color(0.96, 0.93, 0.88, 0.92)
		add_child(sprite)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, _map_size), Color(0.10, 0.07, 0.04, 0.08), true)
	draw_rect(Rect2(Vector2(0, 0), Vector2(_map_size.x, 96)), Color(0.07, 0.06, 0.05, 0.22), true)
	draw_rect(Rect2(Vector2(0, _map_size.y - 96), Vector2(_map_size.x, 96)), Color(0.05, 0.04, 0.03, 0.20), true)
	draw_rect(Rect2(Vector2(-28, -28), Vector2(_map_size.x + 56, _map_size.y + 56)), Color(0.32, 0.23, 0.14, 0.25), false, 28.0)


func _add_border_details() -> void:
	var details := [
		[TREE_TEXTURE, Vector2(110, 120), Vector2(0.8, 0.8)],
		[TREE_TEXTURE, Vector2(1120, 540), Vector2(0.7, 0.7)],
		[TREE_TEXTURE, Vector2(1020, 140), Vector2(0.65, 0.65)],
		[ROCK_TEXTURE, Vector2(570, 120), Vector2(0.8, 0.8)],
		[ROCK_TEXTURE, Vector2(920, 620), Vector2(0.65, 0.65)],
		[ROCK_TEXTURE, Vector2(180, 600), Vector2(0.55, 0.55)],
		[TREE_TEXTURE, Vector2(280, 210), Vector2(0.56, 0.56)],
		[ROCK_TEXTURE, Vector2(1040, 260), Vector2(0.48, 0.48)]
	]
	for entry in details:
		_add_detail(entry[0], entry[1], entry[2])


func _add_detail(texture: Texture2D, world_position: Vector2, detail_scale: Vector2) -> void:
	var snapped_position := _snap_to_iso_cell(world_position)
	if not _can_place_decor(snapped_position):
		return
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.position = snapped_position
	sprite.scale = detail_scale
	sprite.z_index = -5
	add_child(sprite)


func _on_level_loaded(_level_id: String) -> void:
	call_deferred("_build_background")


func _clear_children() -> void:
	for child in get_children():
		child.queue_free()


func _make_pair_key(a: String, b: String) -> String:
	return "%s|%s" % [a, b] if a < b else "%s|%s" % [b, a]


func _pick_ground_tile(x: int, y: int) -> Texture2D:
	var value := posmod((x * 17) + (y * 31), 20)
	if value < 14:
		return GRASS_TILE
	if value < 17:
		return GRASS_TILE
	if value < 19:
		return DIRT_TILE
	return GRASS_TILE


func _pick_ground_modulate(x: int, y: int) -> Color:
	var value := posmod((x * 11) + (y * 19), 20)
	if value < 14:
		return Color(0.94, 1.0, 0.94, 1)
	if value < 17:
		return Color(0.86, 0.95, 0.86, 1)
	if value < 19:
		return Color(0.78, 0.88, 0.78, 1)
	return Color(1, 1, 1, 0.92)


func _can_place_decor(world_position: Vector2) -> bool:
	var safe_radius := 74.0
	if _structures_root != null:
		for structure: Structure in _structures_root.get_children():
			if structure.global_position.distance_to(world_position) < safe_radius:
				return false
	for point in _road_points:
		if point.distance_to(world_position) < 52.0:
			return false
	return true


func _iso_to_screen(grid_position: Vector2) -> Vector2:
	return Vector2(
		(grid_position.x - grid_position.y) * (ISO_TILE_WIDTH * 0.5),
		(grid_position.x + grid_position.y) * (ISO_TILE_HEIGHT * 0.5)
	) + _iso_origin


func _screen_to_iso(screen_position: Vector2) -> Vector2:
	var local := screen_position - _iso_origin
	var half_width := ISO_TILE_WIDTH * 0.5
	var half_height := ISO_TILE_HEIGHT * 0.5
	return Vector2(
		(local.x / half_width + local.y / half_height) * 0.5,
		(local.y / half_height - local.x / half_width) * 0.5
	)


func _snap_to_iso_cell(screen_position: Vector2) -> Vector2:
	var iso := _screen_to_iso(screen_position)
	return _iso_to_screen(Vector2(round(iso.x), round(iso.y)))


func _get_iso_grid_bounds() -> Rect2i:
	var min_screen := Vector2(-128, -128)
	var max_screen := Vector2(_map_size.x + 128, _map_size.y + 128)
	if _structures_root != null and _structures_root.get_child_count() > 0:
		var min_structure := Vector2(INF, INF)
		var max_structure := Vector2(-INF, -INF)
		for structure: Structure in _structures_root.get_children():
			min_structure.x = min(min_structure.x, structure.global_position.x)
			min_structure.y = min(min_structure.y, structure.global_position.y)
			max_structure.x = max(max_structure.x, structure.global_position.x)
			max_structure.y = max(max_structure.y, structure.global_position.y)
		min_screen = min_structure - Vector2(320, 224)
		max_screen = max_structure + Vector2(320, 224)
	var corners := [
		_screen_to_iso(Vector2(min_screen.x, min_screen.y)),
		_screen_to_iso(Vector2(max_screen.x, min_screen.y)),
		_screen_to_iso(Vector2(min_screen.x, max_screen.y)),
		_screen_to_iso(Vector2(max_screen.x, max_screen.y))
	]
	var min_x := int(floor(corners[0].x))
	var max_x := int(ceil(corners[0].x))
	var min_y := int(floor(corners[0].y))
	var max_y := int(ceil(corners[0].y))
	for corner in corners:
		min_x = mini(min_x, int(floor(corner.x)))
		max_x = maxi(max_x, int(ceil(corner.x)))
		min_y = mini(min_y, int(floor(corner.y)))
		max_y = maxi(max_y, int(ceil(corner.y)))
	return Rect2i(min_x - 1, min_y - 1, (max_x - min_x) + 3, (max_y - min_y) + 3)


func _is_inside_background_bounds(point: Vector2, margin: float = 0.0) -> bool:
	return point.x >= -margin and point.x <= _map_size.x + margin and point.y >= -margin and point.y <= _map_size.y + margin


func _sync_iso_origin() -> void:
	var level_data: Dictionary = Game.current_level_data
	if level_data.has("resolved_iso_origin"):
		_iso_origin = _parse_point(level_data.get("resolved_iso_origin"))
		return
	if level_data.has("iso_origin"):
		_iso_origin = _parse_point(level_data.get("iso_origin"))
		return
	if _structures_root != null and _structures_root.get_child_count() > 0:
		var min_position := Vector2(INF, INF)
		var max_position := Vector2(-INF, -INF)
		for structure: Structure in _structures_root.get_children():
			min_position.x = min(min_position.x, structure.global_position.x)
			min_position.y = min(min_position.y, structure.global_position.y)
			max_position.x = max(max_position.x, structure.global_position.x)
			max_position.y = max(max_position.y, structure.global_position.y)
		_iso_origin = Vector2((min_position.x + max_position.x) * 0.5, min_position.y - ISO_TILE_HEIGHT * 1.5)
		return
	_iso_origin = Vector2(_map_size.x * 0.5, 36.0)


func _parse_point(value: Variant) -> Vector2:
	if value is Dictionary:
		var dict_value: Dictionary = value
		return Vector2(float(dict_value.get("x", 0.0)), float(dict_value.get("y", 0.0)))
	if value is Array and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return Vector2.ZERO
