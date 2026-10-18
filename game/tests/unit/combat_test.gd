extends GdUnitTestSuite

var _cfg: Defs.CombatDef


func before() -> void:
	var result: RulesLoadResult = RulesLoader.load_dir("res://data/packs/base")
	_cfg = result.pack.balance.combat


func _fighter(value: int, lvl: int = 1) -> Fighter:
	return Fighter.make("F", lvl, {"for": value, "fol": value, "mal": value, "gin": value})


func _wins_bp(a_value: int, b_value: int, seeds: int) -> int:
	var wins: int = 0
	for s: int in seeds:
		var r: CombatResult = Combat.simulate(
			_fighter(a_value), _fighter(b_value), Rng.new(Rng.derive_seed(777, s)), _cfg
		)
		if r.win:
			wins += 1
	return wins * 10000 / seeds


func test_max_hp_formula() -> void:
	var f := Fighter.make("Jaci", 1, {"for": 10, "fol": 10, "mal": 8, "gin": 8})
	assert_int(f.max_hp(_cfg)).is_equal(132)
	assert_int(_fighter(0, 30).max_hp(_cfg)).is_equal(400)


func test_make_keeps_fields() -> void:
	var f := Fighter.make("Saci", 5, {"for": 1, "fol": 2, "mal": 3, "gin": 4}, "saci")
	assert_str(f.nome).is_equal("Saci")
	assert_int(f.lvl).is_equal(5)
	assert_int(f.stats["gin"]).is_equal(4)
	assert_str(f.legend_id).is_equal("saci")
	assert_str(_fighter(1).legend_id).is_equal("")


func test_dodge_crit_bp_clamped() -> void:
	var low := Fighter.make("a", 1, {"for": 1000, "fol": 1000, "mal": 0, "gin": 0})
	var high := Fighter.make("b", 1, {"for": 0, "fol": 0, "mal": 100000, "gin": 100000})
	# gin_def*5500/(gin_def+for_atk+30): 0 -> piso; enorme -> teto
	assert_int(Combat.dodge_bp(low, low, _cfg)).is_equal(300)
	assert_int(Combat.dodge_bp(low, high, _cfg)).is_equal(3500)
	assert_int(Combat.crit_bp(low, low, _cfg)).is_equal(300)
	assert_int(Combat.crit_bp(high, low, _cfg)).is_equal(4000)
	# valor intermediário exato: 40*5500/(40+40+30) = 2000
	assert_int(Combat.dodge_bp(_fighter(40), _fighter(40), _cfg)).is_equal(2000)
	# 40*6000/(40+40+30) = 2181
	assert_int(Combat.crit_bp(_fighter(40), _fighter(40), _cfg)).is_equal(2181)


func test_base_damage_x10() -> void:
	# for*17 + lvl*25
	assert_int(Combat.base_damage_x10(_fighter(40, 3), _cfg)).is_equal(40 * 17 + 3 * 25)


func test_same_seed_same_events() -> void:
	var r1: CombatResult = Combat.simulate(_fighter(30), _fighter(25), Rng.new(99), _cfg)
	var r2: CombatResult = Combat.simulate(_fighter(30), _fighter(25), Rng.new(99), _cfg)
	assert_bool(r1.win == r2.win).is_true()
	assert_array(r1.events).is_equal(r2.events)
	assert_array(r1.hp_final).is_equal(r2.hp_final)


func test_event_shape_and_final_event() -> void:
	var r: CombatResult = Combat.simulate(_fighter(30), _fighter(25), Rng.new(5), _cfg)
	var last: Dictionary = r.events[r.events.size() - 1]
	assert_str(last["type"]).is_equal("fim")
	assert_bool(last["vencedor"] == 0 or last["vencedor"] == 1).is_true()
	for i: int in r.events.size() - 1:
		var e: Dictionary = r.events[i]
		assert_bool(["golpe", "critico", "esquiva"].has(e["type"])).is_true()
		assert_bool(e["atacante"] == 0 or e["atacante"] == 1).is_true()
		assert_int(typeof(e["dano"])).is_equal(TYPE_INT)
		var hp: Array = e["hp"]
		assert_int(hp.size()).is_equal(2)
		if e["type"] == "esquiva":
			assert_int(e["dano"]).is_equal(0)


