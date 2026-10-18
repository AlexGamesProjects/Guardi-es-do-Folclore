extends GdUnitTestSuite

var _rules: RulesPack


func before() -> void:
	_rules = RulesLoader.load_dir("res://data/packs/base").pack


func test_ally_never_fight() -> void:
	for s: int in 500:
		var m: Dictionary = Missions.generate(30, s, Rng.new(s), _rules)
		if _rules.legends[m["c"]].ally:
			assert_bool(m["luta"]).is_false()


func test_missions_respect_unlock_level() -> void:
	for lvl: int in [1, 3, 7, 12]:
		for s: int in 100:
			var m: Dictionary = Missions.generate(lvl, s, Rng.new(s), _rules)
			assert_int(_rules.legends[m["c"]].lvl).is_less_equal(lvl)


func test_fight_chance_is_about_sixty_percent_of_non_allies() -> void:
	var fights: int = 0
	var total: int = 0
	for s: int in 3000:
		var m: Dictionary = Missions.generate(30, s, Rng.new(Rng.derive_seed(5, s)), _rules)
		if not _rules.legends[m["c"]].ally:
			total += 1
			if m["luta"]:
				fights += 1
	assert_int(fights * 100 / total).is_between(55, 65)


func test_mission_fields() -> void:
	for s: int in 60:
		var m: Dictionary = Missions.generate(10, 77, Rng.new(s), _rules)
		var d: int = m["d"]
		assert_int(m["id"]).is_equal(77)
		assert_int(d).is_between(0, 2)
		assert_int(m["dur"]).is_equal(_rules.balance.mission["dur_s"][d])
		assert_int(m["en"]).is_equal(_rules.balance.mission["energia"][d])
		var legend: Defs.LegendDef = _rules.legends[m["c"]]
		var phrases: PackedStringArray = legend.lutas if m["luta"] else legend.tarefas
		assert_int(m["f"]).is_between(0, phrases.size() - 1)


func test_mission_rewards_exact() -> void:
	# xp = (12 + lvl*5) * dif * luta * (1 + legend.lvl*0,02), arredondado.
	for s: int in 100:
		var m: Dictionary = Missions.generate(10, 1, Rng.new(s), _rules)
		var legend: Defs.LegendDef = _rules.legends[m["c"]]
		var dif: int = _rules.balance.mission["dif_pm"][m["d"]]
		var luta: int = 1300 if m["luta"] else 1000
		var mult_pm: int = dif * luta / 1000 * (1000 + legend.lvl * 20) / 1000
		var expected_xp: int = (62 * mult_pm + 500) / 1000
		assert_int(m["xp"]).is_equal(expected_xp)
		var expected_vint: int = (70 * mult_pm + 500) / 1000
		assert_int(m["vint"]).is_equal(expected_vint)


func test_enemy_for_scales_with_hero_and_floors_at_three() -> void:
	var hero: Dictionary = {"for": 40, "fol": 40, "mal": 40, "gin": 40}
	var m: Dictionary = {"c": "saci", "d": 2}
	var e: Fighter = Missions.enemy_for(m, hero, 9, Rng.new(1), _rules)
	var perf: Dictionary = _rules.legends["saci"].perf_pm
	for k: String in Defs.STAT_KEYS:
		var lo: int = 40 * 1120 * perf[k] * 900 / 1000000000
		var hi: int = 40 * 1120 * perf[k] * 1100 / 1000000000 + 1
		assert_int(e.stats[k]).is_between(maxi(3, lo), maxi(3, hi))
	assert_int(e.lvl).is_equal(9)
	assert_str(e.legend_id).is_equal("saci")
	assert_str(e.nome).is_equal(_rules.legends["saci"].nome)
	var weak: Fighter = Missions.enemy_for(
		m, {"for": 1, "fol": 1, "mal": 1, "gin": 1}, 1, Rng.new(2), _rules
	)
	for k: String in Defs.STAT_KEYS:
		assert_int(weak.stats[k]).is_greater_equal(3)


func test_enemy_difficulty_orders_strength() -> void:
	var hero: Dictionary = {"for": 100, "fol": 100, "mal": 100, "gin": 100}
	var easy: Fighter = Missions.enemy_for({"c": "saci", "d": 0}, hero, 5, Rng.new(3), _rules)
	var hard: Fighter = Missions.enemy_for({"c": "saci", "d": 2}, hero, 5, Rng.new(3), _rules)
	assert_int(hard.stats["for"]).is_greater(easy.stats["for"])
