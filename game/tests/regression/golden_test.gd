extends GdUnitTestSuite
## Regressão: o comportamento atual tem de bater com a cópia de referência gravada em `golden/`.
## Mudança intencional? Rode tools/regen_golden.sh e explique o diff no PR.

const REGEN_HINT: String = "Diverge em %s (rode tools/regen_golden.sh se a mudança for intencional)"


func test_fights_match_golden() -> void:
	var expected: Variant = GoldenCases.read_file("fights.json")
	assert_bool(expected is Array).override_failure_message("golden/fights.json ausente").is_true()
	assert_int((expected as Array).size()).is_equal(GoldenCases.FIGHT_COUNT)
	var diff: String = GoldenCases.first_diff(expected, GoldenCases.fights(), "fights")
	assert_str(diff).override_failure_message(REGEN_HINT % diff).is_empty()


func test_playthrough_match_golden() -> void:
	var expected: Variant = GoldenCases.read_file("playthrough.json")
	(
		assert_bool(expected is Dictionary)
		. override_failure_message("golden/playthrough.json ausente")
		. is_true()
	)
	var actual: Dictionary = GoldenCases.playthrough()
	var levels: Dictionary = actual["levels"]
	assert_array(levels.keys()).contains_exactly_in_any_order(["5", "10", "20", "30"])
	assert_int(int((levels["30"] as Dictionary)["lvl"])).is_greater_equal(30)
	var diff: String = GoldenCases.first_diff(expected, actual, "playthrough")
	assert_str(diff).override_failure_message(REGEN_HINT % diff).is_empty()


func test_golden_detects_change() -> void:
	var rules: RulesPack = GoldenCases.base_rules()
	rules.balance.combat.dmg_for_x10 = 18
	var expected: Variant = GoldenCases.read_file("fights.json")
	var diff: String = GoldenCases.first_diff(expected, GoldenCases.fights(rules), "fights")
	assert_str(diff).is_not_empty()
	assert_str(diff).starts_with("fights[")


func test_first_diff_reports_path() -> void:
	var expected: Array = [{"win": true, "hp": [1, 2]}, {"win": false, "hp": [3, 4]}]
	var changed: Array = [{"win": true, "hp": [1, 2]}, {"win": true, "hp": [3, 4]}]
	assert_str(GoldenCases.first_diff(expected, expected.duplicate(true), "fights")).is_empty()
	assert_str(GoldenCases.first_diff(expected, changed, "fights")).is_equal("fights[1].win")
	var shorter: Array = [{"win": true, "hp": [1]}]
	assert_str(GoldenCases.first_diff(expected, shorter, "fights")).is_equal("fights[0].hp[1]")
	var extra_key: Array = [{"win": true, "hp": [1, 2], "x": 0}, expected[1]]
	assert_str(GoldenCases.first_diff(expected, extra_key, "fights")).is_equal("fights[0].x")
