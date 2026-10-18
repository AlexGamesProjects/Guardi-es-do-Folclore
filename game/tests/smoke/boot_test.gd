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
	assert_bool(_boot.start(BROKEN, _root)).is_false()
	assert_int(_opened.size()).is_equal(1)
	assert_str(_opened[0]["path"]).is_equal("res://ui/erro_regras.tscn")
	assert_bool((_opened[0]["errors"] as PackedStringArray).is_empty()).is_false()


func test_boot_creates_offline_profile_once() -> void:
	assert_bool(_boot.start("res://data/packs/base", _root)).is_true()
	var first_seed: int = (_service().get_state() as GameState).rng_seed
	assert_bool(_boot.start("res://data/packs/base", _root)).is_true()
	assert_int((_service().get_state() as GameState).rng_seed).is_equal(first_seed)
	assert_str(_boot.last_warning).is_equal("")
	var profiles: Array[Dictionary] = SaveService.new(FileIO.new(), _root).list_profiles()
	assert_int(profiles.size()).is_equal(1)
	assert_str(profiles[0]["id"]).is_equal("solo")


func _service() -> Node:
	return Engine.get_main_loop().root.get_node("GameService")
