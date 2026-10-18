class_name CommandResult
extends RefCounted
## Resultado de um comando. Em sucesso, `state` é o novo estado; em erro, é o estado original,
## intacto, e `error` traz o código (ver CommandRouter).

var ok: bool = false
var error: String = ""
var state: GameState = null
var events: Array[Dictionary] = []


static func success(new_state: GameState, new_events: Array[Dictionary]) -> CommandResult:
	var out := CommandResult.new()
	out.ok = true
	out.state = new_state
	out.events = new_events
	return out


static func fail(old_state: GameState, code: String) -> CommandResult:
	var out := CommandResult.new()
	out.ok = false
	out.error = code
	out.state = old_state
	return out
