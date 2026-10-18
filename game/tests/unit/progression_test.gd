extends GdUnitTestSuite

var _rules: RulesPack


func before() -> void:
	_rules = RulesLoader.load_dir("res://data/packs/base").pack


func test_level_up_carries_xp() -> void:
	var r: Dictionary = Progression.add_xp(1, 50, 20, _rules)
	assert_int(r["lvl"]).is_equal(2)
	assert_int(r["xp"]).is_equal(10)
	assert_int(r["levels_gained"]).is_equal(1)


func test_no_level_up_below_threshold() -> void:
	var r: Dictionary = Progression.add_xp(1, 10, 20, _rules)
	assert_int(r["lvl"]).is_equal(1)
	assert_int(r["xp"]).is_equal(30)
	assert_int(r["levels_gained"]).is_equal(0)


func test_multi_level_gain() -> void:
	# xp_table[1] = 60, xp_table[2] = 164, xp_table[3] = 295: 60 + 164 + 295 + 5 = 524.
	var r: Dictionary = Progression.add_xp(1, 0, 524, _rules)
	assert_int(r["lvl"]).is_equal(4)
	assert_int(r["xp"]).is_equal(5)
	assert_int(r["levels_gained"]).is_equal(3)


func test_level_is_capped_at_table_end() -> void:
	var top: int = _rules.balance.xp_table.size() - 1
	var r: Dictionary = Progression.add_xp(top, 0, 999999999, _rules)
	assert_int(r["lvl"]).is_equal(top)
	assert_int(r["levels_gained"]).is_equal(0)


func test_train_cost_table() -> void:
	assert_int(Progression.train_cost(10, _rules)).is_equal(12)
	assert_int(Progression.train_cost(6, _rules)).is_equal(8)


func test_train_cost_clamps_out_of_range() -> void:
	var last: int = _rules.balance.train_cost.size() - 1
	assert_int(Progression.train_cost(0, _rules)).is_equal(_rules.balance.train_cost[1])
	assert_int(Progression.train_cost(last + 50, _rules)).is_equal(_rules.balance.train_cost[last])


func test_rank_by_level() -> void:
	assert_str(Progression.rank(1, _rules)).is_equal("Aprendiz da Mata")
	assert_str(Progression.rank(4, _rules)).is_equal("Aprendiz da Mata")
	assert_str(Progression.rank(5, _rules)).is_equal("Mateiro")
	assert_str(Progression.rank(29, _rules)).is_equal("Guardião Ancestral")
	assert_str(Progression.rank(30, _rules)).is_equal("Lenda Viva")
	assert_str(Progression.rank(99, _rules)).is_equal("Lenda Viva")