func test_damage_never_below_1() -> void:
	var weak := Fighter.make("w", 1, {"for": 0, "fol": 0, "mal": 0, "gin": 0})
	var cfg_low: Defs.CombatDef = Defs.CombatDef.new()
	cfg_low.hp_base = 40
	cfg_low.hp_per_fol = 8
	cfg_low.hp_per_lvl = 12
	cfg_low.dmg_for_x10 = 1
	cfg_low.dmg_lvl_x10 = 0
	cfg_low.dmg_var_min_pm = 800
	cfg_low.dmg_var_max_pm = 1200
	cfg_low.dodge_num = 5500
	cfg_low.dodge_min_bp = 300
	cfg_low.dodge_max_bp = 3500
	cfg_low.crit_num = 6000
	cfg_low.crit_min_bp = 300
	cfg_low.crit_max_bp = 4000
	cfg_low.crit_mult = 2
	cfg_low.chance_pad = 30
	cfg_low.initiative_roll_max = 5
	cfg_low.max_turns = 40
	for s: int in 50:
		var r: CombatResult = Combat.simulate(weak, weak, Rng.new(s), cfg_low)
		for e: Dictionary in r.events:
			if e["type"] == "golpe" or e["type"] == "critico":
				assert_bool(e["dano"] >= 1).is_true()


func test_ends_within_max_turns() -> void:
	for s: int in 100:
		var r: CombatResult = Combat.simulate(_fighter(40), _fighter(40), Rng.new(s), _cfg)
		var swings: int = r.events.size() - 1
		assert_bool(swings <= _cfg.max_turns).is_true()
		assert_str(r.events[r.events.size() - 1]["type"]).is_equal("fim")


func test_hp_never_negative_and_matches_winner() -> void:
	for s: int in 100:
		var r: CombatResult = Combat.simulate(_fighter(40), _fighter(20), Rng.new(s), _cfg)
		assert_bool(r.hp_final[0] >= 0 and r.hp_final[1] >= 0).is_true()
		var last: Dictionary = r.events[r.events.size() - 1]
		assert_bool((last["vencedor"] == 0) == r.win).is_true()


func test_strong_beats_weak_mostly() -> void:
	var bp: int = _wins_bp(40, 15, 200)
	(
		assert_bool(bp > 9500)
		. override_failure_message("forte x fraco: %d bp em 200 sementes" % bp)
		. is_true()
	)


func test_equal_fighters_near_half() -> void:
	var bp: int = _wins_bp(25, 25, 2000)
	(
		assert_bool(bp >= 4500 and bp <= 5500)
		. override_failure_message("iguais: %d bp em 2000 sementes" % bp)
		. is_true()
	)


## Configuração com variação de dano fixa em 1000 pm (sem sorte no dano) e esquiva e crítico
## no piso de 1 bp (praticamente nunca acontecem; os testes conferem os tipos de evento).
func _fixed_cfg(turns: int, lvl_x10: int = 25) -> Defs.CombatDef:
	return (
		Defs
		. CombatDef
		. from_dict(
			{
				"hp_base": 40,
				"hp_per_fol": 8,
				"hp_per_lvl": 12,
				"dmg_for_x10": 17,
				"dmg_lvl_x10": lvl_x10,
				"dmg_var_min_pm": 1000,
				"dmg_var_max_pm": 1000,
				"dodge_num": 5500,
				"dodge_min_bp": 1,
				"dodge_max_bp": 1,
				"crit_num": 6000,
				"crit_min_bp": 1,
				"crit_max_bp": 1,
				"crit_mult": 2,
				"chance_pad": 30,
				"initiative_roll_max": 5,
				"max_turns": turns,
			}
		)
	)


## Lutador de nível 1 com fol 10 (vida máxima 40 + 80 + 12 = 132). `gin` decide a iniciativa:
## com 50 contra 0 ele sempre começa, pois o sorteio de iniciativa vai de 0 a 5.
func _duelist(strength: int, gin: int) -> Fighter:
	return Fighter.make("D", 1, {"for": strength, "fol": 10, "mal": 10, "gin": gin})


func _assert_only_plain_hits(r: CombatResult) -> void:
	for i: int in r.events.size() - 1:
		(
			assert_str(r.events[i]["type"])
			. override_failure_message("a semente fixa deveria dar só golpes normais")
			. is_equal("golpe")
		)


