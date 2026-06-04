class_name LevelData
extends RefCounted

var id := ""
var name_key := ""
var description_key := ""
var scene_type := ""
var commander_id := ""
var music_track := ""
var victory_conditions: Array = []
var defeat_conditions: Array = []
var structures: Array = []
var ai: Dictionary = {}
var rewards: Dictionary = {}


static func from_dict(data: Dictionary) -> LevelData:
	var level := LevelData.new()
	level.id = data.get("id", "")
	level.name_key = data.get("name_key", "")
	level.description_key = data.get("description_key", "")
	level.scene_type = data.get("scene_type", "")
	level.commander_id = data.get("commander_id", "")
	level.music_track = data.get("music_track", "")
	level.victory_conditions = data.get("victory_conditions", [])
	level.defeat_conditions = data.get("defeat_conditions", [])
	level.structures = data.get("structures", [])
	level.ai = data.get("ai", {})
	level.rewards = data.get("rewards", {})
	return level
