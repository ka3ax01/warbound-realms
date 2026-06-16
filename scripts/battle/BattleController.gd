class_name BattleController
extends Node

const TROOP_STREAM_SCENE: PackedScene = preload("res://scenes/world/TroopStream.tscn")

enum BattleState {
	RUNNING,
	PAUSED,
	VICTORY,
	DEFEAT
}

@export var level_id: String = ""
@export var structures_root_path: NodePath
@export var troop_streams_root_path: NodePath

var selected_structure: Structure
var level_data: Dictionary = {}
var battle_state: BattleState = BattleState.RUNNING
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
	battle_state = BattleState.RUNNING
	for structure: Structure in structures_root.get_children():
		structure.structure_clicked.connect(_on_structure_clicked)
		structure.troops_requested.connect(_on_troops_requested)
		structure.owner_changed.connect(_on_structure_owner_changed)
	enemy_ai.setup(self)


func _process(_delta: float) -> void:
	if not is_finished():
		_check_battle_state()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		request_pause_toggle()
		get_viewport().set_input_as_handled()
		return

	if not can_accept_input():
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_clear_selection()
		get_viewport().set_input_as_handled()


func is_running() -> bool:
	return battle_state == BattleState.RUNNING


func is_paused() -> bool:
	return battle_state == BattleState.PAUSED


func is_finished() -> bool:
	return battle_state == BattleState.VICTORY or battle_state == BattleState.DEFEAT


func can_accept_input() -> bool:
	return is_running()


func can_send_troops() -> bool:
	return is_running()


func can_ai_act() -> bool:
	return is_running()


func request_pause_toggle() -> void:
	if is_finished():
		return
	if is_paused():
		request_resume()
	else:
		battle_state = BattleState.PAUSED
		_apply_pause_state(true)


func request_resume() -> void:
	if not is_paused():
		return
	battle_state = BattleState.RUNNING
	_apply_pause_state(false)


func request_restart() -> void:
	_apply_pause_state(false)
	SceneLoader.goto_battle(Game.selected_level_id)


func request_exit_to_campaign() -> void:
	_apply_pause_state(false)
	SceneLoader.goto_campaign()


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
	if not can_send_troops():
		AudioManager.play_sfx(AudioManager.ERROR_SFX)
		return false
	var sent_amount: float = source.send_troops(target, send_fraction)
	if sent_amount > 0.0:
		AudioManager.play_sfx(AudioManager.SEND_TROOPS_SFX)
		EventBus.troops_sent.emit(source.structure_id, target.structure_id, source.owner_id, int(round(sent_amount)))
	else:
		AudioManager.play_sfx(AudioManager.ERROR_SFX)
	return sent_amount > 0.0


func _on_structure_clicked(clicked: Structure) -> void:
	if not can_accept_input():
		return
	if selected_structure == null:
		if clicked.owner_id == "player":
			_set_selected_structure(clicked)
		else:
			AudioManager.play_sfx(AudioManager.ERROR_SFX)
		return

	if selected_structure == clicked:
		_clear_selection()
		return

	if selected_structure.owner_id == "player" and selected_structure.can_send_to(clicked):
		send_troops(selected_structure, clicked, 0.5)
		_clear_selection()
		return

	AudioManager.play_sfx(AudioManager.ERROR_SFX)
	_set_selected_structure(clicked if clicked.owner_id == "player" else null)


func _on_troops_requested(source: Structure, target: Structure, amount: float) -> void:
	var stream: TroopStream = TROOP_STREAM_SCENE.instantiate() as TroopStream
	troop_streams_root.add_child(stream)
	stream.setup(source, target, amount, source.owner_id)
	stream.arrived.connect(_on_troop_stream_arrived)


func _on_structure_owner_changed(_structure: Structure, _previous_owner: String, _new_owner: String) -> void:
	AudioManager.play_sfx(AudioManager.CAPTURE_SFX)
	EventBus.structure_captured.emit(_structure.structure_id, _previous_owner, _new_owner)
	if selected_structure == _structure and _new_owner != "player":
		_clear_selection()
	call_deferred("_check_battle_state")


func _on_troop_stream_arrived(_stream: TroopStream) -> void:
	call_deferred("_check_battle_state")


func _clear_selection() -> void:
	if selected_structure != null:
		selected_structure.deselect()
		selected_structure = null
	EventBus.structure_selected.emit("", "")


func _set_selected_structure(structure: Structure) -> void:
	if selected_structure != null:
		selected_structure.deselect()
	selected_structure = structure
	if selected_structure != null:
		selected_structure.select()
		AudioManager.play_sfx(AudioManager.TOWER_SELECT_SFX)
		EventBus.structure_selected.emit(selected_structure.structure_id, selected_structure.owner_id)
	else:
		EventBus.structure_selected.emit("", "")


func _check_battle_state() -> void:
	var enemy_structures_left: bool = not get_structures_by_owner("enemy").is_empty()
	var player_structures_left: bool = not get_structures_by_owner("player").is_empty()
	var enemy_streams_left: bool = _has_active_troop_streams("enemy")
	var player_streams_left: bool = _has_active_troop_streams("player")

	if not enemy_structures_left and not enemy_streams_left:
		battle_state = BattleState.VICTORY
		_apply_pause_state(true)
		Game.complete_level(Game.selected_level_id, level_data.get("rewards", {}))
		return

	if not player_structures_left and not player_streams_left:
		battle_state = BattleState.DEFEAT
		_apply_pause_state(true)
		Game.fail_level(Game.selected_level_id)


func _has_active_troop_streams(owner_id: String) -> bool:
	return get_active_troop_stream_count(owner_id) > 0


func _apply_pause_state(is_now_paused: bool) -> void:
	get_tree().paused = is_now_paused
	EventBus.pause_changed.emit(is_now_paused)
