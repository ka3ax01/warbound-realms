extends Control

var current_level_id := ""


func _ready() -> void:
	visible = false
	$Panel/VBoxContainer/StartButton.pressed.connect(_on_start_pressed)
	$Panel/VBoxContainer/CloseButton.pressed.connect(_on_close_pressed)


func show_level(level_data: Dictionary) -> void:
	current_level_id = level_data.get("id", "")
	$Panel/VBoxContainer/Title.text = level_data.get("id", "")
	$Panel/VBoxContainer/Description.text = level_data.get("description", "")
	visible = true


func _on_start_pressed() -> void:
	if current_level_id.is_empty():
		return
	Game.start_level(current_level_id)


func _on_close_pressed() -> void:
	visible = false
