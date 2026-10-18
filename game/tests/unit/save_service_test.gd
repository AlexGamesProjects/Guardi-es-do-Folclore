extends GdUnitTestSuite

var _rules: RulesPack
var _root: String
var _io: FileIO
var _svc: SaveService


func before() -> void:
	_rules = Fx.rules()


func before_test() -> void:
	_root = TempDir.make()
	_io = FileIO.new()
	_svc = SaveService.new(_io, _root)


func after_test() -> void:
	TempDir.remove(_root)


func _p(id: String, ext: String) -> String:
	return "%s/%s.%s" % [_root, id, ext]


func _state(id: String = "p1", mode: String = "offline", honra: int = 0) -> GameState:
	var s: GameState = GameState.new_game(id, mode, "Jaci", 7, Fx.T0, _rules)
	s.honra = honra
	return s


func _fresh(id: String, mode: String) -> Callable:
	return func() -> GameState: return GameState.new_game(id, mode, "Jaci", 7, Fx.T0, _rules)


func test_save_then_load_returns_same_state() -> void:
	var s: GameState = _state("p1", "offline", 5)
	assert_bool(_svc.save(s, _rules.rules_version, _rules.schema_version)).is_true()
	assert_bool(_io.exists(_p("p1", "tmp"))).is_false()
	var env: Dictionary = JSON.parse_string(_io.read(_p("p1", "json")))
	assert_int(int(env["schema_version"])).is_equal(_rules.schema_version)
	var res: Dictionary = _svc.load("p1", "offline")
	assert_str(res["warning"]).is_empty()
	assert_dict((res["state"] as GameState).to_dict()).is_equal(s.to_dict())


func test_backups_rotate_up_to_two() -> void:
	for h: int in [1, 2, 3, 4]:
		assert_bool(_svc.save(_state("p1", "offline", h), "rv")).is_true()
	assert_int(_svc.load("p1", "offline")["state"].honra).is_equal(4)
	var b1: Dictionary = SaveCodec.decode(_io.read(_p("p1", "bak1")), SaveMigrations.new())
	var b2: Dictionary = SaveCodec.decode(_io.read(_p("p1", "bak2")), SaveMigrations.new())
	assert_int((b1["state"] as GameState).honra).is_equal(3)
	assert_int((b2["state"] as GameState).honra).is_equal(2)


func test_main_corrupt_uses_backup_with_warning() -> void:
	_svc.save(_state("p1", "offline", 1), "rv")
	_svc.save(_state("p1", "offline", 2), "rv")
	_io.write(_p("p1", "json"), "lixo{{")
	var res: Dictionary = _svc.load("p1", "offline")
	assert_str(res["warning"]).is_equal("RESERVA_USADA")
	assert_int((res["state"] as GameState).honra).is_equal(1)


func test_second_backup_used_when_main_and_first_corrupt() -> void:
	for h: int in [1, 2, 3]:
		_svc.save(_state("p1", "offline", h), "rv")
	_io.write(_p("p1", "json"), "x")
	_io.write(_p("p1", "bak1"), "y")
	var res: Dictionary = _svc.load("p1", "offline")
	assert_str(res["warning"]).is_equal("RESERVA_USADA")
	assert_int((res["state"] as GameState).honra).is_equal(1)


func test_all_copies_corrupt_starts_fresh_with_warning() -> void:
	for h: int in [1, 2, 3]:
		_svc.save(_state("p1", "online", h), "rv")
	for ext: String in ["json", "bak1", "bak2"]:
		_io.write(_p("p1", ext), "corrompido")
	var res: Dictionary = _svc.load("p1", "online", _fresh("p1", "online"))
	assert_str(res["warning"]).is_equal("SAVE_RECRIADO")
	var s: GameState = res["state"]
	assert_str(s.profile_id).is_equal("p1")
	assert_str(s.mode).is_equal("online")
	assert_int(s.honra).is_equal(0)
	assert_int(s.lvl).is_equal(1)


func test_missing_profile_starts_fresh_even_without_factory() -> void:
	var res: Dictionary = _svc.load("novo", "offline")
	assert_str(res["warning"]).is_equal("SAVE_RECRIADO")
	assert_str((res["state"] as GameState).profile_id).is_equal("novo")
	assert_str((res["state"] as GameState).mode).is_equal("offline")


func test_copy_of_other_mode_is_not_accepted() -> void:
	_svc.save(_state("p1", "online", 9), "rv")
	var res: Dictionary = _svc.load("p1", "offline", _fresh("p1", "offline"))
	assert_str(res["warning"]).is_equal("SAVE_RECRIADO")
	assert_str((res["state"] as GameState).mode).is_equal("offline")
	assert_int((res["state"] as GameState).honra).is_equal(0)


func test_write_failure_keeps_previous_file() -> void:
	assert_bool(_svc.save(_state("p1", "offline", 1), "rv")).is_true()
	assert_bool(_svc.save(_state("p1", "offline", 2), "rv")).is_true()
	var before_main: String = _io.read(_p("p1", "json"))
	var before_bak1: String = _io.read(_p("p1", "bak1"))
	var failing := FailingFileIO.new()
	var svc := SaveService.new(failing, _root)
	assert_bool(svc.save(_state("p1", "offline", 3), "rv")).is_false()
	assert_str(_io.read(_p("p1", "json"))).is_equal(before_main)
	assert_str(_io.read(_p("p1", "bak1"))).is_equal(before_bak1)
	assert_bool(_io.exists(_p("p1", "tmp"))).is_false()
	assert_int(_svc.load("p1", "offline")["state"].honra).is_equal(2)


