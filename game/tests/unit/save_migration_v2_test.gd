extends GdUnitTestSuite
## Save: a versão atual e a migração 1→2 (o campo `origem`; perfis antigos viram "legado").

const FIXTURE: String = "res://tests/fixtures/saves/v1_example.json"


func _v1() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))


func test_versao_do_save_e_3() -> void:
	assert_int(SaveCodec.SAVE_VERSION).is_equal(3)


func test_migra_v1_para_v2_legado() -> void:
	var env: Dictionary = SaveMigrations.new({}, 2).migrate(_v1())
	assert_int(int(env["save_version"])).is_equal(2)
	assert_str(str(env["state"]["origem"])).is_equal("legado")


func test_migra_v1_sem_campos_opcionais() -> void:
	var env: Dictionary = _v1()
	var st: Dictionary = env["state"]
	for k: String in ["duelos", "vistos", "rivais", "feira"]:
		st.erase(k)
	var out: Dictionary = SaveMigrations.new().migrate(env)
	assert_str(str(out["state"]["origem"])).is_equal("legado")
	var state: GameState = GameState.from_dict(out["state"])
	assert_str(state.origem).is_equal("legado")


func test_estado_novo_sem_origem_vai_e_volta() -> void:
	var s: GameState = Fx.game(Fx.rules())
	assert_str(s.origem).is_equal("")
	s.origem = "pampa"
	assert_str(GameState.from_dict(s.to_dict()).origem).is_equal("pampa")
