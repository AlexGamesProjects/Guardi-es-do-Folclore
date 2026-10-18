extends Node
## Autoload `GameService`: guarda o estado atual e recebe os comandos das telas.
## Um comando por vez; um segundo enquanto o primeiro está pendente volta com `OCUPADO`.

signal state_changed(state: GameState)
signal events_emitted(events: Array[Dictionary])
signal busy_changed(busy: bool)
signal warning(code: String)

var state: GameState = null

var _rules: RulesPack = null
var _executor: CommandExecutor = null
var _clock: Clock = null
var _busy: bool = false


func setup(rules: RulesPack, executor: CommandExecutor, clock: Clock, initial: GameState) -> void:
	_rules = rules
	_executor = executor
	_clock = clock
	state = initial
	_busy = false


func is_busy() -> bool:
	return _busy


func send(type: String, params: Dictionary = {}) -> CommandResult:
	if _busy:
		return CommandResult.fail(state, "OCUPADO")
	_set_busy(true)
	var cmd: Command = Command.make(
		type,
		params,
		Rng.derive_seed(state.rng_seed, state.cmd_counter),
		_clock.now_ms(),
		_rules.rules_version
	)
	var res: CommandResult = await _executor.execute(state, cmd)
	if res.ok:
		res.state.cmd_counter += 1
		state = res.state
		state_changed.emit(state)
		events_emitted.emit(res.events)
	_set_busy(false)
	return res


func _set_busy(value: bool) -> void:
	_busy = value
	busy_changed.emit(value)
