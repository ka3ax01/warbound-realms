extends Control

@onready var continue_button: Button = $CenterContainer/MenuCard/Margin/MenuColumn/Buttons/ContinueButton
@onready var settings_screen: Control = $SettingsScreen
@onready var version_label: Label = $VersionLabel


func _ready() -> void:
	AudioManager.play_menu_music()
	$CenterContainer/MenuCard/Margin/MenuColumn/Buttons/ContinueButton.pressed.connect(_on_continue_pressed)
	$CenterContainer/MenuCard/Margin/MenuColumn/Buttons/NewGameButton.pressed.connect(_on_new_game_pressed)
	$CenterContainer/MenuCard/Margin/MenuColumn/Buttons/SettingsButton.pressed.connect(_on_settings_pressed)
	$CenterContainer/MenuCard/Margin/MenuColumn/Buttons/ExitButton.pressed.connect(_on_exit_pressed)
	EventBus.settings_changed.connect(_refresh_menu_state)
	_refresh_menu_state()
	version_label.text = "build %s" % ProjectSettings.get_setting("application/config/version", "dev")


func _on_continue_pressed() -> void:
	AudioManager.play_sfx(AudioManager.BUTTON_SFX)
	SceneLoader.goto_campaign()


func _on_new_game_pressed() -> void:
	AudioManager.play_sfx(AudioManager.BUTTON_SFX)
	SaveManager.reset_progress()
	SceneLoader.goto_campaign()


func _on_settings_pressed() -> void:
	AudioManager.play_sfx(AudioManager.BUTTON_SFX)
	settings_screen.visible = true


func _on_exit_pressed() -> void:
	AudioManager.play_sfx(AudioManager.BUTTON_SFX)
	get_tree().quit()


func _refresh_menu_state() -> void:
	continue_button.disabled = not SaveManager.has_any_progress()
