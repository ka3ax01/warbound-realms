extends Node

const MENU_MUSIC := "res://assets/audio/music/Menu.mp3"
const BATTLE_MUSIC := "res://assets/audio/music/Battle.mp3"
const VICTORY_MUSIC := "res://assets/audio/music/victory.mp3"
const DEFEAT_MUSIC := "res://assets/audio/music/defeat.mp3"
const BUTTON_SFX := "res://assets/audio/sfx/ui/button_soft_01.ogg"
const TOWER_SELECT_SFX := "res://assets/audio/sfx/battle/tower_selected_01.ogg"
const SEND_TROOPS_SFX := "res://assets/audio/sfx/battle/troops_sent_01.ogg"
const CAPTURE_SFX := "res://assets/audio/sfx/capture/tower_capture_01.ogg"
const UPGRADE_SFX := "res://assets/audio/sfx/ui/upgrade_01.ogg"
const ERROR_SFX := "res://assets/audio/sfx/ui/error_locked_01.ogg"

var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer


func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	sfx_player = AudioStreamPlayer.new()
	add_child(music_player)
	add_child(sfx_player)
	_apply_settings()
	EventBus.settings_changed.connect(_apply_settings)


func _apply_settings() -> void:
	var settings: Dictionary = SaveManager.get_settings()
	var master_volume: float = linear_to_db(float(settings.get("master_volume", 1.0)))
	var music_volume: float = linear_to_db(float(settings.get("music_volume", 0.8)))
	var sfx_volume: float = linear_to_db(float(settings.get("sfx_volume", 0.8)))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), master_volume)
	music_player.volume_db = music_volume
	sfx_player.volume_db = sfx_volume


func set_master_volume(value: float) -> void:
	SaveManager.update_setting("master_volume", value)


func set_music_volume(value: float) -> void:
	SaveManager.update_setting("music_volume", value)


func set_sfx_volume(value: float) -> void:
	SaveManager.update_setting("sfx_volume", value)


func play_music(track_path: String) -> void:
	if track_path.is_empty() or not ResourceLoader.exists(track_path):
		return
	var stream := load(track_path) as AudioStream
	if music_player.stream == stream and music_player.playing:
		return
	music_player.stream = stream
	music_player.play()


func play_sfx(sfx_path: String) -> void:
	if sfx_path.is_empty() or not ResourceLoader.exists(sfx_path):
		return
	sfx_player.stream = load(sfx_path) as AudioStream
	sfx_player.play()


func play_menu_music() -> void:
	play_music(MENU_MUSIC)


func play_battle_music() -> void:
	play_music(BATTLE_MUSIC)


func play_victory_music() -> void:
	play_music(VICTORY_MUSIC)


func play_defeat_music() -> void:
	play_music(DEFEAT_MUSIC)
