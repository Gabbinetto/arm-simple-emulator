extends Control

@onready var code: CodeEdit = %CodeEdit
@onready var run_button: Button = %RunButton
@onready var decimal_check: BaseButton = %DecimalCheck
@onready var registers_label: Label = %Registers


func _ready() -> void:
	run_button.pressed.connect(
		func():
			Executor.parse(code.text)
			Executor.running = true
	)


func _process(_delta: float) -> void:
	if Executor.running:
		Executor.run_line()

	_update_registers()


func _update_registers() -> void:
	registers_label.text = ""
	for i: int in 16:
		var text: String = ""
		var value: int = 0

		if i < 13:
			text = "r%d" % i
		elif i == 13:
			text = "sp"
		elif i == 14:
			text = "lr"
		elif i == 15:
			text = "pc"

		value = Executor.get(text)
		text = text.to_upper() + ":"
		var value_text: String = str(value) if decimal_check.button_pressed else "0x" + String.num_uint64(value, 16, true).lpad(8, "0")
		registers_label.text += "%s%s\n" % [text.rpad(5), value_text]
