extends GdUnitTestSuite
## Fumaça do Bestiário e das cartas.

const CENA: String = "res://ui/abas/bestiario.tscn"

var _rules: RulesPack
var _log: MotorErros


func before() -> void:
	_rules = Fx.rules()


func before_test() -> void:
	_log = MotorErros.new()
	OS.add_logger(_log)


func after_test() -> void:
	OS.remove_logger(_log)
	_service().setup(null, null, null, null, null)


func _service() -> Node:
	return Engine.get_main_loop().root.get_node("GameService")


func _setup() -> GameState:
	var state: GameState = Fx.game(_rules)
	_service().setup(_rules, LocalExecutor.new(_rules), FakeClock.new(Fx.T0), state)
	return state


func test_oito_lendas_listadas() -> void:
	_setup()
	var runner: GdUnitSceneRunner = scene_runner(CENA)
	await runner.simulate_frames(3)
	for id: String in _rules.legends:
		assert_object(runner.find_child("Lenda_" + id)).is_not_null()


func test_desconhecida_sem_vistos() -> void:
	var state: GameState = _setup()
	state.vistos = {"saci": true}
	var runner: GdUnitSceneRunner = scene_runner(CENA)
	await runner.simulate_frames(3)
	assert_str((runner.find_child("LendaNome_saci") as Label).text).is_equal("Saci-Pererê")
	assert_str((runner.find_child("LendaNome_cuca") as Label).text).is_equal("Lenda desconhecida")


func test_carta_carrega_textura() -> void:
	assert_object(CartaLib.textura("saci")).is_not_null()


func test_lenda_sem_carta_nao_da_erro() -> void:
	assert_object(CartaLib.textura("mula_sem_cabeca")).is_null()
	assert_object(CartaLib.textura("")).is_null()
	assert_array(_log.errors).is_empty()
