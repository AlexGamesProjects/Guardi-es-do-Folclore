extends GdUnitTestSuite

var _rules: RulesPack
var _root: String
var _clock: FakeClock
var _io: FileIO
var _save: SaveService
var _svc: Node


func before() -> void:
	_rules = Fx.rules()


func before_test() -> void:
	_root = TempDir.make()
	_clock = FakeClock.new(Fx.T0)
	_io = FileIO.new()
	_save = SaveService.new(_io, _root)
	_svc = auto_free(load("res://app/game_service.gd").new())


func after_test() -> void:
	TempDir.remove(_root)


func _setup(io: FileIO = null) -> void:
	var service: SaveService = _save if io == null else SaveService.new(io, _root)
	_svc.call("setup", _rules, LocalExecutor.new(_rules), _clock, Fx.game(_rules), service)


func _saved_counter() -> int:
	var res: Dictionary = SaveCodec.decode(_io.read("%s/p1.json" % _root), SaveMigrations.new())
	return -1 if not res["ok"] else (res["state"] as GameState).cmd_counter


func test_first_success_saves_immediately() -> void:
	_setup()
	await _svc.send("treinar", {"stat": "for"})
	assert_int(_saved_counter()).is_equal(2)


func test_failed_command_does_not_save() -> void:
	_setup()
	await _svc.send("treinar", {"stat": "sorte"})
	assert_int(_saved_counter()).is_equal(-1)


func test_saves_at_most_once_per_window_and_last_change_is_never_lost() -> void:
	_setup()
	await _svc.send("treinar", {"stat": "for"})
	assert_int(_saved_counter()).is_equal(2)
	_clock.advance(500)
	await _svc.send("treinar", {"stat": "for"})
	_clock.advance(500)
	await _svc.send("treinar", {"stat": "for"})
	# Dentro da janela de 2000 ms: nada novo no disco.
	assert_int(_saved_counter()).is_equal(2)
	_svc.call("_save_tick")
	assert_int(_saved_counter()).is_equal(2)
	_clock.advance(999)
	_svc.call("_save_tick")
	assert_int(_saved_counter()).is_equal(2)
	# A janela fecha: a última mudança vai para o disco.
	_clock.advance(1)
	_svc.call("_save_tick")
	assert_int(_saved_counter()).is_equal(4)
	# Sem mudança nova, o tick não regrava.
	var main: String = _io.read("%s/p1.json" % _root)
	_clock.advance(5000)
	_svc.call("_save_tick")
	assert_str(_io.read("%s/p1.json" % _root)).is_equal(main)


func test_command_after_window_saves_right_away() -> void:
	_setup()
	await _svc.send("treinar", {"stat": "for"})
	_clock.advance(2000)
	await _svc.send("treinar", {"stat": "for"})
	assert_int(_saved_counter()).is_equal(3)


func test_pause_and_focus_out_save_immediately() -> void:
	for what: int in [
		Node.NOTIFICATION_APPLICATION_PAUSED,
		Node.NOTIFICATION_APPLICATION_FOCUS_OUT,
		Node.NOTIFICATION_WM_CLOSE_REQUEST,
	]:
		TempDir.remove(_root)
		_setup()
		await _svc.send("treinar", {"stat": "for"})
		_clock.advance(100)
		await _svc.send("treinar", {"stat": "for"})
		assert_int(_saved_counter()).is_equal(2)
		_svc.notification(what)
		assert_int(_saved_counter()).is_equal(3)


func test_write_failure_emits_warning_and_game_continues() -> void:
	var failing := FailingFileIO.new()
	_setup(failing)
	var codes: Array[String] = []
	_svc.warning.connect(func(c: String) -> void: codes.append(c))
	var res: CommandResult = await _svc.send("treinar", {"stat": "for"})
	assert_bool(res.ok).is_true()
	assert_array(codes).is_equal(["SAVE_FALHOU"])
	# O jogo segue; sem repetir o aviso enquanto a falha continua.
	_clock.advance(2000)
	_svc.call("_save_tick")
	assert_array(codes).is_equal(["SAVE_FALHOU"])
	# Quando o disco volta, a mudança pendente é gravada.
	failing.fail_writes = false
	_clock.advance(2000)
	_svc.call("_save_tick")
	assert_int(_saved_counter()).is_equal(2)


func test_without_save_service_nothing_is_written() -> void:
	_svc.call("setup", _rules, LocalExecutor.new(_rules), _clock, Fx.game(_rules))
	await _svc.send("treinar", {"stat": "for"})
	_svc.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	assert_bool(_io.exists("%s/p1.json" % _root)).is_false()
