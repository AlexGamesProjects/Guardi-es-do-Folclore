extends GdUnitTestSuite

const STEP: int = 30000


func test_regen_partial() -> void:
	var r: Dictionary = Stamina.regen(0, 0, 65000, 100, STEP)
	assert_int(r["cur"]).is_equal(2)
	assert_int(r["upd_ms"]).is_equal(60000)


func test_regen_less_than_one_step_keeps_clock() -> void:
	var r: Dictionary = Stamina.regen(5, 1000, 20000, 100, STEP)
	assert_int(r["cur"]).is_equal(5)
	assert_int(r["upd_ms"]).is_equal(1000)


func test_regen_clock_back_no_gain() -> void:
	var r: Dictionary = Stamina.regen(10, 90000, 50000, 100, STEP)
	assert_int(r["cur"]).is_equal(10)
	assert_int(r["upd_ms"]).is_equal(50000)


func test_regen_years_forward_caps_at_max() -> void:
	var years_ms: int = 3 * 365 * 24 * 3600 * 1000
	var r: Dictionary = Stamina.regen(3, 0, years_ms, 100, STEP)
	assert_int(r["cur"]).is_equal(100)


func test_regen_full_resets_clock() -> void:
	var r: Dictionary = Stamina.regen(100, 1000, 777000, 100, STEP)
	assert_int(r["cur"]).is_equal(100)
	assert_int(r["upd_ms"]).is_equal(777000)


func test_regen_above_max_resets_clock() -> void:
	var r: Dictionary = Stamina.regen(120, 1000, 5000, 100, STEP)
	assert_int(r["upd_ms"]).is_equal(5000)


func test_regen_results_are_ints() -> void:
	var r: Dictionary = Stamina.regen(0, 0, 65000, 100, STEP)
	assert_int(typeof(r["cur"])).is_equal(TYPE_INT)
	assert_int(typeof(r["upd_ms"])).is_equal(TYPE_INT)


func test_spend_from_full_resets_timer() -> void:
	var r: Dictionary = Stamina.spend(100, 1000, 50000, 100, 12)
	assert_int(r["cur"]).is_equal(88)
	assert_int(r["upd_ms"]).is_equal(50000)
	assert_bool(r["ok"]).is_true()


func test_spend_not_full_keeps_timer() -> void:
	var r: Dictionary = Stamina.spend(50, 1000, 50000, 100, 12)
	assert_int(r["cur"]).is_equal(38)
	assert_int(r["upd_ms"]).is_equal(1000)


func test_spend_insufficient_changes_nothing() -> void:
	var r: Dictionary = Stamina.spend(5, 1000, 50000, 100, 12)
	assert_bool(r["ok"]).is_false()
	assert_int(r["cur"]).is_equal(5)
	assert_int(r["upd_ms"]).is_equal(1000)
