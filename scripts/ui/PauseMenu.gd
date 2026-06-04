extends Control

@onready var settings_screen: Control = $SettingsScreen


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false
	EventBus.pause_changed.connect(_on_pause_changed)
	$Panel/Content/ResumeButton.pressed.connect(_on_resume_pressed)
	$Panel/Content/RestartButton.pressed.connect(_on_restart_pressed)
	$Panel/Content/CampaignButton.pressed.connect(_on_exit_pressed)
	$Panel/Content/SettingsButton.pressed.connect(_on_settings_pressed)


func _on_pause_changed(is_paused: bool) -> void:
	visible = is_paused
	if not is_paused:
		settings_screen.visible = false


func _on_resume_pressed() -> void:
	get_tree().paused = false
	EventBus.pause_changed.emit(false)


func _on_restart_pressed() -> void:
	get_tree().paused = false
	EventBus.pause_changed.emit(false)
	SceneLoader.goto_battle(Game.selected_level_id)


func _on_settings_pressed() -> void:
	settings_screen.visible = true


func _on_exit_pressed() -> void:
	get_tree().paused = false
	EventBus.pause_changed.emit(false)
	SceneLoader.goto_campaign()
