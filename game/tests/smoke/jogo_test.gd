extends GdUnitTestSuite
## Fumaça da casca do jogo: abas, topo, avisos (Toast) e treino.

const JOGO: String = "res://ui/jogo.tscn"

var _rules: RulesPack
var _clock: FakeClock
var _log: MotorErros


func before() -> void:
	_rules = Fx.rules()


func before_test() -> void:
	_clock = FakeClock.new(Fx.T0)
	_log = MotorErros.new()
	OS.add_logger(_log)


func after_test() -> void:
	OS.remove_logger(_log)
	_service().setup(null, null, null, null, null)


func _service() -> Node:
	return Engine.get_main_loop().root.get_node("GameService")


func _setup(delay_ms: int = 0) -> GameState:
	var executor: CommandExecutor = LocalExecutor.new(_rules)
	if delay_ms > 0:
		executor = DelayedExecutor.new(executor, delay_ms)
	var state: GameState = Fx.game(_rules)
	_service().setup(_rules, executor, _clock, state)
	return state


func _abrir() -> GdUnitSceneRunner:
	var runner: GdUnitSceneRunner = scene_runner(JOGO)
	await runner.simulate_frames(3)
	return runner


func test_abre_na_aba_missoes() -> void:
	_setup()
	var runner: GdUnitSceneRunner = await _abrir()
	assert_str(str(runner.scene().get("aba_atual"))).is_equal("missoes")
	assert_array(_log.errors).is_empty()


func test_cinco_abas_trocam_sem_erro() -> void:
	_setup()
	var runner: GdUnitSceneRunner = await _abrir()
	for id: String in ["torre", "arena", "feira", "mais", "missoes"]:
		var botao: Button = runner.find_child("Aba_" + id) as Button
		assert_object(botao).is_not_null()
		botao.pressed.emit()
		await runner.simulate_frames(2)
		assert_str(str(runner.scene().get("aba_atual"))).is_equal(id)
	assert_array(_log.errors).is_empty()


func test_topo_mostra_energia_de_stamina_view() -> void:
	var state: GameState = _setup()
	state.energia = 40
	state.en_upd_ms = Fx.T0
	var runner: GdUnitSceneRunner = await _abrir()
	var view: Dictionary = _service().call("stamina_view")
	var rotulo: Label = runner.find_child("EnergiaValor") as Label
	assert_str(rotulo.text).is_equal("%d/%d" % [int(view["energia"]), int(view["en_max"])])


func test_topo_cabe_nome_longo_e_numeros_grandes() -> void:
	var state: GameState = _setup()
	state.nome = "Guardiã Jacirandaí"
	state.vint = 999999
	state.muir = 99999
	var runner: GdUnitSceneRunner = await _abrir()
	var topo: Control = runner.find_child("Topo") as Control
	assert_float(topo.get_combined_minimum_size().x).is_less_equal(720.0)
	var nome: Label = runner.find_child("NomeHeroi") as Label
	assert_str(nome.text).is_equal("Guardiã Jacirandaí")


func test_troca_de_aba_durante_busy_nao_perde_toast() -> void:
	var state: GameState = _setup(300)
	state.vint = 0
	var runner: GdUnitSceneRunner = await _abrir()
	(runner.find_child("Heroi") as Button).pressed.emit()
	await runner.simulate_frames(2)
	(runner.find_child("Treinar_for") as Button).pressed.emit()
	await runner.simulate_frames(1)
	(runner.find_child("Aba_feira") as Button).pressed.emit()
	await await_signal_on(_service(), "busy_changed", [false], 2000)
	await runner.simulate_frames(2)
	var toast: Label = runner.find_child("ToastTexto") as Label
	assert_bool(toast.is_visible_in_tree()).is_true()
	assert_str(toast.text).is_equal(Textos.erro("VINTENS_INSUFICIENTES", "treino"))


func test_treino_manda_treinar_com_atributo() -> void:
	var state: GameState = _setup()
	state.vint = 10000
	var antes: int = state.stats["fol"]
	var runner: GdUnitSceneRunner = await _abrir()
	(runner.find_child("Heroi") as Button).pressed.emit()
	await runner.simulate_frames(2)
	(runner.find_child("Treinar_fol") as Button).pressed.emit()
	await runner.simulate_frames(5)
	var depois: GameState = _service().call("get_state")
	assert_int(depois.stats["fol"]).is_equal(antes + 1)


func test_textos_erro_por_contexto() -> void:
	var feira: String = Textos.erro("VINTENS_INSUFICIENTES", "feira")
	var treino: String = Textos.erro("VINTENS_INSUFICIENTES", "treino")
	assert_str(feira).is_not_equal(treino)
	assert_str(feira).contains("compra")
	assert_str(Textos.erro("NAO_ENCONTRADO", "mochila")).contains("item")
