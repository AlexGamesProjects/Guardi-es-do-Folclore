extends GdUnitTestSuite
## Fumaça da aba Arena.

const CENA: String = "res://ui/abas/arena.tscn"

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


func test_lista_rivais() -> void:
	var state: GameState = _setup()
	var runner: GdUnitSceneRunner = await _abrir()
	for i: int in state.rivais.size():
		assert_object(runner.find_child("Desafiar_%d" % i)).is_not_null()
	assert_int(state.rivais.size()).is_greater(0)


func test_desafiar_envia_rival_id_e_gasta_coragem() -> void:
	var state: GameState = _setup()
	var antes: int = state.coragem
	var runner: GdUnitSceneRunner = await _abrir()
	(runner.find_child("Desafiar_0") as Button).pressed.emit()
	await runner.simulate_frames(4)
	var depois: GameState = _service().call("get_state")
	assert_int(depois.coragem).is_equal(antes - 1)
	assert_int(depois.duelos.size()).is_equal(1)


func test_sem_coragem_mostra_toast_arena() -> void:
	var state: GameState = _setup()
	state.coragem = 0
	state.co_upd_ms = Fx.T0
	var runner: GdUnitSceneRunner = await _abrir()
	var toast := Toast.new()
	runner.scene().add_child(toast)
	(runner.find_child("Desafiar_0") as Button).pressed.emit()
	await runner.simulate_frames(4)
	var texto: Label = runner.find_child("ToastTexto") as Label
	assert_str(texto.text).is_equal(Textos.erro("CORAGEM_INSUFICIENTE", "arena"))


func test_historico_ultimos_duelos() -> void:
	var state: GameState = _setup()
	state.duelos = [{"nome": "Tião do Brejo", "win": true, "honra": 12}]
	var runner: GdUnitSceneRunner = await _abrir()
	var hist: Label = runner.find_child("Historico") as Label
	assert_str(hist.text).contains("Tião do Brejo")
	assert_str(hist.text).contains("+12")
