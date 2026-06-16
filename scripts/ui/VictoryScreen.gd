extends Control

const LEVEL_INDEX_PATH := "res://data/levels/level_index.json"
const JsonUtilsScript := preload("res://scripts/utils/JsonUtils.gd")

@onready var title_label: Label = $CenterContainer/Panel/Margin/Content/Title
@onready var stars_label: Label = $CenterContainer/Panel/Margin/Content/Stars
@onready var objectives_label: Label = $CenterContainer/Panel/Margin/Content/ObjectivesPanel/ObjectivesMargin/ObjectivesColumn/Objectives
@onready var coins_label: Label = $CenterContainer/Panel/Margin/Content/Coins


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false
	EventBus.battle_won.connect(_on_battle_won)
	$CenterContainer/Panel/Margin/Content/Actions/NextLevelButton.pressed.connect(_on_next_pressed)
	$CenterContainer/Panel/Margin/Content/Actions/RetryButton.pressed.connect(_on_retry_pressed)
	$CenterContainer/Panel/Margin/Content/Actions/CampaignButton.pressed.connect(_on_campaign_pressed)


func _on_battle_won(level_id: String, result: Dictionary) -> void:
	AudioManager.play_victory_music()
	title_label.text = "Victory: %s" % level_id
	stars_label.text = "Stars: %d" % int(result.get("stars", 0))
	var completed: Array = result.get("completed_objectives", [])
	objectives_label.text = "- %s" % "\n- ".join(completed) if not completed.is_empty() else "- None"
	coins_label.text = "Coins Reward: %d" % int(result.get("coins_reward", 0))
	visible = true
	get_tree().paused = true


func _on_next_pressed() -> void:
	AudioManager.play_sfx(AudioManager.BUTTON_SFX)
	var next_level_id: String = _get_next_level_id(Game.selected_level_id)
	if next_level_id.is_empty() or next_level_id == Game.selected_level_id:
		SceneLoader.goto_campaign()
		return
	SceneLoader.goto_battle(next_level_id)


func _on_retry_pressed() -> void:
	AudioManager.play_sfx(AudioManager.BUTTON_SFX)
	SceneLoader.goto_battle(Game.selected_level_id)


func _on_campaign_pressed() -> void:
	AudioManager.play_sfx(AudioManager.BUTTON_SFX)
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
