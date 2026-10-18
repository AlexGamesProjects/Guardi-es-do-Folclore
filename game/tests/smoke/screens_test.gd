extends GdUnitTestSuite
## Fumaça das telas da casca: abrem sem erro, selo de modo, botão online, ocupado e painel.

const SCREENS: Array[String] = [
	"res://ui/menu.tscn",
	"res://ui/diagnostico.tscn",
	"res://ui/luta_teste.tscn",
	"res://ui/mode_badge.tscn",
]
const EXPECTED_LINES: Array[String] = [
	"Jaci enfrenta Saci Ligeiro",
	"Jaci acerta Saci Ligeiro: −16 PV",
	"Golpe crítico! Jaci acerta Saci Ligeiro: −34 PV",
	"Saci Ligeiro esquiva",
	"Vitória!",
]


## Registra todo erro do motor (push_error, erro de script) enquanto está instalado.
class ErrorLog:
	extends Logger
	var errors: Array[String] = []
	var _mutex: Mutex = Mutex.new()

	func _log_error(
		function: String,
		file: String,
		line: int,
		code: String,
		rationale: String,
		_editor_notify: bool,
		error_type: int,
		_script_backtraces: Array[ScriptBacktrace]
	) -> void:
		# Avisos (`push_warning`) não reprovam a tela.
		if error_type == ERROR_TYPE_WARNING:
			return
		_mutex.lock()
		errors.append("%s (%s:%d %s) %s" % [code, file, line, function, rationale])
		_mutex.unlock()

	func _log_message(_message: String, _error: bool) -> void:
		pass


var _rules: RulesPack
var _clock: FakeClock
var _log: ErrorLog


func before() -> void:
	_rules = Fx.rules()


func before_test() -> void:
	_clock = FakeClock.new(Fx.T0)
	_log = ErrorLog.new()
	OS.add_logger(_log)


func after_test() -> void:
	OS.remove_logger(_log)
	_overlay().call("set_open", false)
	_service().setup(null, null, null, null, null)


func _service() -> Node:
	return Engine.get_main_loop().root.get_node("GameService")


func _overlay() -> Node:
	return Engine.get_main_loop().root.get_node("PerfOverlay")


func _setup(delay_ms: int = 0) -> void:
	var executor: CommandExecutor = LocalExecutor.new(_rules)
	if delay_ms > 0:
		executor = DelayedExecutor.new(executor, delay_ms)
	_service().setup(_rules, executor, _clock, Fx.game(_rules))


func test_each_screen_opens_without_errors() -> void:
	_setup()
	for path: String in SCREENS:
		var runner: GdUnitSceneRunner = scene_runner(path)
		await runner.simulate_frames(5)
		assert_object(runner.scene()).is_not_null()
	assert_array(_log.errors).is_empty()


func test_online_button_disabled() -> void:
	_setup()
	var runner: GdUnitSceneRunner = scene_runner("res://ui/menu.tscn")
	await runner.simulate_frames(2)
	var online: Button = runner.find_child("RodaOnline") as Button
	assert_object(online).is_not_null()
	assert_bool(online.disabled).is_true()
	assert_str(online.text).is_equal("Roda Online")
	var selo: Label = runner.find_child("EmBreve") as Label
	assert_str(selo.text).is_equal("Em breve")
	assert_bool(selo.is_visible_in_tree()).is_true()
	var solo: Button = runner.find_child("JornadaSolo") as Button
	assert_bool(solo.disabled).is_false()


func test_badge_shows_offline() -> void:
	_setup()
	var runner: GdUnitSceneRunner = scene_runner("res://ui/diagnostico.tscn")
	await runner.simulate_frames(2)
	var badge: Control = runner.find_child("ModeBadge") as Control
	assert_object(badge).is_not_null()
	assert_bool(badge.is_visible_in_tree()).is_true()
	var texto: Label = badge.find_child("Texto") as Label
	assert_str(texto.text).is_equal("Offline · Jornada Solo")


func test_buttons_disabled_while_busy() -> void:
	_setup(500)
	var runner: GdUnitSceneRunner = scene_runner("res://ui/diagnostico.tscn")
	await runner.simulate_frames(2)
	var names: Array[String] = ["TreinarForca", "MissaoRapida", "EnfrentarFase", "SalvarNome"]
	var buttons: Array[Button] = []
	for n: String in names:
		var b: Button = runner.find_child(n) as Button
		assert_object(b).override_failure_message("botão %s" % n).is_not_null()
		assert_bool(b.disabled).override_failure_message("%s livre" % n).is_false()
		buttons.append(b)
	var espera: Control = runner.find_child("Espera") as Control
	var vint_before: int = (_service().get_state() as GameState).vint
	(runner.find_child("TreinarForca") as Button).pressed.emit()
	await runner.simulate_frames(1)
	for b: Button in buttons:
		assert_bool(b.disabled).override_failure_message("%s ocupado" % b.name).is_true()
	# Antes de 300 ms o indicador não aparece; depois, sim.
	assert_bool(espera.visible).is_false()
	await get_tree().create_timer(0.4).timeout
	assert_bool(espera.visible).is_true()
	await runner.await_signal_on(_service(), "busy_changed", [false], 2000)
	await runner.simulate_frames(1)
	for b: Button in buttons:
		assert_bool(b.disabled).override_failure_message("%s depois" % b.name).is_false()
	assert_bool(espera.visible).is_false()
	assert_int((_service().get_state() as GameState).vint).is_less(vint_before)


