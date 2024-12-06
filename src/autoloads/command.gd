extends Node


#region Command strings
# Data processing
const MOV: String = "mov"
const MVN: String = "mvn"
const AND: String = "and"
const ANDS: String = "and"
const ORR: String = "orr"
const ORRS: String = "orr"
const EOR: String = "eor"
const EORS: String = "eor"
const BIC: String = "bic"
const BICS: String = "bic"
const ADD: String = "add"
const ADDS: String = "adds"
const SUB: String = "sub"
const SUBS: String = "subs"
const MUL: String = "mul"
const UMULL: String = "umull"
const SMULL: String = "smull"
const CMP: String = "cmp"
const CMN: String = "cmn"
const ROR: String = "ror"
const ROL: String = "rol"
const LSL: String = "lsl"
const LSR: String = "lsr"
const ASR: String = "asr"
# Memory
const STR: String = "str"
const STRB: String = "strb"
const LDR: String = "ldr"
const LDRB: String = "ldrb"
const PUSH: String = "push"
const POP: String = "pop"
# Branching
const B: String = "b"
const BL: String = "bl"
#endregion

const ERR_STR_OK: String = "OK"
const ERR_ARG_NUM: String = "Line %d: Not enough arguments for instruction %s"
const ERR_NOT_REG: String = "Line %d: Argument %d is not a valid register"
const ERR_NOT_VAL: String = "Line %d: Argument %d is not a valid register or immediate"
const ERR_BRACKETS: String = "Line %d: Invalid or missing brackets"
const ERR_BRACES: String = "Line %d: Invalid or missing braces"
const ERR_BRANCHING: String = "Line %d: Branch target \"%s\" not found"

