class_name Rng
extends RefCounted
## Sorteio determinístico com semente. Cada instância tem o próprio gerador;
## nunca usa o sorteio global. Chances em pontos-base (10000 = 100%).

const _MASK32: int = 0xFFFFFFFF
const _MASK31: int = 0x7FFFFFFF
const _BP_FULL: int = 10000

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _init(seed_value: int) -> void:
	_rng.seed = seed_value


## Inteiro em [0, max_exclusive). Com max_exclusive <= 0 é erro de programação: devolve 0.
func next_int(max_exclusive: int) -> int:
	if max_exclusive <= 0:
		push_error("Rng.next_int: max_exclusive deve ser > 0, recebido %d" % max_exclusive)
		return 0
	return _rng.randi() % max_exclusive


## Inteiro em [lo, hi_inclusive]. Com hi < lo é erro de programação: devolve lo.
func range_int(lo: int, hi_inclusive: int) -> int:
	if hi_inclusive < lo:
		push_error("Rng.range_int: hi (%d) menor que lo (%d)" % [hi_inclusive, lo])
		return lo
	return lo + next_int(hi_inclusive - lo + 1)


## Verdadeiro com probabilidade chance_bp / 10000.
func roll_bp(chance_bp: int) -> bool:
	return next_int(_BP_FULL) < chance_bp


## Elemento sorteado do array. Array vazio é erro de programação: devolve null.
func pick(arr: Array) -> Variant:
	if arr.is_empty():
		push_error("Rng.pick: array vazio")
		return null
	return arr[next_int(arr.size())]


func get_state() -> int:
	return _rng.state


func set_state(s: int) -> void:
	_rng.state = s


## Semente derivada de (base, n), só com aritmética inteira (igual em toda plataforma).
## Sempre em [0, 2^31).
static func derive_seed(base: int, n: int) -> int:
	var h: int = base & _MASK32
	h = (h + (n & _MASK32) * 0x2545F491 + 0x6A09E667) & _MASK32
	h = ((h ^ (h >> 16)) * 0x045D9F3B) & _MASK32
	h = ((h ^ (h >> 16)) * 0x045D9F3B) & _MASK32
	h = h ^ (h >> 16)
	return h & _MASK31
