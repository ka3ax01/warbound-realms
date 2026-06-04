class_name FactionData
extends RefCounted

var id := ""
var name_key := ""
var color := Color.WHITE
var structure_tint := Color.WHITE
var troop_tint := Color.WHITE
var banner_icon := ""
var default_music := ""


static func from_dict(data: Dictionary) -> FactionData:
	var faction := FactionData.new()
	faction.id = data.get("id", "")
	faction.name_key = data.get("name_key", "")
	faction.color = Color(data.get("color", "#ffffff"))
	faction.structure_tint = Color(data.get("structure_tint", "#ffffff"))
	faction.troop_tint = Color(data.get("troop_tint", "#ffffff"))
	faction.banner_icon = data.get("banner_icon", "")
	faction.default_music = data.get("default_music", "")
	return faction
