class_name Structure
extends Node2D

signal structure_clicked(structure: Structure)
signal troops_requested(source: Structure, target: Structure, amount: float)
signal owner_changed(structure: Structure, previous_owner: String, new_owner: String)

@export var structure_id: String = ""
@export var owner_id: String = "neutral"
@export var garrison: float = 10.0
@export var max_garrison: float = 100.0
@export var level: int = 1
@export var unit_type: String = Constants.UNIT_TYPE_INFANTRY

var connected_to: Array[String] = []
var neighbors: Array[Structure] = []
var _production_accumulator: float = 0.0
var _visual_time: float = 0.0

@onready var sprite: Sprite2D = $TowerSprite
@onready var label: Label = $GarrisonLabel
@onready var production_label: Label = $ProductionLabel
@onready var selection_ring: Sprite2D = $SelectionRing
@onready var owner_glow: Sprite2D = $OwnerGlow
@onready var click_area: Area2D = $ClickArea

const PLAYER_TEXTURE := preload("res://assets/art/towers/player/kenney_td_player_tower_green_01.png")
const NEUTRAL_TEXTURE := preload("res://assets/art/towers/neutral/kenney_td_neutral_ruin_grey_01.png")
const ENEMY_TEXTURE := preload("res://assets/art/towers/enemy/kenney_td_enemy_tower_red_01.png")
const GAME_BALANCE: Resource = preload("res://data/config/game_balance.tres")

var _is_selected: bool = false


func _ready() -> void:
	click_area.input_pickable = true
	click_area.input_event.connect(_on_input_event)
	_update_visuals()


func _process(delta: float) -> void:
	_visual_time += delta
	advance_unit_generation(delta)
	_animate_visuals()


func setup_from_data(data: Dictionary) -> void:
	var connected_value: Variant = data.get("connected_to", [])
	var connected_data: Array = connected_value if connected_value is Array else []

	structure_id = str(data.get("id", ""))
	position = _parse_position(data.get("position", {}))
	owner_id = _normalize_owner_id(str(data.get("owner", "neutral")))
	garrison = float(data.get("garrison", 10.0))
	max_garrison = float(data.get("max_garrison", 100.0))
	level = int(data.get("level", 1))
	unit_type = _normalized_unit_type(str(data.get("unit_type", Constants.UNIT_TYPE_INFANTRY)))
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


func can_generate_units() -> bool:
	return (
		is_inside_tree()
		and not is_queued_for_deletion()
		and process_mode != Node.PROCESS_MODE_DISABLED
		and owner_id != "neutral"
		and get_generation_rate() > 0.0
		and garrison < max_garrison
	)


func advance_unit_generation(delta: float) -> void:
	if delta <= 0.0 or not can_generate_units():
		return

	_production_accumulator += get_generation_rate() * delta
	if _production_accumulator < 1.0:
		return

	var produced: float = floor(_production_accumulator)
	_production_accumulator -= produced
	garrison = min(max_garrison, garrison + produced)
	_update_visuals()


func get_generation_rate() -> float:
	return float(GAME_BALANCE.get("structure_generation_rate"))


func get_unit_type() -> String:
	return unit_type


static func is_valid_unit_type(value: String) -> bool:
	return value == Constants.UNIT_TYPE_INFANTRY or value == Constants.UNIT_TYPE_ARCHER or value == Constants.UNIT_TYPE_CAVALRY


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
			_production_accumulator = 0.0
			_is_selected = false
			selection_ring.visible = false
			owner_changed.emit(self, previous_owner, owner_id)
			_pulse_capture_feedback()
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
	if production_label:
		production_label.text = "+%s/s" % _format_generation_rate()
	if sprite:
		sprite.texture = _get_owner_texture()
	if owner_glow:
		owner_glow.modulate = _get_owner_color()
	EventBus.structure_updated.emit(structure_id, int(round(garrison)))


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
			return PLAYER_TEXTURE
		"neutral":
			return NEUTRAL_TEXTURE
		_:
			return ENEMY_TEXTURE


func _animate_visuals() -> void:
	if owner_glow:
		var glow_alpha: float = 0.18 + (sin(_visual_time * 2.2) + 1.0) * 0.08
		var glow_color: Color = _get_owner_color()
		glow_color.a = glow_alpha
		owner_glow.modulate = glow_color
		owner_glow.scale = Vector2.ONE * (1.28 + (sin(_visual_time * 1.6) + 1.0) * 0.04)
	if selection_ring and selection_ring.visible:
		var pulse: float = 1.28 + (sin(_visual_time * 5.0) + 1.0) * 0.05
		selection_ring.scale = Vector2.ONE * pulse


func _pulse_capture_feedback() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.08, 1.08), 0.12)
	tween.tween_property(self, "scale", Vector2.ONE, 0.14)


func _format_generation_rate() -> String:
	var generation_rate := get_generation_rate()
	if is_equal_approx(generation_rate, round(generation_rate)):
		return str(int(round(generation_rate)))
	return String.num(generation_rate, 1)


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		structure_clicked.emit(self)


func _normalize_owner_id(raw_owner_id: String) -> String:
	if raw_owner_id == "player" or raw_owner_id == "neutral" or raw_owner_id == "enemy":
		return raw_owner_id
	if raw_owner_id.begins_with("enemy"):
		return "enemy"
	return raw_owner_id


func _normalized_unit_type(raw_unit_type: String) -> String:
	return raw_unit_type if is_valid_unit_type(raw_unit_type) else Constants.UNIT_TYPE_INFANTRY


func _parse_position(position_value: Variant) -> Vector2:
	if position_value is Dictionary:
		var position_data: Dictionary = position_value
		return Vector2(
			float(position_data.get("x", 0.0)),
			float(position_data.get("y", 0.0))
		)
	if position_value is Array and position_value.size() >= 2:
		return Vector2(float(position_value[0]), float(position_value[1]))
	return Vector2.ZERO
