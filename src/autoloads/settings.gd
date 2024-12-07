extends Node

signal theme_changed

const SETTINGS_PATH: String = "user://settings.json"
const DARK_THEME: Theme = preload("res://themes/dark.tres")
const LIGHT_THEME: Theme = preload("res://themes/light.tres")

var dark_theme: bool = true:
	set(value):
		dark_theme = value
		theme_changed.emit()
var theme: Theme:
	get: return DARK_THEME if dark_theme else LIGHT_THEME


func save_settings() -> void:
	var file: FileAccess = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	var settings: Dictionary = {"dark_theme": dark_theme}
	file.store_string(JSON.stringify(settings))


func load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var settings: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SETTINGS_PATH))
	dark_theme = settings.dark_theme


func _ready() -> void:
	load_settings()
