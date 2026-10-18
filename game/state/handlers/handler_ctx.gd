class_name HandlerCtx
extends RefCounted
## Tudo que um handler precisa: o estado (já um clone), os parâmetros, o sorteio, o instante e as
## regras. Os eventos gerados se acumulam em `events`.

var s: GameState
var p: Dictionary
var rng: Rng
var now_ms: int
var rules: RulesPack
var events: Array[Dictionary] = []


func _init(
	state: GameState, params: Dictionary, rng_value: Rng, now_value: int, rules_pack: RulesPack
) -> void:
	s = state
	p = params
	rng = rng_value
	now_ms = now_value
	rules = rules_pack


func emit(type: String, data: Dictionary = {}) -> void:
	var e: Dictionary = {"type": type}
	e.merge(data)
	events.append(e)


## Parâmetro numérico como inteiro; -1 se faltar ou não for número.
func arg_int(key: String) -> int:
	var v: Variant = p.get(key)
	if typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT:
		return int(v)
	return -1


## Parâmetro de texto; vazio se faltar ou não for texto.
func arg_str(key: String) -> String:
	var v: Variant = p.get(key)
	return v if v is String else ""