func test_five_taps_toggle_overlay() -> void:
	_setup()
	var runner: GdUnitSceneRunner = scene_runner("res://ui/menu.tscn")
	await runner.simulate_frames(2)
	var versao: Button = runner.find_child("Versao") as Button
	assert_object(versao).is_not_null()
	assert_bool(_overlay().call("is_open")).is_false()
	for i: int in 4:
		versao.pressed.emit()
	assert_bool(_overlay().call("is_open")).is_false()
	versao.pressed.emit()
	assert_bool(_overlay().call("is_open")).is_true()
	await runner.simulate_frames(2)
	var texto: Label = _overlay().find_child("Texto", true, false) as Label
	assert_str(texto.text).contains("FPS")
	assert_str(texto.text).contains("offline")
	assert_str(texto.text).contains(_rules.rules_version)
	for i: int in 5:
		versao.pressed.emit()
	assert_bool(_overlay().call("is_open")).is_false()


func test_fight_lines_from_events() -> void:
	_setup()
	var runner: GdUnitSceneRunner = scene_runner("res://ui/luta_teste.tscn")
	await runner.simulate_frames(1)
	var events: Array[Dictionary] = [
		{
			"type": "luta",
			"contexto": "fase",
			"heroi": {"nome": "Jaci", "lvl": 1, "hp": 132},
			"inimigo": {"nome": "Saci Ligeiro", "lvl": 1, "hp": 100, "legend_id": "saci"},
		},
		{"type": "golpe", "atacante": 0, "dano": 16, "hp": [132, 84]},
		{"type": "critico", "atacante": 0, "dano": 34, "hp": [132, 50]},
		{"type": "esquiva", "atacante": 0, "dano": 0, "hp": [132, 50]},
		{"type": "fim", "vencedor": 0},
	]
	runner.set_property("line_interval_ms", 10)
	runner.invoke("play", events)
	await runner.await_func("is_playing").wait_until(2000).is_false()
	var linhas: Array[String] = []
	for child: Node in runner.find_child("Linhas").get_children():
		linhas.append((child as Label).text)
	assert_array(linhas).contains_exactly(EXPECTED_LINES)
	assert_str((runner.find_child("InimigoPV") as Label).text).is_equal("50 / 100 PV")


func test_enfrentar_fase_opens_fight_and_advances_label() -> void:
	_setup()
	var state: GameState = _service().get_state() as GameState
	Fx.strong(state)
	var runner: GdUnitSceneRunner = scene_runner("res://ui/diagnostico.tscn")
	await runner.simulate_frames(2)
	var fase: Button = runner.find_child("EnfrentarFase") as Button
	assert_str(fase.text).is_equal("Enfrentar fase 1")
	fase.pressed.emit()
	await runner.await_signal_on(_service(), "busy_changed", [false], 2000)
	await runner.simulate_frames(2)
	var luta: Node = runner.scene().find_child("LutaTeste", false, false)
	assert_object(luta).is_not_null()
	assert_int((_service().get_state() as GameState).fases[0]).is_equal(1)
	assert_str(fase.text).is_equal("Enfrentar fase 2")


func test_missao_rapida_runs_three_commands() -> void:
	_setup()
	var before: GameState = _service().get_state() as GameState
	Fx.strong(before)
	var runner: GdUnitSceneRunner = scene_runner("res://ui/diagnostico.tscn")
	await runner.simulate_frames(2)
	(runner.find_child("MissaoRapida") as Button).pressed.emit()
	await runner.await_func_on(self, "_missoes").wait_until(3000).is_equal(1)
	await runner.simulate_frames(2)
	var after: GameState = _service().get_state() as GameState
	assert_bool(after.ativa.is_empty()).is_true()
	assert_int(after.muir).is_less(before.muir)
	assert_str((runner.find_child("Mensagem") as Label).text).starts_with("Missão concluída!")
	assert_bool((runner.find_child("MissaoRapida") as Button).disabled).is_false()


func _missoes() -> int:
	return (_service().get_state() as GameState).missoes


func test_error_code_is_translated() -> void:
	_setup()
	var state: GameState = _service().get_state() as GameState
	state.vint = 0
	var runner: GdUnitSceneRunner = scene_runner("res://ui/diagnostico.tscn")
	await runner.simulate_frames(2)
	(runner.find_child("TreinarForca") as Button).pressed.emit()
	await runner.await_signal_on(_service(), "busy_changed", [false], 2000)
	await runner.simulate_frames(2)
	var msg: Label = runner.find_child("Mensagem") as Label
	assert_str(msg.text).is_equal(Textos.erro("VINTENS_INSUFICIENTES"))
	assert_str(msg.text).not_contains("VINTENS_INSUFICIENTES")


func test_save_warning_is_shown() -> void:
	_setup()
	var runner: GdUnitSceneRunner = scene_runner("res://ui/diagnostico.tscn")
	await runner.simulate_frames(1)
	_service().emit_signal("warning", "SAVE_FALHOU")
	await runner.simulate_frames(1)
	var avisos: Node = runner.find_child("Avisos")
	assert_int(avisos.get_child_count()).is_equal(1)
	var rotulo: Label = avisos.get_child(0).get_child(0) as Label
	assert_str(rotulo.text).is_equal(Textos.aviso("SAVE_FALHOU"))
