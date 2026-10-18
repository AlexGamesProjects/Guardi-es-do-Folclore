extends GdUnitTestSuite

var _rules: RulesPack


func before() -> void:
	_rules = RulesLoader.load_dir("res://data/packs/base").pack


func _total(item: Dictionary) -> int:
	var t: int = 0
	for k: String in item["st"]:
		t += item["st"][k]
	return t


func test_item_points_and_price() -> void:
	# Nível 10, comum: pts 20, principal 12 (arma -> for), preço 360.
	for s: int in 40:
		var it: Dictionary = Items.generate(10, "arma", 0, 7, Rng.new(s), _rules)
		if it["rar"] != 0:
			continue
		assert_int(it["st"]["for"]).is_equal(12)
		assert_int(_total(it)).is_equal(20)
		assert_int(it["preco"]).is_equal(360)
		assert_int(it["id"]).is_equal(7)
		assert_str(it["slot"]).is_equal("arma")
		return
	fail("nenhum item comum em 40 sementes")


func test_item_fields_are_ints() -> void:
	var it: Dictionary = Items.generate(5, "", 0, 3, Rng.new(1), _rules)
	assert_int(typeof(it["id"])).is_equal(TYPE_INT)
	assert_int(typeof(it["rar"])).is_equal(TYPE_INT)
	assert_int(typeof(it["preco"])).is_equal(TYPE_INT)
	for k: String in it["st"]:
		assert_int(typeof(it["st"][k])).is_equal(TYPE_INT)


func test_secondary_is_a_different_stat() -> void:
	for s: int in 60:
		var it: Dictionary = Items.generate(8, "corpo", 0, 1, Rng.new(s), _rules)
		var st: Dictionary = it["st"]
		assert_int(st.size()).is_equal(2)
		assert_bool(st.has("fol")).is_true()


func test_empty_slot_draws_from_all_slots() -> void:
	var seen: Dictionary = {}
	for s: int in 100:
		seen[Items.generate(3, "", 0, 1, Rng.new(s), _rules)["slot"]] = true
	assert_int(seen.size()).is_equal(4)


func test_rarity_multiplies_points() -> void:
	for s: int in 200:
		var it: Dictionary = Items.generate(10, "arma", 2, 1, Rng.new(s), _rules)
		assert_int(it["rar"]).is_equal(2)
		assert_int(_total(it)).is_equal(44)  # 20 * 2,2


func test_name_has_epithet_only_when_not_common() -> void:
	for s: int in 80:
		var it: Dictionary = Items.generate(4, "amuleto", 0, 1, Rng.new(s), _rules)
		var base_names: PackedStringArray = _rules.item_names["amuleto"]
		if it["rar"] == 0:
			assert_bool(base_names.has(it["nome"])).is_true()
		else:
			assert_bool(base_names.has(it["nome"])).is_false()


func test_rarity_distribution_with_fixed_seed() -> void:
	var counts: Array[int] = [0, 0, 0]
	var n: int = 4000
	for i: int in n:
		var it: Dictionary = Items.generate(
			5, "arma", 0, 1, Rng.new(Rng.derive_seed(99, i)), _rules
		)
		counts[it["rar"]] += 1
	# Esperado: 68% / 26% / 6%.
	assert_int(counts[0] * 100 / n).is_between(63, 73)
	assert_int(counts[1] * 100 / n).is_between(22, 30)
	assert_int(counts[2] * 100 / n).is_between(3, 9)


func test_rarity_min_is_a_floor() -> void:
	for s: int in 300:
		var it: Dictionary = Items.generate(5, "arma", 1, 1, Rng.new(s), _rules)
		assert_int(it["rar"]).is_greater_equal(1)


func test_generation_is_deterministic() -> void:
	var a: Dictionary = Items.generate(9, "", 0, 5, Rng.new(42), _rules)
	var b: Dictionary = Items.generate(9, "", 0, 5, Rng.new(42), _rules)
	assert_dict(a).is_equal(b)


func test_rarity_min_above_last_is_clamped() -> void:
	var it: Dictionary = Items.generate(5, "arma", 9, 1, Rng.new(4), _rules)
	assert_int(it["rar"]).is_equal(2)
