class_name CommanderData
extends RefCounted

var id := ""
var name_key := ""
var title_key := ""
var portrait := ""
var faction_id := ""
var ai_profile := ""
var description_key := ""


static func from_dict(data: Dictionary) -> CommanderData:
	var commander := CommanderData.new()
	commander.id = data.get("id", "")
	commander.name_key = data.get("name_key", "")
	commander.title_key = data.get("title_key", "")
	commander.portrait = data.get("portrait", "")
	commander.faction_id = data.get("faction_id", "")
	commander.ai_profile = data.get("ai_profile", "")
	commander.description_key = data.get("description_key", "")
	return commander
