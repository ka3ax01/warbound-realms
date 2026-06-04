extends Control

const LEVEL_INDEX_PATH := "res://data/levels/level_index.json"
const JsonUtilsScript := preload("res://scripts/utils/JsonUtils.gd")

@onready var title_label: Label = $Panel/Content/Title
@onready var stars_label: Label = $Panel/Content/Stars
@onready var objectives_label: Label = $Panel/Content/Objectives
@onready var coins_label: Label = $Panel/Content/Coins


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false
	EventBus.battle_won.connect(_on_battle_won)
	$Panel/Content/Actions/NextLevelButton.pressed.connect(_on_next_pressed)
	$Panel/Content/Actions/RetryButton.pressed.connect(_on_retry_pressed)
	$Panel/Content/Actions/CampaignButton.pressed.connect(_on_campaign_pressed)


func _on_battle_won(level_id: String, result: Dictionary) -> void:
	title_label.text = "Victory: %s" % level_id
	stars_label.text = "Stars: %d" % int(result.get("stars", 0))
	objectives_label.text = "Completed Objectives:\n- %s" % "\n- ".join(result.get("completed_objectives", []))
	coins_label.text = "Coins Reward: %d" % int(result.get("coins_reward", 0))
	visible = true
	get_tree().paused = true


func _on_next_pressed() -> void:
	get_tree().paused = false
	SceneLoader.goto_battle(_get_next_level_id(Game.selected_level_id))


func _on_retry_pressed() -> void:
	get_tree().paused = false
	SceneLoader.goto_battle(Game.selected_level_id)


func _on_campaign_pressed() -> void:
	get_tree().paused = false
	SceneLoader.goto_campaign()


func _get_next_level_id(level_id: String) -> String:
	var raw_index: Variant = JsonUtilsScript.load_json_file(LEVEL_INDEX_PATH, [])
	if raw_index is Array:
		for entry in raw_index:
			if entry is Dictionary and str(entry.get("id", "")) == level_id:
				var next_level: String = str(entry.get("next_level", ""))
				if not next_level.is_empty() and SaveManager.is_level_unlocked(next_level):
					return next_level
	return level_id
