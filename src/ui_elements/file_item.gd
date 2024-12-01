extends HBoxContainer

signal pressed

var file_name: String

func _ready() -> void:
	$Button.text = file_name
	$Button.pressed.connect(pressed.emit)

	$DeleteButton.pressed.connect(
		func():
			var dir: DirAccess = DirAccess.open("user://")
			if dir.file_exists(file_name):
				dir.remove(file_name)
				queue_free()

	)

