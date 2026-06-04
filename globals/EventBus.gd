extends Node

@warning_ignore("unused_signal")

signal structure_selected(structure_id: String, owner_id: String)
signal troops_sent(source_id: String, target_id: String, faction_id: String, amount: int)
signal structure_captured(structure_id: String, old_owner_id: String, new_owner_id: String)
signal battle_won(level_id: String)
signal battle_lost(level_id: String)
signal pause_changed(is_paused: bool)
signal structure_updated(structure_id: String, garrison: int)
signal level_loaded(level_id: String)
signal settings_changed()
