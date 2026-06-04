extends Control

@onready var continue_button: Button = $CenterContainer/MenuColumn/ContinueButton
@onready var settings_screen: Control = $SettingsScreen
@onready var version_label: Label = $VersionLabel


func _ready() -> void:
	$CenterContainer/MenuColumn/ContinueButton.pressed.connect(_on_continue_pressed)
	$CenterContainer/MenuColumn/NewGameButton.pressed.connect(_on_new_game_pressed)
	$CenterContainer/MenuColumn/SettingsButton.pressed.connect(_on_settings_pressed)
	$CenterContainer/MenuColumn/ExitButton.pressed.connect(_on_exit_pressed)
	continue_button.disabled = not SaveManager.has_any_progress()
	version_label.text = "build %s" % ProjectSettings.get_setting("application/config/version", "dev")


func _on_continue_pressed() -> void:
	SceneLoader.goto_campaign()


func _on_new_game_pressed() -> void:
	SaveManager.reset_progress()
	SceneLoader.goto_campaign()


func _on_settings_pressed() -> void:
	settings_screen.visible = true


func _on_exit_pressed() -> void:
	get_tree().quit()
