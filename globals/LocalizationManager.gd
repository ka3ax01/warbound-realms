extends Node

var current_language := "en"


func _ready() -> void:
	var settings := SaveManager.get_settings()
	current_language = settings.get("language", "en")
	set_language(current_language)


func set_language(language_code: String) -> void:
	current_language = language_code
	TranslationServer.set_locale(language_code)
	SaveManager.update_setting("language", language_code)


func tr_key(key: String) -> String:
	return tr(key)
