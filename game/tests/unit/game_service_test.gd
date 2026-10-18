extends GdUnitTestSuite

var _rules: RulesPack
var _clock: FakeClock
var _svc: Node


func before() -> void:
	_rules = Fx.rules()


func before_test() -> void:
	_clock = FakeClock.new(Fx.T0)
	_svc = auto_free(load("res://app/game_service.gd").new())


func _setup_service(executor: CommandExecutor) -> GameState:
	var s: GameState = Fx.game(_rules)
	_svc.call("setup", _rules, executor, _clock, s)
	return s


func _collect(results: Array, type: String, params: Dictionary) -> void:
	results.append(await _svc.send(type, params))


func _wait_for(results: Array, count: int, limit_ms: int = 3000) -> void:
	var started: int = Time.get_ticks_msec()
	while results.size() < count and Time.get_ticks_msec() - started < limit_ms:
		await get_tree().process_frame


func test_second_send_while_busy_is_rejected() -> void:
	var s: GameState = _setup_service(DelayedExecutor.new(LocalExecutor.new(_rules), 500))
	var before_for: int = s.stats["for"]
	var results: Array = []
	_collect(results, "treinar", {"stat": "for"})
	_collect(results, "treinar", {"stat": "for"})
	await _wait_for(results, 2)
	assert_int(results.size()).is_equal(2)
	# O recusado volta na hora; o primeiro só depois do atraso.
	var rejected: CommandResult = results[0]
	var accepted: CommandResult = results[1]
	assert_bool(rejected.ok).is_false()
	assert_str(rejected.error).is_equal("OCUPADO")
	assert_bool(accepted.ok).is_true()
	var now_state: GameState = _svc.get_state()
	assert_int(now_state.stats["for"]).is_equal(before_for + 1)
	assert_int(now_state.cmd_counter).is_equal(2)


func test_send_returns_after_executor_and_clears_busy() -> void:
	_setup_service(LocalExecutor.new(_rules))
	assert_bool(_svc.is_busy()).is_false()
	var res: CommandResult = await _svc.send("treinar", {"stat": "for"})
	assert_bool(res.ok).is_true()
	assert_bool(_svc.is_busy()).is_false()


func test_busy_signal_toggles() -> void:
	_setup_service(LocalExecutor.new(_rules))
	var seen: Array[bool] = []
	_svc.busy_changed.connect(func(b: bool) -> void: seen.append(b))
	await _svc.send("treinar", {"stat": "for"})
	assert_array(seen).is_equal([true, false])


func test_events_emitted_on_success() -> void:
	var s: GameState = _setup_service(LocalExecutor.new(_rules))
	var got: Array = []
	var states: Array = []
	_svc.events_emitted.connect(func(e: Array[Dictionary]) -> void: got.append(e))
	_svc.state_changed.connect(func(st: GameState) -> void: states.append(st))
	var mission_id: int = int(s.ofertas[0]["id"])
	var res: CommandResult = await _svc.send("iniciar_missao", {"mission_id": mission_id})
	assert_bool(res.ok).is_true()
	assert_int(got.size()).is_equal(1)
	assert_int(states.size()).is_equal(1)
	assert_object(states[0]).is_same(_svc.get_state())


func test_failure_keeps_state_and_emits_no_state_change() -> void:
	var s: GameState = _setup_service(LocalExecutor.new(_rules))
	var states: Array = []
	_svc.state_changed.connect(func(st: GameState) -> void: states.append(st))
	var res: CommandResult = await _svc.send("treinar", {"stat": "sorte"})
	assert_bool(res.ok).is_false()
	assert_object(_svc.get_state()).is_same(s)
	assert_int(s.cmd_counter).is_equal(1)
	assert_int(states.size()).is_equal(0)
	assert_bool(_svc.is_busy()).is_false()


func test_command_gets_seed_clock_and_rules_version() -> void:
	var s: GameState = _setup_service(LocalExecutor.new(_rules))
	var probe := ProbeExecutor.new()
	_svc.call("setup", _rules, probe, _clock, s)
	await _svc.send("treinar", {"stat": "for"})
	var cmd: Command = probe.last
	assert_int(cmd.seed).is_equal(Rng.derive_seed(s.rng_seed, 1))
	assert_int(cmd.now_ms).is_equal(Fx.T0)
	assert_str(cmd.rules_version).is_equal(_rules.rules_version)
	await _svc.send("treinar", {"stat": "for"})
	assert_int(probe.last.seed).is_equal(Rng.derive_seed(s.rng_seed, 2))


func test_null_from_executor_becomes_error_and_releases_busy() -> void:
	var s: GameState = _setup_service(NullExecutor.new())
	var res: CommandResult = await _svc.send("treinar", {"stat": "for"})
	assert_bool(res.ok).is_false()
	assert_str(res.error).is_equal("ERRO_EXECUTOR")
	assert_object(_svc.get_state()).is_same(s)
	assert_bool(_svc.is_busy()).is_false()


func test_listener_can_chain_send_from_state_changed() -> void:
	_setup_service(LocalExecutor.new(_rules))
	var chained: Array = []
	_svc.state_changed.connect(
		func(_st: GameState) -> void:
			if chained.is_empty():
				chained.append(await _svc.send("treinar", {"stat": "for"}))
	)
	var s: GameState = _svc.get_state()
	var before_for: int = s.stats["for"]
	await _svc.send("treinar", {"stat": "for"})
	await _wait_for(chained, 1)
	assert_int(chained.size()).is_equal(1)
	var inner: CommandResult = chained[0]
	assert_str(inner.error).is_not_equal("OCUPADO")
	assert_bool(inner.ok).is_true()
	assert_int((_svc.get_state() as GameState).stats["for"]).is_equal(before_for + 2)


class NullExecutor:
	extends CommandExecutor

	func execute(_state: GameState, _cmd: Command) -> CommandResult:
		return null


class ProbeExecutor:
	extends CommandExecutor
	var last: Command = null

	func execute(state: GameState, cmd: Command) -> CommandResult:
		last = cmd
		return CommandRouter.apply(state, cmd, Fx.rules())
