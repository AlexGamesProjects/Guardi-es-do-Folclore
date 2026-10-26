extends GdUnitTestSuite
## Save versão 3: o campo `visual` e a migração 2→3 (perfis antigos ficam com o visual padrão).

const FIXTURE: String = "res://tests/fixtures/saves/v1_example.json"


func _v1() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))


func test_migra_v1_ate_v3_com_visual_padrao() -> void:
	var env: Dictionary = SaveMigrations.new().migrate(_v1())
	assert_int(int(env["save_version"])).is_equal(3)
	assert_dict(env["state"]["visual"]).is_equal(VisualRules.PADRAO)
	assert_str(str(env["state"]["origem"])).is_equal("legado")


func test_decode_de_save_v1_traz_visual_padrao() -> void:
	var raw: String = FileAccess.get_file_as_string(FIXTURE)
	var res: Dictionary = SaveCodec.decode(raw, SaveMigrations.new())
	assert_bool(res["ok"]).is_true()
	assert_dict((res["state"] as GameState).visual).is_equal(VisualRules.PADRAO)


func test_visual_vai_e_volta_no_save() -> void:
	var s: GameState = Fx.game(Fx.rules())
	s.visual["cabelo"] = 3
	s.visual["pele"] = 4
	var texto: String = SaveCodec.encode(s, "1.0.0")
	var res: Dictionary = SaveCodec.decode(texto, SaveMigrations.new())
	assert_bool(res["ok"]).is_true()
	var volta: GameState = res["state"]
	assert_int(int(volta.visual["cabelo"])).is_equal(3)
	assert_int(int(volta.visual["pele"])).is_equal(4)


func test_estado_sem_visual_le_o_padrao() -> void:
	var d: Dictionary = Fx.game(Fx.rules()).to_dict()
	d.erase("visual")
	assert_dict(GameState.from_dict(d).visual).is_equal(VisualRules.PADRAO)
