extends GdUnitTestSuite


func test_command_roundtrip_through_json() -> void:
	var c: Command = Command.make("treinar", {"stat": "for", "n": 3}, 2147483000, 1234567, "1.0.0")
	var parsed: Variant = JSON.parse_string(JSON.stringify(c.to_dict()))
	var back: Command = Command.from_dict(parsed)
	assert_str(back.type).is_equal("treinar")
	assert_str(back.params["stat"]).is_equal("for")
	assert_int(typeof(back.params["n"])).is_equal(TYPE_INT)
	assert_int(typeof(back.seed)).is_equal(TYPE_INT)
	assert_int(back.seed).is_equal(2147483000)
	assert_int(typeof(back.now_ms)).is_equal(TYPE_INT)
	assert_int(back.now_ms).is_equal(1234567)
	assert_str(back.rules_version).is_equal("1.0.0")


func test_result_helpers() -> void:
	var rules: RulesPack = Fx.rules()
	var s: GameState = Fx.game(rules)
	var ok: CommandResult = CommandResult.success(s, [{"type": "xp_ganho", "amount": 1}])
	assert_bool(ok.ok).is_true()
	assert_str(ok.error).is_empty()
	assert_int(ok.events.size()).is_equal(1)
	assert_object(ok.state).is_same(s)
	var bad: CommandResult = CommandResult.fail(s, "SEM_MISSAO")
	assert_bool(bad.ok).is_false()
	assert_str(bad.error).is_equal("SEM_MISSAO")
	assert_array(bad.events).is_empty()
	assert_object(bad.state).is_same(s)
