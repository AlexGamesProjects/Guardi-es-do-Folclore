extends GdUnitTestSuite

var _rules: RulesPack


func before() -> void:
	_rules = Fx.rules()


func _active(c: String, luta: bool, xp: int = 30, vint: int = 25) -> Dictionary:
	return {
		"id": 5,
		"c": c,
		"luta": luta,
		"d": 0,
		"f": 0,
		"dur": 20,
		"en": 6,
		"xp": xp,
		"vint": vint,
		"fim_ms": Fx.T0,
	}


func test_finish_errors() -> void:
	var s: GameState = Fx.game(_rules)
	var before: Dictionary = s.to_dict()
	assert_str(Fx.run(s, "concluir_missao", {}, _rules).error).is_equal("SEM_MISSAO")
	s.ativa = _active("negrinho", false)
	s.ativa["fim_ms"] = Fx.T0 + 1
	before = s.to_dict()
	var res: CommandResult = Fx.run(s, "concluir_missao", {}, _rules)
	assert_str(res.error).is_equal("MISSAO_EM_ANDAMENTO")
	assert_dict(s.to_dict()).is_equal(before)


func test_finish_task_pays_vintens_and_xp() -> void:
	var s: GameState = Fx.game(_rules)
	s.ativa = _active("negrinho", false)
	var res: CommandResult = Fx.run(s, "concluir_missao", {}, _rules)
	assert_bool(res.ok).is_true()
	var st: GameState = res.state
	assert_bool(st.ativa.is_empty()).is_true()
	assert_int(st.missoes).is_equal(1)
	assert_int(st.vint).is_equal(175)
	assert_int(st.xp).is_equal(30)
	assert_int(st.lvl).is_equal(1)
	var kinds: Array[String] = Fx.types(res)
	assert_bool(kinds.has("missao_concluida")).is_true()
	assert_bool(kinds.has("golpe")).is_false()
	assert_int(Fx.find_event(res, "vintens_ganhos")["amount"]).is_equal(25)
	assert_int(Fx.find_event(res, "xp_ganho")["amount"]).is_equal(30)
	assert_bool(Fx.find_event(res, "missao_concluida")["win"]).is_true()


func test_level_up_gives_muiraquita_and_full_energy() -> void:
	var s: GameState = Fx.game(_rules)
	s.ativa = _active("negrinho", false, 70)
	s.energia = 10
	s.en_upd_ms = Fx.T0
	var res: CommandResult = Fx.run(s, "concluir_missao", {}, _rules)
	assert_int(res.state.lvl).is_equal(2)
	assert_int(res.state.xp).is_equal(10)
	assert_int(res.state.muir).is_equal(13)
	assert_int(res.state.energia).is_equal(100)
	assert_int(Fx.find_event(res, "subiu_nivel")["lvl"]).is_equal(2)


func test_two_levels_at_once() -> void:
	var s: GameState = Fx.game(_rules)
	s.ativa = _active("negrinho", false, 60 + 164 + 5)
	var res: CommandResult = Fx.run(s, "concluir_missao", {}, _rules)
	assert_int(res.state.lvl).is_equal(3)
	assert_int(res.state.xp).is_equal(5)
	assert_int(res.state.muir).is_equal(14)
	var levels: Array = res.events.filter(
		func(e: Dictionary) -> bool: return e["type"] == "subiu_nivel"
	)
	assert_int(levels.size()).is_equal(2)


func test_item_drop_rate_is_twenty_percent() -> void:
	var drops: int = 0
	for seed_value: int in 500:
		var s: GameState = Fx.game(_rules)
		s.ativa = _active("negrinho", false)
		var res: CommandResult = Fx.run(s, "concluir_missao", {}, _rules, Fx.T0, seed_value)
		if Fx.types(res).has("item_ganho"):
			drops += 1
			assert_int(res.state.mochila.size()).is_equal(1)
		else:
			assert_array(res.state.mochila).is_empty()
	assert_int(drops).is_between(70, 130)


func test_no_drop_when_bag_is_full() -> void:
	for seed_value: int in 100:
		var s: GameState = Fx.game(_rules)
		Fx.fill_bag(s, _rules)
		s.ativa = _active("negrinho", false)
		var res: CommandResult = Fx.run(s, "concluir_missao", {}, _rules, Fx.T0, seed_value)
		assert_bool(Fx.types(res).has("item_ganho")).is_false()
		assert_int(res.state.mochila.size()).is_equal(14)


func test_fight_win_and_defeat() -> void:
	var wins: int = 0
	var losses: int = 0
	for seed_value: int in 80:
		var s: GameState = Fx.game(_rules)
		Fx.weak(s)
		for k: String in Defs.STAT_KEYS:
			s.stats[k] = 6
		s.ativa = _active("curupira", true, 100, 40)
		s.ativa["d"] = 2
		var res: CommandResult = Fx.run(s, "concluir_missao", {}, _rules, Fx.T0, seed_value)
		assert_bool(res.ok).is_true()
		assert_bool(Fx.types(res).has("luta")).is_true()
		assert_bool(Fx.types(res).has("fim")).is_true()
		var won: bool = Fx.find_event(res, "missao_concluida")["win"]
		if won:
			wins += 1
			assert_int(res.state.vint).is_equal(190)
			assert_int(res.state.lvl).is_equal(2)
			assert_int(res.state.xp).is_equal(40)
			assert_int(res.state.vitorias["curupira"]).is_equal(1)
		else:
			losses += 1
			assert_int(res.state.vint).is_equal(150)
			assert_int(Fx.find_event(res, "xp_ganho")["amount"]).is_equal(30)
			assert_bool(res.state.vitorias.has("curupira")).is_false()
		assert_int(res.state.missoes).is_equal(1)
	assert_int(wins).is_greater(0)
	assert_int(losses).is_greater(0)


func test_strong_hero_always_wins_the_fight() -> void:
	for seed_value: int in 20:
		var s: GameState = Fx.game(_rules)
		Fx.strong(s)
		s.ativa = _active("saci", true)
		var res: CommandResult = Fx.run(s, "concluir_missao", {}, _rules, Fx.T0, seed_value)
		assert_bool(Fx.find_event(res, "missao_concluida")["win"]).is_true()


func test_ally_mission_never_fights() -> void:
	var s: GameState = Fx.game(_rules)
	s.ativa = _active("negrinho", true)
	var res: CommandResult = Fx.run(s, "concluir_missao", {}, _rules)
	assert_bool(res.ok).is_true()
	for kind: String in ["luta", "golpe", "critico", "esquiva", "fim"]:
		assert_bool(Fx.types(res).has(kind)).is_false()
	assert_int(res.state.vint).is_equal(175)
	for seed_value: int in 300:
		var m: Dictionary = Missions.generate(30, 1, Rng.new(seed_value), _rules)
		if m["c"] == "negrinho":
			assert_bool(m["luta"]).is_false()
