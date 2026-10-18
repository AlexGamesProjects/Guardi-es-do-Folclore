extends GdUnitTestSuite

const BASE: String = "res://data/packs/base"
const FIXTURES: String = "res://tests/fixtures/packs"


func _load_base() -> RulesPack:
	var result: RulesLoadResult = RulesLoader.load_dir(BASE)
	assert_array(result.errors).is_empty()
	assert_bool(result.ok).is_true()
	return result.pack


func test_base_pack_loads_ok() -> void:
	var result: RulesLoadResult = RulesLoader.load_dir(BASE)
	assert_bool(result.ok).is_true()
	assert_array(result.errors).is_empty()
	assert_object(result.pack).is_not_null()
	assert_int(result.pack.schema_version).is_equal(1)
	assert_str(result.pack.rules_version).is_equal("1.0.0")


func test_base_counts() -> void:
	var pack: RulesPack = _load_base()
	assert_int(pack.legends.size()).is_equal(8)
	assert_int(pack.acts.size()).is_equal(3)
	for act: Defs.ActDef in pack.acts:
		assert_int(act.stages.size()).is_equal(10)
	assert_int(pack.balance.curva.size()).is_equal(31)
	assert_int(pack.balance.xp_table.size()).is_equal(41)
	assert_int(pack.balance.train_cost.size()).is_equal(201)
	assert_int(pack.rarities.size()).is_equal(3)
	assert_int(pack.rival_first.size()).is_equal(16)
	assert_int(pack.rival_last.size()).is_equal(10)
	assert_int(pack.epithets.size()).is_equal(9)
	assert_int(pack.balance.ranks.size()).is_equal(7)


func test_sampled_values_match_v02() -> void:
	var pack: RulesPack = _load_base()
	var b: Defs.BalanceDef = pack.balance
	assert_int(b.en_max).is_equal(100)
	assert_int(b.en_ms).is_equal(30000)
	assert_int(b.co_max).is_equal(5)
	assert_int(b.co_ms).is_equal(120000)
	assert_int(b.feira_ms).is_equal(600000)
	assert_int(b.mochila).is_equal(14)
	assert_int(b.chefe_en).is_equal(12)
	assert_int(b.chefe_espera_ms).is_equal(90000)
	assert_int(b.curva[0]).is_equal(12)
	assert_int(b.curva[30]).is_equal(65)
	assert_int(b.xp_table[1]).is_equal(60)
	assert_int(b.xp_table[2]).is_equal(164)
	assert_int(b.train_cost[6]).is_equal(8)
	assert_int(b.train_cost[1]).is_equal(5)
	assert_dict(b.mission).contains_key_value("luta_pm", 1300)
	assert_dict(b.stage).contains_key_value("boss_pm", 1120)
	var saci: Defs.LegendDef = pack.legends["saci"]
	assert_int(saci.perf_pm["gin"]).is_equal(1200)
	assert_int(saci.lvl).is_equal(1)
	assert_str(pack.legends["mapinguari"].nome).is_equal("Mapinguari")
	assert_int(pack.legends["mapinguari"].perf_pm["fol"]).is_equal(1250)
	assert_int(pack.rarities[2].mult_pm).is_equal(2200)
	assert_str(pack.acts[1].stages[9].nome).is_equal("Boitatá, a Cobra de Fogo")
	assert_str(pack.acts[2].stages[9].legend_id).is_equal("mapinguari")


func test_negrinho_is_ally_and_never_in_stages() -> void:
	var pack: RulesPack = _load_base()
	assert_bool(pack.legends.has("negrinho")).is_true()
	assert_bool(pack.legends["negrinho"].ally).is_true()
	assert_int(pack.legends["negrinho"].lutas.size()).is_equal(0)
	for act: Defs.ActDef in pack.acts:
		for stage: Defs.StageDef in act.stages:
			assert_str(stage.legend_id).is_not_equal("negrinho")
			assert_bool(pack.legends[stage.legend_id].ally).is_false()


func test_every_stage_legend_exists_and_unlocked_by_act_end() -> void:
	var pack: RulesPack = _load_base()
	for act: Defs.ActDef in pack.acts:
		assert_bool(pack.legends.has(act.capa)).is_true()
		for stage: Defs.StageDef in act.stages:
			assert_bool(pack.legends.has(stage.legend_id)).is_true()
			assert_bool(pack.legends[stage.legend_id].lvl <= act.ate).is_true()


