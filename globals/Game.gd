extends Node

var selected_level_id: String = "level_001"
var current_level_data: Dictionary = {}


func start_level(level_id: String) -> void:
	selected_level_id = level_id
	SceneLoader.goto_battle(level_id)


func complete_level(level_id: String, rewards: Dictionary = {}) -> void:
	var unlock_levels: Array = rewards.get("unlock_levels", [])
	var stars: int = int(rewards.get("stars", 3))
	var coins_reward: int = int(rewards.get("coins_reward", 100))
	var completed_objectives: Array = current_level_data.get("objectives", []) if current_level_data is Dictionary else []
	SaveManager.mark_level_completed(level_id, unlock_levels, stars, coins_reward, completed_objectives)
	EventBus.battle_won.emit(level_id, {
		"stars": stars,
		"coins_reward": coins_reward,
		"completed_objectives": completed_objectives
	})


func fail_level(level_id: String) -> void:
	EventBus.battle_lost.emit(level_id, {
		"tip": "Capture neutral towers first to build momentum."
	})
