extends Control

@onready var title_label: Label = $CenterContainer/Panel/Margin/Content/Title
@onready var tip_label: Label = $CenterContainer/Panel/Margin/Content/TipPanel/TipMargin/TipColumn/Tip


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false
	EventBus.battle_lost.connect(_on_battle_lost)
	$CenterContainer/Panel/Margin/Content/Actions/RetryButton.pressed.connect(_on_retry_pressed)
	$CenterContainer/Panel/Margin/Content/Actions/CampaignButton.pressed.connect(_on_campaign_pressed)


func _on_battle_lost(level_id: String, result: Dictionary) -> void:
	AudioManager.play_defeat_music()
	title_label.text = "Defeat: %s" % level_id
	tip_label.text = str(result.get("tip", "Expand early and avoid isolated attacks."))
	visible = true
	get_tree().paused = true


func _on_retry_pressed() -> void:
	AudioManager.play_sfx(AudioManager.BUTTON_SFX)
	SceneLoader.goto_battle(Game.selected_level_id)


func _on_campaign_pressed() -> void:
	AudioManager.play_sfx(AudioManager.BUTTON_SFX)
	SceneLoader.goto_campaign()
