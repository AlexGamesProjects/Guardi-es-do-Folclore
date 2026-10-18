extends GdUnitTestSuite

var _rules: RulesPack


func before() -> void:
	_rules = Fx.rules()


func test_speed_up_spends_muiraquita_and_finishes_now() -> void:
	var s: GameState = Fx.game(_rules)
	s.ativa = {"id": 4, "c": "negrinho", "luta": false, "fim_ms": Fx.T0 + 50000}
	var res: CommandResult = Fx.run(s, "acelerar_missao", {}, _rules)
	assert_bool(res.ok).is_true()
	assert_int(res.state.muir).is_equal(11)
	assert_int(res.state.ativa["fim_ms"]).is_equal(Fx.T0)


func test_speed_up_errors() -> void:
	var s: GameState = Fx.game(_rules)
	var before: Dictionary = s.to_dict()
	assert_str(Fx.run(s, "acelerar_missao", {}, _rules).error).is_equal("SEM_MISSAO")
	assert_dict(s.to_dict()).is_equal(before)
	s.ativa = {"id": 4, "c": "negrinho", "luta": false, "fim_ms": Fx.T0 + 50000}
	s.muir = 0
	before = s.to_dict()
	assert_str(Fx.run(s, "acelerar_missao", {}, _rules).error).is_equal("MUIRAQUITAS_INSUFICIENTES")
	assert_dict(s.to_dict()).is_equal(before)


func test_renew_missions_costs_one_muiraquita() -> void:
	var s: GameState = Fx.game(_rules)
	var old_ids: Array = s.ofertas.map(func(m: Dictionary) -> int: return m["id"])
	var res: CommandResult = Fx.run(s, "renovar_missoes", {}, _rules)
	assert_bool(res.ok).is_true()
	assert_int(res.state.muir).is_equal(11)
	assert_int(res.state.ofertas.size()).is_equal(3)
	for m: Dictionary in res.state.ofertas:
		assert_bool(old_ids.has(m["id"])).is_false()
	s.muir = 0
	var before: Dictionary = s.to_dict()
	assert_str(Fx.run(s, "renovar_missoes", {}, _rules).error).is_equal("MUIRAQUITAS_INSUFICIENTES")
	assert_dict(s.to_dict()).is_equal(before)
