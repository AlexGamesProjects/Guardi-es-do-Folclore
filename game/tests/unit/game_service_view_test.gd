extends GdUnitTestSuite

var _rules: RulesPack
var _clock: FakeClock
var _svc: Node


func before() -> void:
	_rules = Fx.rules()


func before_test() -> void:
	_clock = FakeClock.new(Fx.T0)
	_svc = auto_free(load("res://app/game_service.gd").new())


func _setup_service() -> GameState:
	var s: GameState = Fx.game(_rules)
	_svc.call("setup", _rules, LocalExecutor.new(_rules), _clock, s)
	return s


func test_view_shows_regenerated_energy_and_countdown() -> void:
	var s: GameState = _setup_service()
	var step: int = _rules.balance.en_ms
	s.energia = 10
	s.en_upd_ms = Fx.T0
	_clock.advance(step * 3 + step / 4)
	var v: Dictionary = _svc.stamina_view()
	assert_int(v["energia"]).is_equal(13)
	assert_int(v["en_max"]).is_equal(_rules.balance.en_max)
	assert_int(v["en_next_ms"]).is_equal(step - step / 4)
	assert_int(v["now_ms"]).is_equal(Fx.T0 + step * 3 + step / 4)


func test_view_shows_regenerated_courage() -> void:
	var s: GameState = _setup_service()
	var step: int = _rules.balance.co_ms
	s.coragem = 0
	s.co_upd_ms = Fx.T0
	_clock.advance(step + 500)
	var v: Dictionary = _svc.stamina_view()
	assert_int(v["coragem"]).is_equal(1)
	assert_int(v["co_max"]).is_equal(_rules.balance.co_max)
	assert_int(v["co_next_ms"]).is_equal(step - 500)


func test_full_bar_has_zero_next_ms() -> void:
	_setup_service()
	var v: Dictionary = _svc.stamina_view()
	assert_int(v["energia"]).is_equal(_rules.balance.en_max)
	assert_int(v["en_next_ms"]).is_equal(0)
	assert_int(v["coragem"]).is_equal(_rules.balance.co_max)
	assert_int(v["co_next_ms"]).is_equal(0)


func test_regen_to_full_gives_zero_next_ms() -> void:
	var s: GameState = _setup_service()
	s.energia = _rules.balance.en_max - 2
	s.en_upd_ms = Fx.T0
	_clock.advance(_rules.balance.en_ms * 50)
	var v: Dictionary = _svc.stamina_view()
	assert_int(v["energia"]).is_equal(_rules.balance.en_max)
	assert_int(v["en_next_ms"]).is_equal(0)


func test_view_does_not_change_stored_state() -> void:
	var s: GameState = _setup_service()
	s.energia = 10
	s.en_upd_ms = Fx.T0
	s.coragem = 1
	s.co_upd_ms = Fx.T0
	_clock.advance(_rules.balance.en_ms * 5 + _rules.balance.co_ms * 2)
	var before_dict: Dictionary = s.to_dict()
	_svc.stamina_view()
	_svc.stamina_view()
	assert_dict(_svc.get_state().to_dict()).is_equal(before_dict)
	assert_int(s.energia).is_equal(10)
	assert_int(s.en_upd_ms).is_equal(Fx.T0)


func test_safe_before_setup() -> void:
	assert_dict(_svc.stamina_view()).is_empty()
	assert_str(_svc.get_rules_version()).is_equal("")


func test_rules_version_after_setup() -> void:
	_setup_service()
	assert_str(_svc.get_rules_version()).is_equal(_rules.rules_version)
	assert_str(_svc.get_rules_version()).is_not_empty()
