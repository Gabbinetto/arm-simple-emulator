extends Node

signal executing_line(line: int)
signal error(line: int, msg: String)
signal finished

enum Conditions {
	EQ = 0b0000,
	NE = 0b0001,
	CS = 0b0010,
	HS = 0b0010,  # CS = HS
	CC = 0b0011,
	LO = 0b0011,  # CC = LO
	MI = 0b0100,
	PL = 0b0101,
	VS = 0b0110,
	VC = 0b0111,
	HI = 0b1000,
	LS = 0b1001,
	GE = 0b1010,
	LT = 0b1011,
	GT = 0b1100,
	LE = 0b1101,
	AL = 0b1110,
}

const COMMENT_CHARACTER: String = ";"
const IMMEDIATE_CHARACTER: String = "#"
const SEPARATOR: String = ","
const STRIP_CHARS: String = ",: \n"
const WORD_SIZE: int = 32
const MAX_UINT32: int = 0xFFFFFFFF
const MAX_UINT16: int = 0xFFFF
const MAX_UINT8: int = 0xFF
const REGISTERS: Array[String] = ["r0", "r1", "r2", "r3", "r4", "r5", "r6", "r7", "r8", "r9", "r10", "r11", "r12", "r13", "r14", "r15", "sp", "lr", "pc"]

var registers: Dictionary = {
	"r0": 0x0,
	"r1": 0x0,
	"r2": 0x0,
	"r3": 0x0,
	"r4": 0x0,
	"r5": 0x0,
	"r6": 0x0,
	"r7": 0x0,
	"r8": 0x0,
	"r9": 0x0,
	"r10": 0x0,
	"r11": 0x0,
	"r12": 0x0,
	"r13": 0x0,  # STACK POINTER
	"r14": 0x0,  # LINK REGISTER
	"r15": 0x0,  # PROGRAM COUNTER
}

var code: Dictionary = {}
var tags: Dictionary = {}
var running: bool = false

#region Register shorthands
var r0: int:
	get:
		return bit32(registers["r0"])
	set(value):
		registers["r0"] = clampi(bit32(value), 0x0, MAX_UINT32)
var r1: int:
	get:
		return bit32(registers["r1"])
	set(value):
		registers["r1"] = clampi(bit32(value), 0x0, MAX_UINT32)
var r2: int:
	get:
		return bit32(registers["r2"])
	set(value):
		registers["r2"] = clampi(bit32(value), 0x0, MAX_UINT32)
var r3: int:
	get:
		return bit32(registers["r3"])
	set(value):
		registers["r3"] = clampi(bit32(value), 0x0, MAX_UINT32)
var r4: int:
	get:
		return bit32(registers["r4"])
	set(value):
		registers["r4"] = clampi(bit32(value), 0x0, MAX_UINT32)
var r5: int:
	get:
		return bit32(registers["r5"])
	set(value):
		registers["r5"] = clampi(bit32(value), 0x0, MAX_UINT32)
var r6: int:
	get:
		return bit32(registers["r6"])
	set(value):
		registers["r6"] = clampi(bit32(value), 0x0, MAX_UINT32)
var r7: int:
	get:
		return bit32(registers["r7"])
	set(value):
		registers["r7"] = clampi(bit32(value), 0x0, MAX_UINT32)
var r8: int:
	get:
		return bit32(registers["r8"])
	set(value):
		registers["r8"] = clampi(bit32(value), 0x0, MAX_UINT32)
var r9: int:
	get:
		return bit32(registers["r9"])
	set(value):
		registers["r9"] = clampi(bit32(value), 0x0, MAX_UINT32)
var r10: int:
	get:
		return bit32(registers["r10"])
	set(value):
		registers["r10"] = clampi(bit32(value), 0x0, MAX_UINT32)
var r11: int:
	get:
		return bit32(registers["r11"])
	set(value):
		registers["r11"] = clampi(bit32(value), 0x0, MAX_UINT32)
var r12: int:
	get:
		return bit32(registers["r12"])
	set(value):
		registers["r12"] = clampi(bit32(value), 0x0, MAX_UINT32)
var r13: int:
	get:
		return bit32(registers["r13"])
	set(value):
		registers["r13"] = clampi(bit32(value), 0x0, MAX_UINT32)
var r14: int:
	get:
		return bit32(registers["r14"])
	set(value):
		registers["r14"] = clampi(bit32(value), 0x0, MAX_UINT32)
var r15: int:
	get:
		return bit32(registers["r15"])
	set(value):
		registers["r15"] = clampi(bit32(value), 0x0, MAX_UINT32)
var sp: int:
	get:
		return bit32(registers["r13"])
	set(value):
		registers["r13"] = clampi(bit32(value), 0x0, MAX_UINT32)
var lr: int:
	get:
		return bit32(registers["r14"])
	set(value):
		registers["r14"] = clampi(bit32(value), 0x0, MAX_UINT32)
var pc: int:
	get:
		return bit32(registers["r15"])
	set(value):
		registers["r15"] = clampi(bit32(value), 0x0, MAX_UINT32)
#endregion
var alu_flags: int = 0b0000  # NZCV
#region ALU shorthands
var n_flag: bool:
	get:
		return bool(alu_flags & 0b1000)
