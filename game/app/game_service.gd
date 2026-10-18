extends Node
## Autoload `GameService`: guarda o estado atual e recebe os comandos das telas.
## As telas só leem o estado (`get_state()`) e mudam tudo por `send`.
## Um comando por vez; um segundo enquanto o primeiro está pendente volta com `OCUPADO`.

signal state_changed(state: GameState)
signal events_emitted(events: Array[Dictionary])
signal busy_changed(busy: bool)
signal warning(code: String)

## Intervalo mínimo entre gravações em disco.
const SAVE_INTERVAL_MS: int = 2000

var _state: GameState = null
var _rules: RulesPack = null
var _executor: CommandExecutor = null
var _clock: Clock = null
var _busy: bool = false
var _save_service: SaveService = null
var _dirty: bool = false
var _last_save_ms: int = -SAVE_INTERVAL_MS
var _save_failing: bool = false


## Com `save_service` nulo o jogo não grava (os testes de comando não precisam de disco).
func setup(
	rules: RulesPack,
	executor: CommandExecutor,
	clock: Clock,
	initial: GameState,
	save_service: SaveService = null
) -> void:
	_rules = rules
	_executor = executor
	_clock = clock
	_state = initial
	_busy = false
	_save_service = save_service
	_dirty = false
	_last_save_ms = -SAVE_INTERVAL_MS
	_save_failing = false


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
		_dirty = true
	# Solta o busy antes dos sinais: um ouvinte pode encadear outro `send`.
	_set_busy(false)
	if res.ok:
		state_changed.emit(_state)
		events_emitted.emit(res.events)
		_save_tick()
	return res


func _set_busy(value: bool) -> void:
	_busy = value
	busy_changed.emit(value)


func _process(_delta: float) -> void:
	_save_tick()


func _notification(what: int) -> void:
	if (
		what == NOTIFICATION_APPLICATION_PAUSED
		or what == NOTIFICATION_APPLICATION_FOCUS_OUT
		or what == NOTIFICATION_WM_CLOSE_REQUEST
	):
		save_now()


## Grava se há mudança pendente e a janela de `SAVE_INTERVAL_MS` já fechou. Assim a última
## mudança nunca fica sem gravar: se caiu dentro da janela, o próximo tick a leva ao disco.
func _save_tick() -> void:
	if not _dirty or _save_service == null or _clock == null:
		return
	if _clock.now_ms() - _last_save_ms >= SAVE_INTERVAL_MS:
		save_now()


## Grava já, se houver mudança pendente. Falha de gravação vira `warning("SAVE_FALHOU")` uma vez
## por sequência de falhas; a mudança continua pendente e é tentada de novo no próximo intervalo.
func save_now() -> bool:
	if not _dirty or _save_service == null or _state == null:
		return false
	_last_save_ms = _clock.now_ms()
	if _save_service.save(_state, _rules.rules_version):
		_dirty = false
		_save_failing = false
		return true
	if not _save_failing:
		_save_failing = true
		warning.emit("SAVE_FALHOU")
	return false
