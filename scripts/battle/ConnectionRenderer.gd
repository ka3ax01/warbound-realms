class_name ConnectionRenderer
extends Node2D

@export var structures_root_path: NodePath

var _structures_root: Node2D


func _ready() -> void:
	_structures_root = get_node_or_null(structures_root_path) as Node2D


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if _structures_root == null:
		return

	var drawn_pairs := {}
	for structure: Structure in _structures_root.get_children():
		for neighbor: Structure in structure.neighbors:
			var key := _make_pair_key(structure.structure_id, neighbor.structure_id)
			if drawn_pairs.has(key):
				continue
			drawn_pairs[key] = true
			draw_line(
				to_local(structure.global_position),
				to_local(neighbor.global_position),
				Color(1, 1, 1, 0.25),
				6.0,
				true
			)
			draw_line(
				to_local(structure.global_position),
				to_local(neighbor.global_position),
				Color(0.15, 0.17, 0.19, 0.5),
				2.0,
				true
			)


func _make_pair_key(a: String, b: String) -> String:
	return "%s|%s" % [a, b] if a < b else "%s|%s" % [b, a]
