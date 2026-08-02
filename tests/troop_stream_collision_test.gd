extends Node

const STRUCTURE_SCENE: PackedScene = preload("res://scenes/world/Structure.tscn")
const TROOP_STREAM_SCENE: PackedScene = preload("res://scenes/world/TroopStream.tscn")

var _failures := 0
var _is_running := true
var _fixture_index := 0
var _finished_counts: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run_tests()


func _run_tests() -> void:
	_test_player_wins_with_remainder()
	_test_enemy_wins_with_remainder()
	_test_equal_streams_destroy_each_other()
	_test_allied_streams_do_not_fight()
	_test_duplicate_resolution_is_ignored()
	_test_destroyed_stream_does_not_arrive()
	_test_winner_updates_label_and_arrives()
	await _test_area_detection_with_opposing_streams()
	_test_pause_guard_blocks_collision()
	await _test_tree_pause_blocks_movement_and_collision()
	await _test_destroyed_stream_is_removed()
	call_deferred("_finish")


func _test_player_wins_with_remainder() -> void:
	var player := _make_stream("player", 20.0)
	var enemy := _make_stream("enemy", 12.0)
	player._resolve_enemy_collision(enemy)
	_expect_equal("player wins with remainder", player.amount, 8.0)
	_expect_true("enemy stream is destroyed", enemy.is_queued_for_deletion())


func _test_enemy_wins_with_remainder() -> void:
	var player := _make_stream("player", 7.0)
	var enemy := _make_stream("enemy", 15.0)
	player._resolve_enemy_collision(enemy)
	_expect_equal("enemy wins with remainder", enemy.amount, 8.0)
	_expect_true("player stream is destroyed", player.is_queued_for_deletion())


func _test_equal_streams_destroy_each_other() -> void:
	var player := _make_stream("player", 10.0)
	var enemy := _make_stream("enemy", 10.0)
	player._resolve_enemy_collision(enemy)
	_expect_true("equal player stream is destroyed", player.is_queued_for_deletion())
	_expect_true("equal enemy stream is destroyed", enemy.is_queued_for_deletion())


func _test_allied_streams_do_not_fight() -> void:
	for owner_id: String in ["player", "enemy"]:
		var first := _make_stream(owner_id, 10.0)
		var second := _make_stream(owner_id, 6.0)
		first._resolve_enemy_collision(second)
		_expect_equal("%s allied first amount unchanged" % owner_id, first.amount, 10.0)
		_expect_equal("%s allied second amount unchanged" % owner_id, second.amount, 6.0)
		_expect_true("%s allied first continues" % owner_id, not first.is_queued_for_deletion())
		_expect_true("%s allied second continues" % owner_id, not second.is_queued_for_deletion())


func _test_duplicate_resolution_is_ignored() -> void:
	var player := _make_stream("player", 20.0)
	var enemy := _make_stream("enemy", 12.0)
	player._resolve_enemy_collision(enemy)
	player._resolve_enemy_collision(enemy)
	enemy._resolve_enemy_collision(player)
	_expect_equal("duplicate collision keeps one subtraction", player.amount, 8.0)
	_expect_equal("destroyed stream finishes once", _finished_counts.get(enemy.get_instance_id(), 0), 1)


func _test_destroyed_stream_does_not_arrive() -> void:
	var player_target := _make_structure("player", Vector2(0, 0), 10.0)
	var enemy_target := _make_structure("enemy", Vector2(100, 0), 10.0)
	var player := _make_stream("player", 7.0, player_target, enemy_target)
	var enemy := _make_stream("enemy", 15.0)
	var garrison_before := enemy_target.garrison
	player._resolve_enemy_collision(enemy)
	player._process(10.0)
	_expect_equal("destroyed stream does not resolve target combat", enemy_target.garrison, garrison_before)
	_expect_equal("destroyed stream has one finish event", _finished_counts.get(player.get_instance_id(), 0), 1)


func _test_winner_updates_label_and_arrives() -> void:
	var player_source := _make_structure("player", Vector2(0, 0), 10.0)
	var enemy_target := _make_structure("enemy", Vector2(100, 0), 5.0)
	var player := _make_stream("player", 20.0, player_source, enemy_target)
	var enemy := _make_stream("enemy", 12.0)
	player._resolve_enemy_collision(enemy)
	_expect_equal("winner amount label updates", float(player.label.text), 8.0)
	player.global_position = enemy_target.global_position
	player._process(0.0)
	_expect_equal("winner delivers remaining troops", enemy_target.garrison, 3.0)
	_expect_true("winner arrival finishes stream", player.is_queued_for_deletion())


