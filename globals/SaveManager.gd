extends Node

const SAVE_VERSION: int = 1
const SAVE_PATH: String = Constants.SAVE_FILE_PATH
const BACKUP_PATH: String = "user://savegame.backup.json"

var save_data: Dictionary = {}


func _ready() -> void:
	load_save()


func load_save() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		save_data = _create_default_save()
		save_game()
		return save_data

	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("SaveManager: failed to open save file, creating a new one.")
		save_data = _create_default_save()
		save_game()
		return save_data

	var parser := JSON.new()
	var parse_result: int = parser.parse(file.get_as_text())
	if parse_result != OK or parser.data is not Dictionary:
		_move_corrupted_save()
		save_data = _create_default_save()
		save_game()
		return save_data

	var loaded_data: Dictionary = parser.data
	save_data = _migrate_save(loaded_data)
	save_game()
	return save_data


func save_game() -> bool:
	if save_data.is_empty():
		save_data = _create_default_save()
	_create_backup()

	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: failed to open save file for writing.")
		return false

	file.store_string(JSON.stringify(save_data, "\t"))
	return true


func reset_progress() -> void:
	var preserved_settings: Dictionary = get_settings().duplicate(true)
	save_data = _create_default_save()
	save_data["settings"] = preserved_settings
	save_game()
	EventBus.settings_changed.emit()


func complete_level(
	level_id: String,
	stars: int,
	best_time: float,
	objectives: Array,
	coins_reward: int
) -> void:
	if save_data.is_empty():
		load_save()

	var completed_levels: Dictionary = save_data.get("completed_levels", {})
	var existing_entry: Dictionary = completed_levels.get(level_id, {})
	var previous_stars: int = int(existing_entry.get("stars", 0))
	var previous_best_time: float = float(existing_entry.get("best_time", 0.0))
	var total_coins: int = int(save_data.get("coins", 0))
	var total_stars: int = int(save_data.get("stars", 0))

	completed_levels[level_id] = {
		"stars": max(previous_stars, stars),
		"best_time": best_time,
		"objectives": objectives
	}
	if previous_best_time > 0.0 and best_time > 0.0:
		completed_levels[level_id]["best_time"] = min(previous_best_time, best_time)
	elif previous_best_time > 0.0:
		completed_levels[level_id]["best_time"] = previous_best_time

	save_data["completed_levels"] = completed_levels
	save_data["coins"] = total_coins + coins_reward
	save_data["stars"] = total_stars - previous_stars + max(previous_stars, stars)
	save_game()


func is_level_unlocked(level_id: String) -> bool:
	if save_data.is_empty():
		load_save()
	if level_id == "1" or level_id == "level_001":
		return true

	var previous_level_id: String = _get_previous_level_id(level_id)
	if previous_level_id.is_empty():
		return true

	var completed_levels: Dictionary = save_data.get("completed_levels", {})
	return completed_levels.has(previous_level_id)


func get_level_stars(level_id: String) -> int:
	return int(get_level_result(level_id).get("stars", 0))


func set_setting(key: String, value: Variant) -> void:
	if save_data.is_empty():
		load_save()
	var settings: Dictionary = save_data.get("settings", {})
	settings[key] = value
	save_data["settings"] = settings
	save_game()
	EventBus.settings_changed.emit()


func get_setting(key: String, default_value: Variant):
	if save_data.is_empty():
		load_save()
	var settings: Dictionary = save_data.get("settings", {})
	return settings.get(key, default_value)


func get_settings() -> Dictionary:
	if save_data.is_empty():
		load_save()
	return save_data.get("settings", {})


func is_level_completed(level_id: String) -> bool:
	if save_data.is_empty():
		load_save()
	var completed_levels: Dictionary = save_data.get("completed_levels", {})
	return completed_levels.has(level_id)


func get_level_result(level_id: String) -> Dictionary:
	if save_data.is_empty():
		load_save()
	var completed_levels: Dictionary = save_data.get("completed_levels", {})
	return completed_levels.get(level_id, {})


func has_any_progress() -> bool:
	if save_data.is_empty():
		load_save()
	var completed_levels: Dictionary = save_data.get("completed_levels", {})
	return not completed_levels.is_empty()


func load_game() -> Dictionary:
	return load_save()


func update_setting(key: String, value: Variant) -> void:
	set_setting(key, value)


func mark_level_completed(
	level_id: String,
	unlock_levels: Array = [],
	stars: int = 0,
	coins_reward: int = 0,
	completed_objectives: Array = []
) -> void:
	complete_level(level_id, stars, 0.0, completed_objectives, coins_reward)


func _create_default_save() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"selected_faction": "slavic",
		"coins": 0,
		"stars": 0,
		"completed_levels": {
		},
		"settings": {
			"master_volume": 1.0,
			"music_volume": 0.7,
			"sfx_volume": 0.8,
			"language": "ru",
			"fullscreen": false
		}
	}


