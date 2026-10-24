extends GdUnitTestSuite
## Fumaça da Feira, da Mochila e do menu Mais (com Ajustes).

var _rules: RulesPack
var _clock: FakeClock


func before() -> void:
	_rules = Fx.rules()


func before_test() -> void:
	_clock = FakeClock.new(Fx.T0)


func after_test() -> void:
	_service().setup(null, null, null, null, null)
	Ajustes.definir_velocidade(1)


func _service() -> Node:
	return Engine.get_main_loop().root.get_node("GameService")


func _setup() -> GameState:
	var state: GameState = Fx.game(_rules)
	_service().setup(_rules, LocalExecutor.new(_rules), _clock, state)
	return state


func _abrir(cena: String) -> GdUnitSceneRunner:
	var runner: GdUnitSceneRunner = scene_runner(cena)
	await runner.simulate_frames(3)
	return runner


func _estado() -> GameState:
	return _service().call("get_state")


func test_feira_lista_itens_com_raridade() -> void:
	var state: GameState = _setup()
	var runner: GdUnitSceneRunner = await _abrir("res://ui/abas/feira.tscn")
	var item: Dictionary = state.feira[0]
	var nome: Label = runner.find_child("ItemNome_%d" % int(item["id"])) as Label
	assert_str(nome.text).contains(str(item["nome"]))
	var rar: Label = runner.find_child("ItemRaridade_%d" % int(item["id"])) as Label
	assert_str(rar.text).is_equal(_rules.rarities[int(item["rar"])].nome)


func test_comprar_envia_item_id() -> void:
	var state: GameState = _setup()
	state.vint = 100000
	var id: int = int(state.feira[0]["id"])
	var runner: GdUnitSceneRunner = await _abrir("res://ui/abas/feira.tscn")
	(runner.find_child("Comprar_%d" % id) as Button).pressed.emit()
	await runner.simulate_frames(4)
	var na_mochila: bool = _estado().mochila.any(
		func(i: Dictionary) -> bool: return int(i["id"]) == id
	)
	var equipado: bool = _estado().equip.values().any(
		func(v: Variant) -> bool: return v is Dictionary and int((v as Dictionary)["id"]) == id
	)
	assert_bool(na_mochila or equipado).is_true()


func test_sem_vintens_toast_feira() -> void:
	var state: GameState = _setup()
	state.vint = 0
	var id: int = int(state.feira[0]["id"])
	var runner: GdUnitSceneRunner = await _abrir("res://ui/abas/feira.tscn")
	var toast := Toast.new()
	runner.scene().add_child(toast)
	(runner.find_child("Comprar_%d" % id) as Button).pressed.emit()
	await runner.simulate_frames(4)
	var texto: Label = runner.find_child("ToastTexto") as Label
	assert_str(texto.text).is_equal(Textos.erro("VINTENS_INSUFICIENTES", "feira"))


func test_mochila_equipar_e_vender_enviam_item_id() -> void:
	var state: GameState = _setup()
	Fx.fill_bag(state, _rules)
	var a: int = int(state.mochila[0]["id"])
	var b: int = int(state.mochila[1]["id"])
	var runner: GdUnitSceneRunner = await _abrir("res://ui/abas/mochila.tscn")
	(runner.find_child("Equipar_%d" % a) as Button).pressed.emit()
	await runner.simulate_frames(4)
	(runner.find_child("Vender_%d" % b) as Button).pressed.emit()
	await runner.simulate_frames(4)
	var ids: Array = _estado().mochila.map(func(i: Dictionary) -> int: return int(i["id"]))
	assert_bool(ids.has(a)).is_false()
	assert_bool(ids.has(b)).is_false()


func test_comparacao_mostra_sinais() -> void:
	var linha := ItemLinha.new()
	add_child(linha)
	linha.mostrar(
		{"id": 1, "nome": "Gorro", "rar": 0, "st": {"for": 3, "gin": 1}, "slot": "cabeca"},
		{"id": 2, "nome": "Chapéu", "rar": 0, "st": {"for": 1, "gin": 2}, "slot": "cabeca"},
		_rules
	)
	var dif: Label = linha.find_child("ItemDiferenca_1", true, false) as Label
	assert_str(dif.text).contains("+2 Força")
	assert_str(dif.text).contains("−1 Ginga")
	linha.queue_free()


func test_ajustes_guarda_velocidade() -> void:
	_setup()
	var runner: GdUnitSceneRunner = await _abrir("res://ui/abas/mais.tscn")
	(runner.find_child("AbrirAjustes") as Button).pressed.emit()
	await runner.simulate_frames(2)
	(runner.find_child("Velocidade_2") as Button).pressed.emit()
	assert_int(Ajustes.velocidade()).is_equal(2)


func test_mais_abre_mochila_e_volta() -> void:
	_setup()
	var runner: GdUnitSceneRunner = await _abrir("res://ui/abas/mais.tscn")
	(runner.find_child("AbrirMochila") as Button).pressed.emit()
	await runner.simulate_frames(2)
	assert_bool((runner.find_child("AbaMochila") as Control).is_visible_in_tree()).is_true()
	(runner.find_child("Voltar") as Button).pressed.emit()
	await runner.simulate_frames(2)
	assert_bool((runner.find_child("AbrirMochila") as Control).is_visible_in_tree()).is_true()


func test_mochila_mostra_boneco_vestido() -> void:
	var state: GameState = _setup()
	state.equip["cabeca"] = {
		"id": 77, "nome": "Gorro Vermelho", "slot": "cabeca", "rar": 0, "st": {}
	}
	var runner: GdUnitSceneRunner = await _abrir("res://ui/abas/mochila.tscn")
	var b: Boneco = runner.find_child("BonecoMochila") as Boneco
	assert_object(b).is_not_null()
	assert_str(b.peca("cabeca").texture.resource_path).ends_with("gorro_vermelho.png")
