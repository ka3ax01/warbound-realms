class_name EnemyAI
extends Node

var battle_controller: BattleController
var think_interval: float = 2.5
var _time_accumulator: float = 0.0


func setup(controller: BattleController) -> void:
	battle_controller = controller


func _process(delta: float) -> void:
	if battle_controller == null or not battle_controller.can_ai_act():
		return
	_time_accumulator += delta
	if _time_accumulator >= think_interval:
		_time_accumulator = 0.0
		_take_turn()


func _take_turn() -> void:
	var owned: Array[Structure] = battle_controller.get_structures_by_owner("enemy")
	if owned.is_empty():
		return

	var available_sources: Array[Structure] = []
	for structure in owned:
		if structure.garrison > 20.0:
			available_sources.append(structure)
	if available_sources.is_empty():
		return

	for source in available_sources:
		var possible_targets: Array[Structure] = []
		for neighbor in source.neighbors:
			if neighbor.owner_id == "neutral" or neighbor.owner_id == "player":
				possible_targets.append(neighbor)
		if possible_targets.is_empty():
			continue

		possible_targets.sort_custom(func(a: Structure, b: Structure) -> bool: return a.garrison < b.garrison)
		battle_controller.send_troops(source, possible_targets[0], 0.5)
		return
