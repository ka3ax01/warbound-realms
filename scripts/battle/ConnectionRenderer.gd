class_name ConnectionRenderer
extends Node2D

@export var structures_root_path: NodePath

var _structures_root: Node2D
var _selected_structure_id: String = ""


func _ready() -> void:
	_structures_root = get_node_or_null(structures_root_path) as Node2D
	EventBus.structure_selected.connect(_on_structure_selected)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if _structures_root == null:
		return

	var drawn_pairs := {}
	for structure: Structure in _structures_root.get_children():
		for neighbor: Structure in structure.neighbors:
			var key: String = _make_pair_key(structure.structure_id, neighbor.structure_id)
			if drawn_pairs.has(key):
				continue
			drawn_pairs[key] = true
			var is_selected_link: bool = _selected_structure_id == structure.structure_id or _selected_structure_id == neighbor.structure_id
			var base_color: Color = Color(0.28, 0.22, 0.16, 0.6) if is_selected_link else Color(0.19, 0.15, 0.11, 0.38)
			var top_color: Color = _get_link_color(structure, neighbor, is_selected_link)
			var width: float = 10.0 if is_selected_link else 7.0
			draw_line(
				to_local(structure.global_position),
				to_local(neighbor.global_position),
				base_color,
				width,
				true
			)
			draw_line(
				to_local(structure.global_position),
				to_local(neighbor.global_position),
				top_color,
				3.0 if is_selected_link else 2.0,
				true
			)


func _make_pair_key(a: String, b: String) -> String:
	return "%s|%s" % [a, b] if a < b else "%s|%s" % [b, a]


func _on_structure_selected(structure_id: String, _owner_id: String) -> void:
	_selected_structure_id = structure_id
	queue_redraw()


func _get_link_color(structure: Structure, neighbor: Structure, is_selected_link: bool) -> Color:
	if is_selected_link:
		return Color(0.92, 0.77, 0.47, 0.95)
	if structure.owner_id == neighbor.owner_id:
		match structure.owner_id:
			"player":
				return Color(0.57, 0.82, 0.62, 0.62)
			"enemy":
				return Color(0.88, 0.45, 0.41, 0.62)
			_:
				return Color(0.82, 0.79, 0.71, 0.5)
	return Color(0.9, 0.87, 0.78, 0.42)
