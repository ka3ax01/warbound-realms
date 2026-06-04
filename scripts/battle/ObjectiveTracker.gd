class_name ObjectiveTracker
extends Node

var battle_controller: BattleController
var level_data: LevelData


func setup(controller: BattleController, new_level_data: LevelData) -> void:
	battle_controller = controller
	level_data = new_level_data


func check_state() -> void:
	if battle_controller == null or level_data == null:
		return
	if battle_controller.get_structures_by_owner(Constants.PLAYER_FACTION_ID).is_empty():
		Game.fail_level(level_data.id)
		return
	if battle_controller.all_structures_owned_by(Constants.PLAYER_FACTION_ID):
		Game.complete_level(level_data.id, level_data.rewards)
