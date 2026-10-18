extends GdUnitTestSuite

var _rules: RulesPack


func before() -> void:
	_rules = Fx.rules()


func _name_after(raw: String) -> String:
	var res: CommandResult = Fx.run(Fx.game(_rules), "renomear", {"nome": raw}, _rules)
	assert_bool(res.ok).is_true()
	return res.state.nome


func test_rename_sanitizes() -> void:
	assert_str(_name_after("  Ana  ")).is_equal("Ana")
	assert_str(_name_after("")).is_equal("Jaci")
	assert_str(_name_after("   ")).is_equal("Jaci")
	assert_str(_name_after("\n\n")).is_equal("Jaci")
	assert_str(_name_after("x".repeat(200))).is_equal("x".repeat(18))
	assert_str(_name_after('Zé "Saci"\t🌿')).is_equal('Zé "Saci"🌿')
	assert_str(_name_after("a\nb\r\nc")).is_equal("abc")
	assert_str(_name_after("  " + "y".repeat(17) + "  z")).is_equal("y".repeat(17))


func test_rename_state_survives_json() -> void:
	for raw: String in ['Zé "Saci"\t🌿', '\\"}{', "x".repeat(200), "a\nb"]:
		var res: CommandResult = Fx.run(Fx.game(_rules), "renomear", {"nome": raw}, _rules)
		var text: String = JSON.stringify(res.state.to_dict())
		var parsed: Variant = JSON.parse_string(text)
		assert_bool(parsed is Dictionary).is_true()
		assert_str(GameState.from_dict(parsed).nome).is_equal(res.state.nome)
		assert_int(res.state.nome.length()).is_between(1, 18)


func test_rename_with_missing_or_wrong_param_uses_default() -> void:
	var s: GameState = Fx.game(_rules)
	s.nome = "Outro"
	assert_str(Fx.run(s, "renomear", {}, _rules).state.nome).is_equal("Jaci")
	assert_str(Fx.run(s, "renomear", {"nome": 12}, _rules).state.nome).is_equal("Jaci")
