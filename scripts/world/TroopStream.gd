class_name TroopStream
extends Node2D

signal arrived(stream: TroopStream)

@export var speed: float = 180.0

var owner_id: String = ""
var amount: float = 0.0
var source: Structure
var target: Structure

@onready var marker: ColorRect = $Marker
@onready var label: Label = $AmountLabel


func setup(stream_source: Structure, stream_target: Structure, troop_amount: float, troop_owner: String) -> void:
	source = stream_source
	target = stream_target
	amount = troop_amount
	owner_id = troop_owner
	global_position = source.global_position
	label.text = str(int(round(amount)))
	marker.color = _get_owner_color()


func _process(delta: float) -> void:
	if target == null:
		queue_free()
		return

	global_position = global_position.move_toward(target.global_position, speed * delta)
	if global_position.distance_to(target.global_position) <= 4.0:
		target.resolve_combat(owner_id, amount)
		arrived.emit(self)
		queue_free()


func _get_owner_color() -> Color:
	match owner_id:
		"player":
			return Color("4caf50")
		"enemy":
			return Color("e53935")
		_:
			return Color("9e9e9e")
