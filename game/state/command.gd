class_name Command
extends RefCounted
## Pedido de mudança de estado. O instante (`now_ms`) e a semente (`seed`) entram prontos, assim o
## mesmo comando sobre o mesmo estado dá sempre o mesmo resultado.

var type: String = ""
var params: Dictionary = {}
var seed: int = 0
var now_ms: int = 0
var rules_version: String = ""


static func make(
	type_value: String,
	params_value: Dictionary,
	seed_value: int,
	now_value: int,
	rules_version_value: String
) -> Command:
	var out := Command.new()
	out.type = type_value
	out.params = params_value
	out.seed = seed_value
	out.now_ms = now_value
	out.rules_version = rules_version_value
	return out


func to_dict() -> Dictionary:
	return {
		"type": type,
		"params": params.duplicate(true),
		"seed": seed,
		"now_ms": now_ms,
		"rules_version": rules_version,
	}


static func from_dict(d: Dictionary) -> Command:
	var raw_params: Variant = Defs.normalize(d.get("params", {}))
	return Command.make(
		str(d.get("type", "")),
		raw_params if raw_params is Dictionary else {},
		int(d.get("seed", 0)),
		int(d.get("now_ms", 0)),
		str(d.get("rules_version", ""))
	)
