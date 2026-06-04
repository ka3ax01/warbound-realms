extends Control

@onready var language_option: OptionButton = $Panel/Content/LanguageRow/LanguageOption
@onready var master_volume: HSlider = $Panel/Content/MasterRow/MasterVolume
@onready var music_volume: HSlider = $Panel/Content/MusicRow/MusicVolume
@onready var sfx_volume: HSlider = $Panel/Content/SfxRow/SfxVolume
@onready var fullscreen_toggle: CheckButton = $Panel/Content/FullscreenToggle


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false
	$Panel/Content/Buttons/CloseButton.pressed.connect(_on_close_pressed)
	$Panel/Content/Buttons/ResetProgressButton.pressed.connect(_on_reset_progress_pressed)
	language_option.item_selected.connect(_on_language_selected)
	master_volume.value_changed.connect(_on_master_changed)
	music_volume.value_changed.connect(_on_music_changed)
	sfx_volume.value_changed.connect(_on_sfx_changed)
	fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	_populate()


func _populate() -> void:
	language_option.clear()
	language_option.add_item("English", 0)
	language_option.add_item("Russian", 1)

	var settings: Dictionary = SaveManager.get_settings()
	master_volume.value = float(settings.get("master_volume", 1.0))
	music_volume.value = float(settings.get("music_volume", 0.8))
	sfx_volume.value = float(settings.get("sfx_volume", 0.8))
	fullscreen_toggle.button_pressed = bool(settings.get("fullscreen", false))
	language_option.select(0 if settings.get("language", "en") == "en" else 1)


func _on_close_pressed() -> void:
	visible = false


func _on_language_selected(index: int) -> void:
	LocalizationManager.set_language("en" if index == 0 else "ru")


func _on_master_changed(value: float) -> void:
	AudioManager.set_master_volume(value)


func _on_music_changed(value: float) -> void:
	AudioManager.set_music_volume(value)


func _on_sfx_changed(value: float) -> void:
	AudioManager.set_sfx_volume(value)


func _on_fullscreen_toggled(toggled_on: bool) -> void:
	SaveManager.update_setting("fullscreen", toggled_on)
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if toggled_on else DisplayServer.WINDOW_MODE_WINDOWED
	)


func _on_reset_progress_pressed() -> void:
	SaveManager.reset_progress()