func _test_pause_guard_blocks_collision() -> void:
	var player := _make_stream("player", 20.0)
	var enemy := _make_stream("enemy", 12.0)
	_is_running = false
	player._resolve_enemy_collision(enemy)
	_expect_equal("paused battle keeps player amount", player.amount, 20.0)
	_expect_equal("paused battle keeps enemy amount", enemy.amount, 12.0)
	_is_running = true
	player._resolve_enemy_collision(enemy)
	_expect_equal("resumed battle resolves collision", player.amount, 8.0)


func _test_tree_pause_blocks_movement_and_collision() -> void:
	var player_source := _make_structure("player", Vector2(100000, 0), 10.0)
	var player_target := _make_structure("enemy", Vector2(100120, 0), 10.0)
	var enemy_source := _make_structure("enemy", Vector2(100012, 0), 10.0)
	var enemy_target := _make_structure("player", Vector2(99880, 0), 10.0)
	var player := _make_stream("player", 20.0, player_source, player_target)
	var enemy := _make_stream("enemy", 12.0, enemy_source, enemy_target)
	player.process_mode = Node.PROCESS_MODE_PAUSABLE
	enemy.process_mode = Node.PROCESS_MODE_PAUSABLE
	var player_start := player.global_position
	get_tree().paused = true
	await get_tree().process_frame
	_expect_equal("paused stream does not move", player.global_position.x, player_start.x)
	_expect_equal("paused stream collision is not resolved", player.amount, 20.0)
	get_tree().paused = false
	player._on_detection_area_entered(enemy.detection_area)
	_expect_equal("resumed stream collision resolves", player.amount, 8.0)


func _test_area_detection_with_opposing_streams() -> void:
	var player_source := _make_structure("player", Vector2(200000, 0), 10.0)
	var player_target := _make_structure("enemy", Vector2(200120, 0), 10.0)
	var enemy_source := _make_structure("enemy", Vector2(200024, 0), 10.0)
	var enemy_target := _make_structure("player", Vector2(199880, 0), 10.0)
	var player := _make_stream("player", 10.0, player_source, player_target)
	var enemy := _make_stream("enemy", 4.0, enemy_source, enemy_target)
	player._process(0.05)
	enemy._process(0.05)
	await get_tree().physics_frame
	await get_tree().physics_frame
	_expect_equal("Area2D detects opposing streams", player.amount, 6.0)
	_expect_true("Area2D destroys weaker stream", not is_instance_valid(enemy) or enemy.is_queued_for_deletion())


func _test_destroyed_stream_is_removed() -> void:
	var player := _make_stream("player", 5.0)
	var enemy := _make_stream("enemy", 9.0)
	var player_id := player.get_instance_id()
	player._resolve_enemy_collision(enemy)
	await get_tree().process_frame
	_expect_true("destroyed stream is removed from tree", not _has_stream_with_id(player_id))


func _make_stream(
	owner_id: String,
	amount: float,
	stream_source: Structure = null,
	stream_target: Structure = null
) -> TroopStream:
	_fixture_index += 1
	var origin := Vector2(1000.0 * _fixture_index, 0.0)
	var source := stream_source if stream_source != null else _make_structure(owner_id, origin, 10.0)
	var target_owner := "enemy" if owner_id == "player" else "player"
	var target := stream_target if stream_target != null else _make_structure(target_owner, origin + Vector2(200, 0), 10.0)
	var stream := TROOP_STREAM_SCENE.instantiate() as TroopStream
	add_child(stream)
	stream.set_battle_running_guard(Callable(self, "_battle_is_running"))
	stream.finished.connect(_on_stream_finished)
	stream.setup(source, target, amount, owner_id)
	return stream


func _make_structure(owner_id: String, world_position: Vector2, garrison: float) -> Structure:
	_fixture_index += 1
	var structure := STRUCTURE_SCENE.instantiate() as Structure
	add_child(structure)
	structure.setup_from_data({
		"id": "stream_test_structure_%d" % _fixture_index,
		"owner": owner_id,
		"position": {"x": world_position.x, "y": world_position.y},
		"garrison": garrison,
		"max_garrison": 100.0,
		"connected_to": []
	})
	return structure


func _battle_is_running() -> bool:
	return _is_running


func _on_stream_finished(stream: TroopStream, _reason: int) -> void:
	var stream_id := stream.get_instance_id()
	_finished_counts[stream_id] = int(_finished_counts.get(stream_id, 0)) + 1


func _has_stream_with_id(instance_id: int) -> bool:
	for child in get_children():
		if child is TroopStream and child.get_instance_id() == instance_id:
			return true
	return false


func _expect_equal(label: String, actual: float, expected: float) -> void:
	if not is_equal_approx(actual, expected):
		_failures += 1
		push_error("%s: expected %s, got %s" % [label, expected, actual])


func _expect_true(label: String, value: bool) -> void:
	if not value:
		_failures += 1
		push_error("Expectation failed: %s" % label)


func _finish() -> void:
	for child in get_children():
		child.queue_free()
	get_tree().quit(0 if _failures == 0 else 1)