func _create_backup() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var absolute_save_path: String = ProjectSettings.globalize_path(SAVE_PATH)
	var absolute_backup_path: String = ProjectSettings.globalize_path(BACKUP_PATH)
	DirAccess.copy_absolute(absolute_save_path, absolute_backup_path)


func _move_corrupted_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var timestamp: int = int(Time.get_unix_time_from_system())
	var corrupted_path: String = "user://corrupted_save_%d.json" % timestamp
	var absolute_save_path: String = ProjectSettings.globalize_path(SAVE_PATH)
	var absolute_corrupted_path: String = ProjectSettings.globalize_path(corrupted_path)
	DirAccess.rename_absolute(absolute_save_path, absolute_corrupted_path)


func _migrate_save(raw_save: Dictionary) -> Dictionary:
	var version: int = int(raw_save.get("version", 0))
	var migrated_save: Dictionary = raw_save.duplicate(true)

	if version == SAVE_VERSION and _is_valid_current_save(migrated_save):
		return _merge_with_defaults(migrated_save)

	if version == 0 or not migrated_save.has("selected_faction"):
		migrated_save = _migrate_legacy_save(migrated_save)

	migrated_save["version"] = SAVE_VERSION
	return _merge_with_defaults(migrated_save)


func _migrate_legacy_save(legacy_save: Dictionary) -> Dictionary:
	var migrated_save: Dictionary = _create_default_save()
	var completed_levels_variant: Variant = legacy_save.get("completed_levels", [])
	var level_results: Dictionary = legacy_save.get("level_results", {})
	var unlocked_levels: Array = legacy_save.get("unlocked_levels", [])

	migrated_save["settings"] = _merge_settings(legacy_save.get("settings", {}))
	migrated_save["selected_faction"] = str(legacy_save.get("selected_faction", "slavic"))

	if completed_levels_variant is Array:
		for level_id_variant in completed_levels_variant:
			var level_id: String = str(level_id_variant)
			var result: Dictionary = level_results.get(level_id, {})
			var stars_value: int = int(result.get("stars", 0))
			migrated_save["completed_levels"][level_id] = {
				"stars": stars_value,
				"best_time": float(result.get("best_time", 0.0)),
				"objectives": result.get("completed_objectives", [])
			}
			migrated_save["stars"] = int(migrated_save["stars"]) + stars_value
			migrated_save["coins"] = int(migrated_save["coins"]) + int(result.get("coins_reward", 0))

	if completed_levels_variant is Dictionary:
		for level_id in completed_levels_variant.keys():
			var result_dict: Dictionary = completed_levels_variant[level_id]
			var stars_value: int = int(result_dict.get("stars", 0))
			migrated_save["completed_levels"][str(level_id)] = {
				"stars": stars_value,
				"best_time": float(result_dict.get("best_time", 0.0)),
				"objectives": result_dict.get("objectives", [])
			}
			migrated_save["stars"] = int(migrated_save["stars"]) + stars_value

	for unlocked_level in unlocked_levels:
		var unlocked_level_id: String = str(unlocked_level)
		if not migrated_save["completed_levels"].has(unlocked_level_id):
			migrated_save["completed_levels"][unlocked_level_id] = {
				"stars": 0,
				"best_time": 0.0,
				"objectives": []
			}

	return migrated_save


func _merge_with_defaults(candidate_save: Dictionary) -> Dictionary:
	var merged: Dictionary = _create_default_save()
	merged["version"] = int(candidate_save.get("version", SAVE_VERSION))
	merged["selected_faction"] = str(candidate_save.get("selected_faction", "slavic"))
	merged["coins"] = int(candidate_save.get("coins", 0))
	merged["stars"] = int(candidate_save.get("stars", 0))
	merged["completed_levels"] = candidate_save.get("completed_levels", {})
	merged["settings"] = _merge_settings(candidate_save.get("settings", {}))
	return merged


func _merge_settings(settings_value: Variant) -> Dictionary:
	var merged_settings: Dictionary = _create_default_save()["settings"].duplicate(true)
	if settings_value is Dictionary:
		merged_settings.merge(settings_value, true)
	return merged_settings


func _is_valid_current_save(candidate_save: Dictionary) -> bool:
	return (
		candidate_save.has("version")
		and candidate_save.has("selected_faction")
		and candidate_save.has("coins")
		and candidate_save.has("stars")
		and candidate_save.has("completed_levels")
		and candidate_save.has("settings")
	)


func _get_previous_level_id(level_id: String) -> String:
	var level_number: int = _extract_level_number(level_id)
	if level_number <= 1:
		return ""
	if level_id.is_valid_int():
		return str(level_number - 1)
	return "level_%03d" % (level_number - 1)


func _extract_level_number(level_id: String) -> int:
	var digits: String = ""
	for character in level_id:
		if character >= "0" and character <= "9":
			digits += character
	return int(digits) if not digits.is_empty() else 1
