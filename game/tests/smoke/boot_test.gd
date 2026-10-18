extends GdUnitTestSuite

const BOOT_SCRIPT: GDScript = preload("res://app/boot.gd")
const BROKEN: String = "res://tests/fixtures/packs/broken_bad_ref"

var _root: String
var _boot: Node
var _opened: Array[Dictionary]


func before_test() -> void:
	_root = TempDir.make()
	_opened = []
	_boot = auto_free(BOOT_SCRIPT.new())
	_boot.opener = func(path: String, errors: PackedStringArray) -> void:
		_opened.append({"path": path, "errors": errors})


func after_test() -> void:
	# Não deixa o autoload com o SaveService da pasta temporária.
	_service().setup(null, null, null, null, null)
	TempDir.remove(_root)


func test_boot_ok_opens_menu() -> void:
	assert_bool(_boot.start("res://data/packs/base", _root)).is_true()
	assert_int(_opened.size()).is_equal(1)
	assert_str(_opened[0]["path"]).is_equal("res://ui/menu.tscn")
	var state: GameState = _service().get_state() as GameState
	assert_str(state.profile_id).is_equal("solo")
	assert_str(state.mode).is_equal("offline")
	assert_int(state.rng_seed).is_between(0, 0x7FFFFFFF)
	assert_bool(SaveService.new(FileIO.new(), _root).list_profiles().is_empty()).is_false()


func test_boot_broken_pack_shows_error() -> void:
	_service().setup(null, null, null, null, null)
	assert_bool(_boot.start(BROKEN, _root)).is_false()
	assert_int(_opened.size()).is_equal(1)
	assert_str(_opened[0]["path"]).is_equal("res://ui/erro_regras.tscn")
	assert_bool((_opened[0]["errors"] as PackedStringArray).is_empty()).is_false()
	assert_bool(SaveService.new(FileIO.new(), _root).list_profiles().is_empty()).is_true()
	assert_object(_service().get_state()).is_null()


func test_boot_creates_offline_profile_once() -> void:
	assert_bool(_boot.start("res://data/packs/base", _root)).is_true()
	var first_seed: int = (_service().get_state() as GameState).rng_seed
	assert_array(_boot.warnings).is_empty()
	var second: Node = auto_free(BOOT_SCRIPT.new())
	second.opener = _boot.opener
	assert_bool(second.start("res://data/packs/base", _root)).is_true()
	assert_int((_service().get_state() as GameState).rng_seed).is_equal(first_seed)
	assert_str(second.last_warning).is_equal("")
	var profiles: Array[Dictionary] = SaveService.new(FileIO.new(), _root).list_profiles()
	assert_int(profiles.size()).is_equal(1)
	assert_str(profiles[0]["id"]).is_equal("solo")


func _service() -> Node:
	return Engine.get_main_loop().root.get_node("GameService")


func test_corrupt_profile_warns_save_recriado() -> void:
	FileIO.new().write("%s/solo.json" % _root, "{ nao e save")
	assert_bool(_boot.start("res://data/packs/base", _root)).is_true()
	assert_array(_boot.warnings).contains(["SAVE_RECRIADO"])
	assert_array(_boot.warnings).not_contains(["SAVE_FALHOU"])


func test_write_failure_warns_save_falhou() -> void:
	var io: FileIO = FailingFileIO.new()
	assert_bool(_boot.start("res://data/packs/base", _root, io)).is_true()
	assert_array(_boot.warnings).contains(["SAVE_FALHOU"])
	assert_array(_boot.warnings).not_contains(["SAVE_RECRIADO"])


func test_second_start_returns_cached_result() -> void:
	assert_bool(_boot.start("res://data/packs/base", _root)).is_true()
	assert_bool(_boot.start(BROKEN, _root)).is_true()
	assert_int(_opened.size()).is_equal(1)
