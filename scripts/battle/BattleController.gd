class_name BattleController
extends Node

const TROOP_STREAM_SCENE: PackedScene = preload("res://scenes/world/TroopStream.tscn")

signal battle_won
signal battle_lost

@export var level_id: String = ""
@export var structures_root_path: NodePath
@export var troop_streams_root_path: NodePath

var selected_structure: Structure
var level_data: Dictionary = {}
var battle_finished: bool = false
var structures_by_id: Dictionary = {}

@onready var structures_root: Node = get_node(structures_root_path)
@onready var troop_streams_root: Node = get_node(troop_streams_root_path)
@onready var level_loader: LevelLoader = $LevelLoader
@onready var enemy_ai: EnemyAI = $EnemyAI


func _ready() -> void:
	var resolved_level_id: String = level_id if not level_id.is_empty() else Game.selected_level_id
	level_data = level_loader.load_level(resolved_level_id, structures_root)
	Game.current_level_data = level_data
	structures_by_id = level_loader.structures_by_id.duplicate()
	for structure: Structure in structures_root.get_children():
		structure.structure_clicked.connect(_on_structure_clicked)
		structure.troops_requested.connect(_on_troops_requested)
		structure.owner_changed.connect(_on_structure_owner_changed)
	enemy_ai.setup(self)


func _process(_delta: float) -> void:
	if not battle_finished:
		_check_battle_state()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		var should_pause: bool = not get_tree().paused
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


func get_structure_count(owner_id: String) -> int:
	return get_structures_by_owner(owner_id).size()


func get_structure_by_id(structure_id: String) -> Structure:
	return structures_by_id.get(structure_id) as Structure


func get_active_troop_stream_count(owner_id: String) -> int:
	var count: int = 0
	for child: Node in troop_streams_root.get_children():
		var stream: TroopStream = child as TroopStream
		if stream != null and stream.owner_id == owner_id:
			count += 1
	return count


func send_troops(source: Structure, target: Structure, send_fraction: float = 0.5) -> bool:
	if battle_finished:
		return false
	var sent_amount: float = source.send_troops(target, send_fraction)
	return sent_amount > 0.0


func _on_structure_clicked(clicked: Structure) -> void:
	if selected_structure == null:
		if clicked.owner_id == "player":
			selected_structure = clicked
			selected_structure.select()
		return

	if selected_structure == clicked:
		_clear_selection()
		return

	if selected_structure.owner_id == "player" and selected_structure.can_send_to(clicked):
		send_troops(selected_structure, clicked, 0.5)
		_clear_selection()
		return

	selected_structure.deselect()
	selected_structure = clicked if clicked.owner_id == "player" else null
	if selected_structure != null:
		selected_structure.select()


func _on_troops_requested(source: Structure, target: Structure, amount: float) -> void:
	var stream: TroopStream = TROOP_STREAM_SCENE.instantiate() as TroopStream
	troop_streams_root.add_child(stream)
	stream.setup(source, target, amount, source.owner_id)
	stream.arrived.connect(_on_troop_stream_arrived)


func _on_structure_owner_changed(_structure: Structure, _previous_owner: String, _new_owner: String) -> void:
	call_deferred("_check_battle_state")


func _on_troop_stream_arrived(_stream: TroopStream) -> void:
	call_deferred("_check_battle_state")


func _clear_selection() -> void:
	if selected_structure != null:
		selected_structure.deselect()
		selected_structure = null


func _check_battle_state() -> void:
	var enemy_structures_left: bool = not get_structures_by_owner("enemy").is_empty()
	var player_structures_left: bool = not get_structures_by_owner("player").is_empty()
	var enemy_streams_left: bool = _has_active_troop_streams("enemy")
	var player_streams_left: bool = _has_active_troop_streams("player")

	if not enemy_structures_left and not enemy_streams_left:
		battle_finished = true
		Game.complete_level(Game.selected_level_id, level_data.get("rewards", {}))
		battle_won.emit()
		return

	if not player_structures_left and not player_streams_left:
		battle_finished = true
		Game.fail_level(Game.selected_level_id)
		battle_lost.emit()


func _has_active_troop_streams(owner_id: String) -> bool:
	return get_active_troop_stream_count(owner_id) > 0
