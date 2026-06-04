class_name TroopStream
extends Node2D

signal arrived(stream: TroopStream)

var faction_id := ""
var amount := 0
var speed := 180.0
var source: Structure
var target: Structure

@onready var marker: ColorRect = $Marker
@onready var label: Label = $AmountLabel


func setup(stream_source: Structure, stream_target: Structure, troop_amount: int, troop_faction_id: String) -> void:
	source = stream_source
	target = stream_target
	amount = troop_amount
	faction_id = troop_faction_id
	global_position = source.global_position
	label.text = str(amount)
	marker.color = Color("4caf50") if faction_id == Constants.PLAYER_FACTION_ID else Color("e53935")


func _process(delta: float) -> void:
	if target == null:
		queue_free()
		return

	global_position = global_position.move_toward(target.global_position, speed * delta)
	if global_position.distance_to(target.global_position) <= 4.0:
		target.receive_troops(amount, faction_id)
		arrived.emit(self)
		queue_free()
