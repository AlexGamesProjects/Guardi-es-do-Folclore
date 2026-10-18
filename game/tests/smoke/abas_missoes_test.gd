extends GdUnitTestSuite
## Fumaça da aba Missões.

const CENA: String = "res://ui/abas/missoes.tscn"

var _rules: RulesPack
var _clock: FakeClock


func before() -> void:
	_rules = Fx.rules()


func before_test() -> void:
	_clock = FakeClock.new(Fx.T0)


func after_test() -> void:
	_service().setup(null, null, null, null, null)


func _service() -> Node:
	return Engine.get_main_loop().root.get_node("GameService")


func _setup() -> GameState:
	var state: GameState = Fx.game(_rules)
	_service().setup(_rules, LocalExecutor.new(_rules), _clock, state)
	return state


func _abrir() -> GdUnitSceneRunner:
	var runner: GdUnitSceneRunner = scene_runner(CENA)
	await runner.simulate_frames(3)
	return runner


func _estado() -> GameState:
	return _service().call("get_state")


func test_mostra_tres_ofertas() -> void:
	_setup()
	var runner: GdUnitSceneRunner = await _abrir()
	for i: int in 3:
		assert_object(runner.find_child("Iniciar_%d" % i)).is_not_null()


func test_iniciar_envia_mission_id() -> void:
	var state: GameState = _setup()
	var id: int = int(state.ofertas[1]["id"])
	var runner: GdUnitSceneRunner = await _abrir()
	(runner.find_child("Iniciar_1") as Button).pressed.emit()
	await runner.simulate_frames(4)
	assert_int(int(_estado().ativa["id"])).is_equal(id)


func test_missao_ativa_mostra_tempo_restante() -> void:
	var state: GameState = _setup()
	var runner: GdUnitSceneRunner = await _abrir()
	(runner.find_child("Iniciar_0") as Button).pressed.emit()
	await runner.simulate_frames(4)
	var dur_ms: int = int(state.ofertas[0]["dur"]) * 1000
	var tempo: Label = runner.find_child("TempoRestante") as Label
	assert_str(tempo.text).contains(Textos.relogio(dur_ms))
	assert_bool((runner.find_child("Concluir") as Button).visible).is_false()


func test_concluir_quando_termina() -> void:
	_setup()
	var runner: GdUnitSceneRunner = await _abrir()
	(runner.find_child("Iniciar_0") as Button).pressed.emit()
	await runner.simulate_frames(4)
	_clock.advance(100_000)
	await runner.simulate_frames(12, 150)
	var concluir: Button = runner.find_child("Concluir") as Button
	assert_bool(concluir.visible).is_true()
	concluir.pressed.emit()
	await runner.simulate_frames(4)
	assert_bool(_estado().ativa.is_empty()).is_true()


func test_acelerar_sem_muiraquita_mostra_toast_missao() -> void:
	var state: GameState = _setup()
	state.muir = 0
	var runner: GdUnitSceneRunner = await _abrir()
	var toast := Toast.new()
	runner.scene().add_child(toast)
	(runner.find_child("Iniciar_0") as Button).pressed.emit()
	await runner.simulate_frames(4)
	(runner.find_child("Acelerar") as Button).pressed.emit()
	await runner.simulate_frames(4)
	var texto: Label = runner.find_child("ToastTexto") as Label
	assert_str(texto.text).is_equal(Textos.erro("MUIRAQUITAS_INSUFICIENTES", "missao"))


func test_renovar_envia_comando() -> void:
	var state: GameState = _setup()
	state.muir = 5
	var antes: Array = state.ofertas.map(func(m: Dictionary) -> int: return int(m["id"]))
	var runner: GdUnitSceneRunner = await _abrir()
	(runner.find_child("Renovar") as Button).pressed.emit()
	await runner.simulate_frames(4)
	var depois: Array = _estado().ofertas.map(func(m: Dictionary) -> int: return int(m["id"]))
	assert_array(depois).is_not_equal(antes)
