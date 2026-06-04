extends Node

var selected_level_id := "level_001"
var current_level_data: LevelData


func start_level(level_id: String) -> void:
	selected_level_id = level_id
	SceneLoader.goto_battle(level_id)


func complete_level(level_id: String, rewards: Dictionary = {}) -> void:
	var unlock_levels: Array = rewards.get("unlock_levels", [])
	SaveManager.mark_level_completed(level_id, unlock_levels)
	EventBus.battle_won.emit(level_id)


func fail_level(level_id: String) -> void:
	EventBus.battle_lost.emit(level_id)
