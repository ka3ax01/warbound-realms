extends Node

const STRUCTURE_SCENE: PackedScene = preload("res://scenes/world/Structure.tscn")
const GAME_BALANCE: Resource = preload("res://data/config/game_balance.tres")

var _failures := 0


func _ready() -> void:
	_test_friendly_generates_units()
	_test_enemy_generates_units()
	_test_neutral_does_not_generate_units()
	_test_garrison_is_capped()
	_test_neutral_to_friendly_starts_generation()
	_test_neutral_to_enemy_starts_generation()
	_test_friendly_or_enemy_to_neutral_stops_generation()
	_test_owner_changes_do_not_duplicate_generation()
	_test_removed_or_disabled_structure_does_not_generate()
	_test_rate_and_limit_come_from_configuration()
	_test_unit_type_defaults_and_capture_persistence()
	for tower: Structure in get_children():
		tower.queue_free()
	call_deferred("_finish")


func _finish() -> void:
	get_tree().quit(0 if _failures == 0 else 1)


func _test_friendly_generates_units() -> void:
	var tower := _make_tower("player", 10.0, 20.0)
	tower.advance_unit_generation(1.0)
	_expect_equal("friendly tower generates", tower.garrison, 10.0 + _generation_rate())


func _test_enemy_generates_units() -> void:
	var tower := _make_tower("enemy", 10.0, 20.0)
	tower.advance_unit_generation(1.0)
	_expect_equal("enemy tower generates", tower.garrison, 10.0 + _generation_rate())


func _test_neutral_does_not_generate_units() -> void:
	var tower := _make_tower("neutral", 10.0, 20.0)
	tower.advance_unit_generation(3.0)
	_expect_equal("neutral tower does not generate", tower.garrison, 10.0)


func _test_garrison_is_capped() -> void:
	var tower := _make_tower("player", 9.0, 10.0)
	tower.advance_unit_generation(1.0)
	tower.advance_unit_generation(1.0)
	_expect_equal("generation respects max garrison", tower.garrison, 10.0)


func _test_neutral_to_friendly_starts_generation() -> void:
	var tower := _make_tower("neutral", 0.0, 20.0)
	tower.resolve_combat("player", 1.0)
	tower.advance_unit_generation(1.0)
	_expect_equal("neutral to friendly starts generation", tower.garrison, 1.0 + _generation_rate())


func _test_neutral_to_enemy_starts_generation() -> void:
	var tower := _make_tower("neutral", 0.0, 20.0)
	tower.resolve_combat("enemy", 1.0)
	tower.advance_unit_generation(1.0)
	_expect_equal("neutral to enemy starts generation", tower.garrison, 1.0 + _generation_rate())


func _test_friendly_or_enemy_to_neutral_stops_generation() -> void:
	for owner_id: String in ["player", "enemy"]:
		var tower := _make_tower(owner_id, 1.0, 20.0)
		tower.resolve_combat("neutral", 2.0)
		var garrison_before := tower.garrison
		tower.advance_unit_generation(2.0)
		_expect_equal("%s to neutral stops generation" % owner_id, tower.garrison, garrison_before)


func _test_owner_changes_do_not_duplicate_generation() -> void:
	var tower := _make_tower("player", 1.0, 20.0)
	tower.resolve_combat("enemy", 2.0)
	tower.resolve_combat("neutral", 2.0)
	tower.resolve_combat("player", 2.0)
	tower.advance_unit_generation(1.0)
	_expect_equal("owner changes keep one generation cycle", tower.garrison, 1.0 + _generation_rate())


func _test_removed_or_disabled_structure_does_not_generate() -> void:
	var disabled_tower := _make_tower("player", 1.0, 20.0)
	disabled_tower.process_mode = Node.PROCESS_MODE_DISABLED
	disabled_tower.advance_unit_generation(1.0)
	_expect_equal("disabled tower does not generate", disabled_tower.garrison, 1.0)

	var removed_tower := _make_tower("player", 1.0, 20.0)
	removed_tower.queue_free()
	removed_tower.advance_unit_generation(1.0)
	_expect_equal("queued-for-removal tower does not generate", removed_tower.garrison, 1.0)


func _test_rate_and_limit_come_from_configuration() -> void:
	var tower := _make_tower("player", 1.0, 6.0)
	tower.advance_unit_generation(0.25)
	_expect_equal("generation rate comes from balance resource", tower.garrison, 2.0)
	tower.advance_unit_generation(2.0)
	_expect_equal("max garrison comes from level data", tower.garrison, 6.0)


func _test_unit_type_defaults_and_capture_persistence() -> void:
	var missing_type := _make_tower("player", 10.0, 20.0)
	_expect_true("missing unit type defaults to infantry", missing_type.get_unit_type() == "infantry")

	var invalid_type := _make_tower("neutral", 1.0, 20.0, "unknown")
	_expect_true("invalid unit type defaults to infantry", invalid_type.get_unit_type() == "infantry")

	var archer_tower := _make_tower("neutral", 1.0, 20.0, "archer")
	archer_tower.resolve_combat("player", 2.0)
	_expect_true("capture keeps tower unit type", archer_tower.get_unit_type() == "archer")


func _make_tower(
	owner_id: String,
	garrison: float,
	max_garrison: float,
	unit_type: String = ""
) -> Structure:
	var tower := STRUCTURE_SCENE.instantiate() as Structure
	add_child(tower)
	var data := {
		"id": "test_%d" % get_child_count(),
		"owner": owner_id,
		"garrison": garrison,
		"max_garrison": max_garrison,
		"connected_to": []
	}
	if not unit_type.is_empty():
		data["unit_type"] = unit_type
	tower.setup_from_data(data)
	return tower


func _expect_equal(label: String, actual: float, expected: float) -> void:
	if not is_equal_approx(actual, expected):
		_failures += 1
		push_error("%s: expected %s, got %s" % [label, expected, actual])


func _expect_true(label: String, value: bool) -> void:
	if not value:
		_failures += 1
		push_error("Expectation failed: %s" % label)


func _generation_rate() -> float:
	return float(GAME_BALANCE.get("structure_generation_rate"))
