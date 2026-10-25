extends GdUnitTestSuite
## HeroiVisual escolhe o desenho de cada item pelo nome-base (sem o epíteto).

var _rules: RulesPack


func before() -> void:
	_rules = Fx.rules()


func test_visual_pelo_nome_base_com_epiteto() -> void:
	var item: Dictionary = {"nome": "Chapéu de Couro da Serra", "slot": "cabeca", "rar": 0}
	assert_str(HeroiVisual.para_item(item, _rules)).is_equal("chapeu_couro")


func test_visual_sem_epiteto() -> void:
	assert_str(HeroiVisual.para_item({"nome": "Facão", "slot": "arma"}, _rules)).is_equal("facao")


func test_item_sem_visual_devolve_vazio() -> void:
	assert_str(HeroiVisual.para_item({"nome": "Espada Laser", "slot": "arma"}, _rules)).is_equal("")
	assert_str(HeroiVisual.para_item({}, _rules)).is_equal("")


func test_todo_nome_base_tem_visual_e_arquivo() -> void:
	for slot: String in _rules.item_names:
		for nome: String in _rules.item_names[slot]:
			var visual: String = HeroiVisual.para_item({"nome": nome, "slot": slot}, _rules)
			assert_str(visual).is_not_empty()
			if slot == "corpo":
				# Roupa é troca de cor no corpo do guardião.
				var tem: bool = Guardiao.ROUPA_ITEM.has(visual)
				assert_bool(tem).override_failure_message(visual).is_true()
			else:
				var arquivo: String = "res://assets/heroi/itens/%s.png" % visual
				var ok: bool = ResourceLoader.exists(arquivo)
				assert_bool(ok).override_failure_message(arquivo).is_true()
