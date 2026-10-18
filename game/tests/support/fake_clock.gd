class_name FakeClock
extends Clock
## Relógio dos testes: o tempo só anda quando o teste manda.

var _now: int = 0


func _init(start_ms: int = 0) -> void:
	_now = start_ms


func now_ms() -> int:
	return _now


func advance(ms: int) -> void:
	_now += ms


func set_now(ms: int) -> void:
	_now = ms
