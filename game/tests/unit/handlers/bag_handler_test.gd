extends GdUnitTestSuite

var _rules: RulesPack


func before() -> void:
	_rules = Fx.rules()


func test_equip_into_empty_slot() -> void:
	var s: GameState = Fx.game(_rules)
	s.mochila.append(Fx.item(60, "cabeca"))
	var res: CommandResult = Fx.run(s, "equipar", {"item_id": 60}, _rules)
	assert_bool(res.ok).is_true()
	assert_int(res.state.equip["cabeca"]["id"]).is_equal(60)
	assert_array(res.state.mochila).is_empty()


func test_equip_swaps_with_current_item_even_with_full_bag() -> void:
	var s: GameState = Fx.game(_rules)
	Fx.fill_bag(s, _rules)
	s.mochila[3] = Fx.item(60, "arma")
	var res: CommandResult = Fx.run(s, "equipar", {"item_id": 60}, _rules)
	assert_bool(res.ok).is_true()
	assert_int(res.state.equip["arma"]["id"]).is_equal(60)
	assert_int(res.state.mochila.size()).is_equal(14)
	var ids: Array = res.state.mochila.map(func(i: Dictionary) -> int: return i["id"])
	assert_bool(ids.has(1)).is_true()
	assert_bool(ids.has(60)).is_false()


func test_equip_not_found() -> void:
	var s: GameState = Fx.game(_rules)
	var before: Dictionary = s.to_dict()
	var res: CommandResult = Fx.run(s, "equipar", {"item_id": 777}, _rules)
	assert_str(res.error).is_equal("NAO_ENCONTRADO")
	assert_dict(s.to_dict()).is_equal(before)
	assert_str(Fx.run(s, "equipar", {}, _rules).error).is_equal("NAO_ENCONTRADO")


func test_unequip_moves_item_to_bag() -> void:
	var s: GameState = Fx.game(_rules)
	var res: CommandResult = Fx.run(s, "desequipar", {"slot": "arma"}, _rules)
	assert_bool(res.ok).is_true()
	assert_object(res.state.equip["arma"]).is_null()
	assert_int(res.state.mochila.size()).is_equal(1)
	assert_int(res.state.mochila[0]["id"]).is_equal(1)


func test_unequip_full_bag() -> void:
	var s: GameState = Fx.game(_rules)
	Fx.fill_bag(s, _rules)
	var before: Dictionary = s.to_dict()
	var res: CommandResult = Fx.run(s, "desequipar", {"slot": "arma"}, _rules)
	assert_str(res.error).is_equal("MOCHILA_CHEIA")
	assert_dict(s.to_dict()).is_equal(before)


func test_unequip_empty_or_invalid_slot() -> void:
	var s: GameState = Fx.game(_rules)
	var before: Dictionary = s.to_dict()
	for params: Dictionary in [{"slot": "corpo"}, {"slot": "pe"}, {}]:
		assert_str(Fx.run(s, "desequipar", params, _rules).error).is_equal("NAO_ENCONTRADO")
	assert_dict(s.to_dict()).is_equal(before)


func test_sell_pays_thirty_percent_rounded() -> void:
	var s: GameState = Fx.game(_rules)
	s.mochila.append(Fx.item(60, "corpo", 100))
	s.mochila.append(Fx.item(61, "corpo", 15))
	var res: CommandResult = Fx.run(s, "vender", {"item_id": 60}, _rules)
	assert_bool(res.ok).is_true()
	assert_int(res.state.vint).is_equal(180)
	assert_int(res.state.mochila.size()).is_equal(1)
	assert_int(Fx.find_event(res, "vintens_ganhos")["amount"]).is_equal(30)
	var res2: CommandResult = Fx.run(s, "vender", {"item_id": 61}, _rules)
	assert_int(res2.state.vint).is_equal(155)


func test_sell_not_found() -> void:
	var s: GameState = Fx.game(_rules)
	var before: Dictionary = s.to_dict()
	var res: CommandResult = Fx.run(s, "vender", {"item_id": 5}, _rules)
	assert_str(res.error).is_equal("NAO_ENCONTRADO")
	assert_dict(s.to_dict()).is_equal(before)
