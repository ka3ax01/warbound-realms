extends Control

@onready var settings_screen: Control = $SettingsScreen

var _battle_controller: BattleController


func setup(controller: BattleController) -> void:
	_battle_controller = controller


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false
	EventBus.pause_changed.connect(_on_pause_changed)
	$CenterContainer/Panel/Margin/Content/Buttons/ResumeButton.pressed.connect(_on_resume_pressed)
	$CenterContainer/Panel/Margin/Content/Buttons/RestartButton.pressed.connect(_on_restart_pressed)
	$CenterContainer/Panel/Margin/Content/Buttons/CampaignButton.pressed.connect(_on_exit_pressed)
	$CenterContainer/Panel/Margin/Content/Buttons/SettingsButton.pressed.connect(_on_settings_pressed)


func _on_pause_changed(is_paused: bool) -> void:
	var should_show: bool = is_paused and _battle_controller != null and _battle_controller.is_paused()
	visible = should_show
	if not should_show:
		settings_screen.visible = false


func _on_resume_pressed() -> void:
	if _battle_controller != null:
		AudioManager.play_sfx(AudioManager.BUTTON_SFX)
		_battle_controller.request_resume()


func _on_restart_pressed() -> void:
	if _battle_controller != null:
		AudioManager.play_sfx(AudioManager.BUTTON_SFX)
		_battle_controller.request_restart()


func _on_settings_pressed() -> void:
	AudioManager.play_sfx(AudioManager.BUTTON_SFX)
	settings_screen.visible = true


func _on_exit_pressed() -> void:
	if _battle_controller != null:
		AudioManager.play_sfx(AudioManager.BUTTON_SFX)
		_battle_controller.request_exit_to_campaign()
