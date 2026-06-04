extends Control

const LEVEL_INDEX_PATH := "res://data/levels/level_index.json"
const JsonUtilsScript := preload("res://scripts/utils/JsonUtils.gd")

@onready var level_list: VBoxContainer = $MarginContainer/Content/LevelList
@onready var title_label: Label = $MarginContainer/Content/Header/Title
@onready var back_button: Button = $MarginContainer/Content/Footer/BackButton
@onready var popup: Control = $LevelInfoPopup

var level_index: Array = []


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	title_label.text = "Campaign Map"
	_load_levels()


func _load_levels() -> void:
	var raw_index: Variant = JsonUtilsScript.load_json_file(LEVEL_INDEX_PATH, [])
	level_index = raw_index if raw_index is Array else []
	for child in level_list.get_children():
		child.queue_free()

	for level in level_index:
		var level_row := HBoxContainer.new()
		level_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var button := Button.new()
		var level_id: String = str(level.get("id", "unknown"))
		var level_name: String = str(level.get("name", level_id))
		button.text = "%s - %s" % [level_id, level_name]
		button.disabled = not SaveManager.is_level_unlocked(level_id)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_on_level_pressed.bind(level_id))
		level_row.add_child(button)

		var stars_label := Label.new()
		var stars: int = SaveManager.get_level_stars(level_id)
		stars_label.text = "Locked" if button.disabled else ("Stars: %s" % _format_stars(stars))
		level_row.add_child(stars_label)

		level_list.add_child(level_row)


func _on_level_pressed(level_id: String) -> void:
	var level_data: Variant = JsonUtilsScript.load_json_file("res://data/levels/%s.json" % level_id, {})
	if level_data is Dictionary:
		popup.show_level(level_data)


func _on_back_pressed() -> void:
	SceneLoader.goto_main_menu()


func _format_stars(count: int) -> String:
	return "%s%s%s" % [
		"*" if count >= 1 else "-",
		"*" if count >= 2 else "-",
		"*" if count >= 3 else "-"
	]