func test_values_in_range() -> void:
	var pack: RulesPack = _load_base()
	for id: String in pack.legends:
		var legend: Defs.LegendDef = pack.legends[id]
		if legend.ally:
			continue
		assert_int(legend.perf_pm.size()).is_equal(4)
		for stat: String in legend.perf_pm:
			var v: int = legend.perf_pm[stat]
			assert_bool(v >= 500 and v <= 2000).is_true()
	var b: Defs.BalanceDef = pack.balance
	for i: int in range(1, b.xp_table.size()):
		assert_bool(b.xp_table[i] > 0).is_true()
	for i: int in range(1, b.train_cost.size()):
		assert_bool(b.train_cost[i] > 0).is_true()
	for d: int in b.mission["dur_s"]:
		assert_bool(d > 0).is_true()
	for e: int in b.mission["energia"]:
		assert_bool(e > 0).is_true()
	assert_int(b.item["price_pt"]).is_greater(0)
	assert_int(b.start["weapon"]["preco"]).is_greater(0)
	for r: Defs.RarityDef in pack.rarities:
		assert_int(r.mult_pm).is_greater(0)


func test_ints_not_floats() -> void:
	var pack: RulesPack = _load_base()
	assert_int(typeof(pack.balance.en_max)).is_equal(TYPE_INT)
	assert_int(typeof(pack.schema_version)).is_equal(TYPE_INT)
	assert_int(typeof(pack.legends["saci"].lvl)).is_equal(TYPE_INT)
	assert_int(typeof(pack.legends["saci"].perf_pm["for"])).is_equal(TYPE_INT)
	assert_int(typeof(pack.acts[0].de)).is_equal(TYPE_INT)
	assert_int(typeof(pack.rarities[1].mult_pm)).is_equal(TYPE_INT)
	assert_int(typeof(pack.balance.mission["dur_s"][0])).is_equal(TYPE_INT)
	assert_int(typeof(pack.balance.item["primary"].size())).is_equal(TYPE_INT)
	assert_int(typeof(pack.balance.bands["stage_win_bp"][0])).is_equal(TYPE_INT)
	assert_int(typeof(pack.balance.start["stats"]["for"])).is_equal(TYPE_INT)


func test_broken_fixtures_fail_with_expected_error() -> void:
	var names: PackedStringArray = DirAccess.get_directories_at(FIXTURES)
	var checked: int = 0
	for dir_name: String in names:
		if not dir_name.begins_with("broken_"):
			continue
		var dir_path: String = "%s/%s" % [FIXTURES, dir_name]
		var expected: String = (
			FileAccess.get_file_as_string(dir_path + "/expected_error.txt").strip_edges()
		)
		(
			assert_str(expected)
			. override_failure_message("%s sem expected_error.txt" % dir_name)
			. is_not_empty()
		)
		var result: RulesLoadResult = RulesLoader.load_dir(dir_path)
		assert_bool(result.ok).override_failure_message("%s deveria falhar" % dir_name).is_false()
		assert_object(result.pack).is_null()
		var found: bool = false
		for message: String in result.errors:
			if message.contains(expected):
				found = true
		(
			assert_bool(found)
			. override_failure_message(
				"%s: esperado '%s' em %s" % [dir_name, expected, str(result.errors)]
			)
			. is_true()
		)
		checked += 1
	assert_int(checked).is_equal(10)


func test_errors_accumulate_instead_of_stopping_at_first() -> void:
	var result: RulesLoadResult = RulesLoader.load_dir(FIXTURES + "/multi_errors")
	assert_bool(result.ok).is_false()
	assert_int(result.errors.size()).is_greater_equal(3)
	var joined: String = "\n".join(result.errors)
	assert_str(joined).contains("legends.json: legends[1].perf_pm: campo ausente")
	assert_str(joined).contains("acts.json: acts[0].stages[3].legend_id: lenda 'zumbi' não existe")
	assert_str(joined).contains("balance.json: item.price_pt: deve ser maior que 0")


func test_missing_directory_reports_missing_files() -> void:
	var result: RulesLoadResult = RulesLoader.load_dir("res://data/packs/nao_existe")
	assert_bool(result.ok).is_false()
	assert_str("\n".join(result.errors)).contains("manifest.json: (raiz): arquivo não encontrado")
