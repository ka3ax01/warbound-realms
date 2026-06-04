extends Control

@onready var pause_button: Button = $TopBar/PauseButton
@onready var level_label: Label = $TopBar/Panel/Margin/InfoRow/LevelLabel
@onready var selected_label: Label = $TopBar/Panel/Margin/InfoRow/SelectedLabel
@onready var hint_label: Label = $TopBar/Panel/Margin/InfoRow/HintLabel
@onready var player_towers_label: Label = $DebugPanel/Margin/DebugColumn/PlayerTowersLabel
@onready var enemy_towers_label: Label = $DebugPanel/Margin/DebugColumn/EnemyTowersLabel
@onready var player_streams_label: Label = $DebugPanel/Margin/DebugColumn/PlayerStreamsLabel
@onready var enemy_streams_label: Label = $DebugPanel/Margin/DebugColumn/EnemyStreamsLabel

var _battle_controller: BattleController


func _ready() -> void:
	pause_button.pressed.connect(_on_pause_pressed)
	EventBus.structure_selected.connect(_on_structure_selected)
	EventBus.structure_updated.connect(_on_structure_updated)
	EventBus.level_loaded.connect(_on_level_loaded)
	_battle_controller = get_node_or_null("/root/BattleScene/Controllers/BattleController") as BattleController


func _process(_delta: float) -> void:
	if _battle_controller == null:
		_battle_controller = get_node_or_null("/root/BattleScene/Controllers/BattleController") as BattleController
		if _battle_controller == null:
			return

	player_towers_label.text = "Player Towers: %d" % _battle_controller.get_structure_count("player")
	enemy_towers_label.text = "Enemy Towers: %d" % _battle_controller.get_structure_count("enemy")
	player_streams_label.text = "Player Streams: %d" % _battle_controller.get_active_troop_stream_count("player")
	enemy_streams_label.text = "Enemy Streams: %d" % _battle_controller.get_active_troop_stream_count("enemy")


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