var z_flag: bool:
	get:
		return bool(alu_flags & 0b0100)
var c_flag: bool:
	get:
		return bool(alu_flags & 0b0010)
var v_flag: bool:
	get:
		return bool(alu_flags & 0b0001)
#endregion


func tokenize(lines: String) -> Array[CommandInfo]:
	var tokens: Array[CommandInfo] = []

	var split: PackedStringArray = lines.split("\n")
	for i: int in split.size():
		var line = split[i]
		line = line.strip_edges().to_lower()
		line = line.get_slice(COMMENT_CHARACTER, 0)
		if line.is_empty():
			continue

		var space_index: int = line.findn(" ")

		var args: Array[String] = []
		if space_index != -1 and space_index != line.length() - 1:
			args.assign(
				Array(line.substr(space_index).split(SEPARATOR)).map(func(arg: String): return arg.strip_edges())
			)

		var command: String = line.substr(0, space_index).rstrip(STRIP_CHARS)
		var condition: Conditions = Conditions.AL
		if args.size() > 0:
			for key: String in Conditions.keys():
				if command.ends_with(key.to_lower()):
					command = command.replacen(key, "")
					condition = Conditions[key]
					break

		tokens.append(CommandInfo.new(command, args, condition, args.size() <= 0, i + 1))

	return tokens


func parse(lines: String) -> void:
	code.clear()

	var tokens: Array[CommandInfo] = tokenize(lines)

	for i: int in tokens.size():
		var token: CommandInfo = tokens[i]
		if token.is_tag:
			tags[token.command] = i * 0x4
		code[i * 0x4] = token

	if code.size() > 0:
		reset_pc()

func reset_pc() -> void:
	if code.size() == 0:
		pc = 0x0
		return	
	pc = code.keys()[0]



func run_line() -> void:
	if code.is_empty() or not running or pc > code.keys()[-1]:
		return
	var command: CommandInfo = code[pc]
	if not command.is_tag and flag_check(command.condition):
		var err: String = Command.error_check(command)
		if err != Command.ERR_STR_OK:
			stop()
			error.emit(command.line, err)
			return

		Command.run_command(command)
		executing_line.emit(command.line)
	pc += 0x4
	if pc > code.keys()[-1]:
		stop()
		finished.emit()

func start() -> void:
	running = true

func stop() -> void:
	running = false


func set_flags(op1: int, op2: int, is_subtraction: bool = false) -> void:
	# Ensure 32-bit operations
	op1 = bit32(op1)
	op2 = bit32(op2)

	var result: int
	if is_subtraction:
		result = op1 - op2
	else:
		result = op1 + op2

	# Negative flag (n_flag)
	alu_flags = alu_flags | 0b1000 if result < 0 else alu_flags & ~0b1000

	# Zero flag (z_flag)
	alu_flags = alu_flags | 0b0100 if result == 0 else alu_flags & ~0b0100

	# Carry/Borrow flag (c_flag)
	if is_subtraction:
		alu_flags = alu_flags | 0b0010 if result > op1 else alu_flags & ~0b0010
	else:
		alu_flags = alu_flags | 0b0010 if result < op1 else alu_flags & ~0b0010

	# Overflow flag (v_flag)
	var sign_a = op1 >> 31
	var sign_b = op2 >> 31
	var sign_r = result >> 31
	if is_subtraction:
		alu_flags = (
			alu_flags | 0b0001 if (sign_a ^ sign_b) & (sign_a ^ sign_r) else alu_flags & ~0b0001
		)
	else:
		alu_flags = (
			alu_flags | 0b0001 if (sign_a ^ sign_b) & ~(sign_a ^ sign_r) else alu_flags & ~0b0001
		)


func flag_check(condition: Conditions) -> bool:
	match condition:
		Conditions.EQ:
			return z_flag
		Conditions.NE:
			return not z_flag
		Conditions.CS, Conditions.HS:
			return c_flag
		Conditions.CC, Conditions.LO:
			return not c_flag
		Conditions.MI:
			return n_flag
		Conditions.PL:
			return not n_flag
		Conditions.VS:
			return v_flag
		Conditions.VC:
			return not v_flag
		Conditions.HI:
			return (not z_flag) and c_flag
		Conditions.LS:
			return z_flag or (not c_flag)
		Conditions.GE:
			return not (n_flag != v_flag)
		Conditions.LT:
			return n_flag != v_flag
		Conditions.GT:
			return (not z_flag) and not (n_flag != v_flag)
		Conditions.LE:
			return z_flag or (n_flag != v_flag)
		Conditions.LE:
			return true
		_:
			return true


func bit32(num: int) -> int:
	return num & MAX_UINT32


func bit16(num: int) -> int:
	return num & MAX_UINT16


func bit8(num: int) -> int:
	return num & MAX_UINT8


class CommandInfo:
	var command: String
	var args: Array[String]
	var condition: Conditions
	var is_tag: bool = false
	var line: int = 0

	func _init(
		_command: String,
		_args: Array[String] = [],
		_condition: Conditions = Conditions.AL,
		_is_tag: bool = false,
		_line: int = 0
	) -> void:
		command = _command
		args = _args
		condition = _condition
		is_tag = _is_tag
		line = _line
