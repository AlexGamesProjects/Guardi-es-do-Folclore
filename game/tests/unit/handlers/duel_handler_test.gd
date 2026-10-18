extends GdUnitTestSuite

var _rules: RulesPack


func before() -> void:
	_rules = Fx.rules()


func _rival(id: int, lvl: int, stat: int, honra: int = 10) -> Dictionary:
	var st: Dictionary = {}
	for k: String in Defs.STAT_KEYS:
		st[k] = stat
	return {
		"id": id, "nome": "Rival %d" % id, "lvl": lvl, "st": st, "cor": "#8fc0d4", "honra": honra
	}


func _duel(s: GameState, id: int, seed_value: int = 99) -> CommandResult:
	return Fx.run(s, "desafiar", {"rival_id": id}, _rules, Fx.T0, seed_value)


func test_duel_win_rewards() -> void:
	var s: GameState = Fx.game(_rules)
	Fx.strong(s)
	s.lvl = 3
	s.rivais[0] = _rival(77, 3, 1)
	var res: CommandResult = _duel(s, 77)
	assert_bool(res.ok).is_true()
	var st: GameState = res.state
	assert_int(st.honra).is_equal(10)
	assert_int(st.vint).is_equal(150 + 8 + 3 * 4)
	assert_int(st.xp).is_equal(5 + 3 * 2)
	assert_int(st.coragem).is_equal(4)
	assert_int(st.duelos.size()).is_equal(1)
	assert_str(st.duelos[0]["nome"]).is_equal("Rival 77")
	assert_bool(st.duelos[0]["win"]).is_true()
	assert_int(st.duelos[0]["honra"]).is_equal(10)
	assert_int(st.rivais.size()).is_equal(3)
	for r: Dictionary in st.rivais:
		assert_int(r["id"]).is_not_equal(77)
	var ev: Dictionary = Fx.find_event(res, "honra_alterada")
	assert_int(ev["delta"]).is_equal(10)
	assert_int(ev["honra"]).is_equal(10)
	assert_bool(Fx.types(res).has("luta")).is_true()


func test_duel_honor_depends_on_level_gap() -> void:
	var s: GameState = Fx.game(_rules)
	Fx.strong(s)
	s.lvl = 3
	s.rivais[0] = _rival(77, 6, 1)
	s.rivais[1] = _rival(78, 1, 1)
	assert_int(_duel(s, 77).state.honra).is_equal(19)
	assert_int(_duel(s, 78).state.honra).is_equal(5)


func test_duel_defeat_loses_up_to_four_honor() -> void:
	var s: GameState = Fx.game(_rules)
	Fx.weak(s)
	s.honra = 10
	s.rivais[0] = _rival(77, 1, 500)
	var res: CommandResult = _duel(s, 77)
	assert_int(res.state.honra).is_equal(6)
	assert_int(res.state.vint).is_equal(150)
	assert_int(res.state.coragem).is_equal(4)
	assert_bool(res.state.duelos[0]["win"]).is_false()
	assert_int(res.state.duelos[0]["honra"]).is_equal(-4)
	assert_int(Fx.find_event(res, "honra_alterada")["delta"]).is_equal(-4)
	s.honra = 3
	assert_int(_duel(s, 77).state.honra).is_equal(0)
	s.honra = 0
	assert_int(_duel(s, 77).state.honra).is_equal(0)


func test_duel_history_keeps_last_six() -> void:
	var s: GameState = Fx.game(_rules)
	Fx.strong(s)
	for i: int in 6:
		s.duelos.append({"nome": "Velho %d" % i, "win": true, "honra": 5})
	s.rivais[0] = _rival(77, 1, 1)
	var res: CommandResult = _duel(s, 77)
	assert_int(res.state.duelos.size()).is_equal(6)
	assert_str(res.state.duelos[0]["nome"]).is_equal("Rival 77")
	assert_str(res.state.duelos[5]["nome"]).is_equal("Velho 4")


func test_duel_errors_keep_state() -> void:
	var s: GameState = Fx.game(_rules)
	var id: int = s.rivais[0]["id"]
	var before: Dictionary = s.to_dict()
	assert_str(_duel(s, 31337).error).is_equal("NAO_ENCONTRADO")
	assert_str(Fx.run(s, "desafiar", {}, _rules).error).is_equal("NAO_ENCONTRADO")
	assert_dict(s.to_dict()).is_equal(before)
	s.coragem = 0
	s.co_upd_ms = Fx.T0
	before = s.to_dict()
	assert_str(_duel(s, id).error).is_equal("CORAGEM_INSUFICIENTE")
	assert_dict(s.to_dict()).is_equal(before)
