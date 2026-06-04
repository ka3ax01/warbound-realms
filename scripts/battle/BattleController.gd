class_name BattleController
extends Node

const TROOP_STREAM_SCENE := preload("res://scenes/world/TroopStream.tscn")

@export var structures_root_path: NodePath
@export var troop_streams_root_path: NodePath

var selected_structure: Structure
var level_data: LevelData

@onready var structures_root: Node = get_node(structures_root_path)
@onready var troop_streams_root: Node = get_node(troop_streams_root_path)
@onready var level_loader: LevelLoader = $LevelLoader
@onready var enemy_ai: EnemyAI = $EnemyAI
@onready var objective_tracker: ObjectiveTracker = $ObjectiveTracker


func _ready() -> void:
	EventBus.structure_selected.connect(_on_structure_selected)
	EventBus.structure_captured.connect(_on_structure_captured)
	level_data = level_loader.load_level(Game.selected_level_id, structures_root)
	for structure in structures_root.get_children():
		structure.troops_requested.connect(_on_troops_requested)
	enemy_ai.setup(self, level_data.ai)
	objective_tracker.setup(self, level_data)


func _process(_delta: float) -> void:
	objective_tracker.check_state()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		var should_pause := not get_tree().paused
		get_tree().paused = should_pause
		EventBus.pause_changed.emit(should_pause)
		get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_clear_selection()
		get_viewport().set_input_as_handled()


func get_structures_by_owner(owner_id: String) -> Array[Structure]:
	var result: Array[Structure] = []
	for structure: Structure in structures_root.get_children():
		if structure.owner_id == owner_id:
			result.append(structure)
	return result


func get_attack_candidates(owner_id: String) -> Array[Structure]:
	var result: Array[Structure] = []
	for structure: Structure in structures_root.get_children():
		if structure.owner_id != owner_id:
			result.append(structure)
	return result


func all_structures_owned_by(owner_id: String) -> bool:
	for structure: Structure in structures_root.get_children():
		if structure.owner_id != owner_id:
			return false
	return true


func send_ai_troops(source: Structure, target: Structure, send_fraction: float) -> void:
	source.send_troops(target, send_fraction)


func _on_structure_selected(structure_id: String, owner_id: String) -> void:
	var clicked := _find_structure_by_id(structure_id)
	if clicked == null:
		return

	if selected_structure == null:
		if owner_id == Constants.PLAYER_FACTION_ID:
			selected_structure = clicked
			selected_structure.select()
		return

	if selected_structure == clicked:
		_clear_selection()
		return

	if selected_structure.owner_id == Constants.PLAYER_FACTION_ID and selected_structure.can_send_to(clicked):
		selected_structure.send_troops(clicked, Constants.DEFAULT_SEND_FRACTION)
		_clear_selection()
		return

	selected_structure.deselect()
	selected_structure = clicked if clicked.owner_id == Constants.PLAYER_FACTION_ID else null
	if selected_structure != null:
		selected_structure.select()


func _find_structure_by_id(structure_id: String) -> Structure:
	for structure: Structure in structures_root.get_children():
		if structure.structure_id == structure_id:
			return structure
	return null


func _on_troops_requested(source: Structure, target: Structure, amount: int) -> void:
	var stream := TROOP_STREAM_SCENE.instantiate() as TroopStream
	troop_streams_root.add_child(stream)
	stream.setup(source, target, amount, source.owner_id)


func _on_structure_captured(_structure_id: String, _old_owner_id: String, _new_owner_id: String) -> void:
	objective_tracker.check_state()


func _clear_selection() -> void:
	if selected_structure != null:
		selected_structure.deselect()
		selected_structure = null
