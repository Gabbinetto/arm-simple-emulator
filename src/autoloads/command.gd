extends Node


#region Command strings
# Data processing
const MOV: String = "mov"
const MVN: String = "mvn"
const ADD: String = "add"
const ADDS: String = "adds"
const SUB: String = "sub"
const SUBS: String = "subs"
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
# Branching
const B: String = "b"
const BL: String = "bl"
#endregion


func run_command(info: Executor.CommandInfo) -> void:
	match info.command:
		#region Data processing
		MOV:
			var op2: int = parse_value(info.args[1])
			Executor.set(
				info.args[0], op2
			)
		MVN:
			var op2: int = parse_value(info.args[1])
			Executor.set(
				info.args[0], ~op2
			)
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
		#endregion
		#region Branching
		B:
			var target: int = Executor.tags.get(info.args[0], -1)
			print("0x%X" % target)
			if target != -1:
				Executor.set("pc", target)
		BL:
			pass

		#endregion
		_:
			print_debug("No command")


func parse_value(value: String) -> int:
	if value[0] == "#":
		return parse_immediate(value)
	return Executor.get(value)


func parse_immediate(num: String) -> int:
	var num_string: String = num.lstrip("#")
	if num_string.containsn("x"):
		return num_string.hex_to_int()
	elif num_string.containsn("b"):
		return num_string.bin_to_int()
	else:
		return int(num)


func parse_address(args: Array[String]) -> int:
	var remove_brackets: Callable = func(string: String): return string.lstrip("[").rstrip("]")

	if args.front() == "#":
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