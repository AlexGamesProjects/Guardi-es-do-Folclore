extends GdUnitTestSuite

var _rules: RulesPack
var _hero: Dictionary = {"for": 30, "fol": 28, "mal": 25, "gin": 22}


func before() -> void:
	_rules = RulesLoader.load_dir("res://data/packs/base").pack


func test_rival_fields_and_ranges() -> void:
	for s: int in 200:
		var r: Dictionary = Rivals.generate(10, _hero, 100, 9, Rng.new(s), _rules)
		assert_int(r["id"]).is_equal(9)
		assert_int(r["lvl"]).is_between(9, 12)
		assert_int(r["honra"]).is_between(60, 180)
		assert_bool(_rules.balance.rival["colors"].has(r["cor"])).is_true()
		var parts: PackedStringArray = (r["nome"] as String).split(" ", true, 1)
		assert_bool(_rules.rival_first.has(parts[0])).is_true()
		for k: String in Defs.STAT_KEYS:
			assert_int(r["st"][k]).is_greater_equal(3)


func test_rival_level_never_below_one() -> void:
	for s: int in 100:
		var r: Dictionary = Rivals.generate(1, _hero, 0, 1, Rng.new(s), _rules)
		assert_int(r["lvl"]).is_greater_equal(1)
		assert_int(r["honra"]).is_between(0, 40)


func test_rival_stat_bounds() -> void:
	# fator 0,78..1,12 * (1 + delta*0,06) * ruído 0,85..1,15 sobre o atributo do herói.
	for s: int in 200:
		var r: Dictionary = Rivals.generate(10, _hero, 0, 1, Rng.new(s), _rules)
		var delta: int = r["lvl"] - 10
		for k: String in Defs.STAT_KEYS:
			var lo: int = _hero[k] * 780 * (1000 + delta * 60) * 850 / 1000000000 - 1
			var hi: int = _hero[k] * 1120 * (1000 + delta * 60) * 1150 / 1000000000 + 1
			assert_int(r["st"][k]).is_between(maxi(3, lo), maxi(3, hi))


func test_rival_is_deterministic() -> void:
	var a: Dictionary = Rivals.generate(10, _hero, 50, 4, Rng.new(8), _rules)
	var b: Dictionary = Rivals.generate(10, _hero, 50, 4, Rng.new(8), _rules)
	assert_dict(a).is_equal(b)
