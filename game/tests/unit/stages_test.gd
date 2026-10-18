extends GdUnitTestSuite

var _rules: RulesPack


func before() -> void:
	_rules = RulesLoader.load_dir("res://data/packs/base").pack


func test_stage_required_level() -> void:
	assert_int(Stages.required_level(1, 0, _rules)).is_equal(11)
	assert_int(Stages.required_level(0, 0, _rules)).is_equal(1)
	assert_int(Stages.required_level(2, 9, _rules)).is_equal(30)


func test_boss_reward() -> void:
	var r: Dictionary = Stages.reward(0, 9, _rules)
	assert_int(r["vint"]).is_equal((40 + 250) * 3)
	assert_int(r["muir"]).is_equal(3)
	assert_int(r["xp"]).is_equal(_rules.balance.xp_table[10] * 500 / 1000)
	assert_int(r["item_rarity_min"]).is_equal(1)


func test_regular_stage_reward() -> void:
	var r: Dictionary = Stages.reward(1, 2, _rules)  # nível 13
	assert_int(r["vint"]).is_equal(40 + 13 * 25)
	assert_int(r["muir"]).is_equal(0)
	assert_int(r["xp"]).is_equal(_rules.balance.xp_table[13] * 180 / 1000)
	assert_int(r["item_rarity_min"]).is_equal(0)


func test_stage_enemy_stats() -> void:
	var e: Fighter = Stages.enemy(0, 0, _rules)
	var legend: Defs.LegendDef = _rules.legends[_rules.acts[0].stages[0].legend_id]
	for k: String in Defs.STAT_KEYS:
		var raw: int = 10 * 892 * legend.perf_pm[k]
		assert_int(e.stats[k]).is_equal((raw + 500000) / 1000000)
	assert_int(e.lvl).is_equal(1)
	assert_str(e.legend_id).is_equal(legend.id)
	assert_str(e.nome).is_equal(_rules.acts[0].stages[0].nome)


func test_boss_enemy_uses_boss_multiplier() -> void:
	var e: Fighter = Stages.enemy(0, 9, _rules)
	var legend: Defs.LegendDef = _rules.legends[_rules.acts[0].stages[9].legend_id]
	var base: int = _rules.balance.curva[9]  # nível 10
	for k: String in Defs.STAT_KEYS:
		assert_int(e.stats[k]).is_equal((base * 1090 * legend.perf_pm[k] + 500000) / 1000000)
	assert_int(e.lvl).is_equal(10)


func test_stages_never_use_ally_and_levels_follow_act() -> void:
	for a: int in _rules.acts.size():
		for n: int in _rules.acts[a].stages.size():
			var e: Fighter = Stages.enemy(a, n, _rules)
			assert_bool(_rules.legends[e.legend_id].ally).is_false()
			assert_int(e.lvl).is_equal(_rules.acts[a].de + n)


func _boss_twos(rules: RulesPack, n: int) -> int:
	var twos: int = 0
	for i: int in n:
		if Stages.boss_item_rarity_min(Rng.new(Rng.derive_seed(31, i)), rules) == 2:
			twos += 1
	return twos


func test_boss_item_rarity_is_about_half_legendary() -> void:
	assert_int(_boss_twos(_rules, 2000) * 10000 / 2000).is_between(4500, 5500)


func test_boss_item_rarity_extremes() -> void:
	var never: RulesPack = RulesLoader.load_dir("res://data/packs/base").pack
	never.balance.stage["boss_legendary_bp"] = 0
	assert_int(_boss_twos(never, 200)).is_equal(0)
	assert_int(Stages.boss_item_rarity_min(Rng.new(1), never)).is_equal(1)
	var always: RulesPack = RulesLoader.load_dir("res://data/packs/base").pack
	always.balance.stage["boss_legendary_bp"] = 10000
	assert_int(_boss_twos(always, 200)).is_equal(200)
