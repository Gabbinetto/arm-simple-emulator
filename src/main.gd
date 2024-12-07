extends Control

@onready var code: CodeEdit = %CodeEdit
@onready var run_button: Button = %RunButton
@onready var run_all_button: Button = %RunAllButton
@onready var step_button: Button = %StepButton
@onready var stop_button: Button = %StopButton
@onready var decimal_check: BaseButton = %DecimalCheck
@onready var registers_label: Label = %Registers
@onready var memory_label: Label = %Memory
@onready var clear_mem_button: Button = %ClearMemButton
@onready var save_button: Button = %SaveButton
@onready var back_button: Button = %BackButton
@onready var grid: GridContainer = %Grid
# Console
@onready var console_button: Button = %ConsoleButton
@onready var console_container: PanelContainer = %ConsoleContainer
@onready var console_text: Label = %ConsoleText
@onready var console_close_button: Button = %ConsoleCloseButton
@onready var clear_console_button: Button = %ClearConsoleButton

var file_name: String = ""
var running_all: bool = false
var last_executed_line: int = -1
var last_error_line: int = 0

func _ready() -> void:
	var refresh_theme: Callable = func(): theme = Settings.theme
	Settings.theme_changed.connect(refresh_theme)
	refresh_theme.call()

	var _on_screen_size_changed: Callable = func():
		var viewport_size: Vector2 = get_viewport().size
		var ratio: float = viewport_size.x / viewport_size.y
		if ratio < 1.0:
			grid.columns = 1
		else:
			grid.columns = 2
		
	get_viewport().size_changed.connect(_on_screen_size_changed)
	_on_screen_size_changed.call()
			

	file_name = SceneTransition.data.filename
	code.text = SceneTransition.data.text
	save_button.pressed.connect(func(): FileManager.save_file(file_name, code.text))
	back_button.pressed.connect(
		func():
			Executor.stop()
			Executor.code.clear()
			for register: String in Executor.REGISTERS:
				Executor.set(register, 0x0)
			Memory.clear()
			SceneTransition.transition("res://src/file_select.tscn")
	)
	clear_mem_button.pressed.connect(func():
		Memory.clear()
		for register: String in Executor.REGISTERS:
			Executor.set(register, 0x0)
	)
	

	code.add_comment_delimiter(Executor.COMMENT_CHARACTER, "", true)
	Executor.executing_line.connect(func(line: int):
		code.set_line_as_executing(last_executed_line, false)
		code.set_line_as_executing(line - 1, true)
		last_executed_line = line - 1
	)
	Executor.finished.connect(
		func():
			code.set_line_as_executing(last_executed_line, false)
			last_executed_line = -1
	)

	Executor.error.connect(
		func(line: int, msg: String):
			code.set_line_as_breakpoint(line - 1, true)
			last_error_line = line - 1
			push_error(msg)
			console_text.text += msg + "\n"
			console_container.show()
	)

	run_button.pressed.connect(_run)
	run_all_button.pressed.connect(_run_all)
	step_button.pressed.connect(_step)
	stop_button.pressed.connect(_stop)

	console_button.pressed.connect(console_container.show)
	console_close_button.pressed.connect(console_container.hide)
	clear_console_button.pressed.connect(func(): console_text.text = "")



func _process(_delta: float) -> void:
	if Executor.running and not running_all:
		Executor.run_line()

	_update_registers()
	_update_memory()


func _update_registers() -> void:
	registers_label.text = ""
	for reg: String in Executor.REGISTERS:
		if ["r13", "r14", "r15"].has(reg): continue
		var value: int = Executor.get(reg)
		var value_text: String
		if decimal_check.button_pressed:
			value_text = str(value)
		else:
			value_text = "0x%08X" % value
			
		reg = (reg + ":").rpad(5).to_upper()
		registers_label.text += " " + reg + value_text + "\n"


func _update_memory() -> void:
	memory_label.text = ""
	for address: int in Memory.get_set_address():
		var value: int = Memory.mem_load(address)
		var value_text: String
		if decimal_check.button_pressed:
			value_text = str(value)
		else:
			value_text = "0x%08X" % value
		var address_text: String
		if decimal_check.button_pressed:
			address_text = str(address) + ": "
		else:
			address_text = "0x%08X: " % address
		memory_label.text += " " + address_text + value_text + "\n"


func _run() -> void:
	code.set_line_as_breakpoint(last_error_line, false)
	Executor.parse(code.text)
	Executor.start()


func _run_all() -> void:
	running_all = true
	code.set_line_as_breakpoint(last_error_line, false)
	Executor.parse(code.text)
	Executor.start()
	while Executor.running:
		Executor.run_line()
	running_all = false
	

func _step() -> void:
	code.set_line_as_breakpoint(last_error_line, false)
	if Executor.code.is_empty():
		Executor.parse(code.text)
	if Executor.pc > Executor.code.keys()[-1]:
		Executor.reset_pc()
	Executor.start()
	Executor.run_line()
	Executor.stop()


func _stop() -> void:
	if Executor.running:
		Executor.stop()
		stop_button.text = "RESUME"
	else:
		Executor.start()
		stop_button.text = "STOP"


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Run"):
		_run()
	elif event.is_action_pressed("RunAll"):
		_run_all()
	elif event.is_action_pressed("Step"):
		_step()
	elif event.is_action_pressed("Stop"):
		_stop()
	elif event.is_action_pressed("Save"):
		FileManager.save_file(file_name, code.text)
