extends GdUnitTestSuite
## Fumaça da aba Torre dos Chefes.

const CENA: String = "res://ui/abas/torre.tscn"

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


func test_tres_atos_dez_fases() -> void:
	_setup()
	var runner: GdUnitSceneRunner = await _abrir()
	for a: int in 3:
		assert_object(runner.find_child("Ato_%d" % a)).is_not_null()
		for n: int in 10:
			assert_object(runner.find_child("Fase_%d_%d" % [a, n])).is_not_null()


func test_so_a_proxima_fase_liberada_fica_ativa() -> void:
	_setup()
	var runner: GdUnitSceneRunner = await _abrir()
	assert_bool((runner.find_child("Fase_0_0") as Button).disabled).is_false()
	assert_bool((runner.find_child("Fase_0_1") as Button).disabled).is_true()


func test_fase_bloqueada_por_nivel_desativada() -> void:
	_setup()
	var runner: GdUnitSceneRunner = await _abrir()
	var fase: Button = runner.find_child("Fase_1_0") as Button
	assert_bool(fase.disabled).is_true()
	assert_str(fase.text).contains("Nível %d" % Stages.required_level(1, 0, _rules))


func test_enfrentar_envia_act_e_n() -> void:
	var state: GameState = _setup()
	Fx.strong(state)
	var runner: GdUnitSceneRunner = await _abrir()
	(runner.find_child("Fase_0_0") as Button).pressed.emit()
	await runner.simulate_frames(4)
	var depois: GameState = _service().call("get_state")
	assert_int(depois.fases[0]).is_equal(1)


func test_chefe_em_espera_mostra_tempo() -> void:
	var state: GameState = _setup()
	state.chefe_espera_ms = Fx.T0 + 65_000
	var runner: GdUnitSceneRunner = await _abrir()
	var espera: Label = runner.find_child("Espera") as Label
	assert_bool(espera.visible).is_true()
	assert_str(espera.text).contains(Textos.relogio(65_000))
