extends GdUnitTestSuite

var _rules: RulesPack


func before() -> void:
	_rules = Fx.rules()


func test_new_game_defaults() -> void:
	var s: GameState = GameState.new_game("p1", "offline", "  Ana ", 123, Fx.T0, _rules)
	assert_str(s.profile_id).is_equal("p1")
	assert_str(s.mode).is_equal("offline")
	assert_str(s.nome).is_equal("Ana")
	assert_int(s.lvl).is_equal(1)
	assert_int(s.xp).is_equal(0)
	assert_int(s.vint).is_equal(150)
	assert_int(s.muir).is_equal(12)
	assert_int(s.energia).is_equal(100)
	assert_int(s.en_upd_ms).is_equal(Fx.T0)
	assert_int(s.coragem).is_equal(5)
	assert_int(s.co_upd_ms).is_equal(Fx.T0)
	assert_int(s.honra).is_equal(0)
	assert_dict(s.stats).is_equal({"for": 10, "fol": 10, "mal": 8, "gin": 8})
	assert_int(s.fases.size()).is_equal(3)
	assert_int(s.rng_seed).is_equal(123)
	assert_int(s.cmd_counter).is_equal(1)
	assert_int(s.chefe_espera_ms).is_equal(0)
	assert_bool(s.ativa.is_empty()).is_true()
	assert_array(s.mochila).is_empty()


func test_new_game_starts_with_weapon_and_filled_lists() -> void:
	var s: GameState = Fx.game(_rules)
	var arma: Dictionary = s.equip["arma"]
	assert_str(arma["nome"]).is_equal("Estilingue de Goiabeira")
	assert_int(arma["id"]).is_equal(1)
	assert_int(arma["st"]["for"]).is_equal(4)
	for slot: String in ["cabeca", "corpo", "amuleto"]:
		assert_object(s.equip[slot]).is_null()
	assert_int(s.ofertas.size()).is_equal(3)
	assert_int(s.rivais.size()).is_equal(3)
	assert_int(s.feira.size()).is_equal(6)
	assert_int(s.feira_upd_ms).is_equal(Fx.T0)
	assert_int(s.uid).is_greater(12)


func test_new_game_reserves_seed_index_zero() -> void:
	var s: GameState = Fx.game(_rules, 123)
	assert_int(s.cmd_counter).is_equal(1)
	assert_int(Rng.derive_seed(s.rng_seed, s.cmd_counter)).is_not_equal(
		Rng.derive_seed(s.rng_seed, 0)
	)


func test_new_game_is_deterministic_per_seed() -> void:
	var a: GameState = Fx.game(_rules, 5)
	var b: GameState = Fx.game(_rules, 5)
	var c: GameState = Fx.game(_rules, 6)
	assert_dict(a.to_dict()).is_equal(b.to_dict())
	assert_dict(a.to_dict()).is_not_equal(c.to_dict())


func test_total_stats_adds_equipment() -> void:
	var s: GameState = Fx.game(_rules)
	var t: Dictionary = s.total_stats()
	assert_int(t["for"]).is_equal(14)
	assert_int(t["gin"]).is_equal(9)
	assert_int(t["fol"]).is_equal(10)
	assert_int(t["mal"]).is_equal(8)
	s.equip["corpo"] = Fx.item(50, "corpo", 10, {"fol": 5, "mal": 2})
	assert_int(s.total_stats()["fol"]).is_equal(15)
	assert_int(s.stats["fol"]).is_equal(10)


func test_clone_is_deep() -> void:
	var s: GameState = Fx.game(_rules)
	s.mochila.append(Fx.item(60, "corpo"))
	var before: Dictionary = s.to_dict()
	var c: GameState = s.clone()
	assert_dict(c.to_dict()).is_equal(before)
	c.stats["for"] = 99
	c.mochila[0]["preco"] = 1
	c.mochila.append(Fx.item(61, "arma"))
	c.equip["arma"]["st"]["for"] = 77
	c.ofertas[0]["xp"] = -5
	c.rivais[0]["st"]["for"] = -5
	c.feira.clear()
	c.fases[1] = 4
	c.vistos["x"] = true
	c.vitorias["y"] = 2
	c.duelos.append({"nome": "a"})
	c.lvl = 9
	assert_dict(s.to_dict()).is_equal(before)


func test_roundtrip_through_json_keeps_int_types() -> void:
	var s: GameState = GameState.new_game("p9", "online", "Zé", 2147483000, Fx.T0, _rules)
	s.mochila.append(Fx.item(60, "corpo"))
	s.ativa = {"id": 4, "c": "saci", "luta": true, "d": 1, "f": 0, "fim_ms": Fx.T0 + 5}
	s.duelos.append({"nome": "Rival", "win": true, "honra": 7})
	s.vistos["saci"] = true
	s.vitorias["saci"] = 3
	s.fases[2] = 4
	var parsed: Variant = JSON.parse_string(JSON.stringify(s.to_dict()))
	var back: GameState = GameState.from_dict(parsed)
	assert_dict(back.to_dict()).is_equal(s.to_dict())
	assert_int(typeof(back.rng_seed)).is_equal(TYPE_INT)
	assert_int(back.rng_seed).is_equal(2147483000)
	for v: int in [back.lvl, back.xp, back.vint, back.muir, back.energia, back.en_upd_ms]:
		assert_int(typeof(v)).is_equal(TYPE_INT)
	for v: int in [back.coragem, back.co_upd_ms, back.honra, back.uid, back.missoes]:
		assert_int(typeof(v)).is_equal(TYPE_INT)
	assert_int(typeof(back.stats["for"])).is_equal(TYPE_INT)
	assert_int(typeof(back.equip["arma"]["st"]["for"])).is_equal(TYPE_INT)
	assert_int(typeof(back.equip["arma"]["id"])).is_equal(TYPE_INT)
	assert_int(typeof(back.ofertas[0]["id"])).is_equal(TYPE_INT)
	assert_int(typeof(back.ofertas[0]["xp"])).is_equal(TYPE_INT)
	assert_int(typeof(back.rivais[0]["st"]["for"])).is_equal(TYPE_INT)
	assert_int(typeof(back.feira[0]["preco"])).is_equal(TYPE_INT)
	assert_int(typeof(back.ativa["fim_ms"])).is_equal(TYPE_INT)
	assert_int(typeof(back.duelos[0]["honra"])).is_equal(TYPE_INT)
	assert_int(typeof(back.vitorias["saci"])).is_equal(TYPE_INT)
	assert_int(typeof(back.fases[2])).is_equal(TYPE_INT)
	assert_str(back.profile_id).is_equal("p9")
	assert_str(back.mode).is_equal("online")
