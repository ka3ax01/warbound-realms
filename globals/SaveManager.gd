extends Node

const SaveDataScript := preload("res://scripts/data/SaveData.gd")
const JsonUtilsScript := preload("res://scripts/utils/JsonUtils.gd")

var save_data: SaveData


func _ready() -> void:
	load_game()


func load_game() -> SaveData:
	var raw_data: Variant = JsonUtilsScript.load_json_file(Constants.SAVE_FILE_PATH, {})
	if raw_data is Dictionary and not raw_data.is_empty():
		save_data = SaveDataScript.from_dict(raw_data)
	else:
		save_data = SaveDataScript.new()
		save_game()
	return save_data


func save_game() -> bool:
	if save_data == null:
		save_data = SaveDataScript.new()
	return JsonUtilsScript.save_json_file(Constants.SAVE_FILE_PATH, save_data.to_dict())


func get_settings() -> Dictionary:
	return save_data.settings if save_data else {}


func update_setting(key: String, value: Variant) -> void:
	if save_data == null:
		load_game()
	save_data.settings[key] = value
	save_game()
	EventBus.settings_changed.emit()


func mark_level_completed(level_id: String, unlock_levels: Array = []) -> void:
	if save_data == null:
		load_game()
	if not save_data.completed_levels.has(level_id):
		save_data.completed_levels.append(level_id)
	for unlock_level in unlock_levels:
		if not save_data.unlocked_levels.has(unlock_level):
			save_data.unlocked_levels.append(unlock_level)
	save_game()


func is_level_unlocked(level_id: String) -> bool:
	return save_data != null and save_data.unlocked_levels.has(level_id)
