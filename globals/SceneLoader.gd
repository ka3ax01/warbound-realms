extends Node

const MAIN_MENU_SCENE := "res://scenes/menu/MainMenu.tscn"
const CAMPAIGN_SCENE := "res://scenes/menu/CampaignMap.tscn"
const BATTLE_SCENE := "res://scenes/battle/BattleScene.tscn"


func goto_main_menu() -> void:
	_prepare_transition()
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func goto_campaign() -> void:
	_prepare_transition()
	get_tree().change_scene_to_file(CAMPAIGN_SCENE)


func goto_battle(level_id: String) -> void:
	_prepare_transition()
	Game.selected_level_id = level_id
	get_tree().change_scene_to_file(BATTLE_SCENE)


func _prepare_transition() -> void:
	get_tree().paused = false
