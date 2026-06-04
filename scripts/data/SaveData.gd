class_name SaveData
extends RefCounted

var version: int = 2
var unlocked_levels: Array[String] = ["level_001"]
var completed_levels: Array[String] = []
var level_results: Dictionary = {}
var settings: Dictionary = {
	"master_volume": 1.0,
	"music_volume": 0.8,
	"sfx_volume": 0.8,
	"language": "en",
	"fullscreen": false
}


func to_dict() -> Dictionary:
	return {
		"version": version,
		"unlocked_levels": unlocked_levels,
		"completed_levels": completed_levels,
		"level_results": level_results,
		"settings": settings
	}


static func from_dict(data: Dictionary) -> SaveData:
	var save := SaveData.new()
	save.version = int(data.get("version", 2))
	save.unlocked_levels.assign(data.get("unlocked_levels", ["level_001"]))
	save.completed_levels.assign(data.get("completed_levels", []))
	save.level_results = data.get("level_results", {})
	save.settings.merge(data.get("settings", {}), true)
	return save
