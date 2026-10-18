extends GdUnitTestSuite

var _rules: RulesPack


func before() -> void:
	_rules = Fx.rules()


func test_unknown_command_fails_and_keeps_state() -> void:
	var s: GameState = Fx.game(_rules)
	var before: Dictionary = s.to_dict()
	var res: CommandResult = Fx.run(s, "voar", {}, _rules)
	assert_bool(res.ok).is_false()
	assert_str(res.error).is_equal("COMANDO_DESCONHECIDO")
	assert_dict(s.to_dict()).is_equal(before)


func test_success_works_on_a_clone() -> void:
	var s: GameState = Fx.game(_rules)
	var before: Dictionary = s.to_dict()
	var res: CommandResult = Fx.run(s, "renomear", {"nome": "Ana"}, _rules)
	assert_bool(res.ok).is_true()
	assert_object(res.state).is_not_same(s)
	assert_str(res.state.nome).is_equal("Ana")
	assert_dict(s.to_dict()).is_equal(before)


func test_failure_returns_original_state() -> void:
	var s: GameState = Fx.game(_rules)
	var res: CommandResult = Fx.run(s, "concluir_missao", {}, _rules)
	assert_str(res.error).is_equal("SEM_MISSAO")
	assert_object(res.state).is_same(s)


func test_regen_runs_before_the_handler() -> void:
	var s: GameState = Fx.game(_rules)
	s.energia = 50
	s.en_upd_ms = Fx.T0 - 30000 * 10 - 5
	s.coragem = 1
	s.co_upd_ms = Fx.T0 - 120000 * 2
	var res: CommandResult = Fx.run(s, "renomear", {"nome": "Ana"}, _rules)
	assert_int(res.state.energia).is_equal(60)
	assert_int(res.state.en_upd_ms).is_equal(Fx.T0 - 5)
	assert_int(res.state.coragem).is_equal(3)
	assert_int(s.energia).is_equal(50)


func test_expired_shop_is_renewed() -> void:
	var s: GameState = Fx.game(_rules)
	var old_ids: Array = s.feira.map(func(i: Dictionary) -> int: return i["id"])
	s.feira_upd_ms = Fx.T0 - 600000 - 1
	var res: CommandResult = Fx.run(s, "renomear", {"nome": "Ana"}, _rules)
	assert_int(res.state.feira_upd_ms).is_equal(Fx.T0)
	assert_int(res.state.feira.size()).is_equal(6)
	for item: Dictionary in res.state.feira:
		assert_bool(old_ids.has(item["id"])).is_false()


func test_fresh_shop_is_kept() -> void:
	var s: GameState = Fx.game(_rules)
	s.feira_upd_ms = Fx.T0 - 600000
	var res: CommandResult = Fx.run(s, "renomear", {"nome": "Ana"}, _rules)
	assert_int(res.state.feira_upd_ms).is_equal(Fx.T0 - 600000)
	assert_array(res.state.feira).is_equal(s.feira)


func test_missing_offers_and_rivals_are_refilled() -> void:
	var s: GameState = Fx.game(_rules)
	s.ofertas.clear()
	s.rivais.pop_back()
	var res: CommandResult = Fx.run(s, "renomear", {"nome": "Ana"}, _rules)
	assert_int(res.state.ofertas.size()).is_equal(3)
	assert_int(res.state.rivais.size()).is_equal(3)
	assert_int(res.state.uid).is_greater(s.uid)


func test_counter_is_not_touched_and_result_is_deterministic() -> void:
	var s: GameState = Fx.game(_rules)
	s.cmd_counter = 41
	s.ofertas.clear()
	var a: CommandResult = Fx.run(s, "renomear", {"nome": "Ana"}, _rules, Fx.T0, 5)
	var b: CommandResult = Fx.run(s, "renomear", {"nome": "Ana"}, _rules, Fx.T0, 5)
	var c: CommandResult = Fx.run(s, "renomear", {"nome": "Ana"}, _rules, Fx.T0, 6)
	assert_int(a.state.cmd_counter).is_equal(41)
	assert_dict(a.state.to_dict()).is_equal(b.state.to_dict())
	assert_dict(a.state.to_dict()).is_not_equal(c.state.to_dict())
