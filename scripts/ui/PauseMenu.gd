extends Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false
	EventBus.pause_changed.connect(_on_pause_changed)
	$Panel/VBoxContainer/ResumeButton.pressed.connect(_on_resume_pressed)
	$Panel/VBoxContainer/RestartButton.pressed.connect(_on_restart_pressed)
	$Panel/VBoxContainer/SettingsButton.pressed.connect(_on_settings_pressed)
	$Panel/VBoxContainer/ExitButton.pressed.connect(_on_exit_pressed)


func _on_pause_changed(is_paused: bool) -> void:
	visible = is_paused
	if not is_paused:
		$SettingsScreen.visible = false


func _on_resume_pressed() -> void:
	get_tree().paused = false
	EventBus.pause_changed.emit(false)


func _on_restart_pressed() -> void:
	get_tree().paused = false
	EventBus.pause_changed.emit(false)
	SceneLoader.goto_battle(Game.selected_level_id)


func _on_settings_pressed() -> void:
	$SettingsScreen.visible = true


func _on_exit_pressed() -> void:
	get_tree().paused = false
	EventBus.pause_changed.emit(false)
	SceneLoader.goto_campaign()
