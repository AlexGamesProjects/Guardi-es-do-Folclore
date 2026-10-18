extends GdUnitTestSuite


func test_same_seed_same_sequence() -> void:
	var a := Rng.new(42)
	var b := Rng.new(42)
	for i: int in 1000:
		assert_int(a.next_int(100)).is_equal(b.next_int(100))


func test_different_seeds_diverge() -> void:
	var a := Rng.new(42)
	var b := Rng.new(43)
	var differs: bool = false
	for i: int in 100:
		if a.next_int(1000000) != b.next_int(1000000):
			differs = true
	assert_bool(differs).is_true()


func test_state_restore() -> void:
	var rng := Rng.new(7)
	for i: int in 10:
		rng.next_int(100)
	var saved: int = rng.get_state()
	var first: Array[int] = []
	for i: int in 50:
		first.append(rng.next_int(100))
	rng.set_state(saved)
	for i: int in 50:
		assert_int(rng.next_int(100)).is_equal(first[i])


func test_roll_bp_bounds() -> void:
	var rng := Rng.new(1)
	for i: int in 1000:
		assert_bool(rng.roll_bp(0)).is_false()
		assert_bool(rng.roll_bp(10000)).is_true()


func test_next_int_stays_below_max() -> void:
	var rng := Rng.new(5)
	for i: int in 1000:
		var v: int = rng.next_int(6)
		assert_bool(v >= 0 and v < 6).is_true()


func test_next_int_invalid_max_returns_zero() -> void:
	var rng := Rng.new(5)
	assert_int(rng.next_int(0)).is_equal(0)
	assert_int(rng.next_int(-3)).is_equal(0)
	(
		assert_error(func() -> void: rng.next_int(0))
		. is_push_error("Rng.next_int: max_exclusive deve ser > 0, recebido 0")
	)


func test_range_int_inclusive_bounds() -> void:
	var rng := Rng.new(9)
	var seen_lo: bool = false
	var seen_hi: bool = false
	for i: int in 1000:
		var v: int = rng.range_int(3, 5)
		assert_bool(v >= 3 and v <= 5).is_true()
		seen_lo = seen_lo or v == 3
		seen_hi = seen_hi or v == 5
	assert_bool(seen_lo).is_true()
	assert_bool(seen_hi).is_true()
	assert_int(rng.range_int(4, 4)).is_equal(4)


func test_pick_returns_member() -> void:
	var rng := Rng.new(11)
	var items: Array = ["a", "b", "c"]
	for i: int in 100:
		assert_bool(items.has(rng.pick(items))).is_true()


func test_derive_seed_range_and_stable() -> void:
	var s: int = Rng.derive_seed(7, 3)
	assert_int(Rng.derive_seed(7, 3)).is_equal(s)
	assert_bool(s >= 0 and s < 2147483648).is_true()
	assert_bool(Rng.derive_seed(7, 4) != s).is_true()


func test_derive_seed_always_in_range() -> void:
	for i: int in 1000:
		var s: int = Rng.derive_seed(i * 2654435761, i)
		assert_bool(s >= 0 and s < 2147483648).is_true()
	assert_bool(Rng.derive_seed(-5, -9) >= 0).is_true()
