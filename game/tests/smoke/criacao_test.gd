extends GdUnitTestSuite
## Criação do guardião e o ponto de controle no menu.

var _rules: RulesPack


func before() -> void:
	_rules = Fx.rules()


func after_test() -> void:
	_service().setup(null, null, null, null, null)


func _service() -> Node:
	return Engine.get_main_loop().root.get_node("GameService")


func _setup(origem: String = "") -> GameState:
	var state: GameState = Fx.game(_rules)
	state.origem = origem
	_service().setup(_rules, LocalExecutor.new(_rules), FakeClock.new(Fx.T0), state)
	return state


func test_perfil_novo_abre_criacao() -> void:
	_setup("")
	var runner: GdUnitSceneRunner = scene_runner("res://ui/menu.tscn")
	await runner.simulate_frames(2)
	assert_str(str(runner.scene().call("destino_solo"))).is_equal("res://ui/criacao.tscn")


func test_perfil_legado_abre_jogo() -> void:
	_setup("legado")
	var runner: GdUnitSceneRunner = scene_runner("res://ui/menu.tscn")
	await runner.simulate_frames(2)
	assert_str(str(runner.scene().call("destino_solo"))).is_equal("res://ui/jogo.tscn")


func test_criacao_quatro_origens_com_bonus_visivel() -> void:
	_setup()
	var runner: GdUnitSceneRunner = scene_runner("res://ui/criacao.tscn")
	await runner.simulate_frames(2)
	for id: String in ["mata_atlantica", "sertao", "amazonia", "pampa"]:
		var b: Button = runner.find_child("Origem_" + id) as Button
		assert_object(b).is_not_null()
		assert_str(b.text).contains("+2")
	assert_str((runner.find_child("Origem_sertao") as Button).text).contains("Fôlego")


func test_criar_abre_jogo() -> void:
	_setup()
	var runner: GdUnitSceneRunner = scene_runner("res://ui/criacao.tscn")
	await runner.simulate_frames(2)
	var abertas: Array[String] = []
	runner.scene().set("abrir_cena", func(p: String) -> void: abertas.append(p))
	(runner.find_child("NomeGuardiao") as LineEdit).text = "Iracema"
	(runner.find_child("Origem_pampa") as Button).pressed.emit()
	(runner.find_child("Criar") as Button).pressed.emit()
	await runner.simulate_frames(4)
	var s: GameState = _service().call("get_state")
	assert_str(s.origem).is_equal("pampa")
	assert_str(s.nome).is_equal("Iracema")
	assert_array(abertas).is_equal(["res://ui/jogo.tscn"])


func test_criar_sem_origem_nao_envia() -> void:
	_setup()
	var runner: GdUnitSceneRunner = scene_runner("res://ui/criacao.tscn")
	await runner.simulate_frames(2)
	assert_bool((runner.find_child("Criar") as Button).disabled).is_true()


func test_erro_mostra_toast() -> void:
	var state: GameState = _setup()
	var runner: GdUnitSceneRunner = scene_runner("res://ui/criacao.tscn")
	await runner.simulate_frames(2)
	runner.scene().set("abrir_cena", func(_p: String) -> void: pass)
	state.origem = "sertao"
	(runner.find_child("Origem_pampa") as Button).pressed.emit()
	(runner.find_child("Criar") as Button).pressed.emit()
	await runner.simulate_frames(4)
	assert_str((runner.find_child("ToastTexto") as Label).text).is_equal(Textos.erro("JA_CRIADO"))


func test_criar_grava_o_visual_escolhido() -> void:
	_setup()
	var runner: GdUnitSceneRunner = scene_runner("res://ui/criacao.tscn")
	await runner.simulate_frames(2)
	runner.scene().set("abrir_cena", func(_p: String) -> void: pass)
	var cabelo: int = int(VisualRules.PADRAO["cabelo"])
	(runner.find_child("Mais_cabelo") as Button).pressed.emit()
	(runner.find_child("Menos_pele") as Button).pressed.emit()
	(runner.find_child("Origem_pampa") as Button).pressed.emit()
	(runner.find_child("Criar") as Button).pressed.emit()
	await runner.simulate_frames(4)
	var s: GameState = _service().call("get_state")
	assert_int(int(s.visual["cabelo"])).is_equal(cabelo + 1)
	assert_int(int(s.visual["pele"])).is_equal(int(VisualRules.PADRAO["pele"]) - 1)
