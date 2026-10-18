extends GdUnitTestSuite

var _rules: RulesPack


func before() -> void:
	_rules = Fx.rules()


func _script(svc: Node, s: GameState) -> Array[CommandResult]:
	var out: Array[CommandResult] = []
	out.append(await svc.send("treinar", {"stat": "for"}))
	var mission_id: int = int(s.ofertas[0]["id"])
	out.append(await svc.send("iniciar_missao", {"mission_id": mission_id}))
	out.append(await svc.send("acelerar_missao", {}))
	out.append(await svc.send("concluir_missao", {}))
	out.append(await svc.send("enfrentar_fase", {"act": 0, "n": 0}))
	return out


func _run_with(executor: CommandExecutor) -> Dictionary:
	var svc: Node = auto_free(load("res://app/game_service.gd").new())
	var s: GameState = Fx.game(_rules)
	svc.call("setup", _rules, executor, FakeClock.new(Fx.T0), s)
	var results: Array[CommandResult] = await _script(svc, s)
	var oks: Array[bool] = []
	for r: CommandResult in results:
		oks.append(r.ok)
	var final_state: GameState = svc.get("state")
	return {"state": final_state.to_dict(), "oks": oks}


func test_executor_parity() -> void:
	var started: int = Time.get_ticks_msec()
	var local: Dictionary = await _run_with(LocalExecutor.new(_rules))
	var delayed: Dictionary = await _run_with(DelayedExecutor.new(LocalExecutor.new(_rules), 500))
	print("PARITY_MS=", Time.get_ticks_msec() - started)
	assert_array(local["oks"]).is_equal(delayed["oks"])
	assert_bool((local["oks"] as Array)[0]).is_true()
	assert_dict(local["state"]).is_equal(delayed["state"])
