extends Control

const LEVEL_INDEX_PATH := "res://data/levels/level_index.json"
const JsonUtilsScript := preload("res://scripts/utils/JsonUtils.gd")

var level_index: Array = []


func _ready() -> void:
	$MarginContainer/VBoxContainer/BackButton.pressed.connect(_on_back_pressed)
	_load_levels()


func _load_levels() -> void:
	var raw_index: Variant = JsonUtilsScript.load_json_file(LEVEL_INDEX_PATH, [])
	level_index = raw_index if raw_index is Array else []
	var list := $MarginContainer/VBoxContainer/LevelList
	for child in list.get_children():
		child.queue_free()

	for level in level_index:
		var button := Button.new()
		button.text = level.get("id", "unknown")
		button.disabled = not SaveManager.is_level_unlocked(level.get("id", ""))
		button.pressed.connect(_on_level_pressed.bind(level))
		list.add_child(button)


func _on_level_pressed(level_data: Dictionary) -> void:
	var popup := $LevelInfoPopup
	popup.show_level(level_data)


func _on_back_pressed() -> void:
	SceneLoader.goto_main_menu()
