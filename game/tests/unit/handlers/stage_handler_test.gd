extends GdUnitTestSuite

var _rules: RulesPack


func before() -> void:
	_rules = Fx.rules()


func _fight(
	s: GameState, act: int, n: int, seed_value: int = 99, now_ms: int = Fx.T0
) -> CommandResult:
	return Fx.run(s, "enfrentar_fase", {"act": act, "n": n}, _rules, now_ms, seed_value)


func test_stage_blocked_unless_it_is_the_next_one() -> void:
	var s: GameState = Fx.game(_rules)
	var before: Dictionary = s.to_dict()
	for pair: Array in [[0, 1], [0, 10], [0, -1], [3, 0], [-1, 0]]:
		var res: CommandResult = _fight(s, pair[0], pair[1])
		assert_str(res.error).override_failure_message(str(pair)).is_equal("FASE_BLOQUEADA")
	s.fases[0] = 1
	assert_str(_fight(s, 0, 0).error).is_equal("FASE_BLOQUEADA")
	s.fases[0] = 0
	assert_dict(s.to_dict()).is_not_equal({})
	assert_dict(s.to_dict()).is_equal(before)
	assert_str(Fx.run(s, "enfrentar_fase", {}, _rules).error).is_equal("FASE_BLOQUEADA")


func test_stage_level_too_low() -> void:
	var s: GameState = Fx.game(_rules)
	s.fases[0] = 3
	var before: Dictionary = s.to_dict()
	var res: CommandResult = _fight(s, 0, 3)
	assert_str(res.error).is_equal("NIVEL_INSUFICIENTE")
	assert_str(_fight(s, 1, 0).error).is_equal("NIVEL_INSUFICIENTE")
	assert_dict(s.to_dict()).is_equal(before)


func test_stage_recovery_window() -> void:
	var s: GameState = Fx.game(_rules)
	Fx.strong(s)
	s.chefe_espera_ms = Fx.T0 + 1000
	var before: Dictionary = s.to_dict()
	assert_str(_fight(s, 0, 0).error).is_equal("EM_RECUPERACAO")
	assert_dict(s.to_dict()).is_equal(before)
	assert_bool(_fight(s, 0, 0, 99, Fx.T0 + 1000).ok).is_true()


func test_stage_needs_energy() -> void:
	var s: GameState = Fx.game(_rules)
	s.energia = 11
	s.en_upd_ms = Fx.T0
	var before: Dictionary = s.to_dict()
	assert_str(_fight(s, 0, 0).error).is_equal("ENERGIA_INSUFICIENTE")
	assert_dict(s.to_dict()).is_equal(before)


func test_stage_win_pays_and_advances() -> void:
	var s: GameState = Fx.game(_rules)
	Fx.strong(s)
	var reward: Dictionary = Stages.reward(0, 0, _rules)
	var res: CommandResult = _fight(s, 0, 0)
	assert_bool(res.ok).is_true()
	var st: GameState = res.state
	assert_int(st.fases[0]).is_equal(1)
	assert_int(st.energia).is_equal(100 - 12)
	assert_int(st.vint).is_equal(150 + int(reward["vint"]))
	assert_int(Fx.find_event(res, "xp_ganho")["amount"]).is_equal(reward["xp"])
	assert_int(st.vitorias["saci"]).is_equal(1)
	assert_bool(st.vistos.has("saci")).is_true()
	assert_int(st.chefe_espera_ms).is_equal(0)
	var ev: Dictionary = Fx.find_event(res, "fase_vencida")
	assert_int(ev["act"]).is_equal(0)
	assert_int(ev["n"]).is_equal(0)
	assert_bool(ev["boss"]).is_false()
	assert_bool(Fx.types(res).has("ato_concluido")).is_false()
	assert_array(st.mochila).is_empty()
	assert_bool(Fx.types(res).has("luta")).is_true()


func test_defeat_sets_recovery_90s() -> void:
	var s: GameState = Fx.game(_rules)
	Fx.weak(s)
	var res: CommandResult = _fight(s, 0, 0)
	assert_bool(res.ok).is_true()
	var st: GameState = res.state
	assert_int(st.chefe_espera_ms).is_equal(Fx.T0 + 90000)
	assert_int(st.fases[0]).is_equal(0)
	assert_int(st.energia).is_equal(100 - 12)
	assert_int(st.vint).is_equal(150)
	assert_bool(Fx.types(res).has("fase_vencida")).is_false()
	assert_bool(Fx.types(res).has("fim")).is_true()
	assert_str(_fight(st, 0, 0, 99, Fx.T0 + 89999).error).is_equal("EM_RECUPERACAO")
	assert_str(_fight(st, 0, 0, 99, Fx.T0 + 90000).error).is_not_equal("EM_RECUPERACAO")


func _boss_ready() -> GameState:
	var s: GameState = Fx.game(_rules)
	Fx.strong(s)
	s.lvl = 10
	s.fases[0] = 9
	return s


func test_boss_win_completes_act() -> void:
	var s: GameState = _boss_ready()
	var reward: Dictionary = Stages.reward(0, 9, _rules)
	var res: CommandResult = _fight(s, 0, 9)
	assert_bool(res.ok).is_true()
	var st: GameState = res.state
	assert_int(st.fases[0]).is_equal(10)
	assert_int(st.muir).is_equal(12 + 3)
	assert_int(st.vint).is_equal(150 + int(reward["vint"]))
	assert_int(st.mochila.size()).is_equal(1)
	assert_int(st.mochila[0]["rar"]).is_greater_equal(1)
	var act_event: Dictionary = Fx.find_event(res, "ato_concluido")
	assert_int(act_event["act"]).is_equal(0)
	assert_bool(Fx.find_event(res, "fase_vencida")["boss"]).is_true()
	assert_str(Fx.find_event(res, "item_ganho")["destino"]).is_equal("mochila")
	assert_str(_fight(st, 0, 9).error).is_equal("FASE_BLOQUEADA")


func test_boss_win_full_bag_sells_item() -> void:
	var s: GameState = _boss_ready()
	Fx.fill_bag(s, _rules)
	var reward: Dictionary = Stages.reward(0, 9, _rules)
	var res: CommandResult = _fight(s, 0, 9)
	assert_bool(res.ok).is_true()
	var st: GameState = res.state
	assert_int(st.mochila.size()).is_equal(14)
	assert_bool(Fx.types(res).has("item_ganho")).is_false()
	var sold: Dictionary = {}
	for e: Dictionary in res.events:
		if e["type"] == "vintens_ganhos" and e["origem"] == "item_vendido":
			sold = e
	assert_bool(sold.is_empty()).is_false()
	assert_int(sold["amount"]).is_greater(0)
	assert_int(st.vint).is_equal(150 + int(reward["vint"]) + int(sold["amount"]))
	assert_int(st.fases[0]).is_equal(10)


func test_boss_item_is_legendary_about_half_the_time() -> void:
	var legendary: int = 0
	for seed_value: int in 60:
		var res: CommandResult = _fight(_boss_ready(), 0, 9, seed_value)
		var rar: int = res.state.mochila[0]["rar"]
		assert_int(rar).is_greater_equal(1)
		if rar == 2:
			legendary += 1
	assert_int(legendary).is_between(18, 46)


func test_level_up_from_stage_xp() -> void:
	var s: GameState = Fx.game(_rules)
	Fx.strong(s)
	s.xp = 55
	var res: CommandResult = _fight(s, 0, 0)
	assert_int(res.state.lvl).is_equal(2)
	assert_bool(Fx.types(res).has("subiu_nivel")).is_true()
