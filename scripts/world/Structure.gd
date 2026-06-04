class_name Structure
extends Node2D

signal troops_requested(source: Structure, target: Structure, amount: int)

@export var structure_id := ""
@export var owner_id := Constants.NEUTRAL_FACTION_ID
@export var structure_type := "tower"
@export var garrison := 10
@export var max_garrison := 100
@export var production_rate := 1.0

var neighbor_ids: Array[String] = []
var neighbors: Array[Structure] = []
var _production_accumulator := 0.0

@onready var sprite: Sprite2D = $TowerSprite
@onready var label: Label = $GarrisonLabel
@onready var selection_ring: Sprite2D = $SelectionRing
@onready var owner_glow: Sprite2D = $OwnerGlow
@onready var click_area: Area2D = $ClickArea

const PLAYER_TEXTURE := preload("res://assets/art/structures/player/tower_player.png")
const PLAYER_SELECTED_TEXTURE := preload("res://assets/art/structures/selected/tower_player_selected.png")
const NEUTRAL_TEXTURE := preload("res://assets/art/structures/neutral/tower_neutral.png")
const ENEMY_TEXTURE := preload("res://assets/art/structures/enemy/tower_enemy.png")

var _is_selected := false


func _ready() -> void:
	click_area.input_pickable = true
	click_area.input_event.connect(_on_input_event)
	_update_visuals()


func _process(delta: float) -> void:
	if owner_id != Constants.NEUTRAL_FACTION_ID and garrison < max_garrison:
		_production_accumulator += production_rate * delta
		if _production_accumulator >= 1.0:
			var produced := int(_production_accumulator)
			_production_accumulator -= produced
			garrison = min(max_garrison, garrison + produced)
			_update_visuals()


func setup_from_data(data: Dictionary) -> void:
	structure_id = data.get("id", "")
	position = Vector2(data.get("position", [0, 0])[0], data.get("position", [0, 0])[1])
	owner_id = data.get("owner", Constants.NEUTRAL_FACTION_ID)
	structure_type = data.get("type", "tower")
	garrison = data.get("garrison", 10)
	max_garrison = data.get("max_garrison", 100)
	production_rate = float(data.get("production_rate", 1.0))
	neighbor_ids.assign(data.get("neighbors", []))


func resolve_neighbors(structure_map: Dictionary) -> void:
	neighbors.clear()
	for neighbor_id in neighbor_ids:
		if structure_map.has(neighbor_id):
			neighbors.append(structure_map[neighbor_id])


func can_send_to(target: Structure) -> bool:
	return target != null and neighbors.has(target) and garrison > 1


func send_troops(target: Structure, send_fraction: float = Constants.DEFAULT_SEND_FRACTION) -> int:
	if not can_send_to(target):
		return 0
	var amount := maxi(1, int(floor(garrison * send_fraction)))
	amount = mini(amount, garrison - 1)
	if amount <= 0:
		return 0
	garrison -= amount
	_update_visuals()
	troops_requested.emit(self, target, amount)
	EventBus.troops_sent.emit(structure_id, target.structure_id, owner_id, amount)
	return amount


func receive_troops(amount: int, faction_id: String) -> void:
	if faction_id == owner_id:
		garrison = mini(max_garrison, garrison + amount)
	else:
		garrison -= amount
		if garrison < 0:
			var previous_owner := owner_id
			owner_id = faction_id
			garrison = abs(garrison)
			EventBus.structure_captured.emit(structure_id, previous_owner, owner_id)
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
		label.text = "%s" % garrison
	if sprite:
		sprite.texture = _get_owner_texture()
	if owner_glow:
		owner_glow.modulate = _get_owner_color()
	EventBus.structure_updated.emit(structure_id, garrison)


func _get_owner_color() -> Color:
	match owner_id:
		Constants.PLAYER_FACTION_ID:
			return Color("4caf50")
		Constants.NEUTRAL_FACTION_ID:
			return Color("9e9e9e")
		_:
			return Color("e53935")


func _get_owner_texture() -> Texture2D:
	match owner_id:
		Constants.PLAYER_FACTION_ID:
			return PLAYER_SELECTED_TEXTURE if _is_selected else PLAYER_TEXTURE
		Constants.NEUTRAL_FACTION_ID:
			return NEUTRAL_TEXTURE
		_:
			return ENEMY_TEXTURE


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		EventBus.structure_selected.emit(structure_id, owner_id)
