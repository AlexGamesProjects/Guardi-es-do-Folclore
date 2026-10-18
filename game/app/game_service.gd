extends Node
## Autoload `GameService`: guarda o estado atual e recebe os comandos das telas.
## As telas só leem o estado (`get_state()`) e mudam tudo por `send`.
## Um comando por vez; um segundo enquanto o primeiro está pendente volta com `OCUPADO`.

signal state_changed(state: GameState)
signal events_emitted(events: Array[Dictionary])
signal busy_changed(busy: bool)
signal warning(code: String)

var _state: GameState = null
var _rules: RulesPack = null
var _executor: CommandExecutor = null
var _clock: Clock = null
var _busy: bool = false


func setup(rules: RulesPack, executor: CommandExecutor, clock: Clock, initial: GameState) -> void:
	_rules = rules
	_executor = executor
	_clock = clock
	_state = initial
	_busy = false


func get_state() -> GameState:
	return _state


func is_busy() -> bool:
	return _busy


func send(type: String, params: Dictionary = {}) -> CommandResult:
	if _busy:
		return CommandResult.fail(_state, "OCUPADO")
	_set_busy(true)
	var cmd: Command = Command.make(
		type,
		params,
		Rng.derive_seed(_state.rng_seed, _state.cmd_counter),
		_clock.now_ms(),
		_rules.rules_version
	)
	var res: CommandResult = await _executor.execute(_state, cmd)
	if res == null:
		res = CommandResult.fail(_state, "ERRO_EXECUTOR")
	if res.ok:
		res.state.cmd_counter += 1
		_state = res.state
	# Solta o busy antes dos sinais: um ouvinte pode encadear outro `send`.
	_set_busy(false)
	if res.ok:
		state_changed.emit(_state)
		events_emitted.emit(res.events)
	return res


func _set_busy(value: bool) -> void:
	_busy = value
	busy_changed.emit(value)
