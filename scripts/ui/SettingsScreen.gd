extends Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false
	$Panel/VBoxContainer/CloseButton.pressed.connect(_on_close_pressed)
	$Panel/VBoxContainer/LanguageOption.item_selected.connect(_on_language_selected)
	$Panel/VBoxContainer/MasterVolume.value_changed.connect(_on_master_changed)
	_populate()


func _populate() -> void:
	var language_option: OptionButton = $Panel/VBoxContainer/LanguageOption
	language_option.clear()
	language_option.add_item("English", 0)
	language_option.add_item("Russian", 1)

	var settings := SaveManager.get_settings()
	$Panel/VBoxContainer/MasterVolume.value = settings.get("master_volume", 1.0)
	language_option.select(0 if settings.get("language", "en") == "en" else 1)


func _on_close_pressed() -> void:
	visible = false


func _on_language_selected(index: int) -> void:
	LocalizationManager.set_language("en" if index == 0 else "ru")


func _on_master_changed(value: float) -> void:
	SaveManager.update_setting("master_volume", value)
