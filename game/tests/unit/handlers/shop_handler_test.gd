extends GdUnitTestSuite

var _rules: RulesPack


func before() -> void:
	_rules = Fx.rules()


func _occupy_all_slots(s: GameState) -> void:
	for slot: String in Defs.SLOT_KEYS:
		s.equip[slot] = Fx.item(500 + slot.length(), slot)


func test_buy_equips_when_slot_is_empty() -> void:
	var s: GameState = Fx.game(_rules)
	s.vint = 100000
	var offer: Dictionary = s.feira.filter(func(i: Dictionary) -> bool: return i["slot"] == "corpo")[0]
	var res: CommandResult = Fx.run(s, "comprar", {"item_id": offer["id"]}, _rules)
	assert_bool(res.ok).is_true()
	assert_int(res.state.equip["corpo"]["id"]).is_equal(offer["id"])
	assert_int(res.state.vint).is_equal(100000 - int(offer["preco"]))
	assert_int(res.state.feira.size()).is_equal(5)
	assert_array(res.state.mochila).is_empty()
	assert_str(Fx.find_event(res, "item_ganho")["destino"]).is_equal("equipado")


func test_buy_goes_to_bag_when_slot_is_taken() -> void:
	var s: GameState = Fx.game(_rules)
	s.vint = 100000
	_occupy_all_slots(s)
	var offer: Dictionary = s.feira[0]
	var res: CommandResult = Fx.run(s, "comprar", {"item_id": offer["id"]}, _rules)
	assert_bool(res.ok).is_true()
	assert_int(res.state.mochila.size()).is_equal(1)
	assert_int(res.state.mochila[0]["id"]).is_equal(offer["id"])
	assert_int(res.state.vint).is_equal(100000 - int(offer["preco"]))
	assert_str(Fx.find_event(res, "item_ganho")["destino"]).is_equal("mochila")


func test_buy_errors_keep_state() -> void:
	var s: GameState = Fx.game(_rules)
	var offer: Dictionary = s.feira[0]
	var before: Dictionary = s.to_dict()
	assert_str(Fx.run(s, "comprar", {"item_id": 424242}, _rules).error).is_equal("NAO_ENCONTRADO")
	s.vint = int(offer["preco"]) - 1
	before = s.to_dict()
	var poor: CommandResult = Fx.run(s, "comprar", {"item_id": offer["id"]}, _rules)
	assert_str(poor.error).is_equal("VINTENS_INSUFICIENTES")
	assert_dict(s.to_dict()).is_equal(before)
	s.vint = 100000
	_occupy_all_slots(s)
	Fx.fill_bag(s, _rules)
	before = s.to_dict()
	var full: CommandResult = Fx.run(s, "comprar", {"item_id": offer["id"]}, _rules)
	assert_str(full.error).is_equal("MOCHILA_CHEIA")
	assert_dict(s.to_dict()).is_equal(before)


func test_buy_with_exact_vintens() -> void:
	var s: GameState = Fx.game(_rules)
	var offer: Dictionary = s.feira[0]
	s.vint = int(offer["preco"])
	assert_int(Fx.run(s, "comprar", {"item_id": offer["id"]}, _rules).state.vint).is_equal(0)


func test_renew_shop_costs_one_muiraquita() -> void:
	var s: GameState = Fx.game(_rules)
	var old_ids: Array = s.feira.map(func(i: Dictionary) -> int: return i["id"])
	var res: CommandResult = Fx.run(s, "renovar_feira", {}, _rules, Fx.T0 + 5000)
	assert_bool(res.ok).is_true()
	assert_int(res.state.muir).is_equal(11)
	assert_int(res.state.feira.size()).is_equal(6)
	assert_int(res.state.feira_upd_ms).is_equal(Fx.T0 + 5000)
	for item: Dictionary in res.state.feira:
		assert_bool(old_ids.has(item["id"])).is_false()
	s.muir = 0
	var before: Dictionary = s.to_dict()
	assert_str(Fx.run(s, "renovar_feira", {}, _rules).error).is_equal("MUIRAQUITAS_INSUFICIENTES")
	assert_dict(s.to_dict()).is_equal(before)