func test_turn_cutoff_decides_by_cross_product() -> void:
	# 3 golpes por luta e ninguém morre. Dano de for 10: (195*1000+5000)/10000 = 20;
	# dano de for 20: (365*1000+5000)/10000 = 37. Vida máxima de ambos: 132.
	var cfg: Defs.CombatDef = _fixed_cfg(3)
	# a começa e golpeia duas vezes (20+20), b uma (37): hp_a 95, hp_b 92 -> 95*132 >= 92*132.
	var win: CombatResult = Combat.simulate(_duelist(10, 50), _duelist(20, 0), Rng.new(1), cfg)
	_assert_only_plain_hits(win)
	assert_int(win.events.size()).is_equal(4)
	assert_array(win.hp_final).is_equal(PackedInt32Array([95, 92]))
	assert_bool(win.win).is_true()
	assert_int(win.events[3]["vencedor"]).is_equal(0)
	# b começa e golpeia duas vezes (74), a uma (20): hp_a 58, hp_b 112 -> a perde pelo corte.
	var loss: CombatResult = Combat.simulate(_duelist(10, 0), _duelist(20, 50), Rng.new(1), cfg)
	_assert_only_plain_hits(loss)
	assert_int(loss.events.size()).is_equal(4)
	assert_array(loss.hp_final).is_equal(PackedInt32Array([58, 112]))
	assert_bool(loss.win).is_false()
	assert_int(loss.events[3]["vencedor"]).is_equal(1)


func test_exact_cross_product_tie_goes_to_a() -> void:
	# 2 golpes por luta, dano 20 para os dois: hp 112 x 112, produto cruzado igual -> a vence,
	# comece ele ou não.
	var cfg: Defs.CombatDef = _fixed_cfg(2)
	var a_first: CombatResult = Combat.simulate(_duelist(10, 50), _duelist(10, 0), Rng.new(1), cfg)
	_assert_only_plain_hits(a_first)
	assert_array(a_first.hp_final).is_equal(PackedInt32Array([112, 112]))
	assert_bool(a_first.win).is_true()
	var b_first: CombatResult = Combat.simulate(_duelist(10, 0), _duelist(10, 50), Rng.new(1), cfg)
	_assert_only_plain_hits(b_first)
	assert_array(b_first.hp_final).is_equal(PackedInt32Array([112, 112]))
	assert_bool(b_first.win).is_true()
	assert_int(b_first.events[2]["vencedor"]).is_equal(0)


func test_damage_rounding_is_half_up() -> void:
	# for 10, nível 1: base x10 = 170 + 25 = 195 -> 195*1000/10000 = 19,5 -> arredonda para 20
	# (truncar daria 19).
	var up: CombatResult = Combat.simulate(
		_duelist(10, 50), _duelist(10, 0), Rng.new(1), _fixed_cfg(1)
	)
	_assert_only_plain_hits(up)
	assert_int(up.events[0]["dano"]).is_equal(20)
	# Com dmg_lvl_x10 = 24: base x10 = 194 -> 19,4 -> 19 (o arredondamento também desce).
	var down: CombatResult = Combat.simulate(
		_duelist(10, 50), _duelist(10, 0), Rng.new(1), _fixed_cfg(1, 24)
	)
	_assert_only_plain_hits(down)
	assert_int(down.events[0]["dano"]).is_equal(19)


func test_turn_cutoff_compares_ratio_not_raw_hp() -> void:
	# a: for 1, fol 20 -> vida máxima 40 + 160 + 12 = 212; dano (42*1000+5000)/10000 = 4.
	# b: for 20, fol 0 -> vida máxima 40 + 0 + 12 = 52; dano 37. b começa (gin 50 contra 0).
	# 3 golpes: b, a, b. hp_a = 212 - 74 = 138; hp_b = 52 - 4 = 48.
	# Vida bruta: 138 > 48 (a "venceria"). Produto cruzado: 138*52 = 7176 < 48*212 = 10176,
	# ou seja 65% da vida contra 92%: a perde.
	var a := Fighter.make("A", 1, {"for": 1, "fol": 20, "mal": 10, "gin": 0})
	var b := Fighter.make("B", 1, {"for": 20, "fol": 0, "mal": 10, "gin": 50})
	var r: CombatResult = Combat.simulate(a, b, Rng.new(1), _fixed_cfg(3))
	_assert_only_plain_hits(r)
	assert_int(r.events.size()).is_equal(4)
	assert_array(r.hp_final).is_equal(PackedInt32Array([138, 48]))
	assert_bool(r.win).is_false()
	assert_int(r.events[3]["vencedor"]).is_equal(1)
