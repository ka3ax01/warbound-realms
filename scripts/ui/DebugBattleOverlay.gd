extends Control

@export var dev_mode_only: bool = true

@onready var player_towers_label: Label = $DebugPanel/Margin/DebugColumn/PlayerTowersLabel
@onready var enemy_towers_label: Label = $DebugPanel/Margin/DebugColumn/EnemyTowersLabel
@onready var player_streams_label: Label = $DebugPanel/Margin/DebugColumn/PlayerStreamsLabel
@onready var enemy_streams_label: Label = $DebugPanel/Margin/DebugColumn/EnemyStreamsLabel

var _battle_controller: BattleController


func setup(controller: BattleController) -> void:
	_battle_controller = controller
	visible = not dev_mode_only or OS.is_debug_build()


func _process(_delta: float) -> void:
	if _battle_controller == null:
		return

	player_towers_label.text = "Player Towers: %d" % _battle_controller.get_structure_count("player")
	enemy_towers_label.text = "Enemy Towers: %d" % _battle_controller.get_structure_count("enemy")
	player_streams_label.text = "Player Streams: %d" % _battle_controller.get_active_troop_stream_count("player")
	enemy_streams_label.text = "Enemy Streams: %d" % _battle_controller.get_active_troop_stream_count("enemy")
