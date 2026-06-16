class_name LevelLoader
extends Node

const STRUCTURE_SCENE: PackedScene = preload("res://scenes/world/Structure.tscn")
const ISO_TILE_WIDTH := 128.0
const ISO_TILE_HEIGHT := 64.0
const DEFAULT_VIEWPORT_SIZE := Vector2(1280.0, 720.0)

var structures_by_id: Dictionary = {}


func load_level(level_id: String, structures_root: Node) -> Dictionary:
	_clear_existing_structures(structures_root)
	structures_by_id.clear()

	var level_path: String = "res://data/levels/%s.json" % level_id
	if not FileAccess.file_exists(level_path):
		push_error("LevelLoader: level file not found: %s" % level_path)
		return {}

	var file: FileAccess = FileAccess.open(level_path, FileAccess.READ)
	if file == null:
		push_error("LevelLoader: failed to open level file: %s" % level_path)
		return {}

	var parser := JSON.new()
	var parse_result: int = parser.parse(file.get_as_text())
	if parse_result != OK:
		push_error(
			"LevelLoader: invalid JSON in %s at line %d: %s" % [
				level_path,
				parser.get_error_line(),
				parser.get_error_message()
			]
		)
		return {}

	var raw_data: Variant = parser.data
	if raw_data is not Dictionary:
		push_error("LevelLoader: root JSON object must be a Dictionary in %s" % level_path)
		return {}

	var level_data: Dictionary = raw_data
	var structures_value: Variant = level_data.get("structures", [])
	if structures_value is not Array:
		push_error("LevelLoader: 'structures' must be an Array in %s" % level_path)
		return {}

	var structures_data: Array = structures_value
	var iso_origin := _resolve_iso_origin(level_data, structures_data)
	if not iso_origin.is_equal_approx(Vector2.ZERO) or level_data.has("iso_origin"):
		level_data["resolved_iso_origin"] = {
			"x": iso_origin.x,
			"y": iso_origin.y
		}
	for structure_value in structures_data:
		if structure_value is not Dictionary:
			push_error("LevelLoader: skipped invalid structure entry in %s" % level_path)
			continue

		var structure_data: Dictionary = _resolve_structure_position(structure_value, iso_origin)
		var structure: Structure = STRUCTURE_SCENE.instantiate() as Structure
		structures_root.add_child(structure)
		structure.setup_from_data(structure_data)
		if structure.structure_id.is_empty():
			push_error("LevelLoader: structure with empty id in %s" % level_path)
			structure.queue_free()
			continue
		if structures_by_id.has(structure.structure_id):
			push_error("LevelLoader: duplicate structure id '%s' in %s" % [structure.structure_id, level_path])
			structure.queue_free()
			continue
		structures_by_id[structure.structure_id] = structure

	for structure: Structure in structures_root.get_children():
		_validate_connections(structure, level_path)
		structure.resolve_neighbors(structures_by_id)

	EventBus.level_loaded.emit(level_id)
	return level_data


func _clear_existing_structures(structures_root: Node) -> void:
	for child in structures_root.get_children():
		child.queue_free()


func get_structure_by_id(structure_id: String) -> Structure:
	return structures_by_id.get(structure_id) as Structure


func _validate_connections(structure: Structure, level_path: String) -> void:
	for target_id in structure.connected_to:
		if not structures_by_id.has(target_id):
			push_error(
				"LevelLoader: structure '%s' references missing connected_to id '%s' in %s" % [
					structure.structure_id,
					target_id,
					level_path
				]
			)


func _resolve_structure_position(structure_data: Dictionary, iso_origin: Vector2) -> Dictionary:
	if not structure_data.has("iso_position"):
		return structure_data
	var resolved := structure_data.duplicate(true)
	var iso_position := _parse_point(structure_data.get("iso_position"))
	var screen_position := _iso_to_screen(iso_position, iso_origin)
	resolved["position"] = {
		"x": screen_position.x,
		"y": screen_position.y
	}
	return resolved


func _resolve_iso_origin(level_data: Dictionary, structures_data: Array) -> Vector2:
	if level_data.has("iso_origin"):
		return _parse_point(level_data.get("iso_origin"))

	var has_iso_positions := false
	var min_position := Vector2(INF, INF)
	var max_position := Vector2(-INF, -INF)
	for structure_data: Dictionary in structures_data:
		if not structure_data.has("iso_position"):
			continue
		has_iso_positions = true
		var iso_position := _parse_point(structure_data.get("iso_position"))
		var raw_screen := _iso_to_screen(iso_position, Vector2.ZERO)
		min_position.x = min(min_position.x, raw_screen.x)
		min_position.y = min(min_position.y, raw_screen.y)
		max_position.x = max(max_position.x, raw_screen.x)
		max_position.y = max(max_position.y, raw_screen.y)

	if not has_iso_positions:
		return Vector2.ZERO

	var content_center := (min_position + max_position) * 0.5
	var viewport_center := DEFAULT_VIEWPORT_SIZE * 0.5
	var origin := viewport_center - content_center
	origin.y -= 32.0
	return origin


func _parse_point(value: Variant) -> Vector2:
	if value is Dictionary:
		var dict_value: Dictionary = value
		return Vector2(float(dict_value.get("x", 0.0)), float(dict_value.get("y", 0.0)))
	if value is Array and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return Vector2.ZERO


func _iso_to_screen(grid_position: Vector2, origin: Vector2) -> Vector2:
	return Vector2(
		(grid_position.x - grid_position.y) * (ISO_TILE_WIDTH * 0.5),
		(grid_position.x + grid_position.y) * (ISO_TILE_HEIGHT * 0.5)
	) + origin
