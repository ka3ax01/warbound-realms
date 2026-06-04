class_name SaveData
extends RefCounted

var version := 1
var unlocked_levels: Array[String] = ["level_001"]
var completed_levels: Array[String] = []
var settings := {
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
		"settings": settings
	}


static func from_dict(data: Dictionary) -> SaveData:
	var save := SaveData.new()
	save.version = data.get("version", 1)
	save.unlocked_levels.assign(data.get("unlocked_levels", ["level_001"]))
	save.completed_levels.assign(data.get("completed_levels", []))
	save.settings.merge(data.get("settings", {}), true)
	return save
