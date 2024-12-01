extends Control

const FileItem: PackedScene = preload("res://src/ui_elements/file_item.tscn")

@onready var file_list: VBoxContainer = %FileList
@onready var new_button: Button = %NewButton
@onready var filename_input: LineEdit = %FilenameInput
@onready var confirm_button: Button = %ConfirmButton
@onready var cancel_button: Button = %CancelButton

func _ready() -> void:
	var dir: DirAccess = DirAccess.open("user://")

	for filename: String in dir.get_files():
		if filename.get_extension() != "arm":
			continue
		var file_item: HBoxContainer = FileItem.instantiate()
		file_item.file_name = filename
		file_item.pressed.connect(
			func():
				SceneTransition.transition("res://src/main.tscn", {"text": FileManager.load_file(filename), "filename": filename})
		)
		file_list.add_child(file_item)
	
	new_button.pressed.connect(filename_input.show)
	cancel_button.pressed.connect(
		func():
			filename_input.text = ""
			filename_input.hide()
	)
	var create_file: Callable = func():
		var filename: String = filename_input.text
		if filename.get_extension() != "arm":
			filename += ".arm"
		SceneTransition.transition("res://src/main.tscn", {"filename": filename, "text": ""})
	confirm_button.pressed.connect(create_file)
	filename_input.text_submitted.connect(create_file)