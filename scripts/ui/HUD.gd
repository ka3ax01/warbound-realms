extends Control

@onready var pause_button: Button = $TopBar/PauseButton
@onready var level_label: Label = $TopBar/Panel/Margin/InfoRow/LevelLabel
@onready var selected_label: Label = $TopBar/Panel/Margin/InfoRow/SelectedLabel
@onready var hint_label: Label = $TopBar/Panel/Margin/InfoRow/HintLabel
@onready var status_label: Label = $TopBar/PauseStack/Status
@onready var detail_title: Label = $SelectedPanel/Margin/Stack/Title
@onready var detail_owner: Label = $SelectedPanel/Margin/Stack/Owner
@onready var detail_garrison: Label = $SelectedPanel/Margin/Stack/Garrison
@onready var detail_growth: Label = $SelectedPanel/Margin/Stack/Growth
@onready var detail_level: Label = $SelectedPanel/Margin/Stack/Level
@onready var detail_unit: Label = $SelectedPanel/Margin/Stack/Unit
@onready var detail_links: Label = $SelectedPanel/Margin/Stack/Links
@onready var debug_overlay: Control = $DebugBattleOverlay

var _battle_controller: BattleController
var _selected_structure_id: String = ""


func setup(controller: BattleController) -> void:
	_battle_controller = controller
	if debug_overlay != null and debug_overlay.has_method("setup"):
		debug_overlay.call("setup", controller)


func _ready() -> void:
	pause_button.pressed.connect(_on_pause_pressed)
	EventBus.structure_selected.connect(_on_structure_selected)
	EventBus.structure_updated.connect(_on_structure_updated)
	EventBus.level_loaded.connect(_on_level_loaded)
	EventBus.pause_changed.connect(_on_pause_changed)
	EventBus.battle_won.connect(_on_battle_won)
	EventBus.battle_lost.connect(_on_battle_lost)
	_reset_selected_panel()


func _process(_delta: float) -> void:
	pass


func _on_pause_pressed() -> void:
	if _battle_controller != null:
		AudioManager.play_sfx(AudioManager.BUTTON_SFX)
		_battle_controller.request_pause_toggle()


func _on_structure_selected(structure_id: String, owner_id: String) -> void:
	_selected_structure_id = structure_id
	if structure_id.is_empty():
		selected_label.text = "Selected: none"
		_reset_selected_panel()
		return
	selected_label.text = "Selected: %s [%s]" % [structure_id, owner_id]
	_refresh_selected_panel()


func _on_structure_updated(structure_id: String, _garrison: int) -> void:
	if structure_id == _selected_structure_id:
		_refresh_selected_panel()


func _on_level_loaded(level_id: String) -> void:
	level_label.text = "Level: %s" % level_id
	hint_label.text = "LMB: select/send  RMB: clear  Esc: pause"
	_update_status("Running")


func _on_pause_changed(is_paused: bool) -> void:
	_update_status("Paused" if is_paused else "Running")


func _on_battle_won(_level_id: String, _result: Dictionary) -> void:
	_update_status("Victory")


func _on_battle_lost(_level_id: String, _result: Dictionary) -> void:
	_update_status("Defeat")


func _refresh_selected_panel() -> void:
	if _battle_controller == null or _selected_structure_id.is_empty():
		_reset_selected_panel()
		return
	var structure: Structure = _battle_controller.get_structure_by_id(_selected_structure_id)
	if structure == null:
		_reset_selected_panel()
		return
	detail_title.text = "Structure: %s" % structure.structure_id
	detail_owner.text = "Owner: %s" % structure.owner_id.capitalize()
	detail_garrison.text = "Garrison: %d / %d" % [int(round(structure.garrison)), int(round(structure.max_garrison))]
	detail_growth.text = "Generation: +%s/s" % _format_rate(structure.get_generation_rate())
	detail_level.text = "Level: %d" % structure.level
	detail_unit.text = "Unit: %s" % _format_unit_type(structure.get_unit_type())
	detail_links.text = "Links: %s" % ", ".join(structure.connected_to) if not structure.connected_to.is_empty() else "Links: -"


func _reset_selected_panel() -> void:
	detail_title.text = "No Tower Selected"
	if _battle_controller == null:
		detail_owner.text = "Player Towers: -"
		detail_garrison.text = "Enemy Towers: -"
		detail_growth.text = "Player Streams: -"
		detail_level.text = "Enemy Streams: -"
		detail_unit.text = "Unit: -"
		detail_links.text = "Links: -"
		return
	detail_owner.text = "Player Towers: %d" % _battle_controller.get_structure_count("player")
	detail_garrison.text = "Enemy Towers: %d" % _battle_controller.get_structure_count("enemy")
	detail_growth.text = "Player Streams: %d" % _battle_controller.get_active_troop_stream_count("player")
	detail_level.text = "Enemy Streams: %d" % _battle_controller.get_active_troop_stream_count("enemy")
	detail_unit.text = "Unit: -"
	detail_links.text = "Links: -"


func _update_status(value: String) -> void:
	status_label.text = value


func _format_rate(value: float) -> String:
	if is_equal_approx(value, round(value)):
		return str(int(round(value)))
	return String.num(value, 1)


func _format_unit_type(value: String) -> String:
	return value.capitalize()
