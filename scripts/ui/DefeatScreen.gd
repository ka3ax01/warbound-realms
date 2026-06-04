extends Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false
	EventBus.battle_lost.connect(_on_battle_lost)
	$Panel/VBoxContainer/RetryButton.pressed.connect(_on_retry_pressed)
	$Panel/VBoxContainer/CampaignButton.pressed.connect(_on_campaign_pressed)


func _on_battle_lost(level_id: String) -> void:
	$Panel/VBoxContainer/Title.text = "Defeat: %s" % level_id
	visible = true
	get_tree().paused = true


func _on_retry_pressed() -> void:
	get_tree().paused = false
	SceneLoader.goto_battle(Game.selected_level_id)


func _on_campaign_pressed() -> void:
	get_tree().paused = false
	SceneLoader.goto_campaign()
