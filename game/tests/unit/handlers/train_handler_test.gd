extends GdUnitTestSuite

var _rules: RulesPack


func before() -> void:
	_rules = Fx.rules()


func test_train_raises_stat_and_charges_table_cost() -> void:
	var s: GameState = Fx.game(_rules)
	var res: CommandResult = Fx.run(s, "treinar", {"stat": "for"}, _rules)
	assert_bool(res.ok).is_true()
	assert_int(res.state.stats["for"]).is_equal(11)
	assert_int(res.state.vint).is_equal(150 - 12)
	assert_int(s.stats["for"]).is_equal(10)


func test_train_cost_follows_the_base_stat_not_equipment() -> void:
	var s: GameState = Fx.game(_rules)
	var res: CommandResult = Fx.run(s, "treinar", {"stat": "mal"}, _rules)
	assert_int(res.state.vint).is_equal(150 - 10)


func test_train_invalid_stat() -> void:
	var s: GameState = Fx.game(_rules)
	var before: Dictionary = s.to_dict()
	for params: Dictionary in [{"stat": "sorte"}, {}, {"stat": 3}]:
		var res: CommandResult = Fx.run(s, "treinar", params, _rules)
		assert_bool(res.ok).is_false()
		assert_str(res.error).is_equal("ATRIBUTO_INVALIDO")
	assert_dict(s.to_dict()).is_equal(before)


func test_train_without_vintens() -> void:
	var s: GameState = Fx.game(_rules)
	s.vint = 11
	var before: Dictionary = s.to_dict()
	var res: CommandResult = Fx.run(s, "treinar", {"stat": "for"}, _rules)
	assert_str(res.error).is_equal("VINTENS_INSUFICIENTES")
	assert_dict(s.to_dict()).is_equal(before)
	s.vint = 12
	assert_bool(Fx.run(s, "treinar", {"stat": "for"}, _rules).ok).is_true()
