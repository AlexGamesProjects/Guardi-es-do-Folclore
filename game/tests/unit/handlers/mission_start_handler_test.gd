extends GdUnitTestSuite

var _rules: RulesPack


func before() -> void:
	_rules = Fx.rules()


func test_start_mission_spends_energy_and_sets_end_time() -> void:
	var s: GameState = Fx.game(_rules)
	var m: Dictionary = s.ofertas[0].duplicate(true)
	var res: CommandResult = Fx.run(s, "iniciar_missao", {"mission_id": m["id"]}, _rules)
	assert_bool(res.ok).is_true()
	var st: GameState = res.state
	assert_int(st.ativa["id"]).is_equal(m["id"])
	assert_int(st.ativa["fim_ms"]).is_equal(Fx.T0 + int(m["dur"]) * 1000)
	assert_int(st.energia).is_equal(100 - int(m["en"]))
	assert_int(st.en_upd_ms).is_equal(Fx.T0)
	assert_int(st.ofertas.size()).is_equal(3)
	for o: Dictionary in st.ofertas:
		assert_int(o["id"]).is_not_equal(m["id"])
	assert_int(s.ofertas.size()).is_equal(3)
	assert_bool(s.ativa.is_empty()).is_true()


func test_start_mission_errors_keep_state() -> void:
	var s: GameState = Fx.game(_rules)
	var id: int = s.ofertas[0]["id"]
	var before: Dictionary = s.to_dict()
	assert_str(Fx.run(s, "iniciar_missao", {"mission_id": 31337}, _rules).error).is_equal(
		"NAO_ENCONTRADO"
	)
	assert_str(Fx.run(s, "iniciar_missao", {}, _rules).error).is_equal("NAO_ENCONTRADO")
	assert_dict(s.to_dict()).is_equal(before)
	s.energia = 0
	s.en_upd_ms = Fx.T0
	before = s.to_dict()
	var tired: CommandResult = Fx.run(s, "iniciar_missao", {"mission_id": id}, _rules)
	assert_str(tired.error).is_equal("ENERGIA_INSUFICIENTE")
	assert_dict(s.to_dict()).is_equal(before)


func test_start_mission_while_active() -> void:
	var s: GameState = Fx.game(_rules)
	var first: CommandResult = Fx.run(
		s, "iniciar_missao", {"mission_id": s.ofertas[0]["id"]}, _rules
	)
	var st: GameState = first.state
	var before: Dictionary = st.to_dict()
	var second: CommandResult = Fx.run(
		st, "iniciar_missao", {"mission_id": st.ofertas[0]["id"]}, _rules
	)
	assert_str(second.error).is_equal("MISSAO_ATIVA")
	assert_dict(st.to_dict()).is_equal(before)


func test_start_needs_exact_energy() -> void:
	var s: GameState = Fx.game(_rules)
	var m: Dictionary = s.ofertas[0]
	s.energia = int(m["en"])
	s.en_upd_ms = Fx.T0
	var res: CommandResult = Fx.run(s, "iniciar_missao", {"mission_id": m["id"]}, _rules)
	assert_bool(res.ok).is_true()
	assert_int(res.state.energia).is_equal(0)
