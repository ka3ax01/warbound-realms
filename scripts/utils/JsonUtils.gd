class_name JsonUtils
extends RefCounted

static func load_json_file(path: String, default_value = null):
	if not FileAccess.file_exists(path):
		return default_value

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Failed to open JSON file: %s" % path)
		return default_value

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed == null:
		push_error("Failed to parse JSON file: %s" % path)
		return default_value

	return parsed


static func save_json_file(path: String, data: Variant) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to write JSON file: %s" % path)
		return false

	file.store_string(JSON.stringify(data, "\t"))
	return true
