extends GdUnitTestSuite
## Editor do visual (Mais → Guardião) e o mesmo visual no topo e no treino.

var _rules: RulesPack


func before() -> void:
	_rules = Fx.rules()


func after_test() -> void:
	_service().setup(null, null, null, null, null)


func _service() -> Node:
	return Engine.get_main_loop().root.get_node("GameService")


func _setup() -> GameState:
	var state: GameState = Fx.game(_rules)
	state.origem = "pampa"
	_service().setup(_rules, LocalExecutor.new(_rules), FakeClock.new(Fx.T0), state)
	return state


func test_editor_troca_dando_a_volta() -> void:
	var ed: EditorVisual = auto_free(EditorVisual.new())
	ed.definir({"barba": 3})
	ed.trocar("barba", 1)
	assert_int(int(ed.visual()["barba"])).is_equal(0)
	ed.trocar("barba", -1)
	assert_int(int(ed.visual()["barba"])).is_equal(3)
	assert_str((ed.find_child("Valor_barba", true, false) as Label).text).is_equal("Bigode")
	assert_dict(ed.previa().visual()).is_equal(ed.visual())


func test_sortear_da_um_visual_valido() -> void:
	var ed: EditorVisual = auto_free(EditorVisual.new())
	ed.sortear_visual()
	assert_dict(VisualRules.sanitize(ed.visual())).is_equal(ed.visual())


func test_salvar_manda_mudar_visual() -> void:
	_setup()
	var runner: GdUnitSceneRunner = scene_runner("res://ui/abas/visual.tscn")
	await runner.simulate_frames(2)
	var salvar: Button = runner.find_child("SalvarVisual") as Button
	assert_bool(salvar.disabled).is_true()
	(runner.find_child("Mais_barba") as Button).pressed.emit()
	assert_bool(salvar.disabled).is_false()
	salvar.pressed.emit()
	await runner.simulate_frames(4)
	var s: GameState = _service().call("get_state")
	assert_int(int(s.visual["barba"])).is_equal(1)
	assert_bool(salvar.disabled).is_true()


func test_mais_tem_o_guardiao() -> void:
	_setup()
	var runner: GdUnitSceneRunner = scene_runner("res://ui/abas/mais.tscn")
	await runner.simulate_frames(2)
	assert_object(runner.find_child("AbrirGuardiao")).is_not_null()
	runner.scene().call("abrir", "Guardiao")
	await runner.simulate_frames(2)
	assert_object(runner.find_child("EditorVisual")).is_not_null()


func test_treino_e_mochila_mostram_o_visual_salvo() -> void:
	var state: GameState = _setup()
	state.visual["cabelo"] = 4
	var treino: PainelTreino = auto_free(PainelTreino.new())
	add_child(treino)
	var g: Guardiao = treino.find_child("GuardiaoTreino", true, false)
	assert_int(int(g.visual()["cabelo"])).is_equal(4)
	treino.queue_free()


func test_topo_mostra_o_rosto() -> void:
	var state: GameState = _setup()
	var topo: Topo = auto_free(Topo.new())
	add_child(topo)
	var b: Button = topo.find_child("Heroi", true, false)
	assert_object(b.icon).is_same(GuardiaoRosto.textura(state.visual))
	topo.queue_free()
