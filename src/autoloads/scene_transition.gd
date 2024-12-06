extends Node


var data: Dictionary = {
	"filename": "",
	"text": "",
}


func transition(path: String, _data: Dictionary = {}) -> void:
	data = _data
	get_tree().change_scene_to_file(path)