func run_command(info: Executor.CommandInfo) -> void:
	match info.command:
		#region Data processing
		MOV:
			var op2: int = parse_value(info.args[1])
			var pc_offset: int = 0x0
			if info.args[0] == "pc": pc_offset = 0x4
			Executor.set(
				info.args[0], op2 - pc_offset
			)
		MVN:
			var op2: int = parse_value(info.args[1])
			Executor.set(
				info.args[0], ~op2
			)
		AND:
			var op1: int = reg(info.args[1])
			var op2: int = parse_value(info.args[2])
			Executor.set(
				info.args[0], op1 & op2
			)
		ANDS:
			var op1: int = reg(info.args[1])
			var op2: int = parse_value(info.args[2])
			Executor.set(
				info.args[0], op1 & op2
			)
			Executor.set_flags(op1 & op2, 0)
		ORR:
			var op1: int = reg(info.args[1])
			var op2: int = parse_value(info.args[2])
			Executor.set(
				info.args[0], op1 | op2
			)
		ORRS:
			var op1: int = reg(info.args[1])
			var op2: int = parse_value(info.args[2])
			Executor.set(
				info.args[0], op1 | op2
			)
			Executor.set_flags(op1 | op2, 0)
		EOR:
			var op1: int = reg(info.args[1])
			var op2: int = parse_value(info.args[2])
			Executor.set(
				info.args[0], op1 ^ op2
			)
		EORS:
			var op1: int = reg(info.args[1])
			var op2: int = parse_value(info.args[2])
			Executor.set(
				info.args[0], op1 ^ op2
			)
			Executor.set_flags(op1 ^ op2, 0)
		BIC:
			var op1: int = reg(info.args[1])
			var op2: int = parse_value(info.args[2])
			Executor.set(
				info.args[0], op1 | (~op2)
			)
		BICS:
			var op1: int = reg(info.args[1])
			var op2: int = parse_value(info.args[2])
			Executor.set(
				info.args[0], op1 | (~op2)
			)
			Executor.set_flags(op1 | (~op2), 0)
		ADD:
			var op1: int = reg(info.args[1])
			var op2: int = parse_value(info.args[2])
			Executor.set(
				info.args[0], op1 + op2
			)
		ADDS:
			var op1: int = reg(info.args[1])
			var op2: int = parse_value(info.args[2])
			Executor.set(
				info.args[0], op1 + op2
			)
			Executor.set_flags(op1, op2)
		SUB:
			var op1: int = reg(info.args[1])
			var op2: int = parse_value(info.args[2])
			Executor.set(
				info.args[0], op1 - op2
			)
		SUBS:
			var op1: int = reg(info.args[1])
			var op2: int = parse_value(info.args[2])
			Executor.set(
				info.args[0], op1 - op2
			)
			Executor.set_flags(op1, op2, true)
		MUL:
			var op1: int = reg(info.args[1])
			var op2: int = parse_value(info.args[2])
			Executor.set(
				info.args[0], op1 * op2
			)
		UMULL:
			var op1: int = reg(info.args[2])
			var op2: int = parse_value(info.args[3])
			var result: int = op1 * op2
			Executor.set(
				info.args[0], Executor.bit32(result)
			)
			Executor.set(
				info.args[1], result >> Executor.WORD_SIZE
			)
		SMULL:
			pass
		CMP:
			var op1: int = reg(info.args[0])
			var op2: int = parse_value(info.args[1])
			Executor.set_flags(op1, op2, true)
		CMN:
			var op1: int = reg(info.args[0])
			var op2: int = parse_value(info.args[1])
			Executor.set_flags(op1, op2)
		ROR, ROL, LSL, LSR, ASR:
			var op1: int = reg(info.args[1])
			var op2: int = parse_value(info.args[2])
			Executor.set(
				info.args[0], shift_command(info.command, op1, op2)
			)
		#endregion
		#region Memory
		STR:
			var address: int = parse_address(info.args.slice(1))
			Memory.mem_store(address, reg(info.args[0]))
		STRB:
			var address: int = parse_address(info.args.slice(1))
			Memory.mem_store_byte(address, reg(info.args[0]))
		LDR:
			var address: int = parse_address(info.args.slice(1))
			Executor.set(info.args[0], Memory.mem_load(address))
		LDRB:
			var address: int = parse_address(info.args.slice(1))
			Executor.set(info.args[0], Memory.mem_load_byte(address))
		PUSH:
			var args: Array[String] = []
			args.assign(
				info.args.map(func(item: String): return item.lstrip("{").rstrip("}"))
			)
			for register: String in args:
				Memory.mem_store(Executor.sp, reg(register))
				Executor.sp -= 0x4
		POP:
			var args: Array[String] = []
			args.assign(
				info.args.map(func(item: String): return item.lstrip("{").rstrip("}"))
			)
			for register: String in args:
				Executor.sp += 0x4
				Executor.set(
					register,
					Memory.mem_load(Executor.sp)
				)
				Memory.mem_store(Executor.sp, 0x0)
		#endregion
		#region Branching
		B:
			var target: int = Executor.tags.get(info.args[0], -1)
			if target != -1:
				Executor.pc = target
		BL:
			var target: int = Executor.tags.get(info.args[0], -1)
			if target != -1:
				Executor.lr = Executor.pc + 0x4
				Executor.pc = target

		#endregion
		_:
			print_debug("No command")


func parse_value(value: String) -> int:
	if value[0] == Executor.IMMEDIATE_CHARACTER:
		return parse_immediate(value)
	return Executor.get(value)


func parse_immediate(num: String) -> int:
	var num_string: String = num.lstrip(Executor.IMMEDIATE_CHARACTER)
	if num_string.containsn("x"):
		return num_string.hex_to_int()
	elif num_string.containsn("b"):
		return num_string.bin_to_int()
	else:
		return int(num)


func parse_address(args: Array[String]) -> int:
	var remove_brackets: Callable = func(string: String): return string.lstrip("[").rstrip("]")

	if args.front() == Executor.IMMEDIATE_CHARACTER:
		return parse_immediate(args.front())

	var pre_index_end: int = 0
	for i: int in args.size():
		if args[i].ends_with("]"):
			pre_index_end = i
			break
	
	var address: int = 0x0
	if pre_index_end == 0 and args.size() == 1:
		# [rX]
		return Executor.get(remove_brackets.call(args.front()))

	var register: String = remove_brackets.call(args.front())
	address = Executor.get(register)
	var offset: int = 0
	if args.size() == 2:
		if args.back().contains(" "):
			pass
		else:
			var shift: String = remove_brackets.call(args.back()).get_slice(" ", 0)
			var amount: int = parse_value(remove_brackets.call(args.back()).get_slice(" ", 1))
			offset = shift_command(shift, address, amount) - address
	elif args.size() == 3:
		var shift: String = remove_brackets.call(args.back()).get_slice(" ", 0)
		var amount: int = parse_value(remove_brackets.call(args.back()).get_slice(" ", 1))
		offset = (
			shift_command(shift, parse_value(remove_brackets.call(args[1])), amount)
		)
	if pre_index_end == args.size() - 1:
		# [rX, rY, SHIFT #z]
		address += offset
	else:
		# [rX], rY, SHIFT #z
		Executor.set(register, address + offset)

	return address


