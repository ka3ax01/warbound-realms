extends Control

@onready var title_label: Label = $Panel/Content/Title
@onready var objectives_label: Label = $Panel/Content/Objectives

var current_level_id: String = ""


func _ready() -> void:
	visible = false
	$Panel/Content/Actions/StartButton.pressed.connect(_on_start_pressed)
	$Panel/Content/Actions/BackButton.pressed.connect(_on_close_pressed)


func show_level(level_data: Dictionary) -> void:
	current_level_id = str(level_data.get("id", ""))
	title_label.text = str(level_data.get("name", current_level_id))
	var objectives: Array = level_data.get("objectives", [])
	objectives_label.text = "Objectives:\n- %s" % "\n- ".join(objectives)
	visible = true


func _on_start_pressed() -> void:
	if current_level_id.is_empty():
		AudioManager.play_sfx(AudioManager.ERROR_SFX)
		return
	AudioManager.play_sfx(AudioManager.BUTTON_SFX)
	visible = false
	Game.start_level(current_level_id)


func _on_close_pressed() -> void:
	AudioManager.play_sfx(AudioManager.BUTTON_SFX)
	visible = false
	current_level_id = ""