func test_corrupt_main_does_not_push_good_backup_out() -> void:
	for h: int in [1, 2]:
		_svc.save(_state("p1", "offline", h), "rv")
	_io.write(_p("p1", "json"), "quebrado")
	_svc.save(_state("p1", "offline", 3), "rv")
	_svc.save(_state("p1", "offline", 4), "rv")
	var b2: Dictionary = SaveCodec.decode(_io.read(_p("p1", "bak2")), SaveMigrations.new())
	assert_bool(b2["ok"]).is_true()
	assert_int((b2["state"] as GameState).honra).is_equal(1)


func test_unsafe_profile_id_is_not_saved() -> void:
	assert_bool(_svc.save(_state("../fora", "offline"), "rv")).is_false()
	assert_bool(_svc.save(_state("", "offline"), "rv")).is_false()


func test_future_version_copy_is_set_aside_not_deleted() -> void:
	_svc.save(_state("p1", "offline", 1), "rv")
	var env: Dictionary = JSON.parse_string(_io.read(_p("p1", "json")))
	env.erase("hash")
	env["save_version"] = SaveCodec.SAVE_VERSION + 1
	env["hash"] = JSON.stringify(Defs.normalize(env), "", true).sha256_text()
	_io.write(_p("p1", "json"), JSON.stringify(env, "", true))
	var res: Dictionary = _svc.load("p1", "offline", _fresh("p1", "offline"))
	assert_str(res["warning"]).is_equal("SAVE_RECRIADO")
	assert_bool(_io.exists(_p("p1", "json.futuro"))).is_true()


func test_list_profiles_shows_mode() -> void:
	var a: GameState = _state("a1", "offline")
	a.lvl = 4
	_svc.save(a, "rv")
	_svc.save(_state("b2", "online"), "rv")
	var list: Array[Dictionary] = _svc.list_profiles()
	assert_int(list.size()).is_equal(2)
	assert_dict(list[0]).is_equal({"id": "a1", "mode": "offline", "nome": "Jaci", "lvl": 4})
	assert_str(list[1]["id"]).is_equal("b2")
	assert_str(list[1]["mode"]).is_equal("online")


func test_list_profiles_uses_backup_when_main_corrupt() -> void:
	_svc.save(_state("a1", "offline"), "rv")
	_svc.save(_state("a1", "offline"), "rv")
	_io.write(_p("a1", "json"), "x")
	assert_int(_svc.list_profiles().size()).is_equal(1)


func test_list_profiles_empty_when_no_folder() -> void:
	assert_int(_svc.list_profiles().size()).is_equal(0)


func test_load_with_unsafe_id_starts_fresh_without_touching_disk() -> void:
	# Um save válido, com honra distinta, no lugar exato a que "../x" aponta fora da raiz.
	DirAccess.make_dir_recursive_absolute(_root)
	var outside: String = "%s/../x.json" % _root
	var planted: GameState = _state("../x", "offline", 777)
	assert_bool(_io.write(outside, SaveCodec.encode(planted, "rv"))).is_true()
	var planted_text: String = _io.read(outside)
	var spy := SpyFileIO.new()
	var svc := SaveService.new(spy, _root)
	var res: Dictionary = svc.load("../x", "offline", _fresh("../x", "offline"))
	assert_str(res["warning"]).is_equal("SAVE_RECRIADO")
	assert_int((res["state"] as GameState).honra).is_not_equal(777)
	assert_int((res["state"] as GameState).honra).is_equal(0)
	assert_int(spy.calls.size()).is_equal(0)
	assert_str(_io.read(outside)).is_equal(planted_text)
	assert_bool(_io.exists("%s/../x.json.futuro" % _root)).is_false()
	_io.remove(outside)


func test_id_with_trailing_newline_is_rejected() -> void:
	assert_bool(_svc.save(_state("abc\n", "offline"), "rv")).is_false()
	var res: Dictionary = _svc.load("abc\n", "offline")
	assert_str(res["warning"]).is_equal("SAVE_RECRIADO")


func test_final_rename_failure_rolls_back_and_keeps_previous_save() -> void:
	_svc.save(_state("p1", "offline", 1), "rv")
	_svc.save(_state("p1", "offline", 2), "rv")
	var before_main: String = _io.read(_p("p1", "json"))
	var svc := SaveService.new(TmpRenameFailsIO.new(), _root)
	assert_bool(svc.save(_state("p1", "offline", 3), "rv")).is_false()
	assert_str(_io.read(_p("p1", "json"))).is_equal(before_main)
	assert_bool(_io.exists(_p("p1", "tmp"))).is_false()
	assert_int(_svc.load("p1", "offline")["state"].honra).is_equal(2)


class TmpRenameFailsIO:
	extends FileIO

	func rename(from: String, to: String) -> bool:
		if from.ends_with(".tmp"):
			return false
		return super.rename(from, to)


class SpyFileIO:
	extends FileIO
	var calls: Array[String] = []

	func read(path: String) -> String:
		calls.append("read " + path)
		return super.read(path)

	func rename(from: String, to: String) -> bool:
		calls.append("rename " + from)
		return super.rename(from, to)

	func write(path: String, text: String) -> bool:
		calls.append("write " + path)
		return super.write(path, text)

	func remove(path: String) -> bool:
		calls.append("remove " + path)
		return super.remove(path)