func shift_command(command: String, value: int, amount: int) -> int:
	var output: int = 0
	match command:
		ROR: output = (value >> amount) | (value << (Executor.WORD_SIZE - amount))
		ROL: output = (value << amount) | (value >> (Executor.WORD_SIZE - amount))
		LSL: output = value << amount
		LSR: output = value >> amount
		ASR: output = (value >> amount) | (((2 ** value - 1) * (value >> (Executor.WORD_SIZE - 1))) << (Executor.WORD_SIZE - amount))
		_: return 0
	return Executor.bit32(output)


func reg(register: String) -> int:
	if Executor.get(register):
		return Executor.get(register)
	else:
		return 0


func check_register(s: String) -> bool:
	return Executor.POSSIBLE_REGISTERS.has(s)

func check_immediate(s: String) -> bool:
	if s[0] != Executor.IMMEDIATE_CHARACTER:
		return false
	return s.substr(1).is_valid_int()

func check_value(s: String) -> bool:
	if s[0] == "r" or ["sp", "lr", "lr"].has(s):
		return check_register(s)
	if s[0] == Executor.IMMEDIATE_CHARACTER:
		return check_immediate(s)
	else:
		return false


func error_check(command: Executor.CommandInfo) -> String:
	match command.command:
		MOV, MVN, CMP, CMN:
			if command.args.size() != 2:
				return ERR_ARG_NUM % [command.line, command.command]
			var val: String = command.args[0]
			if not check_register(val):
				return ERR_NOT_REG % [command.line, 0]
			val = command.args[1]
			if not check_value(val):
				return ERR_NOT_VAL % [command.line, 1]
		AND, ANDS, ORR, ORRS, EOR, EORS, BIC, BICS, ADD, ADDS, SUB, SUBS, MUL, ROR, ROL, LSL, LSR, ASR:
			if command.args.size() != 3:
				return ERR_ARG_NUM % [command.line, command.command]
			var val: String 
			for i: int in 2:
				val = command.args[i]
				if not check_register(val):
					return ERR_NOT_REG % [command.line, i]
			val = command.args[2]
			if not check_value(val):
				return ERR_NOT_VAL % [command.line, 2]
		UMULL, SMULL:
			if command.args.size() != 4:
				return ERR_ARG_NUM % [command.line, command.command]
			var val: String
			for i: int in 3:
				val = command.args[i]
				if not check_register(val):
					return ERR_NOT_REG % [command.line, i]
			val = command.args[3]
			if not check_value(val):
				return ERR_NOT_VAL % [command.line, 3]
		STR, STRB, LDR, LDRB:
			if command.args.size() < 2:
				return ERR_ARG_NUM % [command.line, command.command]
			if not check_register(command.args[0]):
				return ERR_NOT_REG % [command.line, 0]

			var has_start: bool = false
			var has_end: bool = false
			for i: int in range(1, command.args.size()):
				if command.args[i][0] == "[": has_start = true
				if command.args[i][-1] == "]": has_end = true
				var s: String = command.args[i].lstrip("[").rstrip("]")
				if not check_value(s):
					return ERR_NOT_VAL % [command.line, i]
			if not (has_start or has_end):
				return ERR_BRACKETS % command.line
		PUSH, POP:
			if command.args.size() < 1:
				return ERR_ARG_NUM % [command.line, command.command]
			if command.args.front()[0] != "{" or command.args.back()[-1] != "}":
				return ERR_BRACES % command.line
			for i: int in range(1, command.args.size() - 1):
				var s: String = command.args[i].lstrip("{").rstrip("}")
				if not check_value(s):
					return ERR_NOT_VAL % [command.line, i]
		BL:
			if command.args.size() != 1:
				return ERR_ARG_NUM % [command.line, command.command]
			if Executor.tags.get(command.args.front(), -1) == -1:
				return ERR_BRANCHING % [command.line, command.args.front()]

	return ERR_STR_OK
