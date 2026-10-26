extends GdUnitTestSuite
## VisualRules (saneamento do visual) e o comando `mudar_visual`.

var _rules: RulesPack


func before() -> void:
	_rules = Fx.rules()


func test_sanitize_completa_com_o_padrao() -> void:
	var v: Dictionary = VisualRules.sanitize({"cabelo": 4})
	assert_int(int(v["cabelo"])).is_equal(4)
	assert_int(int(v["pele"])).is_equal(int(VisualRules.PADRAO["pele"]))
	assert_array(v.keys()).contains_exactly_in_any_order(VisualRules.BLOCOS.keys())


func test_sanitize_descarta_lixo() -> void:
	var v: Dictionary = VisualRules.sanitize({"pele": 99, "barba": -1, "boca": "x", "asa": 2})
	assert_int(int(v["pele"])).is_equal(0)
	assert_int(int(v["barba"])).is_equal(0)
	assert_int(int(v["boca"])).is_equal(0)
	assert_bool(v.has("asa")).is_false()
	assert_dict(VisualRules.sanitize("nada")).is_equal(VisualRules.PADRAO)


func test_numero_do_json_vira_inteiro() -> void:
	assert_int(int(VisualRules.sanitize({"cabelo": 2.0})["cabelo"])).is_equal(2)


func test_blocos_batem_com_as_opcoes_da_ui() -> void:
	assert_array(GuardiaoRosto.OPCOES.keys()).contains_exactly(VisualRules.BLOCOS.keys())
	for bloco: String in VisualRules.BLOCOS:
		var n: int = GuardiaoRosto.OPCOES[bloco].size()
		assert_int(n).override_failure_message(bloco).is_equal(VisualRules.BLOCOS[bloco])


func test_mudar_visual_grava_saneado_e_de_graca() -> void:
	var s: GameState = Fx.game(_rules)
	var res: CommandResult = Fx.run(s, "mudar_visual", {"visual": {"barba": 2, "pele": 50}}, _rules)
	assert_bool(res.ok).is_true()
	assert_int(int(res.state.visual["barba"])).is_equal(2)
	assert_int(int(res.state.visual["pele"])).is_equal(0)
	assert_int(res.state.vint).is_equal(s.vint)
	assert_int(res.state.muir).is_equal(s.muir)


func test_criar_guardiao_grava_o_visual() -> void:
	var s: GameState = Fx.game(_rules)
	var params: Dictionary = {"nome": "Jaci", "origem": "pampa", "visual": {"cabelo": 2}}
	var res: CommandResult = Fx.run(s, "criar_guardiao", params, _rules)
	assert_bool(res.ok).is_true()
	assert_int(int(res.state.visual["cabelo"])).is_equal(2)


func test_criar_sem_visual_fica_no_padrao() -> void:
	var s: GameState = Fx.game(_rules)
	var res: CommandResult = Fx.run(s, "criar_guardiao", {"nome": "Jaci", "origem": "pampa"}, _rules)
	assert_dict(res.state.visual).is_equal(VisualRules.PADRAO)
