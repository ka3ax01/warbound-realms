class_name BattleBackground
extends Node2D

const GRASS_TILE := preload("res://assets/art/backgrounds/battlefield/tile_grass.png")
const DIRT_TILE := preload("res://assets/art/backgrounds/battlefield/tile_dirt.png")
const TREE_TEXTURE := preload("res://assets/art/details/tree.png")
const ROCK_TEXTURE := preload("res://assets/art/details/rock.png")

@export var structures_root_path: NodePath

var _structures_root: Node2D
var _map_size := Vector2(1280, 720)


func _ready() -> void:
	_structures_root = get_node_or_null(structures_root_path) as Node2D
	_build_background()
	EventBus.level_loaded.connect(_on_level_loaded)


func _build_background() -> void:
	_clear_children()
	_build_ground_tiles()
	_add_border_details()
	_build_paths()


func _build_ground_tiles() -> void:
	var columns := int(ceil(_map_size.x / 160.0)) + 1
	var rows := int(ceil(_map_size.y / 120.0)) + 1
	for x in range(columns):
		for y in range(rows):
			var sprite := Sprite2D.new()
			sprite.texture = GRASS_TILE
			sprite.position = Vector2(160 + x * 160, 120 + y * 120)
			sprite.scale = Vector2(2.5, 2.5)
			sprite.z_index = -10
			add_child(sprite)


func _build_paths() -> void:
	if _structures_root == null:
		return

	var drawn_pairs := {}
	for structure: Structure in _structures_root.get_children():
		for neighbor: Structure in structure.neighbors:
			var key := _make_pair_key(structure.structure_id, neighbor.structure_id)
			if drawn_pairs.has(key):
				continue
			drawn_pairs[key] = true
			_stamp_path(structure.global_position, neighbor.global_position)


func _stamp_path(from_point: Vector2, to_point: Vector2) -> void:
	var direction := to_point - from_point
	var distance := direction.length()
	if distance <= 0.0:
		return

	var step := 56.0
	var count := maxi(1, int(ceil(distance / step)))
	for index in range(count + 1):
		var t := float(index) / float(count)
		var sprite := Sprite2D.new()
		sprite.texture = DIRT_TILE
		sprite.position = from_point.lerp(to_point, t)
		sprite.rotation = direction.angle()
		sprite.scale = Vector2(1.8, 1.2)
		sprite.z_index = -8
		add_child(sprite)


func _add_border_details() -> void:
	_add_detail(TREE_TEXTURE, Vector2(110, 120), Vector2(0.8, 0.8))
	_add_detail(TREE_TEXTURE, Vector2(1120, 540), Vector2(0.7, 0.7))
	_add_detail(TREE_TEXTURE, Vector2(1020, 140), Vector2(0.65, 0.65))
	_add_detail(ROCK_TEXTURE, Vector2(570, 120), Vector2(0.8, 0.8))
	_add_detail(ROCK_TEXTURE, Vector2(920, 620), Vector2(0.65, 0.65))
	_add_detail(ROCK_TEXTURE, Vector2(180, 600), Vector2(0.55, 0.55))


func _add_detail(texture: Texture2D, world_position: Vector2, detail_scale: Vector2) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.position = world_position
	sprite.scale = detail_scale
	sprite.z_index = -5
	add_child(sprite)


func _on_level_loaded(_level_id: String) -> void:
	call_deferred("_build_background")


func _clear_children() -> void:
	for child in get_children():
		child.queue_free()


func _make_pair_key(a: String, b: String) -> String:
	return "%s|%s" % [a, b] if a < b else "%s|%s" % [b, a]
