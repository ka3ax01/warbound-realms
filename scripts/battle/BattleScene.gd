extends Node2D

@onready var battle_controller: BattleController = $Controllers/BattleController
@onready var hud: Control = $CanvasLayer/HUD
@onready var pause_menu: Control = $CanvasLayer/PauseMenu


func _ready() -> void:
	AudioManager.play_battle_music()
	if hud.has_method("setup"):
		hud.call("setup", battle_controller)
	if pause_menu.has_method("setup"):
		pause_menu.call("setup", battle_controller)
