extends Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false
	EventBus.battle_won.connect(_on_battle_won)
	$Panel/VBoxContainer/NextButton.pressed.connect(_on_next_pressed)
	$Panel/VBoxContainer/CampaignButton.pressed.connect(_on_campaign_pressed)


func _on_battle_won(level_id: String) -> void:
	$Panel/VBoxContainer/Title.text = "Victory: %s" % level_id
	visible = true
	get_tree().paused = true


func _on_next_pressed() -> void:
	get_tree().paused = false
	SceneLoader.goto_campaign()


func _on_campaign_pressed() -> void:
	get_tree().paused = false
	SceneLoader.goto_campaign()
