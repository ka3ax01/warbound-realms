class_name LevelLoader
extends Node

const STRUCTURE_SCENE: PackedScene = preload("res://scenes/world/Structure.tscn")

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
	for structure_value in structures_data:
		if structure_value is not Dictionary:
			push_error("LevelLoader: skipped invalid structure entry in %s" % level_path)
			continue

		var structure_data: Dictionary = structure_value
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
