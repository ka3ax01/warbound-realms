class_name EnemyAI
extends Node

var battle_controller: BattleController
var think_interval := 1.5
var _time_accumulator := 0.0


func setup(controller: BattleController, config: Dictionary) -> void:
	battle_controller = controller
	think_interval = float(config.get("think_interval", 1.5))


func _process(delta: float) -> void:
	if battle_controller == null or get_tree().paused:
		return
	_time_accumulator += delta
	if _time_accumulator >= think_interval:
		_time_accumulator = 0.0
		_take_turn()


func _take_turn() -> void:
	var owned := battle_controller.get_structures_by_owner("enemy_01")
	var targets := battle_controller.get_attack_candidates("enemy_01")
	if owned.is_empty() or targets.is_empty():
		return

	owned.sort_custom(func(a: Structure, b: Structure): return a.garrison > b.garrison)
	var source: Structure = owned[0]
	if source.garrison < 8:
		return

	targets.sort_custom(func(a: Structure, b: Structure): return a.garrison < b.garrison)
	for target in targets:
		if source.can_send_to(target):
			battle_controller.send_ai_troops(source, target, 0.5)
			return
