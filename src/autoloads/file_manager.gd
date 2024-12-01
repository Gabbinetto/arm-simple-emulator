extends Node


func save_file(filename: String, text: String) -> void:
	var file: FileAccess = FileAccess.open("user://" + filename, FileAccess.WRITE)
	print(text)
	file.store_string(text)


func load_file(path: String) -> String:
	return FileAccess.get_file_as_string("user://" + path)