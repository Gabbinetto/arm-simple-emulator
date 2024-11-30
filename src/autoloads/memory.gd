extends Node


const STACK_POINTER_ADDRESS: int = 0x60000 # Arbitrary definition


var _memory: Dictionary = {}

func mem_store(address: int, value: int) -> void:
    _memory[address] = Executor.bit32(value)


func mem_store_byte(address: int, value: int) -> void:
    var byte: int = address % 0x4
    address -= byte
    value = Executor.bit8(value) << byte * 0x4
    var mask: int = ~(Executor.MAX_UINT8 << byte * 0x4)
    _memory[address] = (_memory.get(address, 0x0) & mask) | value


func mem_load(address: int) -> int:
    return _memory.get(address, 0x0)


func mem_load_byte(address: int) -> int:
    var byte: int = address % 0x4
    address -= byte
    var mask: int = Executor.MAX_UINT8 << byte * 0x4
    var value: int = _memory.get(address, 0x0) & mask
    value >>= byte * 0x4
    return Executor.bit8(value)


func _ready() -> void:
    Executor.set("sp", STACK_POINTER_ADDRESS)