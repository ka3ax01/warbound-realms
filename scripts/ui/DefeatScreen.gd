extends Control

@onready var title_label: Label = $Panel/Content/Title
@onready var tip_label: Label = $Panel/Content/Tip


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false
	EventBus.battle_lost.connect(_on_battle_lost)
	$Panel/Content/Actions/RetryButton.pressed.connect(_on_retry_pressed)
	$Panel/Content/Actions/CampaignButton.pressed.connect(_on_campaign_pressed)


func _on_battle_lost(level_id: String, result: Dictionary) -> void:
	title_label.text = "Defeat: %s" % level_id
	tip_label.text = str(result.get("tip", "Expand early and avoid isolated attacks."))
	visible = true
	get_tree().paused = true


func _on_retry_pressed() -> void:
	get_tree().paused = false
	SceneLoader.goto_battle(Game.selected_level_id)


func _on_campaign_pressed() -> void:
	get_tree().paused = false
	SceneLoader.goto_campaign()
