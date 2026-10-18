extends GdUnitTestSuite

const FIXTURE: String = "res://tests/fixtures/saves/v1_example.json"


func _step_1_to_2(env: Dictionary) -> Dictionary:
	# Passo de exemplo, só do teste: acrescenta um campo e muda a honra.
	var st: Dictionary = env["state"]
	st["campo_novo"] = "oi"
	st["honra"] = int(st["honra"]) + 10
	return env


func test_production_table_is_empty() -> void:
	var m := SaveMigrations.new()
	assert_int(m.target()).is_equal(SaveCodec.SAVE_VERSION)
	var env: Dictionary = {"save_version": SaveCodec.SAVE_VERSION, "state": {}}
	assert_dict(m.migrate(env)).is_equal(env)


func test_example_migration_applies() -> void:
	var raw: String = FileAccess.get_file_as_string(FIXTURE)
	assert_str(raw).is_not_empty()
	var m := SaveMigrations.new({1: _step_1_to_2}, 2)
	var env: Dictionary = Defs.normalize(JSON.parse_string(raw))
	assert_int(int(env["save_version"])).is_equal(1)
	var out: Dictionary = m.migrate(env)
	assert_int(out["save_version"]).is_equal(2)
	assert_str(out["state"]["campo_novo"]).is_equal("oi")
	assert_int(out["state"]["honra"]).is_equal(int(env["state"]["honra"]) + 10)
	# O original não é alterado.
	assert_bool((env["state"] as Dictionary).has("campo_novo")).is_false()


func test_decode_runs_migration_on_fixture() -> void:
	var raw: String = FileAccess.get_file_as_string(FIXTURE)
	var res: Dictionary = SaveCodec.decode(raw, SaveMigrations.new({1: _step_1_to_2}, 2))
	assert_bool(res["ok"]).is_true()
	var plain: Dictionary = SaveCodec.decode(raw, SaveMigrations.new())
	assert_int((res["state"] as GameState).honra).is_equal((plain["state"] as GameState).honra + 10)


func test_missing_step_is_corrupt() -> void:
	var raw: String = FileAccess.get_file_as_string(FIXTURE)
	var res: Dictionary = SaveCodec.decode(raw, SaveMigrations.new({}, 3))
	assert_str(res["error"]).is_equal("CORROMPIDO")


func test_steps_chain_in_order() -> void:
	var log: Array[int] = []
	var m := SaveMigrations.new(
		{
			1:
			func(e: Dictionary) -> Dictionary:
				# Passo de exemplo, só do teste: acrescenta um campo e muda a honra.

				# O original não é alterado.

				log.append(1)
				return e,
			2:
			func(e: Dictionary) -> Dictionary:
				# Passo de exemplo, só do teste: acrescenta um campo e muda a honra.

				# O original não é alterado.

				log.append(2)
				return e,
		},
		3
	)
	var out: Dictionary = m.migrate({"save_version": 1, "state": {}})
	assert_array(log).is_equal([1, 2])
	assert_int(out["save_version"]).is_equal(3)
