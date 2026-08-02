class_name TroopStream
extends Node2D

signal arrived(stream: TroopStream)
signal finished(stream: TroopStream, reason: int)

enum FinishReason {
	ARRIVED,
	DESTROYED_IN_TRANSIT,
	INVALID_TARGET
}

@export var speed: float = 180.0

var owner_id: String = ""
var amount: float = 0.0
var source: Structure
var target: Structure
var _travel_time: float = 0.0
var _battle_running_guard: Callable
var _is_finished := false
var _resolving_collision := false

@onready var glow: ColorRect = $Glow
@onready var trail: ColorRect = $Trail
@onready var marker: ColorRect = $Marker
@onready var label: Label = $AmountLabel
@onready var detection_area: Area2D = $DetectionArea


func _ready() -> void:
	detection_area.area_entered.connect(_on_detection_area_entered)


func setup(stream_source: Structure, stream_target: Structure, troop_amount: float, troop_owner: String) -> void:
	source = stream_source
	target = stream_target
	amount = troop_amount
	owner_id = troop_owner
	global_position = source.global_position
	_refresh_amount_label()
	if not _has_valid_combat_owner() or amount <= 0.0:
		push_error("TroopStream: invalid owner '%s' or amount '%s'." % [owner_id, amount])
		call_deferred("_finish", FinishReason.DESTROYED_IN_TRANSIT)
		return
	var color: Color = _get_owner_color()
	var glow_color: Color = color
	var trail_color: Color = color
	glow_color.a = 0.35
	trail_color.a = 0.25
	marker.color = color
	glow.color = glow_color
	trail.color = trail_color


func set_battle_running_guard(guard: Callable) -> void:
	_battle_running_guard = guard


func _process(delta: float) -> void:
	if _is_finished:
		return
	if target == null:
		_finish(FinishReason.INVALID_TARGET)
		return

	_travel_time += delta
	global_position = global_position.move_toward(target.global_position, speed * delta)
	var direction: Vector2 = global_position.direction_to(target.global_position)
	if direction.length_squared() > 0.0:
		rotation = direction.angle()
	var pulse_scale: float = 0.94 + (sin(_travel_time * 8.0) + 1.0) * 0.05
	scale = Vector2.ONE * pulse_scale
	if global_position.distance_to(target.global_position) <= 4.0:
		target.resolve_combat(owner_id, amount)
		_finish(FinishReason.ARRIVED)


func _on_detection_area_entered(area: Area2D) -> void:
	var other: TroopStream = area.get_parent() as TroopStream
	if other == null or other == self:
		return
	if not _can_resolve_enemy_collision(other):
		return
	if owner_id == other.owner_id:
		return
	if get_instance_id() > other.get_instance_id():
		return
	_resolve_enemy_collision(other)


func _can_resolve_enemy_collision(other: TroopStream) -> bool:
	return (
		not _is_finished
		and not other._is_finished
		and not _resolving_collision
		and not other._resolving_collision
		and _has_valid_combat_owner()
		and other._has_valid_combat_owner()
		and _is_battle_running()
		and other._is_battle_running()
	)


func _resolve_enemy_collision(other: TroopStream) -> void:
	if not _can_resolve_enemy_collision(other) or owner_id == other.owner_id:
		return
	_resolving_collision = true
	other._resolving_collision = true

	if amount > other.amount:
		amount -= other.amount
		_refresh_amount_label()
		other._finish(FinishReason.DESTROYED_IN_TRANSIT)
	elif other.amount > amount:
		other.amount -= amount
		other._refresh_amount_label()
		_finish(FinishReason.DESTROYED_IN_TRANSIT)
	else:
		_finish(FinishReason.DESTROYED_IN_TRANSIT)
		other._finish(FinishReason.DESTROYED_IN_TRANSIT)

	if not _is_finished:
		_resolving_collision = false
	if not other._is_finished:
		other._resolving_collision = false


func _finish(reason: int) -> void:
	if _is_finished:
		return
	_is_finished = true
	detection_area.set_deferred("monitoring", false)
	if reason == FinishReason.ARRIVED:
		arrived.emit(self)
	finished.emit(self, reason)
	queue_free()


func _is_battle_running() -> bool:
	return _battle_running_guard.is_valid() and bool(_battle_running_guard.call())


func _has_valid_combat_owner() -> bool:
	return owner_id == "player" or owner_id == "enemy"


func _refresh_amount_label() -> void:
	if label != null:
		label.text = str(int(round(amount)))


func _get_owner_color() -> Color:
	match owner_id:
		"player":
			return Color("4caf50")
		"enemy":
			return Color("e53935")
		_:
			return Color("9e9e9e")
