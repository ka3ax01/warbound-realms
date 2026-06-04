class_name Structure
extends Node2D

signal structure_clicked(structure: Structure)
signal troops_requested(source: Structure, target: Structure, amount: float)
signal owner_changed(structure: Structure, previous_owner: String, new_owner: String)

@export var structure_id: String = ""
@export var owner_id: String = "neutral"
@export var garrison: float = 10.0
@export var max_garrison: float = 100.0
@export var generation_rate: float = 1.0
@export var level: int = 1

var connected_to: Array[String] = []
var neighbors: Array[Structure] = []
var _production_accumulator: float = 0.0

@onready var sprite: Sprite2D = $TowerSprite
@onready var label: Label = $GarrisonLabel
@onready var selection_ring: Sprite2D = $SelectionRing
@onready var owner_glow: Sprite2D = $OwnerGlow
@onready var click_area: Area2D = $ClickArea

const PLAYER_TEXTURE := preload("res://assets/art/structures/player/tower_player.png")
const PLAYER_SELECTED_TEXTURE := preload("res://assets/art/structures/selected/tower_player_selected.png")
const NEUTRAL_TEXTURE := preload("res://assets/art/structures/neutral/tower_neutral.png")
const ENEMY_TEXTURE := preload("res://assets/art/structures/enemy/tower_enemy.png")

var _is_selected: bool = false


func _ready() -> void:
	click_area.input_pickable = true
	click_area.input_event.connect(_on_input_event)
	_update_visuals()


func _process(delta: float) -> void:
	if owner_id != "neutral" and garrison < max_garrison:
		_production_accumulator += generation_rate * delta
		if _production_accumulator >= 1.0:
			var produced: float = floor(_production_accumulator)
			_production_accumulator -= produced
			garrison = min(max_garrison, garrison + produced)
			_update_visuals()


func setup_from_data(data: Dictionary) -> void:
	var position_value: Variant = data.get("position", {})
	var position_data: Dictionary = position_value if position_value is Dictionary else {}
	var x_value: float = float(position_data.get("x", 0.0))
	var y_value: float = float(position_data.get("y", 0.0))
	var connected_value: Variant = data.get("connected_to", [])
	var connected_data: Array = connected_value if connected_value is Array else []

	structure_id = str(data.get("id", ""))
	position = Vector2(x_value, y_value)
	owner_id = _normalize_owner_id(str(data.get("owner", "neutral")))
	garrison = float(data.get("garrison", 10.0))
	max_garrison = float(data.get("max_garrison", 100.0))
	generation_rate = float(data.get("generation_rate", 1.0))
	level = int(data.get("level", 1))
	connected_to.clear()
	for entry in connected_data:
		connected_to.append(str(entry))
	_production_accumulator = 0.0
	_update_visuals()


func resolve_neighbors(structure_map: Dictionary) -> void:
	neighbors.clear()
	for neighbor_id in connected_to:
		if structure_map.has(neighbor_id):
			neighbors.append(structure_map[neighbor_id])


func can_send_to(target: Structure) -> bool:
	return target != null and neighbors.has(target) and garrison >= 2.0


func send_troops(target: Structure, send_fraction: float = 0.5) -> float:
	if not can_send_to(target):
		return 0.0
	var amount: float = floor(garrison * send_fraction)
	if amount < 1.0:
		return 0.0
	garrison -= amount
	_update_visuals()
	troops_requested.emit(self, target, amount)
	return amount


func resolve_combat(attacker_owner: String, attack_power: float) -> void:
	if attacker_owner == owner_id:
		garrison = min(max_garrison, garrison + attack_power)
	else:
		var defense: float = garrison
		if attack_power > defense:
			var previous_owner: String = owner_id
			owner_id = attacker_owner
			garrison = attack_power - defense
			owner_changed.emit(self, previous_owner, owner_id)
		else:
			garrison = defense - attack_power
	_update_visuals()


func select() -> void:
	_is_selected = true
	selection_ring.visible = true
	_update_visuals()


func deselect() -> void:
	_is_selected = false
	selection_ring.visible = false
	_update_visuals()


func _update_visuals() -> void:
	if label:
		label.text = str(int(round(garrison)))
	if sprite:
		sprite.texture = _get_owner_texture()
	if owner_glow:
		owner_glow.modulate = _get_owner_color()


func _get_owner_color() -> Color:
	match owner_id:
		"player":
			return Color("4caf50")
		"neutral":
			return Color("9e9e9e")
		_:
			return Color("e53935")


func _get_owner_texture() -> Texture2D:
	match owner_id:
		"player":
			return PLAYER_SELECTED_TEXTURE if _is_selected else PLAYER_TEXTURE
		"neutral":
			return NEUTRAL_TEXTURE
		_:
			return ENEMY_TEXTURE


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		structure_clicked.emit(self)


func _normalize_owner_id(raw_owner_id: String) -> String:
	if raw_owner_id == "player" or raw_owner_id == "neutral" or raw_owner_id == "enemy":
		return raw_owner_id
	if raw_owner_id.begins_with("enemy"):
		return "enemy"
	return raw_owner_id
