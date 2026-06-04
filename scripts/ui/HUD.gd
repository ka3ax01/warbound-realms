extends Control

@onready var pause_button: Button = $TopBar/PauseButton
@onready var level_label: Label = $TopBar/Panel/Margin/InfoRow/LevelLabel
@onready var selected_label: Label = $TopBar/Panel/Margin/InfoRow/SelectedLabel
@onready var hint_label: Label = $TopBar/Panel/Margin/InfoRow/HintLabel


func _ready() -> void:
	pause_button.pressed.connect(_on_pause_pressed)
	EventBus.structure_selected.connect(_on_structure_selected)
	EventBus.structure_updated.connect(_on_structure_updated)
	EventBus.level_loaded.connect(_on_level_loaded)


func _on_pause_pressed() -> void:
	var should_pause := not get_tree().paused
	get_tree().paused = should_pause
	EventBus.pause_changed.emit(should_pause)


func _on_structure_selected(structure_id: String, owner_id: String) -> void:
	selected_label.text = "Selected: %s [%s]" % [structure_id, owner_id]


func _on_structure_updated(_structure_id: String, _garrison: int) -> void:
	pass


func _on_level_loaded(level_id: String) -> void:
	level_label.text = "Level: %s" % level_id
	hint_label.text = "LMB: select/send  RMB: clear  Esc: pause"
