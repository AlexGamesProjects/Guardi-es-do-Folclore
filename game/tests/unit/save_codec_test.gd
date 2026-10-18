extends GdUnitTestSuite

const MAX_SEED: int = 2147483647

var _rules: RulesPack


func before() -> void:
	_rules = Fx.rules()


func _rich_state() -> GameState:
	var s: GameState = Fx.game(_rules, MAX_SEED)
	s.lvl = 7
	s.xp = 1234
	s.honra = 55
	s.cmd_counter = 99
	s.mochila.append(Fx.item(500, "corpo"))
	s.vitorias["curupira"] = 3
	s.vistos["curupira"] = true
	s.fases = PackedInt32Array([4, 2, 1])
	s.chefe_espera_ms = Fx.T0 + 90000
	s.ativa = {"id": 3, "fim_ms": Fx.T0 + 20000, "mission": {"xp": 40, "vint": 12}}
	s.duelos.append({"rival": 1, "win": true, "ts": Fx.T0})
	s.nome = 'Jaci "👍"'
	return s


func _assert_no_float(value: Variant, path: String) -> void:
	(
		assert_bool(typeof(value) == TYPE_FLOAT)
		. override_failure_message("float em %s" % path)
		. is_false()
	)
	if value is Dictionary:
		var d: Dictionary = value
		for k: Variant in d:
			_assert_no_float(d[k], "%s.%s" % [path, k])
	elif value is Array:
		var a: Array = value
		for i: int in a.size():
			_assert_no_float(a[i], "%s[%d]" % [path, i])


func test_roundtrip_keeps_int_types() -> void:
	var original: GameState = _rich_state()
	var text: String = SaveCodec.encode(original, _rules.rules_version)
	# O texto canônico não pode trazer inteiros escritos como 5.0.
	var re := RegEx.new()
	re.compile("[0-9]\\.0[,}\\]]")
	assert_bool(re.search(text) == null).is_true()
	var res: Dictionary = SaveCodec.decode(text, SaveMigrations.new())
	assert_bool(res["ok"]).is_true()
	assert_str(res["error"]).is_empty()
	var back: GameState = res["state"]
	assert_dict(back.to_dict()).is_equal(original.to_dict())
	assert_int(typeof(back.rng_seed)).is_equal(TYPE_INT)
	assert_int(back.rng_seed).is_equal(MAX_SEED)
	_assert_no_float(back.to_dict(), "state")
	for key: String in GameState._INT_FIELDS:
		assert_int(typeof(back.get(key))).override_failure_message(key).is_equal(TYPE_INT)
	assert_str(back.nome).is_equal(original.nome)


func test_envelope_has_expected_fields() -> void:
	var text: String = SaveCodec.encode(_rich_state(), "rv-x")
	var env: Dictionary = JSON.parse_string(text)
	assert_array(env.keys()).contains_exactly_in_any_order(
		["save_version", "rules_version", "profile", "state", "hash"]
	)
	assert_int(int(env["save_version"])).is_equal(SaveCodec.SAVE_VERSION)
	assert_str(env["rules_version"]).is_equal("rv-x")
	assert_dict(env["profile"]).is_equal({"id": "p1", "mode": "offline", "nome": 'Jaci "👍"'})
	assert_int(str(env["hash"]).length()).is_equal(64)


func test_tampered_byte_is_corrupt() -> void:
	var text: String = SaveCodec.encode(_rich_state(), _rules.rules_version)
	var tampered: String = text.replace('"honra":55', '"honra":56')
	assert_str(tampered).is_not_equal(text)
	var res: Dictionary = SaveCodec.decode(tampered, SaveMigrations.new())
	assert_bool(res["ok"]).is_false()
	assert_str(res["error"]).is_equal("CORROMPIDO")


func test_garbage_and_truncation_are_corrupt() -> void:
	var text: String = SaveCodec.encode(_rich_state(), _rules.rules_version)
	for bad: String in ["", "nao e json", "[1,2]", text.substr(0, text.length() / 2)]:
		var res: Dictionary = SaveCodec.decode(bad, SaveMigrations.new())
		assert_str(res["error"]).is_equal("CORROMPIDO")


func test_future_version_rejected() -> void:
	var env: Dictionary = JSON.parse_string(SaveCodec.encode(_rich_state(), "rv"))
	env.erase("hash")
	env["save_version"] = SaveCodec.SAVE_VERSION + 1
	env["hash"] = JSON.stringify(Defs.normalize(env), "", true).sha256_text()
	var res: Dictionary = SaveCodec.decode(JSON.stringify(env, "", true), SaveMigrations.new())
	assert_bool(res["ok"]).is_false()
	assert_str(res["error"]).is_equal("VERSAO_FUTURA")


func test_mode_edit_without_rehash_is_corrupt() -> void:
	var text: String = SaveCodec.encode(_rich_state(), "rv")
	var edited: String = text.replace('"mode":"offline"', '"mode":"online"')
	assert_str(edited).is_not_equal(text)
	var res: Dictionary = SaveCodec.decode(edited, SaveMigrations.new())
	assert_str(res["error"]).is_equal("CORROMPIDO")
