extends Control


func _ready() -> void:
	$CenterContainer/VBoxContainer/StartButton.pressed.connect(_on_start_pressed)
	$CenterContainer/VBoxContainer/ContinueButton.pressed.connect(_on_continue_pressed)
	$CenterContainer/VBoxContainer/SettingsButton.pressed.connect(_on_settings_pressed)
	$CenterContainer/VBoxContainer/QuitButton.pressed.connect(_on_quit_pressed)


func _on_start_pressed() -> void:
	SceneLoader.goto_campaign()


func _on_continue_pressed() -> void:
	SceneLoader.goto_campaign()


func _on_settings_pressed() -> void:
	$SettingsScreen.visible = true


func _on_quit_pressed() -> void:
	get_tree().quit()
