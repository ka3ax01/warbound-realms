class_name LevelLoader
extends Node

const STRUCTURE_SCENE: PackedScene = preload("res://scenes/world/Structure.tscn")
const JsonUtilsScript := preload("res://scripts/utils/JsonUtils.gd")


func load_level(level_id: String, structures_root: Node) -> LevelData:
	var level_path := "res://data/levels/campaign_01/%s.json" % level_id
	var raw_data: Variant = JsonUtilsScript.load_json_file(level_path, {})
	var level_data: LevelData = LevelData.from_dict(raw_data)
	var structure_map: Dictionary = {}

	for structure_data in level_data.structures:
		var structure: Structure = STRUCTURE_SCENE.instantiate() as Structure
		structures_root.add_child(structure)
		structure.setup_from_data(structure_data)
		structure_map[structure.structure_id] = structure

	for structure: Structure in structures_root.get_children():
		structure.resolve_neighbors(structure_map)

	Game.current_level_data = level_data
	EventBus.level_loaded.emit(level_id)
	return level_data
